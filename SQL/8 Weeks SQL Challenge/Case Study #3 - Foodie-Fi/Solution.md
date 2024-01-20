# :avocado: Case Study #3 - Foodie-Fi  
<img src = "https://8weeksqlchallenge.com/images/case-study-designs/3.png"
alt = "Image" width = "500" height = "520">

## Case Study Questions

### A. Customer Journey: Joining both tables
```sql
CREATE OR REPLACE VIEW COMBINED AS
	(SELECT *
		FROM FOODIE_FI.SUBSCRIPTIONS
		INNER JOIN FOODIE_FI.PLANS USING (PLAN_ID))
```

### B. Data Analysis Questions

#### 1. How many customers has Foodie-Fi ever had?
```sql
SELECT COUNT(DISTINCT CUSTOMER_ID) AS N_CUSTOMERS
FROM FOODIE_FI.SUBSCRIPTIONS
```
| n_customers |
| ------------------------- |
| 1000                      |

***

#### 2. What is the monthly distribution of trial plan `start_date` values for our dataset - use the start of the month as the group by value
```sql
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
```
| start_date | n_times |
|------------|---------|
| 2020-01-01 | 88      |
| 2020-02-01 | 68      |
| 2020-03-01 | 94      |
| 2020-04-01 | 81      |
| 2020-05-01 | 88      |
| 2020-06-01 | 79      |
| 2020-07-01 | 89      |
| 2020-08-01 | 88      |
| 2020-09-01 | 87      |
| 2020-10-01 | 79      |
| 2020-11-01 | 75      |
| 2020-12-01 | 84      |

***

#### 3. What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of events for each `plan_name`
```sql
SELECT 
	plan_name,
	COUNT(*) AS n_events
FROM combined 
WHERE start_date > '2020-12-31'
GROUP BY 1
ORDER BY 2
```
| plan_name     | n_events |
| ------------- | ---------------- |
| basic monthly | 8                |
| churn         | 71               |
| pro annual    | 63               |
| pro monthly   | 60               |

***

#### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
SELECT SUM(CASE
				WHEN PLAN_NAME = 'churn' THEN 1
				ELSE 0
				END) AS N_CHURN,
	ROUND(CAST(SUM(CASE
						WHEN PLAN_NAME = 'churn' THEN 1
						ELSE 0
						END) AS numeric) / COUNT(DISTINCT CUSTOMER_ID) * 100, 1) AS PERC_CHURN
FROM COMBINED
```
| n_churn | perc_churn |
| ----------------- | ---------------- |
| 307               | 30.7             |

***

#### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```sql
WITH SEQUENCE_OF_EVENTS AS
	(SELECT CUSTOMER_ID,
			PLAN_NAME,
	 		-- use lead to get the plan immediately after their free trial
			LEAD(PLAN_NAME) OVER(PARTITION BY CUSTOMER_ID ORDER BY CUSTOMER_ID, START_DATE) AS NEXT_PLAN
		FROM COMBINED
		ORDER BY CUSTOMER_ID, START_DATE)
		
SELECT COUNT(DISTINCT CUSTOMER_ID) AS N_CUSTOMERS,
	ROUND(CAST(COUNT(DISTINCT CUSTOMER_ID) AS numeric) /
								(SELECT COUNT(DISTINCT CUSTOMER_ID)
									FROM COMBINED) * 100, 1) AS CHURN_PERC
FROM SEQUENCE_OF_EVENTS
WHERE PLAN_NAME = 'trial'
	AND NEXT_PLAN = 'churn'
```
| n_customers | churn_perc |
| ----------------- | ---------------- |
| 92              | 9            |

***

#### 6. What is the number and percentage of customer plans after their initial free trial?
```sql
WITH SEQUENCE_OF_EVENTS AS
	(SELECT CUSTOMER_ID,
			PLAN_NAME,
			LEAD(PLAN_NAME) OVER(PARTITION BY CUSTOMER_ID ORDER BY CUSTOMER_ID, START_DATE) AS NEXT_PLAN
		FROM COMBINED
		ORDER BY CUSTOMER_ID, START_DATE)
		
SELECT NEXT_PLAN AS PLAN_NAME,
	COUNT(NEXT_PLAN) AS PLAN_AFTER_TRIAL,
	ROUND(CAST(COUNT(NEXT_PLAN) AS numeric) /
								(SELECT COUNT(DISTINCT CUSTOMER_ID)
									FROM COMBINED) * 100, 1) AS PERC
FROM SEQUENCE_OF_EVENTS
WHERE PLAN_NAME = 'trial'
GROUP BY 1
```
| plan_name     | plan_after_trial | perc |
| ------------- | --------------------------- | ----------------------------- |
| basic monthly | 546                         | 54.6                          |
| churn         | 92                          | 9.2                           |
| pro annual    | 37                          | 3.7                           |
| pro monthly   | 325                         | 32.5                          |

***

#### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```sql
WITH BEFORE_YEAR_END AS
	(SELECT PLAN_NAME,
			CUSTOMER_ID,
			ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE DESC) AS PLAN_ORDER
		FROM COMBINED
		WHERE START_DATE <= '2020-12-31' )
		
SELECT PLAN_NAME,
	COUNT(DISTINCT CUSTOMER_ID) AS TOTAL_CUSTOMERS,
	ROUND(CAST(COUNT(DISTINCT CUSTOMER_ID) AS numeric) /
								(SELECT COUNT(DISTINCT CUSTOMER_ID)
									FROM COMBINED) * 100, 1)
FROM BEFORE_YEAR_END
WHERE PLAN_ORDER = 1 -- only want the most recent plan
GROUP BY 1
```
| plan_name     | total_customers | round |
|---------------|-----------------|-------|
| "basic monthly" | 224           | 22.4  |
| "churn"       | 236             | 23.6  |
| "pro annual"  | 195             | 19.5  |
| "pro monthly" | 326             | 32.6  |
| "trial"       | 19              | 1.9   |

***

#### 8. How many customers have upgraded to an annual plan in 2020?
```sql
WITH IN_2020 AS
	(SELECT PLAN_NAME,
			CUSTOMER_ID,
			ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID ORDER BY START_DATE) AS PLAN_ORDER
		FROM COMBINED
		WHERE DATE_PART('year', START_DATE) = 2020 ),
		
	UPGRADED AS
	(SELECT PLAN_NAME,
			CUSTOMER_ID
		FROM IN_2020
		WHERE PLAN_ORDER > 1
			AND PLAN_NAME = 'pro annual' -- pro annual should not be the first plan
)

SELECT PLAN_NAME,
	COUNT(DISTINCT CUSTOMER_ID) AS N_COUNT
FROM UPGRADED
GROUP BY 1
```
| plan_name  | n_count |
| ---------- | ------------------- |
| pro annual | 195                 |

***

#### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
WITH ANNUAL_PLANS AS
	(SELECT DISTINCT CUSTOMER_ID,
			START_DATE AS ANNUAL_DATE
		FROM COMBINED
		WHERE PLAN_NAME = 'pro annual' ),
		
	FIRST_JOIN AS
	(SELECT CUSTOMER_ID,
			MIN(START_DATE) AS FIRST_JOINED
		FROM COMBINED
		GROUP BY 1),
		
	DAYS_TAKEN AS
	(SELECT CUSTOMER_ID,
			FIRST_JOINED,
			ANNUAL_DATE,
			ANNUAL_DATE - FIRST_JOINED AS NUM_DAYS
		FROM ANNUAL_PLANS
		INNER JOIN FIRST_JOIN USING (CUSTOMER_ID)
		ORDER BY CUSTOMER_ID)
		
SELECT ROUND(AVG(NUM_DAYS), 0) AS AVERAGE_DAYS
FROM DAYS_TAKEN
```
| plan_name  | average_days |
| ---------- | ------------ |
| pro annual | 105          |

***

#### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```sql
WITH ANNUAL_PLANS AS
	(SELECT DISTINCT CUSTOMER_ID,
			START_DATE AS ANNUAL_DATE
		FROM COMBINED
		WHERE PLAN_NAME = 'pro annual' ),
		
	FIRST_JOIN AS
	(SELECT CUSTOMER_ID,
			MIN(START_DATE) AS FIRST_JOINED
		FROM COMBINED
		GROUP BY 1),
		
	DAYS_TAKEN AS
	(SELECT CUSTOMER_ID,
			FIRST_JOINED,
			ANNUAL_DATE,
			ANNUAL_DATE - FIRST_JOINED AS NUM_DAYS,
			(ANNUAL_DATE - FIRST_JOINED) / 30 + 1 AS BIN
		FROM ANNUAL_PLANS
		INNER JOIN FIRST_JOIN USING (CUSTOMER_ID)
		ORDER BY CUSTOMER_ID),
		
	BINS AS
	(SELECT CUSTOMER_ID,
			NUM_DAYS,
			CASE
				WHEN BIN = 1 THEN CONCAT((BIN-1), ' - ', BIN * 30, ' days')
				ELSE CONCAT((BIN-1) * 30 + 1, ' - ', BIN * 30, ' days')
			END AS PERIOD
		FROM DAYS_TAKEN)
		
SELECT PERIOD,
	COUNT(DISTINCT CUSTOMER_ID) AS NUM_COUNT,
	ROUND(AVG(NUM_DAYS), 2) AS AVERAGE_DAYS
FROM BINS
GROUP BY 1
ORDER BY 
	CASE
		 WHEN PERIOD = '0 - 30 days' THEN 1
		 WHEN PERIOD = '31 - 60 days' THEN 2
		 WHEN PERIOD = '61 - 90 days' THEN 3
		 WHEN PERIOD = '91 - 120 days' THEN 4
		 WHEN PERIOD = '121 - 150 days' THEN 5
		 WHEN PERIOD = '151 - 180 days' THEN 6
		 WHEN PERIOD = '181 - 210 days' THEN 7
		 WHEN PERIOD = '211 - 240 days' THEN 8
		 WHEN PERIOD = '241 - 270 days' THEN 9
		 WHEN PERIOD = '271 - 300 days' THEN 10
		 WHEN PERIOD = '301 - 330 days' THEN 11
		 WHEN PERIOD = '331 - 360 days' THEN 12
    END
```
| period       | num_count | average_days |
|--------------|-----------|--------------|
| 0 - 30 days  | 48        | 9.54         |
| 31 - 60 days | 25        | 41.84        |
| 61 - 90 days | 33        | 70.88        |
| 91 - 120 days| 35        | 99.83        |
| 121 - 150 days| 43       | 133.05       |
| 151 - 180 days| 35       | 161.54       |
| 181 - 210 days| 27       | 190.33       |
| 211 - 240 days| 4        | 224.25       |
| 241 - 270 days| 5        | 257.20       |
| 271 - 300 days| 1        | 285.00       |
| 301 - 330 days| 1        | 327.00       |
| 331 - 360 days| 1        | 346.00       |

***

#### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
WITH PRO_MONTHLY AS
	(SELECT DISTINCT CUSTOMER_ID,
			START_DATE AS PRO_DATE
		FROM COMBINED
		WHERE PLAN_NAME = 'pro monthly'),
		
	BASIC_MONTHLY AS
	(SELECT DISTINCT CUSTOMER_ID,
			START_DATE AS BASIC_DATE
		FROM COMBINED
		WHERE PLAN_NAME = 'basic monthly' )
		
SELECT CASE
			WHEN COUNT(*) IS NULL THEN 0
			ELSE COUNT(*)
			END AS NUM_DOWNGRADES
FROM PRO_MONTHLY AS PM
INNER JOIN BASIC_MONTHLY AS BM USING (CUSTOMER_ID)
WHERE PM.PRO_DATE < BM.BASIC_DATE
```
| num_downgrades |
| -------------- |
| 0              |

### C. Outside The Box Questions 
1. How would you calculate the rate of growth for Foodie-Fi?
- We can use the subscriber growth rate formula, which is ((E - S) / S) * 100, where E is the number of subscribers at the end of a period, and S is the number of subscribers at the start of the period. 
- This will give the percentage growth rate over that period. The periods could include months/years when doing period-on-period analyses.

2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
- Subscriber growth rate
- Churn rate
- Average revenue per user (ARPU)
- Customer lifetime value (CLV)
- Customer acquisition cost (CAC)
- Monthly recurring revenue (MRR)
- Customer retention rate

3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?
- Onboarding process for new subscribers
- Usage patterns and engagement with the platform
- Customer support interactions
- Reasons for plan downgrades or cancellations
- Feedback and reviews from customers

4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
- What was the primary reason for canceling your subscription?
- How likely are you to recommend Foodie-Fi to a friend or colleague?
- Did you find the content on Foodie-Fi engaging and valuable?
- Was the pricing of the subscription plans a factor in your decision to cancel?
- What new features or content could Foodie-Fi have offered to keep you as a subscriber?

5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?
- Improving the onboarding process to help customers get value from the service quickly
- Offering personalized recommendations and content based on user preferences
- Providing incentives for annual subscriptions
- Enhancing customer support and addressing user concerns effectively
- Monitoring and acting on feedback from exit surveys and customer reviews to make continuous improvements