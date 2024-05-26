-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS Customers_Count
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start 
-- of the month as the group by value
SELECT 
    monthname(start_date) AS month, 
    COUNT(customer_id) AS Customer_count
FROM subscriptions
WHERE plan_id = 0
GROUP BY month
ORDER BY Customer_count DESC;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown 
-- by count of events for each plan_name
SELECT 
    plan_name, 
    plan_id, 
    COUNT(*) AS customers
FROM subscriptions
INNER JOIN plans
USING(plan_id)
WHERE YEAR(start_date) > 2020
GROUP BY Plan_name, plan_id;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT 
    COUNT(*) AS Customer_churn,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1) AS percentage
FROM 
    subscriptions
WHERE 
    plan_id = 4;

-- 5. How many customers have churned straight after their initial free trial - what percentage is 
-- this rounded to the nearest whole number?
WITH cte AS (
    SELECT *,
        lag(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY plan_id) AS prev_plan
    FROM subscriptions
)
SELECT 
    COUNT(*) AS count,
    ROUND(COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) * 100) AS percentage
FROM cte
WHERE plan_id = 4 AND prev_plan = 0;

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH cte AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY customer_id ORDER BY start_date) AS rnk
    FROM 
        subscriptions
)
SELECT 
    plan_name,
    COUNT(plan_id) AS counts,
    ROUND(COUNT(plan_id) / (SELECT COUNT(plan_id) FROM cte WHERE rnk = 2) * 100, 1) AS percentage
FROM 
    cte
JOIN 
    plans USING (plan_id)
WHERE 
    rnk = 2
GROUP BY 
    plan_name;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020--- 12-31?
with cte as (
select *, 
rank() over(partition by customer_id order by start_date desc) as rnk
from subscriptions
where start_date <= '2020-12-31'
)
SELECT 
    plan_name,
    COUNT(DISTINCT customer_id) AS customer_count,
    ROUND(COUNT(customer_id) / (SELECT 
                    COUNT(customer_id)
                FROM
                    cte
                WHERE
                    rnk = 1) * 100,
            1) percentage
FROM
    cte
        JOIN
    plans USING (plan_id)
WHERE
    rnk = 1
GROUP BY plan_name;

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS counts
FROM subscriptions
WHERE plan_id = 3 AND start_date <= '2020-12-31';

-- 9. How many days on average does it take for a customer to an annual plan from the day they 
-- join Foodie-Fi?
WITH START_CTE AS (
    SELECT 
        customer_id,
        start_date 
    FROM 
        subscriptions
    WHERE 
        plan_id = 3
),
ANNUAL_CTE AS (
    SELECT 
        customer_id,
        start_date AS start_annual
    FROM 
        subscriptions
    WHERE 
        plan_id = 0
)
SELECT 
    ROUND(AVG(DATEDIFF(start_date, start_annual)), 0) AS average_day
FROM 
    ANNUAL_CTE
LEFT JOIN 
    START_CTE USING(customer_id);

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 
-- days etc)
WITH annual_plan AS (
    SELECT customer_id, start_date AS annual_date
    FROM subscriptions
    WHERE plan_id = 3
), trial_plan AS (
    SELECT customer_id, start_date AS trial_date
    FROM subscriptions
    WHERE plan_id = 0
), day_period AS (
    SELECT DATEDIFF(annual_date, trial_date) AS diff
    FROM trial_plan AS tp
    LEFT JOIN annual_plan AS ap USING(customer_id)
    WHERE annual_date IS NOT NULL
), bins AS (
    SELECT *, FLOOR(diff/30) AS bins
    FROM day_period
)
SELECT CONCAT((bins * 30) + 1, ' - ', (bins + 1) * 30, ' days ') AS days, 
COUNT(diff) AS total
FROM bins
GROUP BY bins;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH cte AS (
    SELECT 
        *,
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date, plan_id) AS next_plan
    FROM 
        subscriptions
)
SELECT 
    COUNT(DISTINCT customer_id) AS downgraded
FROM 
    cte
WHERE 
    plan_id = 2 AND next_plan = 1 AND YEAR(start_date) = 2020; 
