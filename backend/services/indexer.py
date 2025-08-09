from __future__ import annotations

import os
import hashlib
import sqlite3
from datetime import datetime
from typing import Iterable, Optional

from ..email_parser import EmailParser
from ..models import get_db


def _compute_sha1(file_path: str) -> str:
    hasher = hashlib.sha1()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


class EmailIndexer:
    """Builds and maintains search indexes for .eml files."""

    def __init__(self, email_root: str):
        self.email_root = email_root
        self.parser = EmailParser()

    def initialize_schema(self) -> None:
        """Create core and FTS5 schema if not exists."""
        conn = get_db()
        cur = conn.cursor()
        # Core emails table for metadata cache
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS emails(
              email_path TEXT PRIMARY KEY,
              subject TEXT, sender TEXT, recipient TEXT,
              date_parsed TIMESTAMP, message_id TEXT,
              has_attachments BOOLEAN, size_bytes INTEGER,
              sha1 TEXT
            )
            """
        )

        # Enable FTS5 virtual table
        cur.execute(
            """
            CREATE VIRTUAL TABLE IF NOT EXISTS emails_fts USING fts5(
              email_path UNINDEXED,
              subject, sender, recipient, body_text,
              tokenize = 'unicode61'
            )
            """
        )
        conn.commit()
        conn.close()

    def full_scan_and_index(self) -> dict:
        """Perform full scan of email_root and (re)build indexes."""
        total = 0
        processed = 0
        for root, _, files in os.walk(self.email_root):
            for fn in files:
                if not fn.lower().endswith(".eml"):
                    continue
                total += 1

        conn = get_db()
        cur = conn.cursor()
        try:
            for root, _, files in os.walk(self.email_root):
                for fn in files:
                    if not fn.lower().endswith(".eml"):
                        continue
                    file_path = os.path.join(root, fn)
                    rel_path = os.path.relpath(file_path, self.email_root)

                    # Parse headers first (fast path)
                    headers = self.parser.parse_email_headers(file_path)

                    # Compute sha1 and size for change tracking
                    size_bytes = os.path.getsize(file_path)
                    sha1 = _compute_sha1(file_path)

                    # Upsert core metadata
                    cur.execute(
                        """
                        INSERT INTO emails(email_path, subject, sender, recipient, date_parsed, message_id, has_attachments, size_bytes, sha1)
                        VALUES(?,?,?,?,?,?,?,?,?)
                        ON CONFLICT(email_path) DO UPDATE SET
                          subject=excluded.subject,
                          sender=excluded.sender,
                          recipient=excluded.recipient,
                          date_parsed=excluded.date_parsed,
                          message_id=excluded.message_id,
                          has_attachments=excluded.has_attachments,
                          size_bytes=excluded.size_bytes,
                          sha1=excluded.sha1
                        """,
                        (
                            rel_path,
                            headers.get("subject", ""),
                            headers.get("from", ""),
                            headers.get("to", ""),
                            headers.get("date_parsed"),
                            headers.get("message_id", ""),
                            1 if headers.get("has_attachments") else 0,
                            size_bytes,
                            sha1,
                        ),
                    )

                    # For FTS: include body text (may parse full message lazily)
                    full = self.parser.parse_email_full(file_path)
                    body_text = full.get("body_text", "")
                    cur.execute(
                        """
                        INSERT INTO emails_fts(email_path, subject, sender, recipient, body_text)
                        VALUES(?,?,?,?,?)
                        ON CONFLICT(email_path) DO NOTHING
                        """,
                        (
                            rel_path,
                            headers.get("subject", ""),
                            headers.get("from", ""),
                            headers.get("to", ""),
                            body_text,
                        ),
                    )

                    processed += 1
            conn.commit()
        finally:
            conn.close()
        return {"total": total, "processed": processed}

    def incremental_index(self) -> dict:
        """Incrementally update emails and FTS rows when size/sha1 changed."""
        conn = get_db()
        cur = conn.cursor()
        processed = 0
        total = 0

        # Build existing map email_path -> (size, sha1)
        cur.execute("SELECT email_path, size_bytes, sha1 FROM emails")
        existing = {row[0]: (row[1], row[2]) for row in cur.fetchall()}

        try:
            for root, _, files in os.walk(self.email_root):
                for fn in files:
                    if not fn.lower().endswith(".eml"):
                        continue
                    total += 1
                    file_path = os.path.join(root, fn)
                    rel_path = os.path.relpath(file_path, self.email_root)
                    size_bytes = os.path.getsize(file_path)
                    sha1 = _compute_sha1(file_path)

                    old = existing.get(rel_path)
                    if old and old == (size_bytes, sha1):
                        continue  # unchanged

                    headers = self.parser.parse_email_headers(file_path)
                    full = self.parser.parse_email_full(file_path)
                    body_text = full.get("body_text", "")

                    cur.execute(
                        """
                        INSERT INTO emails(email_path, subject, sender, recipient, date_parsed, message_id, has_attachments, size_bytes, sha1)
                        VALUES(?,?,?,?,?,?,?,?,?)
                        ON CONFLICT(email_path) DO UPDATE SET
                          subject=excluded.subject,
                          sender=excluded.sender,
                          recipient=excluded.recipient,
                          date_parsed=excluded.date_parsed,
                          message_id=excluded.message_id,
                          has_attachments=excluded.has_attachments,
                          size_bytes=excluded.size_bytes,
                          sha1=excluded.sha1
                        """,
                        (
                            rel_path,
                            headers.get("subject", ""),
                            headers.get("from", ""),
                            headers.get("to", ""),
                            headers.get("date_parsed"),
                            headers.get("message_id", ""),
                            1 if headers.get("has_attachments") else 0,
                            size_bytes,
                            sha1,
                        ),
                    )

                    # Upsert FTS by deleting and inserting (contentless FTS)
                    cur.execute("DELETE FROM emails_fts WHERE email_path=?", (rel_path,))
                    cur.execute(
                        "INSERT INTO emails_fts(email_path, subject, sender, recipient, body_text) VALUES(?,?,?,?,?)",
                        (rel_path, headers.get("subject", ""), headers.get("from", ""), headers.get("to", ""), body_text),
                    )

                    processed += 1
            conn.commit()
        finally:
            conn.close()
        return {"total": total, "processed": processed}


