CREATE DATABASE techprotodo;

\c techprotodo;

CREATE TABLE todo(
    todo_id SERIAL PRIMARY KEY,
    description VARCHAR(255)
);