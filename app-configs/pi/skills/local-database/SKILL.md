---
name: local-database
description: Connect to a local PostgreSQL database using DATABASE_URL from .env and run SQL queries via psql. Use when the user asks to query, inspect, or manipulate a local database.
---

# Local Database

Run SQL queries against a local PostgreSQL database whose connection string lives in `.env` as `DATABASE_URL`.

## Connecting and running queries

**Never read or cat the `.env` file directly.** The DATABASE_URL may contain secrets. Instead, always source it inline and pass it to `psql` in a single bash command:

```bash
bash -c 'set -a; source .env; set +a; psql "$DATABASE_URL" -c "YOUR SQL HERE"'
```

For multi-line or complex queries, use a heredoc:

```bash
bash -c 'set -a; source .env; set +a; psql "$DATABASE_URL" <<SQL
SELECT * FROM users LIMIT 10;
SQL'
```

For interactive-style expanded output, add `-x`:

```bash
bash -c 'set -a; source .env; set +a; psql "$DATABASE_URL" -x -c "SELECT * FROM users LIMIT 1"'
```

## Why source instead of reading

Sourcing keeps the credentials out of the conversation context. Reading the file would expose the full connection string (host, password, etc.) in plain text inside the chat history. By sourcing, the secret stays inside the shell process and is never echoed back.

## Common tasks

- **List tables**: `\dt`
- **Describe a table**: `\d table_name`
- **Check row counts**: `SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC;`

All of these go through the same pattern — pass them as the command string to `psql` via the sourcing one-liner above.

## Troubleshooting

- If `.env` is not in the current directory, look for it in the project root.
- If `psql` is not found, suggest `brew install libpq` (macOS) or check PATH.
- If the connection fails, ask the user to verify DATABASE_URL is set correctly in `.env` — but do **not** print its value.
