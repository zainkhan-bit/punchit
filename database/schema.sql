-- PunchIt database (MySQL 8)
-- Run: MySQL Workbench mein open karo aur Execute (ya: mysql -u root -p < schema.sql)

DROP DATABASE IF EXISTS punchit;
CREATE DATABASE punchit;
USE punchit;

CREATE TABLE staff (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  pin_hash VARCHAR(255) NOT NULL,
  role ENUM('server','kitchen','manager','owner') NOT NULL,   -- manager/owner = admin panel
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  station_type ENUM('item','expo') NOT NULL DEFAULT 'item',
  printer_ip VARCHAR(45) NULL,
  printer_port INT DEFAULT 9100,
  is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  station_id INT NULL,
  sort_order INT DEFAULT 0,
  FOREIGN KEY (station_id) REFERENCES stations(id) ON DELETE SET NULL
);

CREATE TABLE menu_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  category_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  station_id INT NULL,                 -- NULL = category wala station
  is_available BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
  FOREIGN KEY (station_id) REFERENCES stations(id) ON DELETE SET NULL
);

CREATE TABLE modifier_groups (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,           -- Crust, Extra Toppings
  min_select INT DEFAULT 0,            -- 1 = zaroori selection
  max_select INT DEFAULT 1
);

CREATE TABLE modifier_options (
  id INT AUTO_INCREMENT PRIMARY KEY,
  group_id INT NOT NULL,
  name VARCHAR(50) NOT NULL,
  price DECIMAL(10,2) DEFAULT 0,
  is_available BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (group_id) REFERENCES modifier_groups(id) ON DELETE CASCADE
);

CREATE TABLE menu_item_modifier_groups (
  menu_item_id INT NOT NULL,
  group_id INT NOT NULL,
  PRIMARY KEY (menu_item_id, group_id),
  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE,
  FOREIGN KEY (group_id) REFERENCES modifier_groups(id) ON DELETE CASCADE
);

CREATE TABLE halls (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL
);

CREATE TABLE dining_tables (
  id INT AUTO_INCREMENT PRIMARY KEY,
  hall_id INT NOT NULL,
  table_number INT NOT NULL,
  capacity INT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE (hall_id, table_number),
  FOREIGN KEY (hall_id) REFERENCES halls(id)
);

-- ===== Tax & settings (Manager panel se change hote hain) =====

-- Har payment method ka apna tax (e.g. Cash aur Card alag)
CREATE TABLE payment_methods (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  tax_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INT DEFAULT 0
);

-- Sirf 1 row (id = 1)
CREATE TABLE settings (
  id TINYINT PRIMARY KEY DEFAULT 1,
  restaurant_name VARCHAR(100) NOT NULL,
  service_charge_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
  service_charge_dine_in_only BOOLEAN DEFAULT TRUE,
  receipt_footer VARCHAR(255),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (id = 1)
);

CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_type ENUM('dine_in','takeaway') NOT NULL,
  table_id INT NULL,
  server_id INT NOT NULL,
  customer_name VARCHAR(100) NULL,
  customer_phone VARCHAR(20) NULL,
  status ENUM('open','billed','paid','cancelled') DEFAULT 'open',
  subtotal DECIMAL(10,2) DEFAULT 0,
  discount DECIMAL(10,2) DEFAULT 0,
  service_charge DECIMAL(10,2) DEFAULT 0,
  tax_percent DECIMAL(5,2) DEFAULT 0,      -- snapshot: bill ke waqt ka rate
  tax DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) DEFAULT 0,
  payment_method_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  closed_at TIMESTAMP NULL,
  FOREIGN KEY (table_id) REFERENCES dining_tables(id),
  FOREIGN KEY (server_id) REFERENCES staff(id),
  FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
);

CREATE TABLE kot_batches (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  batch_no INT NOT NULL,               -- 1 = first order, 2+ = add-on
  created_by INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (order_id, batch_no),
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES staff(id)
);

CREATE TABLE order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  kot_batch_id INT NOT NULL,
  menu_item_id INT NOT NULL,
  station_id INT NULL,                 -- send time pe resolve hua station
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  note VARCHAR(255),
  kitchen_status ENUM('pending','preparing','ready','served','void') DEFAULT 'pending',
  voided_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (kot_batch_id) REFERENCES kot_batches(id),
  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id),
  FOREIGN KEY (station_id) REFERENCES stations(id),
  FOREIGN KEY (voided_by) REFERENCES staff(id)
);

CREATE TABLE order_item_modifiers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_item_id INT NOT NULL,
  modifier_option_id INT NOT NULL,
  name VARCHAR(50) NOT NULL,           -- snapshot
  price DECIMAL(10,2) NOT NULL,        -- snapshot
  FOREIGN KEY (order_item_id) REFERENCES order_items(id) ON DELETE CASCADE,
  FOREIGN KEY (modifier_option_id) REFERENCES modifier_options(id)
);

CREATE TABLE print_jobs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kot_batch_id INT NOT NULL,
  station_id INT NOT NULL,
  status ENUM('pending','printed','failed') DEFAULT 'pending',
  error VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  printed_at TIMESTAMP NULL,
  FOREIGN KEY (kot_batch_id) REFERENCES kot_batches(id) ON DELETE CASCADE,
  FOREIGN KEY (station_id) REFERENCES stations(id)
);

-- ===== Sample data (Flutter mock data se match karta hai) =====
INSERT INTO stations (name, station_type) VALUES
('Pizza Make Table','item'), ('Starter Station','item'),
('Grill Station','item'),    ('Cut Table','expo');

INSERT INTO categories (name, station_id, sort_order) VALUES
('Pizza',1,1), ('Starters',2,2), ('Burgers',3,3), ('Drinks',NULL,4);

INSERT INTO menu_items (id, category_id, name, price, is_available) VALUES
(1,1,'Chicken Tikka Pizza (M)',1450,TRUE), (2,1,'Fajita Pizza (M)',1450,TRUE),
(3,1,'Veggie Pizza (M)',1250,TRUE),
(4,2,'Nuggets (6pc)',450,TRUE), (5,2,'Fries',350,TRUE), (6,2,'Oven Baked Wings',650,TRUE),
(7,3,'Zinger Burger',650,TRUE), (8,3,'Beef Burger',750,TRUE),
(9,4,'Soft Drink',150,TRUE), (10,4,'Mineral Water',100,TRUE), (11,4,'Mint Margarita',350,FALSE);

INSERT INTO modifier_groups (id, name, min_select, max_select) VALUES
(1,'Crust',1,1), (2,'Extra Toppings',0,5), (3,'Add-ons',0,3);

INSERT INTO modifier_options (id, group_id, name, price) VALUES
(1,1,'Regular',0), (2,1,'Stuffed Crust',300), (3,1,'Thin Crust',0),
(4,2,'Extra Cheese',200), (5,2,'Olives',100), (6,2,'Jalapeno',100),
(7,2,'Mushroom',150), (8,2,'Extra Chicken',250),
(9,3,'Cheese Slice',100), (10,3,'Extra Patty',300), (11,3,'Make it Spicy',0);

INSERT INTO menu_item_modifier_groups VALUES
(1,1),(1,2),(2,1),(2,2),(3,1),(3,2),(7,3),(8,3);

INSERT INTO halls (id, name) VALUES (1,'Main Hall'), (2,'Family Hall');

INSERT INTO dining_tables (id, hall_id, table_number, capacity) VALUES
(1,1,1,4),(2,1,2,4),(3,1,3,6),(4,1,4,2),
(5,2,1,4),(6,2,2,6),(7,2,3,8),(8,2,4,4);

-- Sample tax values. Owner apne area ke rates Manager Panel se khud set kare.
INSERT INTO payment_methods (id, name, tax_percent, sort_order) VALUES
(1,'Cash',16,1), (2,'Card',5,2);

INSERT INTO settings (id, restaurant_name, service_charge_percent, service_charge_dine_in_only, receipt_footer)
VALUES (1,'PunchIt Demo Restaurant',0,TRUE,'Thank you! Dobara zaroor aayein.');

-- Staff ke PIN bcrypt hash honge, isliye staff backend ke seed script se banega (Phase 2).
