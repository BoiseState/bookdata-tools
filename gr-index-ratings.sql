-- users
CREATE TABLE IF NOT EXISTS gr_user (
  gr_user_rid SERIAL PRIMARY KEY,
  gr_user_id VARCHAR NOT NULL
);
CREATE TEMPORARY TABLE gr_new_users
  AS SELECT gr_int_data->>'user_id' AS gr_user_id
     FROM gr_raw_interaction LEFT JOIN gr_user ON (gr_user_id = gr_int_data->>'user_id')
     WHERE gr_user_rid IS NULL;
INSERT INTO gr_user (gr_user_id)
SELECT DISTINCT gr_user_id FROM gr_new_users;

CREATE UNIQUE INDEX IF NOT EXISTS gr_user_id_idx ON gr_user (gr_user_id);
ANALYZE gr_user;

-- Rating data
CREATE TABLE IF NOT EXISTS gr_interaction
  AS SELECT gr_int_rid, book_id, gr_user_rid, rating, (gr_int_data->'isRead')::boolean AS is_read, date_added, date_updated
     FROM gr_raw_interaction,
          jsonb_to_record(gr_int_data) AS
              x(book_id INTEGER, user_id VARCHAR, rating INTEGER,
                date_added TIMESTAMP WITH TIME ZONE, date_updated TIMESTAMP WITH TIME ZONE),
          gr_user
     WHERE user_id = gr_user_id;
DO $$
BEGIN
    ALTER TABLE gr_interaction ADD CONSTRAINT gr_interaction_pk PRIMARY KEY (gr_int_rid);
EXCEPTION
    WHEN invalid_table_definition THEN
        RAISE NOTICE 'primary key already exists';
END;
$$;
CREATE INDEX IF NOT EXISTS gr_interaction_book_idx ON gr_interaction (book_id);
CREATE INDEX IF NOT EXISTS gr_interaction_user_idx ON gr_interaction (user_id);
ANALYZE gr_interaction;

-- users
CREATE TABLE IF NOT EXISTS gr_user (
  gr_user_rid SERIAL PRIMARY KEY,
  gr_user_id VARCHAR NOT NULL
);
INSERT INTO gr_user (gr_user_id)
  SELECT DISTINCT user_id
  FROM gr_interaction LEFT JOIN gr_user ON (gr_user_id = user_id)
  WHERE gr_user_rid IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS gr_user_id_idx ON gr_user (gr_user_id);
ANALYZE gr_user;

-- ratings
CREATE MATERIALIZED VIEW IF NOT EXISTS gr_rating
  AS SELECT gr_user_rid AS user_id, cluster AS book_id, MEDIAN(rating) AS rating, COUNT(rating) AS nratings
  FROM gr_interaction
  JOIN gr_user ON (user_id = gr_user_id)
  JOIN gr_book_isbn ON (gr_book_id = book_id)
  JOIN isbn_cluster USING (isbn_id)
  WHERE rating > 0
  GROUP BY gr_user_rid, cluster;
CREATE INDEX gr_rating_user_idx ON gr_rating (user_id);
CREATE INDEX gr_rating_item_idx ON gr_rating (book_id);