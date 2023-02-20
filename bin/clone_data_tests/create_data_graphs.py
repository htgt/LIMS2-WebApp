from sys import argv
from collections import namedtuple

from matplotlib.pyplot import savefig, subplots
from networkx import multipartite_layout, draw_networkx, Graph, is_isomorphic
from sqlalchemy import create_engine, select, text, MetaData, tuple_
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import joinedload, relationship, Session


engine = None

Plate = None
Process = None
Well = None


def init(data_base_details):
    global engine, Plate, Process, Well
    engine = create_engine(f"postgresql://{data_base_details}")
    metadata = MetaData()
    metadata.reflect(engine, only=["plates", "process_input_well", "process_output_well", "processes", "wells"])
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
    Base.prepare()
    Plate = Base.classes.plates
    Process = Base.classes.processes
    return metadata


def get_clones():
    Clone = namedtuple("Clone", ["plate", "well"])
    with open("bin/get_list_of_clones.sql") as clones_sql:
        with engine.connect() as conn:
            results = conn.execute(text(clones_sql.read())).all()
            clones = {
                Clone(*result)
                for result in results
            }
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


def plot_graphs(equivalence_classes):
    fig, axes = subplots(nrows=len(equivalence_classes), **{"figsize": (10, 50)})
    for equivalence_class, axis in zip(equivalence_classes, axes):
        graph = equivalence_class[0]
        draw_networkx(graph, ax=axis, pos=multipartite_layout(graph, subset_key="layer"))
        fp_well = get_fp_well_from_graph(graph)
        axis.set_title(f"Number of cases: {len(equivalence_class)}  -  Example:  {fp_well}")
    fig.tight_layout()
    savefig("well_graphs.png")


def get_fp_well_from_graph(graph):
    fp_wells = [n for n, d in graph.nodes(data=True) if d["type"] == "fp_well"]
    assert len(fp_wells) == 1
    return fp_wells[0]


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



if __name__ == "__main__":

    data_base_details = argv[1]
    init(data_base_details)

    # This might change if staging db is updated, but shouldn't decrease.
    clones = get_clones()
    expected_number_of_clones = 1866
    assert len(clones) == expected_number_of_clones, f"Expected {expected_number_of_clones} clones, found {len(clones)}."

    fp_wells = get_fp_wells_from_clones(clones)
    # Should be one well for each clone.
    assert len(fp_wells) == expected_number_of_clones, f"Expected {expected_number_of_clones} freeze plate wells,found {len(fp_wells)}."
    # Check that known clone, HUPFP0085A1_C10 from LIMS-46 tests, is in returned data.
    try:
        test_fp_well = list(filter(
            lambda well: well.name == "C10" and well.plates.name == "HUPFP0085A1", fp_wells
        ))[0]
    except IndexError:
        assert False, "Cannot find well for HUPFP0085A1_C10"

    test_piq_wells = get_piq_wells_from_fp_well(test_fp_well)
    assert len(test_piq_wells) == 1, f"Found {len(test_piq_wells)}"
    test_piq_well = test_piq_wells[0]
    full_well_name = test_piq_well.plates.name + "_" + test_piq_well.name
    assert full_well_name == "HUEDQ0591_B01", f"Full well name is {full_well_name}"
    graphs = [create_graph_from_fp_well(fp_well) for fp_well in fp_wells]
    for graph in graphs:
        add_piq_wells_to_graph(graph)
        add_miseq_wells_to_graph(graph)
    equivalence_classes = create_equivalence_classes(graphs)
    assert_the_biggest_equivalence_class_has_graphs_of_the_expected_shape(equivalence_classes)

    print(f"Number of equivalence classes: {len(equivalence_classes)}")
    print(f"Graphs in each equivalence class: {[len(ec) for ec in equivalence_classes]}")

    plot_graphs(equivalence_classes)

    equivalence_classes_and_plate_names = [
        (ec, get_plate_names_from_graphs(ec))
        for ec in equivalence_classes
    ]

    happy_plate_names = get_plate_names_by_shape(equivalence_classes_and_plate_names, happy_shape())
    missing_miseq_plate_names = get_plate_names_by_shape(equivalence_classes_and_plate_names, missing_miseq_shape())

    print(f"Plates with just happy wells: {happy_plate_names - missing_miseq_plate_names}")
    print(f"Plates with happy and missing-miseq wells: {happy_plate_names & missing_miseq_plate_names}")
    print(f"Plates with just missing-miseq wells: {missing_miseq_plate_names - happy_plate_names}")

    plate_with_just_missing_miseq_wells = missing_miseq_plate_names - happy_plate_names
    example_just_missing_miseq_plate = plate_with_just_missing_miseq_wells.pop()
    clones_in_missing_miseq_plate_example = [c for c in clones if c.plate == example_just_missing_miseq_plate]
    print(f"Clones in missing-miseq plate example {example_just_missing_miseq_plate}: {[c.plate + '_' + c.well for c in clones_in_missing_miseq_plate_example]}")
    fp_wells_for_clones = get_fp_wells_from_clones(clones_in_missing_miseq_plate_example)
