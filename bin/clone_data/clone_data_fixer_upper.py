from csv import DictReader, DictWriter
from itertools import chain
from os import mkdir
from subprocess import run, CalledProcessError
from sys import argv
from collections import namedtuple

from matplotlib.pyplot import savefig, subplots, show as show_plot
from networkx import multipartite_layout, draw_networkx, Graph, is_isomorphic
from requests import get
from requests.exceptions import HTTPError
from sqlalchemy import create_engine, select, text, MetaData, tuple_
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import joinedload, relationship, Session

from analyse_it import (
    convert_alphanumeric_well_name_to_numeric,
    convert_numeric_well_name_to_alphanumeric,
    filter_graphs_by_shape,
    get_well_graph_from_graph,
    get_equivalence_class_by_shape
)
from check_it import (
    check_clone_data,
    check_the_server_is_up_and_running,
    print_clone_data_results,
)


class DataFixerUpperException(Exception):
    pass


class ExpectedMissingExperiment(DataFixerUpperException):
    """Raised when we can't find an experiment ID, and we weren't expecting to."""


class UnexpectedMissingExperiment(DataFixerUpperException):
    """Raised when we can't find an experiment ID, and we were expecting to."""


class NoUniqueExperiment(DataFixerUpperException):
    """Raised when there is either no or multiple experiments linked to a clone."""


class NoRowForClone(DataFixerUpperException):
    """Raised when the no row found in spreadsheet for clone"""


class MultipleRowsForClone(DataFixerUpperException):
    """Raised when multiple rows found in spreadsheet for clone"""


engine = None

Plate = None
Process = None
Well = None
MiseqWellExperiment = None
MiseqExperiment = None
Experiment = None


def init(data_base_details):
    global engine, Plate, Process, Well, MiseqWellExperiment, MiseqExperiment, Experiment
    engine = create_engine(f"postgresql://{data_base_details}")
    metadata = MetaData()
    metadata.reflect(
        engine,
        only=[
            "plates",
            "process_input_well",
            "process_output_well",
            "processes",
            "miseq_experiment",
            "miseq_well_experiment",
            "wells",
            "experiments",
            "miseq_alleles_frequency",
            "indel_histogram",
        ]
    )
    Base = automap_base(metadata=metadata)
    wells = metadata.tables["wells"]
    processes = metadata.tables["processes"]
    process_input_well = metadata.tables["process_input_well"]
    process_output_well = metadata.tables["process_output_well"]
    well_to_well_join = process_input_well.join(processes, process_input_well.c.process_id == processes.c.id).join(process_output_well, process_output_well.c.process_id == processes.c.id)
    class Well(Base):
        __tablename__ = "wells"
        next_wells = relationship(
            "Well",
            secondary=well_to_well_join,
            primaryjoin=wells.c.id == process_input_well.c.well_id,
            secondaryjoin=process_output_well.c.well_id == wells.c.id,
            viewonly=True,
        )
        def __repr__(self):
            return self.plates.name + "_" + self.name
    class MiseqWellExperiment(Base):
        __tablename__ = "miseq_well_experiment"
        def __repr__(self):
            return str(self.id)
    class MiseqExperiment(Base):
        __tablename__ = "miseq_experiment"
        def __repr__(self):
            return str(self.id) + ":" + self.name
    class Experiment(Base):
        __tablename__ = "experiments"
        def __repr__(self):
            return str(self.id)
    Base.prepare()
    Plate = Base.classes.plates
    Process = Base.classes.processes
    return metadata


def get_clones(*, expected_number_of_clones):
    Clone = namedtuple("Clone", ["plate", "well"])
    with open("get_list_of_clones.sql") as clones_sql:
        with engine.connect() as conn:
            results = conn.execute(text(clones_sql.read())).all()
            clones = {
                Clone(*result)
                for result in results
            }

    assert len(clones) == expected_number_of_clones, f"Expected {expected_number_of_clones} clones, found {len(clones)}."

    return clones


def get_fp_wells_from_clones(clones):
    with Session(engine) as session:
        results = session.execute(
            select(Well)
            .join(Well.plates)
            .where(tuple_(Plate.name, Well.name).in_(clones))
            .options(joinedload(Well.plates))
        )
        wells = [r.Well for r in results]
    return wells


def get_piq_wells_from_fp_well(fp_well):
    with Session(engine) as session:
        session.add(fp_well)
        next_wells = fp_well.next_wells
        # Probably a way to do this using a query, rather than in code, but for now...
        piq_wells = [well for well in next_wells if well.plates.type_id == "PIQ"]
    return piq_wells


def get_miseq_wells_from_piq_well(piq_well):
    with Session(engine) as session:
        session.add(piq_well)
        next_wells = piq_well.next_wells
        # Access plates attribute to populate - this seems a bit hacky, not to say inneffiecient, but...
        for well in next_wells:
            well.plates
        # Probably a way to do this using a query, rather than in code, but for now...
        miseq_wells = [well for well in next_wells if well.plates.type_id == "MISEQ"]
    return miseq_wells


def get_miseq_well_experiments_from_miseq_well(miseq_well):
    with Session(engine) as session:
        session.add(miseq_well)
        return miseq_well.miseqwellexperiment_collection

def get_miseq_experiment_from_miseq_well_experiment(miseq_well_experiment):
    with Session(engine) as session:
        session.add(miseq_well_experiment)
        return miseq_well_experiment.miseqexperiment


def add_experiments_to_miseq_experiments(graphs):
    with open("missing-misseq-wells - fp_and_piq_wells_for_fp_plates_that_only_have_missing_miseq_wells.tsv", newline='') as f:
        reader = DictReader(f, delimiter="\t")
        rows_with_miseq_experiment = [row for row in reader if row["miseq_experiment_name"]]
        for row in rows_with_miseq_experiment:
            graph_for_row = get_graph_containing_fp_well(graphs, row["fp_plate"], row["fp_well"])
            try:
                experiment = get_experiment_from_graph(graph_for_row)
            except NoUniqueExperiment:
                print(f"No unique experiment for {row['fp_plate']}_{row['fp_well']}")
                return
            ids_of_miseq_experiments_in_graph = [
                me.id
                for me in get_miseq_experiments_from_graph(graph_for_row)
            ]
            with Session(engine) as session, session.begin():
                results = session.execute(
                    select(MiseqExperiment)
                    .where(MiseqExperiment.name == row["miseq_experiment_name"])
                    .where(MiseqExperiment.id.in_(ids_of_miseq_experiments_in_graph))
                )
                miseq_experiment = results.scalar_one_or_none()
                if miseq_experiment is not None and miseq_experiment.experiment_id is None:
                    print(f"Adding experiment {experiment.id} to miseq experiment {miseq_experiment.id}")
                    miseq_experiment.experiment_id = experiment.id
                if miseq_experiment is None:
                    print(f"Couldn't fix up experiment/miseq-experiment data for {row['fp_plate']}_{row['fp_well']}")


def delete_miseq_well_experiment(miseq_well_experiment):
    with Session(engine) as session, session.begin():
        session.delete(miseq_well_experiment)


def get_experiment_from_fp_well(fp_well):
    try:
        experiment_id = get_experiment_id_for_clone(fp_well.plates.name, fp_well.name)
    except ExpectedMissingExperiment:
        return
    with Session(engine) as session:
        experiments = session.execute(
            select(Experiment).where(Experiment.id == experiment_id)
        )
        experiment = experiments.scalar_one_or_none()
        if experiment is None:
            raise RuntimeError(f"No experiment found for {experiment_id}")
        return experiment


def get_experiment_id_for_clone(plate_name, well_name):
    response = get(
        f"http://localhost:8081/public_reports/get_experiment_id_from_clone/{plate_name}/{well_name}",
        headers={"accept": "application/json"},
    )
    try:
        response.raise_for_status()
    except HTTPError as e:
        if e.response.status_code != 500:
            raise
        clone_name = plate_name + "_" + well_name
        if clone_name in [
           "HUPFP0039_2_F10",
           "HUPFP0039_2_E10",
           "HUPFP0020_10_E08",
           "HUPFP0020_10_C12",
           "HUPFP0020_10_G05",
           "HUPFP0020_10_G07",
        ]:
            print(f"Known missing experiment for: {clone_name}")
            raise ExpectedMissingExperiment()
        print(f"Unexpected missing experiment for: {clone_name}")
        raise UnexpectedMissingExperiment()
    experiment_id = response.json()[0]
    return experiment_id


def create_graph_from_fp_well(fp_well):
    graph = Graph()
    graph.add_node(fp_well, **{"type": "fp_well", "layer": 1})
    return graph


def add_piq_wells_to_graph(graph):
    fp_wells = [node for node, attributes in graph.nodes.items() if attributes["type"] == "fp_well"]
    for fp_well in fp_wells:
        for piq_well in get_piq_wells_from_fp_well(fp_well):
            graph.add_node(piq_well, **{"type": "piq_well", "layer": 2})
            graph.add_edge(fp_well, piq_well)


def add_miseq_wells_to_graph(graph):
    piq_wells = [node for node, attributes in graph.nodes.items() if attributes["type"] == "piq_well"]
    for piq_well in piq_wells:
        for miseq_well in get_miseq_wells_from_piq_well(piq_well):
            graph.add_node(miseq_well, **{"type": "miseq_well", "layer": 3})
            graph.add_edge(piq_well, miseq_well)


def add_miseq_well_experiments_to_graph(graph):
    miseq_wells = [node for node, attributes in graph.nodes.items() if attributes["type"] == "miseq_well"]
    for miseq_well in miseq_wells:
        for miseq_well_experiment in get_miseq_well_experiments_from_miseq_well(miseq_well):
            graph.add_node(miseq_well_experiment, **{"type": "miseq_well_experiment", "layer": 4})
            graph.add_edge(miseq_well, miseq_well_experiment)


def add_miseq_experiments_to_graph(graph):
    miseq_well_experiments = [
        node for node, attributes
        in graph.nodes.items()
        if attributes["type"] == "miseq_well_experiment"
    ]
    for miseq_well_experiment in miseq_well_experiments:
        miseq_experiment = get_miseq_experiment_from_miseq_well_experiment(miseq_well_experiment)
        if miseq_experiment:
            graph.add_node(miseq_experiment, **{"type": "miseq_experiment", "layer": 5})
            graph.add_edge(miseq_well_experiment, miseq_experiment)


def add_experiments_to_graph(graph):
    fp_wells = [node for node, attributes in graph.nodes.items() if attributes["type"] == "fp_well"]
    for fp_well in fp_wells:
        experiment = get_experiment_from_fp_well(fp_well)
        if experiment is None:
            continue
        graph.add_node(experiment, **{"type": "experiment", "layer": 1})
        graph.add_edge(fp_well, experiment)


def add_experiment_miseq_experiment_relation_to_graph(graph):
    try:
        experiment = get_experiment_from_graph(graph)
    except NoUniqueExperiment:
        return
    miseq_experiments_for_experiment = [
        me for me in get_miseq_experiments_from_graph(graph)        
        if me.experiment_id == experiment.id
    ]
    for miseq_experiment in miseq_experiments_for_experiment:
        graph.add_edge(experiment, miseq_experiment)


def create_graphs_from_clones(clones):
    fp_wells = get_fp_wells_from_clones(clones)
    graphs = [create_graph_from_fp_well(fp_well) for fp_well in fp_wells]
    for graph in graphs:
        add_piq_wells_to_graph(graph)
        add_miseq_wells_to_graph(graph)
        add_miseq_well_experiments_to_graph(graph)
        add_miseq_experiments_to_graph(graph)
        add_experiments_to_graph(graph)
        add_experiment_miseq_experiment_relation_to_graph(graph)
    return graphs


def create_equivalence_classes(graphs):
    equivalence_classes = []
    for graph in graphs:
        for equivalence_class in equivalence_classes:
            other_graph = equivalence_class[0]
            if is_isomorphic(graph, other_graph, node_match=lambda n1, n2: n1["type"] == n2["type"]):
                equivalence_class.append(graph)
                break
        else:
            equivalence_classes.append([graph])

    return equivalence_classes


def assert_the_biggest_equivalence_class_has_graphs_of_the_expected_shape(equivalence_classes):
    expected_graph = happy_shape()
    biggest_ec_example = sorted(equivalence_classes, key=len)[-1][0]
    assert is_isomorphic(
        expected_graph,
        biggest_ec_example,
        node_match=lambda n1, n2: n1["type"] == n2["type"]
    )


def assert_wells_correct_for_known_example(graphs):
    graph = get_graph_containing_fp_well(graphs, "HUPFP0085A1", "C10")
    assert is_isomorphic(
        get_well_graph_from_graph(graph),
        happy_shape(),
        node_match=lambda n1, n2: n1["type"] == n2["type"],
    )
    fp_well = get_fp_well_from_graph(graph)
    assert fp_well.plates.name == "HUPFP0085A1"
    assert fp_well.name == "C10"
    piq_wells = get_piq_wells_from_graph(graph)
    assert len(piq_wells) == 1
    assert piq_wells[0].plates.name == "HUEDQ0591"
    assert piq_wells[0].name == "B01"
    miseq_wells = get_miseq_wells_from_graph(graph)
    assert len(miseq_wells) == 1
    assert miseq_wells[0].plates.name == "Miseq_116"
    assert miseq_wells[0].name == "J13"


def assert_miseq_experiment_correct_for_known_example(graphs):
    # We test using the example HUPFP0085A1_C10 from 
    # https://jira.sanger.ac.uk/browse/LIMS-46
    graph = get_graph_containing_fp_well(graphs, "HUPFP0085A1", "C10")
    miseq_experiment_names = [n.name for n, d in graph.nodes(data=True) if d["type"] == "miseq_experiment"]
    # Just check required miseq experiment is in list of all miseq experiments - others will exist.
    assert "HUEDQ0591_BRPF1" in miseq_experiment_names, f"Found miseq experiment names: {miseq_experiment_names}"


def assert_experiment_miseq_experiment_relation_correct_for_known_example(graphs):
    graph = get_graph_containing_fp_well(graphs, "HUPFP0085A1", "C10")
    experiment_miseq_experiment_graph = graph.subgraph(
        get_experiment_from_graph(graph) + get_miseq_experiments_from_graph(graph)
    )
    edges = experiment_miseq_experiment_graph.edges
    assert len(edges) == 1
    assert edges[0][0].id == "2518"
    assert edges[0][1].name == "HUEDQ0591_BRPF1"


def assert_correct_number_of_graphs(graphs, expected_number_of_graphs):
    assert len(graphs) == expected_number_of_clones, f"Expected {expected_number_of_clones} freeze plate wells,found {len(graphs)}."


def plot_equivalence_class_exmaples(equivalence_classes):
    fig, axes = subplots(nrows=len(equivalence_classes), **{"figsize": (10, 50)})
    for equivalence_class, axis in zip(equivalence_classes, axes):
        graph = equivalence_class[0]
        draw_networkx(graph, ax=axis, pos=multipartite_layout(graph, subset_key="layer"))
        fp_well = get_fp_well_from_graph(graph)
        axis.set_title(f"Number of cases: {len(equivalence_class)}  -  Example:  {fp_well}")
    fig.tight_layout()
    savefig("well_graphs.png")


def plot_one_piq_two_miseq_graphs(graphs):
    one_piq_two_miseq_graphs = filter_graphs_by_shape(
        graphs=graphs,
        shape=one_piq_two_miseq_shape(),
        with_respect_to_types=["fp_well", "piq_well", "miseq_well"]
    )
    fig, axes = subplots(nrows=len(one_piq_two_miseq_graphs), **{"figsize": (10, 5*len(one_piq_two_miseq_graphs))})
    for graph, axis in zip(one_piq_two_miseq_graphs, axes):
        draw_networkx(graph, ax=axis, pos=multipartite_layout(graph, subset_key="layer"))
        fp_well = get_fp_well_from_graph(graph)
        axis.set_title(f"Clone: {fp_well}")
    fig.tight_layout()
    savefig("one_piq_two_miseq_graphs.png")


def print_out_wells_for_one_piq_two_miseq_cases(graphs):
    one_piq_two_miseq_graphs = filter_graphs_by_shape(
        graphs=graphs,
        shape=one_piq_two_miseq_shape(),
        with_respect_to_types=["fp_well", "piq_well", "miseq_well"]
    )
    print("One PIQ - two Miseq Cases:")
    print("fp_plate, fp_well, piq_plate, piq_well, possible_miseqs")
    for graph in one_piq_two_miseq_graphs:
        print(
            "{}, {}, {}, {}, {}".format(
                get_fp_well_from_graph(graph).plates.name,
                get_fp_well_from_graph(graph).name,
                get_piq_wells_from_graph(graph)[0].plates.name,
                get_piq_wells_from_graph(graph)[0].name,
                get_miseq_wells_from_graph(graph),
            )
        )


def get_fp_well_from_graph(graph):
    fp_wells = [n for n, d in graph.nodes(data=True) if d["type"] == "fp_well"]
    assert len(fp_wells) == 1
    return fp_wells[0]


def get_piq_wells_from_graph(graph):
    piq_wells = [n for n, d in graph.nodes(data=True) if d["type"] == "piq_well"]
    return piq_wells


def get_miseq_wells_from_graph(graph):
    miseq_wells = [n for n, d in graph.nodes(data=True) if d["type"] == "miseq_well"]
    return miseq_wells


def get_miseq_experiments_from_graph(graph):
    miseq_experiments = [n for n, d in graph.nodes(data=True) if d["type"] == "miseq_experiment"]
    return miseq_experiments


def get_experiment_from_graph(graph):
    experiments = [n for n, d in graph.nodes(data=True) if d["type"] == "experiment"]
    if len(experiments) != 1:
        raise NoUniqueExperiment()
    return experiments[0]


def get_plate_names_from_graphs(graphs):
    return {
        get_fp_well_from_graph(graph).plates.name
        for graph in graphs
    }


def get_plate_names_by_shape(equivalence_classes_and_plate_names, shape):
    for equivalence_class, plate_names in equivalence_classes_and_plate_names:
        if is_isomorphic(equivalence_class[0], shape):
            return plate_names
    raise RuntimeError("Can't find graphs with correct shape")


def happy_shape():
    graph = Graph()
    graph.add_node(1, **{"type": "fp_well"})
    graph.add_node(2, **{"type": "piq_well"})
    graph.add_node(3, **{"type": "miseq_well"})
    graph.add_edge(1,2)
    graph.add_edge(2,3)

    return graph


def missing_miseq_shape():
    graph = Graph()
    graph.add_node(1, **{"type": "fp_well"})
    graph.add_node(2, **{"type": "piq_well"})
    graph.add_edge(1,2)

    return graph


def two_piqs_two_miseq_shape():
    graph = Graph()
    graph.add_node(1, **{"type": "fp_well"})
    graph.add_node(2, **{"type": "piq_well"})
    graph.add_node(3, **{"type": "piq_well"})
    graph.add_node(4, **{"type": "miseq_well"})
    graph.add_node(5, **{"type": "miseq_well"})
    graph.add_edge(1,2)
    graph.add_edge(1,3)
    graph.add_edge(2,4)
    graph.add_edge(3,5)

    return graph


def one_piq_two_miseq_shape():
    graph = Graph()
    graph.add_node(1, **{"type": "fp_well"})
    graph.add_node(2, **{"type": "piq_well"})
    graph.add_node(3, **{"type": "miseq_well"})
    graph.add_node(4, **{"type": "miseq_well"})
    graph.add_edge(1,2)
    graph.add_edge(2,3)
    graph.add_edge(2,4)

    return graph


def get_all_piq_plate_names(graphs):
    all_piq_wells = chain(*[get_piq_wells_from_graph(g) for g in graphs])
    return {
        pw.plates.name for pw in all_piq_wells
    }


def get_graphs_containing_wells_in_piq_plate(graphs, piq_plate_name):
    piq_plate_name_graphs = []
    for graph in graphs:
        piq_wells = get_piq_wells_from_graph(graph)
        if piq_plate_name in [p.plates.name for p in piq_wells]:
            piq_plate_name_graphs.append(graph)

    return piq_plate_name_graphs


def get_graph_containing_fp_well(graphs, plate_name, well_name):
    fp_well_graphs = []
    for graph in graphs:
        fp_well = get_fp_well_from_graph(graph)
        if fp_well.plates.name == plate_name and fp_well.name == well_name:
            fp_well_graphs.append(graph)
    assert len(fp_well_graphs) == 1, f"Expecting only one graph but found {len(fp_well_graphs)}"
    return fp_well_graphs[0]


def plot_graphs_grouped_by_piq_plate(graphs, piq_plate_names):
    mkdir("graphs_grouped_by_piq_plate")
    for piq_plate_name in piq_plate_names:
        piq_plate_graphs = get_graphs_containing_wells_in_piq_plate(graphs, piq_plate_name)
        fig, axes = subplots(nrows=len(piq_plate_graphs), **{"figsize": (10, 5*len(piq_plate_graphs))})
        # Rubbish API - axes is a single object if len is 1.
        try:
            iter(axes)
        except TypeError:
            axes = [axes]
        for piq_plate_graph, axis in zip(piq_plate_graphs, axes):
            draw_networkx(piq_plate_graph, ax=axis, pos=multipartite_layout(piq_plate_graph, subset_key="layer"))
            fp_well = get_fp_well_from_graph(piq_plate_graph)
            axis.set_title(f"FP well:  {fp_well}")
        fig.tight_layout()
        savefig(f"graphs_grouped_by_piq_plate/{piq_plate_name}.png")


def create_tsv_of_fp_and_piq_well_details_for_wells_with_missing_miseq_plates(plates_with_just_missing_miseq_wells, clones):
    """
    A complete list of fp/piq wells for clones where,
        * There is a single mapping from the fp well containing the clone to a piq well.
        * The fp well containing the clone is on a plate in which *none* of the wells
          on that plate have a mapping (via a piq well) to a miseq plate.
    """
    with open("fp_and_piq_wells_for_fp_plates_that_only_have_missing_miseq_wells.tsv", "w", newline='') as f:
        fp_and_piq_writer = DictWriter(f, fieldnames=["fp_plate", "fp_well", "piq_plate", "piq_well"], delimiter="\t")
        fp_and_piq_writer.writeheader()
        for plate_name in plates_with_just_missing_miseq_wells:
            clones_in_missing_miseq_plate_example = [c for c in clones if c.plate == plate_name]
            fp_wells_for_clones = get_fp_wells_from_clones(clones_in_missing_miseq_plate_example)
            for fp_well in fp_wells_for_clones:
                piq_well = get_piq_wells_from_fp_well(fp_well)[0]
                fp_and_piq_writer.writerow({
                    "fp_plate": fp_well.plates.name,
                    "fp_well": fp_well.name,
                    "piq_plate": piq_well.plates.name,
                    "piq_well": piq_well.name,
                })


def create_missing_piq_miseq_well_relations(graphs, docker_image):
    with open("missing-misseq-wells - fp_and_piq_wells_for_fp_plates_that_only_have_missing_miseq_wells.tsv", newline='') as f:
        reader = DictReader(f, delimiter="\t")
        rows_with_miseq_data = [row for row in reader if row["miseq_plate"] and row["miseq_well"]]
    one_piq_no_miseq_graphs = filter_graphs_by_shape(
        graphs=graphs,
        shape=missing_miseq_shape(),
        with_respect_to_types=["fp_well", "piq_well", "miseq_well"]
    )
    for graph in one_piq_no_miseq_graphs:
        fp_well = get_fp_well_from_graph(graph)
        try:
            row_for_clone = get_row_for_clone(rows_with_miseq_data, fp_well.plates.name, fp_well.name)
        except (NoRowForClone, MultipleRowsForClone):
            continue
        run(
            (
                "docker" " run"
                " --rm"
                " --env" " LIMS2_DB=LIMS2_CLONE_DATA"
                f" {docker_image}"
                " ./bin/clone_data/add-piq-to-miseq-process-between-wells.pl"
                    f" --piq_plate_name {row_for_clone['piq_plate']}"
                    f" --piq_well_name {row_for_clone['piq_well']}"
                    f" --miseq_plate_name {row_for_clone['miseq_plate']}"
                    f" --miseq_well_number {row_for_clone['miseq_well']}"
            ),
            check=True,
            shell=True,
        )


def delete_extraneous_piq_miseq_well_relations(graphs, docker_image):
    with open("missing-misseq-wells - fp_and_piq_wells_for_fp_plates_that_only_have_missing_miseq_wells.tsv", newline='') as f:
        reader = DictReader(f, delimiter="\t")
        rows_with_miseq_data = [row for row in reader if row["miseq_plate"] and row["miseq_well"]]
    one_piq_two_miseq_graphs = filter_graphs_by_shape(
        graphs=graphs,
        shape=one_piq_two_miseq_shape(),
        with_respect_to_types=["fp_well", "piq_well", "miseq_well"]
    )
    for graph in one_piq_two_miseq_graphs:
        fp_well = get_fp_well_from_graph(graph)
        piq_well = get_piq_wells_from_graph(graph)[0]
        miseq_wells = get_miseq_wells_from_graph(graph)
        try:
            row_for_clone = get_row_for_clone(rows_with_miseq_data, fp_well.plates.name, fp_well.name)
        except (NoRowForClone, MultipleRowsForClone):
            continue
        miseq_plate_from_row =  row_for_clone["miseq_plate"]
        miseq_well_from_row =  convert_numeric_well_name_to_alphanumeric(row_for_clone["miseq_well"])
        bad_miseq_wells = [
            miseq_well for miseq_well in miseq_wells
            if not (
                miseq_well.plates.name == miseq_plate_from_row
                and
                miseq_well.name == miseq_well_from_row
            )
        ]
        if len(bad_miseq_wells) != len(miseq_wells) - 1:
            print(f"bad: {bad_miseq_wells}, all: {miseq_wells}, row: {miseq_plate_from_row}_{miseq_well_from_row}")
            continue
        for miseq_well in bad_miseq_wells:
            try:
                print(f"Deleting relation for {piq_well} - {miseq_well}.")
                run(
                    (
                        "docker run"
                        " --rm"
                        " --env LIMS2_DB=LIMS2_CLONE_DATA"
                        " --env PERL5LIB=/home/user/git_checkout/LIMS2-WebApp/lib/:/opt/sci/global/software/lims2/lib/"
                        f" {docker_image}"
                        " ./bin/clone_data/delete-processes-between-wells.pl"
                            f" --piq_plate_name {piq_well.plates.name}"
                            f" --piq_well_name {piq_well.name}"
                            f" --miseq_plate_name {miseq_well.plates.name}"
                            f" --miseq_well_name {miseq_well.name}"
                    ),
                    check=True,
                    shell=True,
                    capture_output=True,
                )
            except CalledProcessError as e:
                print(e.stdout)
                print(e.stderr)
                raise e


def delete_extraneous_miseq_well_experiments(graphs):
    print("Deleting extraeous miseq well experiments")
    with open("missing-misseq-wells - fp_and_piq_wells_for_fp_plates_that_only_have_missing_miseq_wells.tsv", newline='') as f:
        reader = DictReader(f, delimiter="\t")
        rows_with_miseq_experiment_data = [row for row in reader if row["miseq_experiment_name"]]
    graphs_with_correct_well_relations = filter_graphs_by_shape(
        graphs=graphs,
        shape=happy_shape(),
        with_respect_to_types=["fp_well", "piq_well", "miseq_well"]
    )
    graphs_with_multiple_experiment_miseq_experiment_relations = [
        graph for graph in graphs_with_correct_well_relations 
        if len(get_experiment_miseq_experiment_subgraph(graph).edges) > 1
    ]
    for graph in graphs_with_multiple_experiment_miseq_experiment_relations:
        fp_well = get_fp_well_from_graph(graph)
        try:
            row_for_clone = get_row_for_clone(rows_with_miseq_experiment_data, fp_well.plates.name, fp_well.name)
        except (NoRowForClone, MultipleRowsForClone):
            continue
        miseq_experiments = get_miseq_experiments_from_graph(
            get_experiment_miseq_experiment_subgraph(graph)
        )
        bad_miseq_experiments = [
            me for me in miseq_experiments 
            if me.name != row_for_clone["miseq_experiment_name"]
        ]
        if len(bad_miseq_experiments) != len(miseq_experiments) - 1:
            print(f"bad: {bad_miseq_experiments}, all: {miseq_experiments}, row: {row_for_clone['miseq_experiment_name']}")
            continue
        bad_miseq_well_experiments = [
            n
            for n, l in graph.nodes(data=True)
            if l["type"] == "miseq_well_experiment" and n in sum([list(graph[m]) for m in bad_miseq_experiments], [])
        ]
        for miseq_well_experiment in bad_miseq_well_experiments:  
            delete_miseq_well_experiment(miseq_well_experiment) 

    
def get_experiment_miseq_experiment_subgraph(graph):
    try:
        experiment = get_experiment_from_graph(graph)
    except NoUniqueExperiment:
        return Graph()
    return (
        graph
        .subgraph([experiment] + get_miseq_experiments_from_graph(graph))
        .subgraph([experiment] + list(graph[experiment]))
    )



def get_row_for_clone(rows, plate_name, well_name):
    rows_with_correct_plate_and_well = [
        row for row in rows
        if row["fp_plate"] == plate_name and row["fp_well"] == well_name
    ]
    if len(rows_with_correct_plate_and_well) == 0:
        raise NoRowForClone(f"No rows for {plate_name}_{well_name}")
    if len(rows_with_correct_plate_and_well) > 1:
        raise MultipleRowsForClone(f"Multiple rows for {plate_name}_{well_name}")
    return rows_with_correct_plate_and_well[0]


def show_graph(graph):
    """Renders the graph to screem.

    This exists to be used interactively from a python shell.
    It's not used as part of the script.
    """
    draw_networkx(graph, pos=multipartite_layout(graph, subset_key="layer"))
    show_plot()


def print_clones_with_extraneous_miseq_experiments(results, graphs):
    with open("missing-misseq-wells - fp_and_piq_wells_for_fp_plates_that_only_have_missing_miseq_wells.tsv", newline='') as f:
        reader = DictReader(f, delimiter="\t")
        rows = list(reader)
    # Get all graphs with good well relations.
    _ = filter_graphs_by_shape(
        graphs=graphs,
        shape=happy_shape(),
        with_respect_to_types=["fp_well", "piq_well", "miseq_well"]
    )
    # Get those extraneous experiment - miseq-well-experiment relations.
    _ = [
        graph for graph in _ 
        if len(get_experiment_miseq_experiment_subgraph(graph).edges) > 1
    ]
    # Exclude those for which we already have good results.
    _ = [
        graph for graph in _
        if (
            (fp_well:=get_fp_well_from_graph(graph)).plates.name + "_" + fp_well.name
            not in 
            [result.clone_name for result in results if result.error is None]
        )
    ]
    # Exclude those already on our spreadsheet.
    filtered_graphs = [
        graph for graph in _
        if len(
            [
                row for row in rows 
                if (
                    row["fp_plate"] == (fp_well:=get_fp_well_from_graph(graph)).plates.name
                    and 
                    row["fp_well"] == fp_well.name
                )
            ]
        ) == 0
    ]


    print("Multiple miseq-experiment cases:")
    print("fp_plate, fp_well, piq_plate, piq_well, miseq_plate, miseq_well, possible_miseq_experiments")
    for graph in filtered_graphs:
        fp_well = get_fp_well_from_graph(graph)
        piq_well = get_piq_wells_from_graph(graph)[0]
        miseq_well = get_miseq_wells_from_graph(graph)[0]
        associated_miseq_experiments = get_miseq_experiments_from_graph(
            get_experiment_miseq_experiment_subgraph(graph)
        )
        print(
            "{}, {}, {}, {}, {}, {}, {}".format(
                fp_well.plates.name,
                fp_well.name,
                piq_well.plates.name,
                piq_well.name,
                miseq_well.plates.name,
                convert_alphanumeric_well_name_to_numeric(miseq_well.name),
                associated_miseq_experiments,
            )
        )


if __name__ == "__main__":

    data_base_details = argv[1]
    docker_image = argv[2]

    check_the_server_is_up_and_running()

    init(data_base_details)

    # This might change if staging db is updated, but shouldn't decrease.
    expected_number_of_clones = 1866
    clones = get_clones(expected_number_of_clones=expected_number_of_clones)

    results_from_checking = check_clone_data(clones)
    print("Results before fixing:")
    print_clone_data_results(results_from_checking)

    graphs = create_graphs_from_clones(clones)
    assert_correct_number_of_graphs(graphs, expected_number_of_clones)
    assert_wells_correct_for_known_example(graphs)
    assert_miseq_experiment_correct_for_known_example(graphs)

    plot_one_piq_two_miseq_graphs(graphs)
    print_out_wells_for_one_piq_two_miseq_cases(graphs)

    equivalence_classes = create_equivalence_classes(
        [get_well_graph_from_graph(graph) for graph in graphs]
    )
    assert_the_biggest_equivalence_class_has_graphs_of_the_expected_shape(equivalence_classes)
    print(f"Number of equivalence classes: {len(equivalence_classes)}")
    print(f"Graphs in each equivalence class: {[len(ec) for ec in equivalence_classes]}")
    assert sorted([len(ec) for ec in equivalence_classes], reverse=True) == [1184, 499, 114, 30, 23, 9, 4, 2, 1]
    plot_equivalence_class_exmaples(equivalence_classes)

    equivalence_classes_and_plate_names = [
        (ec, get_plate_names_from_graphs(ec))
        for ec in equivalence_classes
    ]

    happy_plate_names = get_plate_names_by_shape(equivalence_classes_and_plate_names, happy_shape())
    missing_miseq_plate_names = get_plate_names_by_shape(equivalence_classes_and_plate_names, missing_miseq_shape())

    graphs_with_two_piq_plates_and_two_miseq_wells = get_equivalence_class_by_shape(equivalence_classes, two_piqs_two_miseq_shape())
    clone_names_for_graphs_with_two_piq_plates_and_two_miseq_wells = {
        str(get_fp_well_from_graph(graph))
        for graph in graphs_with_two_piq_plates_and_two_miseq_wells 
    }
    print(f"clone_names_for_graphs_with_two_piq_plates_and_two_miseq_wells: {clone_names_for_graphs_with_two_piq_plates_and_two_miseq_wells}")

    print(f"Plates with just happy wells: {happy_plate_names - missing_miseq_plate_names}")
    print(f"Plates with happy and missing-miseq wells: {happy_plate_names & missing_miseq_plate_names}")
    plates_with_just_missing_miseq_wells = missing_miseq_plate_names - happy_plate_names
    print(f"Plates with just missing-miseq wells: {plates_with_just_missing_miseq_wells}")
    create_tsv_of_fp_and_piq_well_details_for_wells_with_missing_miseq_plates(plates_with_just_missing_miseq_wells, clones)
    all_piq_plate_names = get_all_piq_plate_names(graphs)
    plot_graphs_grouped_by_piq_plate(graphs, all_piq_plate_names)

    create_missing_piq_miseq_well_relations(graphs, docker_image)

    # We need to 'refresh' the graph to take in to account the changes from
    # adding the missing miseq_well relations.
    graphs = create_graphs_from_clones(clones)
    add_experiments_to_miseq_experiments(graphs)

    delete_extraneous_piq_miseq_well_relations(graphs, docker_image)

    graphs = create_graphs_from_clones(clones)
    delete_extraneous_miseq_well_experiments(graphs)

    results_from_checking = check_clone_data(clones)
    print("Results after fixing:")
    print_clone_data_results(results_from_checking)

    print("Good clones that previously had two PIQ/Miseq wells:")
    good_and_two_piq_miseq = [
        result for result in results_from_checking
        if result.error == None
        if result.clone_name in clone_names_for_graphs_with_two_piq_plates_and_two_miseq_wells 
    ]
    print("Clone name, Miseq experiment")
    for result in good_and_two_piq_miseq:
        print(result.clone_name + ", " + result.json_data["miseq_data"]["experiment_name"])

    # We need to 'refresh' the graph to take in to account the changes from
    # deleting some extraneous ones.
    graphs = create_graphs_from_clones(clones)
    print_clones_with_extraneous_miseq_experiments(results_from_checking, graphs)

