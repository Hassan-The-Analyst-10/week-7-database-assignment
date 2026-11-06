
-- ============================================================
-- Assignment: Audit Logging, Hierarchical Data, Migrations,
--             and Least-Privilege Database Security
-- Database: PostgreSQL
-- File: answers.sql
-- ============================================================


-- STEP 1: BUILD A REUSABLE AUDIT LOG

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tbl TEXT,
    op TEXT,
    old_row JSONB,
    new_row JSONB,
    changed_by TEXT DEFAULT current_user,
    at TIMESTAMPTZ DEFAULT now()
);


-- Create the audit trigger function.

CREATE OR REPLACE FUNCTION audit()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (
        tbl,
        op,
        old_row,
        new_row,
        changed_by,
        at
    )
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        CASE
            WHEN TG_OP IN ('UPDATE', 'DELETE')
            THEN to_jsonb(OLD)
            ELSE NULL
        END,
        CASE
            WHEN TG_OP IN ('INSERT', 'UPDATE')
            THEN to_jsonb(NEW)
            ELSE NULL
        END,
        current_user,
        clock_timestamp()
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Attach the audit trigger to the students table.
-- The students table must already exist.

DROP TRIGGER IF EXISTS trg_audit ON students;

CREATE TRIGGER trg_audit
AFTER INSERT OR UPDATE OR DELETE
ON students
FOR EACH ROW
EXECUTE FUNCTION audit();


-- STEP 2: TEST THE AUDIT LOG

-- Update a student's name.
UPDATE students
SET name = 'Kofi M.'
WHERE id = 1;

-- Delete a student.
-- WARNING: This permanently deletes the matching row
-- unless the transaction is rolled back or data is restored.
DELETE FROM students
WHERE id = 3;


-- View the audit trail.

SELECT
    tbl,
    op,
    old_row->>'name' AS was,
    new_row->>'name' AS now,
    changed_by,
    at
FROM audit_log
ORDER BY at DESC;


-- STEP 3: CREATE A HIERARCHICAL CATEGORY TREE

CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id INT REFERENCES categories(id)
);


-- Insert sample categories only if they do not already exist.

INSERT INTO categories (name, parent_id)
SELECT v.name, v.parent_id
FROM (
    VALUES
        ('Electronics', NULL::INT),
        ('Computers', 1),
        ('Laptops', 2),
        ('Phones', 1)
) AS v(name, parent_id)
WHERE NOT EXISTS (
    SELECT 1
    FROM categories c
    WHERE c.name = v.name
);


-- Query the hierarchy using a recursive CTE.

WITH RECURSIVE tree AS (
    SELECT
        id,
        name,
        parent_id,
        0 AS depth
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT
        c.id,
        c.name,
        c.parent_id,
        t.depth + 1
    FROM categories c
    JOIN tree t
        ON c.parent_id = t.id
)
SELECT
    repeat('  ', depth) || name AS category_tree,
    id,
    parent_id,
    depth
FROM tree
ORDER BY depth, name;


-- STEP 4: VERSIONED DATABASE MIGRATIONS
-- Flyway commands are shell commands, not SQL.
-- Create these files in your migrations/ directory:
--
-- V1__core_tables.sql
-- V2__audit_log.sql
-- V3__categories.sql
--
-- Run the following commands in your terminal:
--
-- flyway -url=jdbc:postgresql://localhost/bootcamp \
--        -user=postgres migrate
--
-- flyway -url=jdbc:postgresql://localhost/bootcamp \
--        -user=postgres info


-- STEP 5: LEAST-PRIVILEGE SECURITY

-- Create application roles.

CREATE ROLE app_read;
CREATE ROLE app_write;


-- Grant database connection privileges.

GRANT CONNECT ON DATABASE bootcamp
TO app_read, app_write;


-- Grant access to the public schema.

GRANT USAGE ON SCHEMA public
TO app_read, app_write;


-- Read-only role: SELECT privileges.

GRANT SELECT ON ALL TABLES IN SCHEMA public
TO app_read;


-- Write role: required data modification privileges.

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO app_write;


-- Grant sequence access required for identity/serial inserts.

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public
TO app_write;


-- Create an application login and assign the write role.
-- Replace the example password before using this in a real system.

CREATE USER api
LOGIN PASSWORD 'replace_with_a_strong_password'
IN ROLE app_write;


-- Configure privileges for tables created in the future.
-- Run these as the role that will create future tables.

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO app_read;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLES TO app_write;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT USAGE, SELECT ON SEQUENCES TO app_write;


-- END OF ASSIGNMENT
