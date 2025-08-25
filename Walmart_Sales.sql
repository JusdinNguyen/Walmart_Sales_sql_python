-- Walmart Project Queries

SELECT * FROM walmart;

-- DROP TABLE walmart;

-- Simple counts
SELECT COUNT(*) FROM walmart;

SELECT 
    payment_method,
    COUNT(*)
FROM walmart
GROUP BY payment_method;

SELECT 
    COUNT(DISTINCT branch) 
FROM walmart;

SELECT MIN(quantity) FROM walmart;

-- Business Problems
-- Q.1 Find different payment methods, number of transactions, number of qty sold
SELECT 
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Project Question #2
-- Identify the highest-rated category in each branch, displaying the branch, category, and AVG rating
SELECT * 
FROM (
    SELECT 
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
    FROM walmart
    GROUP BY branch, category
) t
WHERE rank = 1;

-- Q.3 Identify the busiest day for each branch based on the number of transactions
SELECT * 
FROM (
    SELECT 
        branch,
        TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart
    GROUP BY branch, day_name
) t
WHERE rank = 1;

-- Q.4 Calculate the total quantity of items sold per payment method. 
-- List payment_method and total_quantity.
SELECT 
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Q.5 Determine the average, minimum, and maximum rating of category for each city. 
-- List the city, category, average_rating, min_rating, and max_rating.
SELECT 
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart
GROUP BY city, category;

-- Q.6 Calculate the total profit for each category.
-- total_profit = unit_price * quantity * profit_margin
-- List category and total_profit, ordered from highest to lowest profit.
SELECT 
    category,
    SUM(total) AS total_revenue,
    SUM(total * profit_margin) AS profit
FROM walmart
GROUP BY category
ORDER BY profit DESC;

-- Q.7 Determine the most common payment method for each Branch. 
-- Display Branch and the preferred_payment_method.
WITH cte AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT *
FROM cte
WHERE rank = 1;

-- Q.8 Categorize sales into 3 groups (MORNING, AFTERNOON, EVENING). 
-- Find out each shift and number of invoices.
SELECT
    branch,
    CASE 
        WHEN EXTRACT(HOUR FROM (time::time)) < 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM (time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS day_time,
    COUNT(*)
FROM walmart
GROUP BY branch, day_time
ORDER BY branch, COUNT(*) DESC;

-- Q.9 Identify 5 branches with highest decrease ratio in revenue compared to last year
-- Decrease ratio = (last_rev - cur_rev) / last_rev * 100
WITH revenue_2022 AS (
    SELECT 
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT 
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
    GROUP BY branch
)
SELECT 
    ls.branch,
    ls.revenue AS last_year_revenue,
    cs.revenue AS cur_year_revenue,
    ROUND(((ls.revenue - cs.revenue)::numeric / ls.revenue::numeric) * 100, 2) AS rev_dec_ratio
FROM revenue_2022 ls
JOIN revenue_2023 cs
    ON ls.branch = cs.branch
WHERE ls.revenue > cs.revenue
ORDER BY rev_dec_ratio DESC
LIMIT 5;