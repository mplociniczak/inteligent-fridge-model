CREATE TABLE product (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT,
    expiration_date DATE,
    added_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE recipe (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    instructions TEXT
);

CREATE TABLE fridge (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    added_date DATE DEFAULT CURRENT_DATE,
    status TEXT CHECK (status IN ('available', 'used', 'restored')),
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0)
);

CREATE TABLE recipe_product (
    recipe_id INTEGER NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    quantity NUMERIC(10, 2) NOT NULL CHECK (quantity > 0),
    unit TEXT,
    PRIMARY KEY (recipe_id, product_id)
);
