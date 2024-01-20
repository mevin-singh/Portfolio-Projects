# :bank: Case Study #4: Data Bank

<img src="https://8weeksqlchallenge.com/images/case-study-designs/4.png" alt="Image" width="500" height="520">

All the information regarding the case study has been sourced from the following link: [here](https://8weeksqlchallenge.com/case-study-4/). 

## A. Customer Nodes Exploration

**1. How many unique nodes are there on the Data Bank system?**
```sql
SELECT COUNT(DISTINCT node_id)
FROM data_bank.customer_nodes;
```
Answer:
|count|
|----|
|5|

***

**2. What is the number of nodes per region?**
```sql
WITH COMBINED AS
	(SELECT REGION_NAME,
			NODE_ID
		FROM DATA_BANK.CUSTOMER_NODES
		INNER JOIN DATA_BANK.REGIONS USING (REGION_ID))
		
SELECT REGION_NAME,
	COUNT(NODE_ID) AS N_NODES
FROM COMBINED
GROUP BY 1
```
Answer:
| region_name | n_nodes |
|-------------|---------|
| "America"   | 735     |
| "Australia" | 770     |
| "Africa"    | 714     |
| "Asia"      | 665     |
| "Europe"    | 616     |

***

**3. How many customers are allocated to each region?**
```sql
WITH COMBINED AS
	(SELECT REGION_NAME,
			CUSTOMER_ID
		FROM DATA_BANK.CUSTOMER_NODES
		INNER JOIN DATA_BANK.REGIONS USING (REGION_ID))
		
SELECT REGION_NAME,
	COUNT(DISTINCT CUSTOMER_ID) AS N_CUSTOMERS
FROM COMBINED
GROUP BY 1
```
Answer:
| region_name | n_customers |
|-------------|-------------|
| "Africa"    | 102         |
| "America"   | 105         |
| "Asia"      | 95          |
| "Australia" | 110         |
| "Europe"    | 88          |

***

**4. How many days on average are customers reallocated to a different node?**
```sql
WITH NODE_DAYS AS
	(SELECT CUSTOMER_ID,
			NODE_ID,
			END_DATE - START_DATE AS DAYS_IN_NODE
		FROM DATA_BANK.CUSTOMER_NODES
		WHERE END_DATE != '9999-12-31'
		GROUP BY CUSTOMER_ID,
			NODE_ID,
			START_DATE,
			END_DATE),
			
	TOTAL_NODE_DAYS AS
	(SELECT CUSTOMER_ID,
			NODE_ID,
			SUM(DAYS_IN_NODE) AS N_DAYS
		FROM NODE_DAYS
		GROUP BY 1, 2)
		
SELECT ROUND(AVG(N_DAYS), 0) AS AVERAGE_DAYS
FROM TOTAL_NODE_DAYS
```
Answer:
| average_days |
|--------------|
| 24           |

***

**5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?**
```sql
WITH COMBINED AS
	(SELECT *
		FROM DATA_BANK.CUSTOMER_NODES
		INNER JOIN DATA_BANK.REGIONS USING (REGION_ID)),
		
	NODE_DAYS AS
	(SELECT REGION_NAME,
			END_DATE - START_DATE AS DAYS_IN_NODE
		FROM COMBINED
		WHERE END_DATE != '9999-12-31'
		GROUP BY CUSTOMER_ID,
			NODE_ID,
			REGION_NAME,
			START_DATE,
			END_DATE)
			
SELECT REGION_NAME,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DAYS_IN_NODE) AS MEDIAN,
	PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY DAYS_IN_NODE) AS PERCENTILE_80,
	PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY DAYS_IN_NODE) AS PERCENTILE_90
FROM NODE_DAYS
GROUP BY 1;
```
Answer:
| region_name | median | percentile_80 | percentile_90 |
|-------------|--------|---------------|---------------|
| "Africa"    | 15     | 24            | 26            |
| "America"   | 15     | 23            | 27            |
| "Asia"      | 15     | 23            | 26            |
| "Australia" | 15     | 23            | 26            |
| "Europe"    | 15     | 24            | 27            |

***

## A. Customer Nodes Exploration

**1. What is the unique count and total amount for each transaction type?**
```sql
SELECT TXN_TYPE,
	COUNT(DISTINCT CUSTOMER_ID) AS UNIQUE_COUNT,
	SUM(TXN_AMOUNT) AS TOTAL_TXN_AMOUNT
FROM DATA_BANK.CUSTOMER_TRANSACTIONS
GROUP BY 1
```
Answer:
| txn_type  | unique_count | total_txn_amount |
|-----------|--------------|------------------|
| "deposit" | 500          | 1359168          |
| "purchase"| 448          | 806537           |
| "withdrawal" | 439       | 793003           |

***

**2. What is the average total historical deposit counts and amounts for all customers?**
```sql
WITH DEPOSIT_COUNTS_AMOUNT AS
	(SELECT CUSTOMER_ID,
			COUNT(*) AS DEPOSIT_COUNT,
			SUM(TXN_AMOUNT) AS DEPOSIT_AMOUNT
		FROM DATA_BANK.CUSTOMER_TRANSACTIONS
		WHERE TXN_TYPE = 'deposit'
		GROUP BY 1)
		
SELECT ROUND(AVG(DEPOSIT_COUNT), 0) AS AVG_DEPOSIT_COUNT,
	ROUND(AVG(DEPOSIT_AMOUNT), 2) AS AVG_DEPOSIT_AMOUNT
FROM DEPOSIT_COUNTS_AMOUNT
```
Answer:
| avg_deposit_count | avg_deposit_amount |
|------------------|-------------------|
| 5                | 2718.34           |

***

**3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?**
```sql
WITH TXN_TYPE_MONTHLY AS
	(SELECT CUSTOMER_ID,
			DATE_PART('month', TXN_DATE) AS MONTH,
	 
			SUM(CASE
					WHEN TXN_TYPE = 'deposit' THEN 1
					ELSE 0
					END) AS N_DEPOSITS,
	 
			SUM(CASE
					WHEN TXN_TYPE = 'withdrawal' THEN 1
					ELSE 0
					END) AS N_WITHDRAWALS,
	 
			SUM(CASE
					WHEN TXN_TYPE = 'purchase' THEN 1
					ELSE 0
					END) AS N_PURCHASES
	 
		FROM DATA_BANK.CUSTOMER_TRANSACTIONS
		GROUP BY 1, 2
		ORDER BY 1, 2),
		
	FILTERED AS
	(SELECT CUSTOMER_ID,
			MONTH
		FROM TXN_TYPE_MONTHLY
		WHERE N_DEPOSITS > 1
			AND (N_PURCHASES = 1 OR N_WITHDRAWALS = 1) )
			
SELECT MONTH,
	COUNT(DISTINCT CUSTOMER_ID) AS N_COUNT
FROM FILTERED
GROUP BY 1
```
Answer:
| month | n_count |
|-------|---------|
| 1     | 115     |
| 2     | 108     |
| 3     | 113     |
| 4     | 50      |

***

**4. What is the closing balance for each customer at the end of the month?**
```sql
WITH MONTH_TXN_AMOUNT AS
	(SELECT CUSTOMER_ID,
			DATE_PART('month', TXN_DATE) AS MONTH,
			TXN_TYPE,
			CASE
				WHEN TXN_TYPE IN ('withdrawal', 'purchase') THEN TXN_AMOUNT * -1
				ELSE TXN_AMOUNT
			END AS TXN_AMOUNT
		FROM DATA_BANK.CUSTOMER_TRANSACTIONS
		ORDER BY 1, 2),
		
	MONTHLY_EXPENDITURE AS
	(SELECT CUSTOMER_ID,
			MONTH,
			SUM(TXN_AMOUNT) AS AMOUNT
		FROM MONTH_TXN_AMOUNT
		GROUP BY 1, 2
		ORDER BY 1, 2), 
		
		-- finding the number of months for each customer
	NUM_MONTHS AS
	(SELECT CUSTOMER_ID,
			CAST(MAX(DATE_PART('month', TXN_DATE)) AS numeric) AS MAX_MONTH
		FROM DATA_BANK.CUSTOMER_TRANSACTIONS
		GROUP BY 1),
		
	GENERATE_MONTH_SERIES AS
	(SELECT CUSTOMER_ID,
			MONTH
		FROM NUM_MONTHS,
			GENERATE_SERIES(1, MAX_MONTH) AS MONTH
		ORDER BY 1),
		
	COMBINED AS
	(SELECT GENERATE_MONTH_SERIES.CUSTOMER_ID,
			GENERATE_MONTH_SERIES.MONTH,
			COALESCE(AMOUNT,
				0) AS AMOUNT
		FROM MONTHLY_EXPENDITURE
		RIGHT JOIN GENERATE_MONTH_SERIES USING (CUSTOMER_ID, MONTH))
		
SELECT CUSTOMER_ID,
	MONTH,
    -- sum the amount from the first to current row to find the ending balance of that month
	SUM(AMOUNT) OVER(PARTITION BY CUSTOMER_ID
						ORDER BY MONTH RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ENDING_BALANCE
FROM COMBINED
```
Answer:
For the first 15 rows:
| customer_id | month | ending_balance |
|-------------|-------|----------------|
| 1           | 1     | 312            |
| 1           | 2     | 312            |
| 1           | 3     | -640           |
| 2           | 1     | 549            |
| 2           | 2     | 549            |
| 2           | 3     | 610            |
| 3           | 1     | 144            |
| 3           | 2     | -821           |
| 3           | 3     | -1222          |
| 3           | 4     | -729           |
| 4           | 1     | 848            |
| 4           | 2     | 848            |
| 4           | 3     | 655            |
| 5           | 1     | 954            |
| 5           | 2     | 954            |

***

**5. What is the percentage of customers who increase their closing balance by more than 5%?**
```sql
WITH MONTH_TXN_AMOUNT AS
	(SELECT CUSTOMER_ID,
			DATE_PART('month', TXN_DATE) AS MONTH,
			TXN_TYPE,
			CASE
				WHEN TXN_TYPE IN ('withdrawal', 'purchase') THEN TXN_AMOUNT * -1
				ELSE TXN_AMOUNT
			END AS TXN_AMOUNT
		FROM DATA_BANK.CUSTOMER_TRANSACTIONS
		ORDER BY 1, 2),
		
	MONTHLY_EXPENDITURE AS
	(SELECT CUSTOMER_ID,
			MONTH,
			SUM(TXN_AMOUNT) AS AMOUNT
		FROM MONTH_TXN_AMOUNT
		GROUP BY 1, 2
		ORDER BY 1, 2),
		
	RANKED AS
	(SELECT CUSTOMER_ID,
			MONTH,
			AMOUNT,
			ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID ORDER BY MONTH) AS SOE
		FROM MONTHLY_EXPENDITURE),
		
	BEGINNING_BALANCE AS
	(SELECT CUSTOMER_ID,
			AMOUNT AS BEGINNING
		FROM RANKED
		WHERE SOE = 1 ),
		
	CLOSING_BALANCE AS
	(SELECT CUSTOMER_ID,
			SUM(AMOUNT) AS CLOSING
		FROM MONTHLY_EXPENDITURE
		GROUP BY 1),
		
	PERCENT_CHANGE AS
	(SELECT CUSTOMER_ID,
			BEGINNING,
			CLOSING,
			ROUND((CLOSING - BEGINNING) / BEGINNING * 100, 2) AS PERC_CHANGE
		FROM BEGINNING_BALANCE
		INNER JOIN CLOSING_BALANCE USING (CUSTOMER_ID))
		
SELECT ROUND(CAST(COUNT(*) AS numeric) / CAST((SELECT COUNT (DISTINCT CUSTOMER_ID) FROM DATA_BANK.CUSTOMER_TRANSACTIONS) AS numeric) * 100, 2) AS PROPORTION
FROM PERCENT_CHANGE
WHERE PERC_CHANGE >= 5
```
Answer:
| proportion   |
|--------------|
| 44.20        |

