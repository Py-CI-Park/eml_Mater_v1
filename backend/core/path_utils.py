from __future__ import annotations

import os
import re
from pathlib import Path


def normalize_and_validate_path(root_dir: str, relative_path: str) -> str:
    """Return an absolute path under the given root after normalization.

    Raises ValueError if the resolved path escapes the root directory.
    """
    if not root_dir:
        raise ValueError("Root directory is not configured")

    root = Path(root_dir).resolve()
    # Allow empty or 'root' to refer to the root itself
    safe_rel = "" if relative_path in (None, "", ".", "root") else relative_path
    candidate = (root / safe_rel).resolve()

    try:
        candidate.relative_to(root)
    except Exception:
        raise ValueError("Resolved path is outside of root directory")

    return str(candidate)


def is_allowed_eml_filename(filename: str) -> bool:
    """Allow only simple `.eml` filenames without path separators."""
    if not filename or any(sep in filename for sep in ("/", "\\")):
        return False
    return filename.lower().endswith(".eml")


_ATTACHMENT_SAFE_CHARS = re.compile(r"[^A-Za-z0-9._ -]")


def sanitize_attachment_name(name: str) -> str:
    """Sanitize attachment name to a safe filename (no path traversal).

    This does not touch the email content; it only ensures a safe download name.
    """
    if not name:
        return "attachment.bin"
    # Remove any path components and unsafe characters
    base = os.path.basename(name)
    base = _ATTACHMENT_SAFE_CHARS.sub("_", base)
    # enforce some length limit
    return base[:255] or "attachment.bin"


