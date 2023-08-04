/*
	A: Joining both tables
*/
CREATE OR REPLACE VIEW combined AS(
	SELECT
		*
	FROM foodie_fi.subscriptions
	INNER JOIN foodie_fi.plans USING (plan_id)
)

/*
	B: Data Analysis Questions
*/

-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS n_customers 
FROM foodie_fi.subscriptions


-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
WITH truncated_date AS (
	SELECT 
		DATE(DATE_TRUNC('month', start_date)) AS start_date
	FROM combined
	WHERE plan_id = 0)
	
SELECT 
	start_date,
	COUNT(*) AS n_times
FROM truncated_date
GROUP BY 1
ORDER BY 1

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT 
	plan_name,
	COUNT(*) AS n_events
FROM combined 
WHERE start_date >= '2020-01-01'
GROUP BY 1
ORDER BY 2

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
-- 6. What is the number and percentage of customer plans after their initial free trial?
-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- 8. How many customers have upgraded to an annual plan in 2020?
-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- 12. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?


/*
	C: Challenge Payment Question
*/

/*
	The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts 
	paid by each customer in the subscriptions table with the following requirements:

	1. monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
	2. upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
	3. upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
	4. once a customer churns they will no longer make payments
*/
