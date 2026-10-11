     -- monday coffee project --

    select * from  city;
    select * from customers;
    select * from products;
    select * from sales;


 -- reports & data analysis 
 
 -- Q.1 coffee consumers Count 
 -- how many people in each city are estimated to consume coffee, given that 25% of the population dose?
 
 
 select  
 city_name,
 round (
 (population * 0.25)/1000000,
 2) as coffee_cunsumers_in_millions,
 city_rank
 from city
 order by 2 DESC
 
 
 -- Q.2 Total revenue from coffee sales 
 -- what is the total revenue generated from coffee sales across all cities in the last quater of 2023?
 
SELECT SUM(total) AS total_revenue
FROM sales
WHERE sale_date >='2023-10-01'
  AND sale_date < '2024-01-01';
 
 SELECT
    c.city_name,
    SUM(s.total) AS total_revenue
FROM sales s
JOIN city c
    ON city_id = c.city_id
WHERE s.sale_date >= '2023-10-01'
  AND s.sale_date < '2024-01-01'
GROUP BY c.city_name
ORDER BY total_revenue DESC;
 
 -- Q.3 Sales count for each product 
 -- how many units of each coffee product have been sold?
 
 SELECT
    p.product_name,
    count(s.sale_id) AS total_units_sold
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units_sold DESC;


-- Q.4 average Sales amount per city
-- what is the average sales amount per customers in each city?

select 
 ci.city_name,
 sum(s.total)as total_ravenue,
 count(distinct s.customer_id) as total_cx,
 Round(
        sum(s.total)/
        count(distinct s.customer_id) ,2) AS AVG_SALE_PR_CX
 FROM SALES AS S
 JOIN customers as c
 on s.customer_id = c.customer_id 
 join city as ci
 on ci.city_id = c.city_id
 group by  1
 order by 2 desc
 
 
 -- Q.5 city population and coffee consumers
-- Provide  a list of cities along with their population and estimated coffee consumers.
 
WITH city_table AS  
(  
    SELECT 
        city_name,
        ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers 
    FROM city
),
customers_table AS  
(  
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_cx
    FROM sales AS s
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)
SELECT 
    customers_table.city_name,
    city_table.coffee_consumers AS coffee_consumer_in_millions,
    customers_table.unique_cx
FROM city_table
JOIN customers_table 
    ON city_table.city_name = customers_table.city_name;
    
    SELECT * 
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS ranking
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci   
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) AS t1
WHERE ranking <= 3;


-- Q.7 Costumer segmantation by city
--  how many unique customers are there in each city who have purchesd coffee products?


select 
     ci.city_name,
     count(distinct c.customer_id) as unique_cx
 from city as ci
 left join 
 customers as c
 on c.city_id = ci.city_id
 join sales as s
 on s.customer_id = c.customer_id
 where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
 group by 1

-- Q.8 average sale vs rent
-- find each city and their average sale per customer and avg rent per customer 

WITH city_table AS ( 
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name,
        estimated_rent
    FROM city
) 
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(cr.estimated_rent / ct.total_cx, 2) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
    ON cr.city_name = ct.city_name
ORDER BY ct.avg_sale_pr_cx DESC;
  
  
-- Q.9 monthly sales growth
-- sales growth rate ,calculate the percentage growth/ decline in sales over diffrent time month    
   
WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
        SUM(s.total) AS total_sales
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, DATE_FORMAT(s.sale_date, '%Y-%m')
),
growth_calc AS (
    SELECT 
        city_name,
        month,
        total_sales,
        LAG(total_sales) OVER (PARTITION BY city_name ORDER BY month) AS previous_month_sales
    FROM monthly_sales
)
SELECT 
    city_name,
    month,
    total_sales,
    previous_month_sales,
    ROUND(
        ((total_sales - previous_month_sales) / NULLIF(previous_month_sales, 0)) * 100, 2
    ) AS growth_percentage
FROM growth_calc;


-- Q.10 market potential analysis
-- identify top 3 city base on highest sales,return city name , total sale , total rant ,total customers , estimated coffee cunsumer



WITH city_sales AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx
    FROM sales AS s
    JOIN customers AS c 
        ON s.customer_id = c.customer_id
    JOIN city AS ci 
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)
SELECT 
    ci.city_name,
    cs.total_revenue,
    ci.estimated_rent AS total_rent,
    cs.total_cx AS total_customers,
    ROUND((ci.population * 0.25) / 1000000, 2) AS estimated_coffee_consumers_in_millions
FROM city AS ci
JOIN city_sales AS cs 
    ON ci.city_name = cs.city_name
ORDER BY cs.total_revenue DESC
LIMIT 3;

-- 1) DELHI - Highest Potential in Sales 
-- 2) Pune- Expected to have decent potential with the highest Profitability due to lower costs
-- 3) Chennai- Offers a balance of high potential and affordable rent




