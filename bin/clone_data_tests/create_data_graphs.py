from sys import argv
from collections import namedtuple

from networkx import Graph, is_isomorphic
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


def create_graph_from_fp_well(fp_well):
    graph = Graph()
    graph.add_node(fp_well, **{"type": "fp_well"})
    return graph

def add_piq_wells_to_graph(graph):
    fp_wells = [node for node, attributes in graph.nodes.items() if attributes["type"] == "fp_well"]
    for fp_well in fp_wells:
        for piq_well in get_piq_wells_from_fp_well(fp_well):
            graph.add_node(piq_well, **{"type": "piq_well"})
            graph.add_edge(fp_well, piq_well)


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
    equivalence_classes = create_equivalence_classes(graphs)
