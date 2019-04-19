CREATE OR REPLACE FUNCTION extract_isbn(raw_isbn VARCHAR) RETURNS VARCHAR
LANGUAGE SQL IMMUTABLE PARALLEL SAFE COST 5
AS $$
SELECT upper(regexp_replace(substring(raw_isbn from
    '^\s*(?:(?:(?:ISBN)?[:;a-zA-Z]+?|\([[:digit:]]+\))\s*)?([0-9 -]+[0-9Xx])'), '[- ]', ''))
$$;