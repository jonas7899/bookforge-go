-- +goose Up
-- +goose StatementBegin

-- IMPORTANT: Set search path to application schema
-- This ensures tables are created in the correct schema
SET search_path = 'bookforge', public;

-- Your migration SQL here
-- Example:
-- CREATE TABLE example_table (
--     id BIGINT PRIMARY KEY,
--     name VARCHAR(255) NOT NULL,
--     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
-- );

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin

-- Set search path for rollback
SET search_path = 'bookforge', public;

-- Rollback SQL here
-- Example:
-- DROP TABLE IF EXISTS example_table;

-- +goose StatementEnd
