"""Step 4: pull records from Airtable and print them, plus a field/type inventory.

Setup:
    pip install pyairtable python-dotenv
    # .env (gitignored):
    #   AIRTABLE_API_KEY=pat...      (personal access token)
    #   AIRTABLE_BASE_ID=app...
    #   AIRTABLE_TABLE_ID=tbl...     (table ID or table name both work)

Token scopes needed: data.records:read (required), schema.bases:read (optional,
for the declared-schema section). The token must also be granted access to the base.
"""

import json
import os
import sys
from collections import defaultdict

from dotenv import load_dotenv
from pyairtable import Api

PREVIEW_COUNT = 3  # how many full records to print


def get_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        sys.exit(f"Missing env var: {name}")
    return value


def print_declared_schema(table) -> None:
    """Field types as Airtable declares them (needs schema.bases:read)."""
    try:
        schema = table.schema()
    except Exception as exc:  # 403 if the scope is missing
        print(f"\n[schema] skipped ({type(exc).__name__}: {exc})")
        print("[schema] add the schema.bases:read scope to your token to see declared types")
        return

    print(f"\n=== Declared schema for table '{schema.name}' ===")
    for field in schema.fields:
        print(f"  {field.name:<30} {field.type}")
        options = getattr(field, "options", None)
        choices = getattr(options, "choices", None)
        if choices:
            print(f"    options: {[c.name for c in choices]}")


def main() -> None:
    load_dotenv()
    api = Api(get_env("AIRTABLE_API_KEY"))
    table = api.table(get_env("AIRTABLE_BASE_ID"), get_env("AIRTABLE_TABLE_ID"))

    # pyairtable handles pagination (100 records/page) and rate-limit retries.
    records = table.all()
    print(f"Fetched {len(records)} records")

    print(f"\n=== First {PREVIEW_COUNT} records ===")
    for rec in records[:PREVIEW_COUNT]:
        print(json.dumps(rec, indent=2, default=str))

    # Observed inventory: Airtable omits empty fields, so union across all records.
    types_seen: dict[str, set[str]] = defaultdict(set)
    counts: dict[str, int] = defaultdict(int)
    for rec in records:
        for name, value in rec["fields"].items():
            types_seen[name].add(type(value).__name__)
            counts[name] += 1

    print("\n=== Observed fields (across all records) ===")
    print(f"  {'field':<30} {'python types':<20} populated")
    for name in sorted(types_seen):
        types = ", ".join(sorted(types_seen[name]))
        print(f"  {name:<30} {types:<20} {counts[name]}/{len(records)}")

    print_declared_schema(table)


if __name__ == "__main__":
    main()