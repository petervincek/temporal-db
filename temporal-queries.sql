-- bring the extension with ranges
CREATE EXTENSION btree_gist;
-- CREATE invoices table first
CREATE TABLE invoices (
    id integer,
    valid_at tstzrange,
    customer_name text,
    total decimal(10,2)
);
ALTER TABLE invoices add constraint pk_invoices EXCLUDE USING GIST (id with =, valid_at with &&);
-- CREATE line_items table next
CREATE TABLE line_items (
    item_id integer,
    valid_at tstzrange,
    invoice_id integer,
    item_name text,
    price decimal(10,2)
);
ALTER TABLE line_items add constraint pk_line_items EXCLUDE USING GIST (item_id with =, invoice_id with =, valid_at with &&);
--ALTER TABLE line_items add constraint fk_line_items_invoice_id FOREIGN KEY (invoice_id, valid_at) REFERENCES invoices(id, valid_at);

-- INSERT first batch of invoices, set valid_from to time of arrival and valid_to to infinity
-- batch came 4/21/2020
INSERT INTO invoices(id, valid_at, customer_name, total) VALUES (1, '[2020-04-21 00:00,)', 'ABC', 150);
INSERT INTO line_items(item_id, valid_at, invoice_id, item_name, price) VALUES (1, '[2020-04-21 00:00,)', 1, 'sneakers', 50);
INSERT INTO line_items(item_id, valid_at, invoice_id, item_name, price) VALUES (2, '[2020-04-21 00:00,)', 1, 'jacket', 100);

INSERT INTO invoices(id, valid_at, customer_name, total) VALUES (2, '[2020-04-21 00:00,)', 'ABC', 250);
INSERT INTO line_items(item_id, valid_at, invoice_id, item_name, price) VALUES (1, '[2020-04-21 00:00,)', 2, 'mobile phone', 250);

-- after the arrival of update batch first UPDATE the valid_to in the range for records from the previous batch,
-- in the same transaction insert the newly received invoices with the valid_from set to time of arrival and valid_to set to infinity
-- reproces came 5/21/2020
UPDATE invoices SET valid_at = tstzrange(lower(valid_at), '2020-05-21 00:00', concat('[', ')')) WHERE id = 1 AND upper(valid_at) IS NULL;
UPDATE line_items SET valid_at = tstzrange(lower(valid_at), '2020-05-21 00:00', concat('[', ')')) WHERE invoice_id = 1 AND upper(valid_at) IS NULL;
INSERT INTO invoices(id, valid_at, customer_name, total) VALUES (1, '[2020-05-21 00:00,)', 'ABC', 160);
INSERT INTO line_items(item_id, valid_at, invoice_id, item_name, price) VALUES (1, '[2020-05-21 00:00,)', 1, 'sneakers', 160);

UPDATE invoices SET valid_at = tstzrange(lower(valid_at), '2020-05-21 00:00', concat('[', ')')) WHERE id = 2 AND upper(valid_at) IS NULL;
UPDATE line_items SET valid_at = tstzrange(lower(valid_at), '2020-05-21 00:00', concat('[', ')')) WHERE invoice_id = 2 AND upper(valid_at) IS NULL;
INSERT INTO invoices(id, valid_at, customer_name, total) VALUES (2, '[2020-05-21 00:00,)', 'ABC', 270);
INSERT INTO line_items(item_id, valid_at, invoice_id, item_name, price) VALUES (1, '[2020-05-21 00:00,)', 2, 'mobile phone', 270);

-- Query a history state
SELECT * FROM line_items WHERE invoice_id = 1 AND valid_at @> '2020-05-15'::timestamptz;
-- Query a present (latest) state
SELECT * FROM line_items WHERE invoice_id = 1 AND upper(valid_at) IS NULL;

