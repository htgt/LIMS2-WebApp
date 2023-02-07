from sys import argv
from collections import namedtuple

from sqlalchemy import create_engine, select, text, MetaData, tuple_
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import joinedload, Session

engine = None

Plate = None
Well = None


def init(data_base_details):
    global engine, Plate, Well
    engine = create_engine(f"postgresql://{data_base_details}")
    metadata = MetaData()
    metadata.reflect(engine, only=["plates", "wells"])
    Base = automap_base(metadata=metadata)
    Base.prepare()
    Plate = Base.classes.plates
    Well = Base.classes.wells


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

        wells = [r.wells for r in results]
    return wells


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
    wells_for_clone_HUPFP0085A1_C10 = list(filter(lambda well: well.name == "C10" and well.plates.name == "HUPFP0085A1", fp_wells))
    assert len(wells_for_clone_HUPFP0085A1_C10) == 1, f"Found {len(wells_for_clone_HUPFP0085A1_C10)} wells containing clone HUPFP0085A1_C10"
