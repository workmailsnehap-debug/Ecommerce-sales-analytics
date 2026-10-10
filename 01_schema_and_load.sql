-- MySQL 8.x
-- Step 1: create database + table, then load data/clean_sales.csv
-- Run in MySQL Workbench (File > Open SQL Script > Run) or the mysql command line.

CREATE DATABASE IF NOT EXISTS ecommerce_analytics;
USE ecommerce_analytics;

DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    order_id        VARCHAR(10)   NOT NULL,
    order_date      DATE          NOT NULL,
    customer_id     VARCHAR(10)   NOT NULL,
    product_id      VARCHAR(10)   NOT NULL,
    quantity        INT           NOT NULL,
    discount_pct    INT           NOT NULL,
    payment_method  VARCHAR(20),
    order_status    VARCHAR(15),
    city            VARCHAR(30),
    segment         VARCHAR(15),
    category        VARCHAR(30),
    product_name    VARCHAR(50),
    unit_price      DECIMAL(10,2),
    sales_amount    DECIMAL(12,2),
    profit          DECIMAL(12,2),
    year            INT,
    month           INT,
    month_name      VARCHAR(5),
    ym      VARCHAR(7),
    PRIMARY KEY (order_id)
);

-- Load the cleaned CSV.
-- IMPORTANT: change the path below to where YOUR data/clean_sales.csv is.
-- Use forward slashes on Windows, e.g. 'C:/Users/you/ecommerce-sales-analytics/data/clean_sales.csv'
-- If you get error 3948 / 1290 (secure_file_priv / local_infile), use the Workbench
-- "Table Data Import Wizard" instead: right-click the `sales` table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/path/to/ecommerce-sales-analytics/data/clean_sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, order_date, customer_id, product_id, quantity, discount_pct,
 payment_method, order_status, city, segment, category, product_name,
 unit_price, sales_amount, profit, year, month, month_name, ym);

-- Sanity checks: expect 50,081 rows
SELECT COUNT(*) AS total_rows FROM sales;
SELECT MIN(order_date) AS first_order, MAX(order_date) AS last_order FROM sales;
