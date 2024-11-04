--Widok Dostępnych Produktów - Pokazuje wszystkie produkty obecnie dostępne w lodówce.
CREATE VIEW available_products AS
SELECT p.name, p.category, f.status, f.added_date
FROM product p
JOIN fridge f ON p.id = f.product_id
WHERE f.status = 'available';

--Widok Przepisów i Ich Składników - Umożliwia szybkie przeglądanie, jakie produkty są potrzebne do każdego przepisu.
CREATE VIEW recipe_ingredients AS
SELECT r.name AS recipe_name, p.name AS product_name, rp.quantity, rp.unit
FROM recipe r
JOIN recipe_product rp ON r.id = rp.recipe_id
JOIN product p ON rp.product_id = p.id;


--Trigger Aktualizujący Status Produktu - Automatycznie aktualizuje status produktu w lodówce na "used" po użyciu go w przepisie.
CREATE OR REPLACE FUNCTION update_product_status()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE fridge
  SET status = 'used'
  WHERE product_id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_status
AFTER INSERT ON recipe_product
FOR EACH ROW
EXECUTE FUNCTION update_product_status();


--Trigger Sprawdzający Daty Ważności - Informuje, gdy produkt zbliża się do daty ważności lub ją przekroczył.
CREATE OR REPLACE FUNCTION check_expiration_date()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.expiration_date < CURRENT_DATE THEN
    RAISE EXCEPTION 'Product % is expired', NEW.name;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_expiration
BEFORE INSERT OR UPDATE ON product
FOR EACH ROW
EXECUTE FUNCTION check_expiration_date();


--Procedura Dodawania Produktu do Lodówki - Umożliwia dodanie produktu do lodówki z jednoczesnym sprawdzeniem i aktualizacją stanu.
CREATE OR REPLACE PROCEDURE add_product_to_fridge(product_name TEXT, product_category TEXT, exp_date DATE, quantity NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO product (name, category, expiration_date)
  VALUES (product_name, product_category, exp_date);

  INSERT INTO fridge (product_id, quantity, status)
  VALUES (currval('product_id_seq'), quantity, 'available');
END;
$$;


--Procedura Usuwania Przeterminowanych Produktów - Regularnie usuwa z bazy przeterminowane produkty.
CREATE OR REPLACE PROCEDURE remove_expired_products()
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM fridge
  WHERE product_id IN (SELECT id FROM product WHERE expiration_date < CURRENT_DATE);
END;
$$;


--Indeks na Daty Ważności - Poprawia wydajność zapytań filtrujących produkty według daty ważności.
CREATE INDEX idx_expiration_date ON product(expiration_date);
