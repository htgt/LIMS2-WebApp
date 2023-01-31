from sys import argv

from sqlalchemy import create_engine, text

data_base_details = argv[1]
engine = create_engine(f"postgresql://{data_base_details}")

with engine.connect() as conn:
    results = conn.execute(text("SELECT * FROM plates"))
    print(results.all())
