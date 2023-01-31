from sys import argv

from sqlalchemy import create_engine, text, MetaData
from sqlalchemy.ext.automap import automap_base

data_base_details = argv[1]
engine = create_engine(f"postgresql://{data_base_details}")

metadata = MetaData()
metadata.reflect(engine, only=["plates", "wells"])

Base = automap_base(metadata=metadata)
Base.prepare()

Plate = Base.classes.plates
Well = Base.classes.wells

with engine.connect() as conn:
    results = conn.execute(text("SELECT * FROM plates"))
    print(results.all())
