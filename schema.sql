CREATE TABLE lists(
  id serial PRIMARY KEY,
  name text NOT NULL UNIQUE
);

CREATE TABLE todos(
  id serial PRIMARY KEY,
  name text NOT NULL,
  is_completed boolean NOT NULL DEFAULT FALSE,
  list_id int NOT NULL REFERENCES lists(id)
); 
