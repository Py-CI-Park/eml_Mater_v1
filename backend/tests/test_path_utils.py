from backend.core.path_utils import normalize_and_validate_path, is_allowed_eml_filename, sanitize_attachment_name
import os
import tempfile


def test_normalize_and_validate_path_within_root():
    with tempfile.TemporaryDirectory() as tmp:
        root = tmp
        sub = os.path.join(root, "a", "b")
        os.makedirs(sub, exist_ok=True)
        path = normalize_and_validate_path(root, "a/b")
        assert path.startswith(root)


def test_normalize_and_validate_path_escaping_raises():
    with tempfile.TemporaryDirectory() as tmp:
        try:
            normalize_and_validate_path(tmp, "../outside")
        except ValueError:
            return
        assert False, "Expected ValueError for path escaping root"


def test_is_allowed_eml_filename():
    assert is_allowed_eml_filename("a.eml")
    assert not is_allowed_eml_filename("a.txt")
    assert not is_allowed_eml_filename("../a.eml")


def test_sanitize_attachment_name():
    assert sanitize_attachment_name("evil/../name.exe") == "name.exe"
    assert sanitize_attachment_name(":*?bad.txt").endswith(".txt")

