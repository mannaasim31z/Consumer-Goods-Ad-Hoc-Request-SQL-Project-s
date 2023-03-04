-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT DISTINCT(market) AS market_name
FROM dim_customer
WHERE region="APAC"
AND customer="Atliq Exclusive";

-- 2. What is the percentage of unique product increase in 2021 vs. 2020?
WITH year_2020 AS (
SELECT COUNT(DISTINCT(product_code)) AS unique_product_2020
FROM fact_sales_monthly 
WHERE fiscal_year=2020),
year_2021 AS (
SELECT COUNT(DISTINCT(product_code)) AS unique_product_2021
FROM fact_sales_monthly 
WHERE fiscal_year=2021)
SELECT unique_product_2020,
       unique_product_2021,
       ROUND(((unique_product_2021/unique_product_2020)-1)*100,2) AS percentage_chg
FROM year_2020,year_2021;

-- 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
SELECT segment,COUNT(DISTINCT(product)) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- 4.Which segment had the most increase in unique products in 2021 vs 2020?
WITH year_2020 AS (
SELECT segment,COUNT(DISTINCT(product)) AS product_count_2020
FROM dim_product
LEFT JOIN fact_sales_monthly
USING (product_code)
WHERE fiscal_year=2020
GROUP BY segment),
year_2021 AS (
SELECT segment,COUNT(DISTINCT(product)) AS product_count_2021
FROM dim_product
LEFT JOIN fact_sales_monthly
USING (product_code)
WHERE fiscal_year=2021
GROUP BY segment)
SELECT segment,product_count_2020,product_count_2021,(product_count_2021-product_count_2020) AS difference
FROM year_2020
JOIN year_2021
USING(segment);

-- 5.Get the products that have the highest and lowest manufacturing costs.
SELECT product_code,product,manufacturing_cost
FROM dim_product
LEFT JOIN fact_manufacturing_cost
USING (product_code)
WHERE manufacturing_cost IN
((SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost),(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost));

-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
SELECT customer_code,customer,ROUND(AVG(pre_invoice_discount_pct)*100,2) AS average_discount_percentage
FROM dim_customer
LEFT JOIN fact_pre_invoice_deductions
USING (customer_code)
WHERE fiscal_year=2021 
AND market="India"
GROUP BY customer,customer_code
ORDER BY average_discount_percentage
DESC LIMIT 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month
SELECT MONTHNAME(DATE) AS month_name,fiscal_year,ROUND(SUM(sold_quantity*gross_price)/1000000,2) AS total_gross_price_millions
FROM dim_customer
LEFT JOIN fact_sales_monthly
USING (customer_code)
LEFT JOIN fact_gross_price
USING (product_code,fiscal_year)
GROUP BY month_name,fiscal_year;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity?
WITH x AS (
SELECT MONTH(DATE_ADD(date,INTERVAL 4 month)) AS fiscal_month_no,ROUND(SUM(sold_quantity)/1000000,2) AS total_sold_quantity_millions
FROM fact_sales_monthly
WHERE fiscal_year=2020
GROUP BY fiscal_month_no)
SELECT
CASE
WHEN fiscal_month_no IN (1,2,3) THEN "Q1"
WHEN fiscal_month_no IN (4,5,6) THEN "Q2"
WHEN fiscal_month_no IN (7,8,9) THEN "Q3"
WHEN fiscal_month_no IN (10,11,12) THEN "Q4"
END quarter_number,
SUM(total_sold_quantity_millions) AS total_sold_quantity_millions
FROM X
GROUP BY quarter_number
ORDER BY total_sold_quantity_millions DESC;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
WITH x AS (
SELECT channel,round(sum(sold_quantity*gross_price)/1000000,2) as gross_sales_million
FROM dim_customer
LEFT JOIN fact_sales_monthly
USING (customer_code)
LEFT JOIN fact_gross_price
USING(product_code,fiscal_year)
GROUP BY channel)
SELECT channel,gross_sales_million,
ROUND(gross_sales_million*100/sum(gross_sales_million) OVER(),2) AS percentage
FROM X
ORDER BY percentage DESC;

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
WITH x AS (
SELECT division,product_code,product,ROUND(SUM(sold_quantity)/1000,2) AS sold_quantity_thousands
FROM dim_product
LEFT JOIN fact_sales_monthly
USING (product_code)
WHERE fiscal_year=2021
GROUP BY division,product,product_code),
y AS (
SELECT division,product_code,product,sold_quantity_thousands,
RANK() OVER(PARTITION BY division ORDER BY  sold_quantity_thousands DESC) AS rnk
from x)
SELECT division,product_code,product,sold_quantity_thousands,rnk
FROM y
WHERE rnk<=3;











