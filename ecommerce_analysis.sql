DROP DATABASE IF EXISTS ecommerce;

CREATE DATABASE ecommerce;
USE ecommerce;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  category_id INT,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  stock INT NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  status ENUM('pending','shipped','delivered','cancelled') DEFAULT 'pending',
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  user_id INT NOT NULL,
  rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orderitems_order ON order_items(order_id);
CREATE INDEX idx_orderitems_product ON order_items(product_id);



INSERT INTO users (name, email) VALUES
('Alice Johnson','alice@example.com'),
('Bob Kumar','bob@example.com'),
('Cara Lee','cara@example.com');

INSERT INTO categories (name) VALUES 
('Electronics'),
('Home'),
('Books');

INSERT INTO products (name, category_id, price, stock) VALUES
('Wireless Mouse', 1, 19.99, 120),
('Bluetooth Speaker', 1, 49.99, 45),
('Ceramic Mug', 2, 9.95, 200),
('Data Structures Book', 3, 39.90, 30);

INSERT INTO orders (user_id, order_date, status, total_amount) VALUES
(1,'2025-07-10 10:25:00','delivered',69.98),
(2,'2025-07-11 12:00:00','shipped',9.95),
(1,'2025-08-01 09:00:00','pending',39.90);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1,1,1,19.99),
(1,2,1,49.99),
(2,3,1,9.95),
(3,4,1,39.90);

INSERT INTO reviews (product_id, user_id, rating, review) VALUES
(1,1,5,'Excellent mouse'),
(2,1,4,'Great sound for the price'),
(4,3,5,'Well-written explanations');


SELECT * FROM users;

SELECT * FROM products;

SELECT id, user_id, order_date, total_amount 
FROM orders
WHERE status <> 'cancelled'
ORDER BY order_date DESC;

SELECT oi.id AS order_item_id, o.id AS order_id, u.name AS customer, 
       p.name AS product, oi.quantity, oi.unit_price, o.order_date
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.id
INNER JOIN products p ON oi.product_id = p.id
INNER JOIN users u ON o.user_id = u.id
ORDER BY o.order_date DESC;

SELECT p.id, p.name, p.price, AVG(r.rating) AS avg_rating, COUNT(r.id) AS num_reviews
FROM products p
LEFT JOIN reviews r ON p.id = r.product_id
GROUP BY p.id, p.name, p.price
ORDER BY avg_rating DESC;

SELECT p.id, p.name, SUM(oi.quantity * oi.unit_price) AS total_sales,
       SUM(oi.quantity) AS total_units_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.id, p.name
ORDER BY total_sales DESC;

SELECT u.id, u.name, COUNT(o.id) AS orders_count, 
       AVG(o.total_amount) AS avg_order_value,
       SUM(o.total_amount) AS lifetime_value
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name
ORDER BY lifetime_value DESC;

CREATE OR REPLACE VIEW vw_product_sales AS
SELECT p.id AS product_id, p.name, p.category_id,
       IFNULL(SUM(oi.quantity * oi.unit_price),0) AS total_sales,
       IFNULL(SUM(oi.quantity),0) AS total_units
FROM products p
LEFT JOIN order_items oi ON p.id = oi.product_id
GROUP BY p.id, p.name, p.category_id;


SELECT * FROM vw_product_sales ORDER BY total_sales DESC;

ALTER TABLE products ADD INDEX idx_products_cat_price (category_id, price);

EXPLAIN SELECT p.id, p.name, SUM(oi.quantity * oi.unit_price) AS total_sales
FROM products p
JOIN order_items oi ON p.id = oi.product_id
GROUP BY p.id, p.name;

SELECT category_id, product_id, product_name, total_sales 
FROM (
  SELECT p.category_id, p.id AS product_id, p.name AS product_name,
         SUM(oi.quantity * oi.unit_price) AS total_sales,
         ROW_NUMBER() OVER (PARTITION BY p.category_id ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS rn
  FROM products p
  JOIN order_items oi ON oi.product_id = p.id
  GROUP BY p.category_id, p.id, p.name
) t 
WHERE rn = 1;






