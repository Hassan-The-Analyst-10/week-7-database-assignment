
-- V3: Create hierarchical categories

CREATE TABLE IF NOT EXISTS categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    parent_id BIGINT REFERENCES categories(id)
);

INSERT INTO categories (name, parent_id)
VALUES ('Electronics', NULL)
ON CONFLICT (name) DO NOTHING;

INSERT INTO categories (name, parent_id)
SELECT 'Computers', id
FROM categories
WHERE name = 'Electronics'
ON CONFLICT (name) DO NOTHING;

INSERT INTO categories (name, parent_id)
SELECT 'Laptops', id
FROM categories
WHERE name = 'Computers'
ON CONFLICT (name) DO NOTHING;

INSERT INTO categories (name, parent_id)
SELECT 'Phones', id
FROM categories
WHERE name = 'Electronics'
ON CONFLICT (name) DO NOTHING;
