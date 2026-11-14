"""Stream the phone's recovery configuration over SSH."""
from contextlib import closing
from io import BytesIO
from pathlib import Path
from tempfile import TemporaryDirectory
import os
import re
import sqlite3
import sys
import tarfile

os.umask(0o077)
home = Path.home()
agent = home / ".hermes"
router = home / ".9router"

with TemporaryDirectory(prefix="hermes-backup-") as temporary:
    database = Path(temporary) / "data.sqlite"
    with closing(sqlite3.connect(f"file:{router / 'db/data.sqlite'}?mode=ro", uri=True)) as live:
        with closing(sqlite3.connect(database)) as copy:
            live.backup(copy)
            copy.execute("PRAGMA journal_mode=DELETE")
            for table in (
                "usageHistory", "usageDaily", "requestDetails", "upstream_leases",
                "compressionAnalytics", "semanticCacheEntries", "guardrail_logs",
                "files", "batches", "thoughtSignatures",
            ):
                if copy.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", (table,)).fetchone():
                    copy.execute(f'DELETE FROM "{table}"')
            copy.commit()
            copy.execute("VACUUM")

    # The backup uses the model-router key, but runs no phone dashboard.
    env = (agent / ".env").read_text()
    env = re.sub(r"(?m)^\s*(?:export +)?HERMES_DASHBOARD_[^\n]*\n?", "", env).encode()
    with tarfile.open(fileobj=sys.stdout.buffer, mode="w|gz") as archive:
        entry = tarfile.TarInfo("agent/.env")
        entry.mode = 0o600
        entry.size = len(env)
        archive.addfile(entry, BytesIO(env))
        for name in ("config.yaml", "SOUL.md", "skills", "memories", "plugins", "hooks"):
            path = agent / name
            if path.exists():
                archive.add(path, f"agent/{name}")
        router_env = (home / ".config/9router-go/service.env").read_text()
        key = re.search(r"(?m)^[ \t]*(?:export +)?ROUTER_MASTER_KEY=[^\n]+", router_env)
        if not key:
            raise ValueError("The model-router encryption key is missing")
        entry = tarfile.TarInfo("router.env")
        entry.mode = 0o600
        data = (key.group() + "\n").encode()
        entry.size = len(data)
        archive.addfile(entry, BytesIO(data))
        archive.add(database, "router/data.sqlite")
        if (router / "machine-id").is_file():
            archive.add(router / "machine-id", "router/machine-id")
