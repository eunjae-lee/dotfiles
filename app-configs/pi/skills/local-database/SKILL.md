---
name: local-database
description: Connect to a local PostgreSQL database using DATABASE_URL from .env and run SQL queries via psql. Use when the user asks to query, inspect, or manipulate a local database.
---

# Local Database

Run SQL queries against a local PostgreSQL database whose connection string lives in `.env` as `DATABASE_URL`.

## Connecting and running queries

**Never read or cat the `.env` file directly.** The DATABASE_URL may contain secrets. Instead, extract only `DATABASE_URL` from `.env` and pass it to `psql` in a single bash command:

```bash
bash -c 'DATABASE_URL=$(grep "^DATABASE_URL=" .env | sed "s/^DATABASE_URL=//; s/^\"//" | sed "s/\"$//"); psql "$DATABASE_URL" -c "YOUR SQL HERE"'
```

For multi-line or complex queries, use a heredoc:

```bash
bash -c 'DATABASE_URL=$(grep "^DATABASE_URL=" .env | sed "s/^DATABASE_URL=//; s/^\"//" | sed "s/\"$//"); psql "$DATABASE_URL" <<SQL
SELECT * FROM users LIMIT 10;
SQL'
```

For interactive-style expanded output, add `-x`:

```bash
bash -c 'DATABASE_URL=$(grep "^DATABASE_URL=" .env | sed "s/^DATABASE_URL=//; s/^\"//" | sed "s/\"$//"); psql "$DATABASE_URL" -x -c "SELECT * FROM users LIMIT 1"'
```

## Why this approach

- **Only DATABASE_URL is extracted** — sourcing the entire `.env` (`set -a; source .env`) can export other PG-related env vars (like `PGSSLMODE=""`) that interfere with psql.
- **The value is never echoed** — the secret stays inside the shell process and doesn't leak into conversation context.
- **Quotes are stripped** — handles both `DATABASE_URL=postgres://...` and `DATABASE_URL="postgres://..."` formats.

## Common tasks

- **List tables**: `\dt`
- **Describe a table**: `\d table_name`
- **Check row counts**: `SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC;`

All of these go through the same pattern — pass them as the command string to `psql` via the sourcing one-liner above.

## Troubleshooting

- If `.env` is not in the current directory, look for it in the project root.
- If `psql` is not found, suggest `brew install libpq` (macOS) or check PATH.
- If the connection fails, ask the user to verify DATABASE_URL is set correctly in `.env` — but do **not** print its value.
