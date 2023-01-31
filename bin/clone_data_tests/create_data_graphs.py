from sys import argv
from collections import namedtuple

from sqlalchemy import create_engine, select, text, MetaData, tuple_
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session

Clone = namedtuple("Clone", ["plate", "well"])

data_base_details = argv[1]
engine = create_engine(f"postgresql://{data_base_details}")

metadata = MetaData()
metadata.reflect(engine, only=["plates", "wells"])

Base = automap_base(metadata=metadata)
Base.prepare()

Plate = Base.classes.plates
Well = Base.classes.wells

with open("bin/get_list_of_clones.sql") as clones_sql:
    with engine.connect() as conn:
        results = conn.execute(text(clones_sql.read())).all()
        clones = {
            Clone(*result)
            for result in results
        }

# This might change if staging db is updated, but shouldn't decrease.
expected_number_of_clones = 1866
assert len(clones) == expected_number_of_clones, f"Found {len(clones)} clones."

with Session(engine) as session:
    results = session.execute(
        select(Well)
        .join(Well.plates)
        .where(tuple_(Plate.name, Well.name).in_(clones))
    )

    wells = [r[0] for r in results]

# Should be one well for each clone.
assert len(wells) == expected_number_of_clones, f"Found {len(wells)} wells."
