--- #step ISBN ID storage
CREATE TABLE IF NOT EXISTS isbn_id (
  isbn_id SERIAL PRIMARY KEY,
  isbn VARCHAR NOT NULL UNIQUE
);

--- #step Functions for book code numberspaces
CREATE OR REPLACE FUNCTION bc_of_work(wk INTEGER) RETURNS INTEGER
AS $$ SELECT $1 + 100000000 $$
LANGUAGE SQL
IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION bc_of_edition(ed INTEGER) RETURNS INTEGER
AS $$ SELECT $1 + 200000000 $$
LANGUAGE SQL
IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION bc_of_loc_rec(rec INTEGER) RETURNS INTEGER
AS $$ SELECT $1 + 300000000 $$
LANGUAGE SQL
IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION bc_of_gr_work(rec INTEGER) RETURNS INTEGER
AS $$ SELECT $1 + 400000000 $$
LANGUAGE SQL
IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION bc_of_gr_book(rec INTEGER) RETURNS INTEGER
AS $$ SELECT $1 + 500000000 $$
LANGUAGE SQL
IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION bc_of_loc_work(rec INTEGER) RETURNS INTEGER
AS $$ SELECT $1 + 600000000 $$
LANGUAGE SQL
IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION bc_of_loc_instance(rec INTEGER) RETURNS INTEGER
AS $$ SELECT $1 + 700000000 $$
LANGUAGE SQL
IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION bc_of_isbn(id INTEGER) RETURNS INTEGER
AS $$ SELECT $1 + 900000000 $$
LANGUAGE SQL
IMMUTABLE STRICT PARALLEL SAFE;

--- #step ExtractISBN function
CREATE OR REPLACE FUNCTION extract_isbn(raw_isbn VARCHAR) RETURNS VARCHAR
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE COST 5
AS $$
SELECT upper(regexp_replace(substring(regexp_replace(raw_isbn, '[^[:alnum:]_ -]', '') from
    '^\s*(?:(?:(?:ISBN)?[a-zA-Z]+?|\(\d+\))\s*)?([0-9 -]+[0-9Xx])'
), '[- ]', ''))
$$;

--- #step Node IRI to UUID conversion
CREATE OR REPLACE FUNCTION node_uuid(iri VARCHAR) RETURNS UUID
LANGUAGE SQL IMMUTABLE PARALLEL SAFE
AS $$
SELECT uuid_generate_v5(uuid_ns_url(), iri);
$$;
