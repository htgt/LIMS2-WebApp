from sys import argv

from sqlalchemy import create_engine, select, text, MetaData
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session

data_base_details = argv[1]
engine = create_engine(f"postgresql://{data_base_details}")

metadata = MetaData()
metadata.reflect(engine, only=["plates", "wells"])

Base = automap_base(metadata=metadata)
Base.prepare()

Plate = Base.classes.plates
Well = Base.classes.wells

with Session(engine) as session:
    results = session.execute(select(Plate))
    print(results.all())
