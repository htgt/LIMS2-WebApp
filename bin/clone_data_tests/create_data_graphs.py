from sys import argv
from collections import namedtuple

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
    return next_wells


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
