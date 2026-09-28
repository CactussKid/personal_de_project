"""Step 5: prove the push pattern by uploading a test JSONL file to the dev UC volume."""
import io
import json
import os

from databricks.sdk import WorkspaceClient
from databricks.sdk.core import Config
from dotenv import load_dotenv

# override=True so .env always wins over anything exported in the shell
load_dotenv(override=True)

# Which token the SDK uses. Both DATABRICKS_DBT_TOKEN and the regenerated
# DATABRICKS_TOKEN work; swap here if you create a dedicated SDK/Dagster token.
TOKEN_VAR = "DATABRICKS_TOKEN"

VOLUME_DIR = "/Volumes/dev/bronze/landing"
FILE_PATH = f"{VOLUME_DIR}/_test_records.json"

# Shaped like real Airtable output: id/createdTime at top level, raw field names,
# nested AI-text object, linked-record array, checkbox omitted when unchecked.
records = [
    {
        "id": "recTEST000000001",
        "createdTime": "2026-01-15T10:00:00.000Z",
        "fields": {
            "Provider Name": "Jane Doe",
            "First Name": "Jane",
            "Last Name": "Doe",
            "NPI": "1234567893",
            "TIN Number": "012345678",
            "Provider Specialty": "Cardiology",
            "Record Status": "Active",
            "Provider Specialty Category": "Physician",
            "Primary Office": ["recOFFICE0000001"],
            "Provider Profile Summary": {
                "state": "generated",
                "value": "Test summary.",
                "isStale": False,
            },
        },
    },
    {
        "id": "recTEST000000002",
        "createdTime": "2026-01-16T10:00:00.000Z",
        "fields": {
            "Provider Name": "John Roe",
            "First Name": "John",
            "Last Name": "Roe",
            "NPI": "1234567893",
            "TIN Number": "987654321",
            "Provider Specialty": "Family Medicine",
            "Record Status": "Inactive",
            "Provider Specialty Category": "Physician",
            "Primary Office": [],
            "NPI/TIN Duplicate Flag": True,  # exercises the checkbox path
        },
    },
]

payload = "\n".join(json.dumps(r) for r in records).encode("utf-8")

# Normalize the host so it works with or without scheme / trailing slash.
host = os.environ["DATABRICKS_HOST_SERVER"].removeprefix("https://").rstrip("/")

cfg = Config(
    host=f"https://{host}",
    token=os.environ[TOKEN_VAR],
    http_timeout_seconds=30,
    retry_timeout_seconds=60,  # fail in ~1 min instead of hanging for 5
)
w = WorkspaceClient(config=cfg)

print("Authenticated as:", w.current_user.me().user_name)

# Upload
w.files.upload(FILE_PATH, io.BytesIO(payload), overwrite=True)
print(f"Uploaded {len(payload)} bytes to {FILE_PATH}")

# Verify: list the directory and round-trip the contents
for entry in w.files.list_directory_contents(VOLUME_DIR):
    print(" -", entry.path, entry.file_size)

downloaded = w.files.download(FILE_PATH).contents.read()
assert downloaded == payload, "Round-trip mismatch"
print("Round-trip OK")