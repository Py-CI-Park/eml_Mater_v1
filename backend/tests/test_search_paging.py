import os
import sqlite3
import tempfile

from backend.services.indexer import EmailIndexer
from backend.models import get_db


def _seed_dummy_fts(tmp_root: str, monkeypatch):
    # temp DB
    db_path = os.path.join(tmp_root, "test.db")
    monkeypatch.setenv("EMAIL_DB_PATH", db_path)

    # create schema
    indexer = EmailIndexer(tmp_root)
    indexer.initialize_schema()

    # seed minimal rows
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute(
        "INSERT OR REPLACE INTO emails(email_path, subject, sender, recipient, date_parsed) VALUES(?,?,?,?,datetime('now'))",
        ("a.eml", "Hello A", "a@x", "b@y",),
    )
    cur.execute(
        "INSERT OR REPLACE INTO emails(email_path, subject, sender, recipient, date_parsed) VALUES(?,?,?,?,datetime('now','-1 day'))",
        ("b.eml", "Hello B", "b@x", "b@y",),
    )
    cur.execute(
        "INSERT INTO emails_fts(email_path, subject, sender, recipient, body_text) VALUES(?,?,?,?,?)",
        ("a.eml", "Hello A", "a@x", "b@y", "Alpha body"),
    )
    cur.execute(
        "INSERT INTO emails_fts(email_path, subject, sender, recipient, body_text) VALUES(?,?,?,?,?)",
        ("b.eml", "Hello B", "b@x", "b@y", "Beta body"),
    )
    conn.commit()
    conn.close()


def test_paging_and_count(monkeypatch):
    with tempfile.TemporaryDirectory() as tmp:
        _seed_dummy_fts(tmp, monkeypatch)

        # count by API-level helper
        from backend.models import SearchIndexManager
        total = SearchIndexManager.count("Hello")
        assert total >= 2

        # page 1
        results = SearchIndexManager.search_emails("Hello", limit=1, offset=0, order="date_desc")
        assert len(results) == 1
        # page 2
        results2 = SearchIndexManager.search_emails("Hello", limit=1, offset=1, order="date_desc")
        assert len(results2) == 1


