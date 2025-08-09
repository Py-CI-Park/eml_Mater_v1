import os
import sqlite3
import tempfile

from backend.services.indexer import EmailIndexer
from backend.models import get_db


def test_initialize_schema_creates_tables(monkeypatch):
    with tempfile.TemporaryDirectory() as tmp:
        # Use temp DB
        db_path = os.path.join(tmp, "test.db")
        monkeypatch.setenv("EMAIL_DB_PATH", db_path)

        # Initialize schema
        indexer = EmailIndexer(tmp)
        indexer.initialize_schema()

        conn = sqlite3.connect(db_path)
        try:
            cur = conn.cursor()
            cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
            names = {row[0] for row in cur.fetchall()}
            assert 'emails' in names
            # FTS virtual table shows in sqlite_master as 'emails_fts'
            cur.execute("SELECT name FROM sqlite_master WHERE name='emails_fts'")
            assert cur.fetchone() is not None
        finally:
            conn.close()

