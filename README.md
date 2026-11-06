
# PostgreSQL Audit Logging, Migrations, and Security

## Project Overview

This project demonstrates database auditing, hierarchical data
modeling, versioned schema migrations, and least-privilege security
using PostgreSQL.

## Learning Objectives

- Track inserts, updates, and deletes with audit triggers.
- Store audit records as JSONB.
- Query hierarchical categories using recursive CTEs.
- Manage database changes using Flyway migrations.
- Create roles and grant appropriate database privileges.

## Technologies

- PostgreSQL
- SQL and PL/pgSQL
- Flyway
- Linux terminal

## Project Structure

```text
postgresql-audit-migrations/
├── answers.sql
├── README.md
└── migrations/
    ├── V1__core_tables.sql
    ├── V2__audit_log.sql
    └── V3__categories.sql
```

## Running the Migrations

Run these commands in the terminal from the project directory:

```bash
flyway -url=jdbc:postgresql://localhost/bootcamp \
  -user=postgres -locations=filesystem:migrations migrate

flyway -url=jdbc:postgresql://localhost/bootcamp \
  -user=postgres -locations=filesystem:migrations info
```

## Testing Audit Logging

Connect to the bootcamp database and run:

```sql
UPDATE students
SET name = 'Kofi M.'
WHERE id = 1;

SELECT *
FROM audit_log
ORDER BY at DESC;
```

Use test records when experimenting with updates or deletes.

## Querying Categories

The recursive CTE in `answers.sql` displays categories
and their hierarchy.

Example:

- Electronics
  - Computers
    - Laptops
  - Phones

## Database Security

The project creates read and write roles and assigns
specific permissions. Replace example passwords with
strong credentials and do not commit real secrets to GitHub.

## Author

Name: [Your Name]

## Conclusion

This project demonstrates practical PostgreSQL techniques
for auditing changes, organizing hierarchical data,
managing schema versions, and controlling database access.
