# 🛍️ Case Study #5: Data Mart

<img src="https://8weeksqlchallenge.com/images/case-study-designs/5.png" alt="Image" width="500" height="520">

All the information regarding the case study has been sourced from the following link: [here](https://8weeksqlchallenge.com/case-study-5/)

## 🧼 A. Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the `data_mart` schema named `clean_weekly_sales`:
- Convert the `week_date` to a `DATE` format
- Add a `week_number` as the second column for each `week_date` value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a `month_number` with the calendar month for each `week_date` value as the 3rd column
- Add a `calendar_year` column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called `age_band` after the original segment column using the following mapping on the number inside the segment value:
  
| segment | age_band    |
|---------|-------------|
| 1       | Young Adults|
| 2       | Middle Aged |
| 3 or 4  | Retirees    |

  
- Add a new `demographic` column using the following mapping for the first letter in the `segment` values:  
| segment | demographic | 
| ------- | ----------- |
| C | Couples |
| F | Families |

- Ensure all `null` string values with an "unknown" string value in the original `segment` column as well as the new `age_band` and `demographic` columns
- Generate a new `avg_transaction` column as the sales value divided by transactions rounded to 2 decimal places for each record

```sql
CREATE OR REPLACE VIEW CLEAN_WEEKLY_SALES AS
	(WITH WEEKLY_SALES AS
			(SELECT TO_DATE(WEEK_DATE, 'DD-MM-YYY') AS WEEK_DATE,
					REGION,
					PLATFORM,
					CASE
						WHEN SEGMENT = 'null' THEN 'Unknown'
						ELSE SEGMENT
					END AS SEGMENT,
			 
					CASE
						WHEN SEGMENT = 'Unknown' THEN SEGMENT
						ELSE REGEXP_REPLACE(SEGMENT, '\D', '', 'g') -- getting segment number
					END AS SEGMENT_NUMBER,
			 
					-- getting first letter
			 		SUBSTRING(SEGMENT, 1, 1) AS SEGMENT_LETTER,
			 
					CUSTOMER_TYPE,
					TRANSACTIONS,
					SALES
			 
				FROM DATA_MART.WEEKLY_SALES) 
	 
	 SELECT WEEK_DATE,
			EXTRACT(WEEK FROM WEEK_DATE) AS WEEK_NUMBER,
			EXTRACT(MONTH FROM WEEK_DATE) AS MONTH_NUMBER,
			EXTRACT(YEAR FROM WEEK_DATE) AS CALENDAR_YEAR,
			REGION,
			PLATFORM,
			SEGMENT,
	 
			CASE
				WHEN SEGMENT_NUMBER = '' THEN 'Unknown'
				WHEN SEGMENT_NUMBER = '1' THEN 'Young Adults'
				WHEN SEGMENT_NUMBER = '2' THEN 'Middle Aged'
				ELSE 'Retirees'
			END AS AGE_BAND,
	 
			CASE
				WHEN SEGMENT_LETTER = 'C' THEN 'Couples'
				WHEN SEGMENT_LETTER = 'F' THEN 'Families'
				ELSE 'Unknown'
			END AS DEMOGRAPHIC,
	 
			CUSTOMER_TYPE,
			TRANSACTIONS,
			SALES,
			ROUND(CAST(SALES AS numeric) / TRANSACTIONS, 2) AS AVG_TRANSACTION
		
	 FROM WEEKLY_SALES)

SELECT * FROM CLEAN_WEEKLY_SALES
LIMIT 10
```
First 10 rows:

| week_date  | week_number | month_number | calendar_year | region | platform | segment | age_band     | demographic  | customer_type | transactions | sales   | avg_transaction |
|------------|-------------|--------------|----------------|--------|----------|---------|--------------|--------------|---------------|--------------|---------|-----------------|
| 2020-08-31 | 36          | 8            | 2020           | "ASIA" | "Retail" | "C3"    | "Retirees"   | "Couples"    | "New"         | 120631       | 3656163 | 30.31           |
| 2020-08-31 | 36          | 8            | 2020           | "ASIA" | "Retail" | "F1"    | "Young Adults" | "Families"  | "New"         | 31574        | 996575  | 31.56           |
| 2020-08-31 | 36          | 8            | 2020           | "USA"  | "Retail" | "Unknown"| "Unknown"    | "Unknown"    | "Guest"       | 529151       | 16509610| 31.20           |
| 2020-08-31 | 36          | 8            | 2020           | "EUROPE"| "Retail" | "C1"    | "Young Adults" | "Couples"   | "New"         | 4517         | 141942  | 31.42           |
| 2020-08-31 | 36          | 8            | 2020           | "AFRICA"| "Retail" | "C2"    | "Middle Aged"| "Couples"    | "New"         | 58046        | 1758388 | 30.29           |
| 2020-08-31 | 36          | 8            | 2020           | "CANADA"| "Shopify"| "F2"    | "Middle Aged"| "Families"   | "Existing"    | 1336         | 243878  | 182.54          |
| 2020-08-31 | 36          | 8            | 2020           | "AFRICA"| "Shopify"| "F3"    | "Retirees"   | "Families"   | "Existing"    | 2514         | 519502  | 206.64          |
| 2020-08-31 | 36          | 8            | 2020           | "ASIA" | "Shopify"| "F1"    | "Young Adults"| "Families"   | "Existing"    | 2158         | 371417  | 172.11          |
| 2020-08-31 | 36          | 8            | 2020           | "AFRICA"| "Shopify"| "F2"    | "Middle Aged"| "Families"   | "New"         | 318          | 49557   | 155.84          |
| 2020-08-31 | 36          | 8            | 2020           | "AFRICA"| "Retail" | "C3"    | "Retirees"   | "Couples"    | "New"         | 111032       | 3888162 | 35.02           |

***

## 🛍 B. Data Exploration

**1. What day of the week is used for each week_date value?**
```sql
SELECT DISTINCT TO_CHAR(WEEK_DATE, 'Day') AS DAY_NAME
FROM CLEAN_WEEKLY_SALES
```
|day_name|
|----|
|Monday|

***

**2. What range of week numbers are missing from the dataset?**
```sql
WITH FULL_WEEK_NUMBERS AS
	(SELECT *
		FROM GENERATE_SERIES(1, 52) AS WEEK_NUM)
		
SELECT WEEK_NUM
FROM FULL_WEEK_NUMBERS
WHERE WEEK_NUM NOT IN
		(SELECT DISTINCT WEEK_NUMBER
			FROM CLEAN_WEEKLY_SALES)
```
| week_num |
|----------|
| 1        |
| 2        |
| 3        |
| 4        |
| 5        |
| 6        |
| 7        |
| 8        |
| 9        |
| 10       |
| 11       |
| 12       |
| 37       |
| 38       |
| 39       |
| 40       |
| 41       |
| 42       |
| 43       |
| 44       |
| 45       |
| 46       |
| 47       |
| 48       |
| 49       |
| 50       |
| 51       |
| 52       |

***

**3. How many total transactions were there for each year in the dataset?**
```sql
SELECT CALENDAR_YEAR,
	SUM(TRANSACTIONS) AS TOTAL_TRANSACTIONS
FROM CLEAN_WEEKLY_SALES
GROUP BY 1
ORDER BY 1
```
| calendar_year | total_transactions |
|---------------|--------------------|
| 2018          | 346406460          |
| 2019          | 365639285          |
| 2020          | 375813651          |

***

**4. What is the total sales for each region for each month?**
```sql
SELECT REGION,
	MONTH_NUMBER,
	SUM(SALES) AS TOTAL_SALES
FROM CLEAN_WEEKLY_SALES
GROUP BY 1, 2
ORDER BY 2, 3 DESC
```
For the month of march (as an example):
| region       | month_number | total_sales |
|--------------|--------------|-------------|
| "OCEANIA"    | 3            | 783282888   |
| "AFRICA"     | 3            | 567767480   |
| "ASIA"       | 3            | 529770793   |
| "USA"        | 3            | 225353043   |
| "CANADA"     | 3            | 144634329   |
| "SOUTH AMERICA" | 3         | 71023109    |
| "EUROPE"     | 3            | 35337093    |

***

**5. What is the total count of transactions for each platform**
```sql
SELECT PLATFORM,
	SUM(TRANSACTIONS) AS TOTAL_TRANSACTIONS
FROM CLEAN_WEEKLY_SALES
GROUP BY 1
ORDER BY 2 DESC
```
| platform | total_transactions |
|----------|--------------------|
| "Retail" | 1081934227         |
| "Shopify" | 5925169           |

***

**6. What is the percentage of sales for Retail vs Shopify for each month?**
```sql
WITH MONTHLY_SALES AS
	(SELECT PLATFORM,
			CALENDAR_YEAR,
			MONTH_NUMBER,
			CAST(SUM(SALES) AS numeric) AS MONTHLY_SALES
		FROM CLEAN_WEEKLY_SALES
		GROUP BY 1, 2, 3
		ORDER BY 2, 3)
		
SELECT CALENDAR_YEAR,
	MONTH_NUMBER,
	ROUND(100 * MAX (CASE
						WHEN PLATFORM = 'Retail' THEN MONTHLY_SALES
						ELSE NULL
						END) / SUM(MONTHLY_SALES), 2) AS RETAIL_PERCENTAGE,
						
	ROUND(100 * MAX (CASE
						WHEN PLATFORM = 'Shopify' THEN MONTHLY_SALES
						ELSE NULL
						END) / SUM(MONTHLY_SALES), 2) AS SHOPIFY_PERCENTAGE
						
FROM MONTHLY_SALES
GROUP BY 1, 2
ORDER BY 1, 2
```
| calendar_year | month_number | retail_percentage | shopify_percentage |
|---------------|--------------|-------------------|---------------------|
| 2018          | 3            | 97.92             | 2.08                |
| 2018          | 4            | 97.93             | 2.07                |
| 2018          | 5            | 97.73             | 2.27                |
| 2018          | 6            | 97.76             | 2.24                |
| 2018          | 7            | 97.75             | 2.25                |
| 2018          | 8            | 97.71             | 2.29                |
| 2018          | 9            | 97.68             | 2.32                |
| 2019          | 3            | 97.71             | 2.29                |
| 2019          | 4            | 97.80             | 2.20                |
| 2019          | 5            | 97.52             | 2.48                |
| 2019          | 6            | 97.42             | 2.58                |
| 2019          | 7            | 97.35             | 2.65                |
| 2019          | 8            | 97.21             | 2.79                |
| 2019          | 9            | 97.09             | 2.91                |
| 2020          | 3            | 97.30             | 2.70                |
| 2020          | 4            | 96.96             | 3.04                |
| 2020          | 5            | 96.71             | 3.29                |
| 2020          | 6            | 96.80             | 3.20                |
| 2020          | 7            | 96.67             | 3.33                |
| 2020          | 8            | 96.51             | 3.49                |

***

**7. What is the percentage of sales by demographic for each year in the dataset?**
```sql
WITH DEMOGRAPHIC_SALES AS
	(SELECT DEMOGRAPHIC,
			CALENDAR_YEAR,
			CAST(SUM(SALES) AS numeric) AS YEARLY_SALES
		FROM CLEAN_WEEKLY_SALES
		GROUP BY 1, 2
		ORDER BY 2)
		
SELECT CALENDAR_YEAR,
	ROUND(100 * MAX (CASE
						WHEN DEMOGRAPHIC = 'Unknown' THEN YEARLY_SALES
						ELSE NULL
						END) / SUM(YEARLY_SALES), 2) AS UNKNOWN_PERCENTAGE,
						
	ROUND(100 * MAX (CASE
						WHEN DEMOGRAPHIC = 'Families' THEN YEARLY_SALES
						ELSE NULL
						END) / SUM(YEARLY_SALES), 2) AS FAMILIES_PERCENTAGE,
						
	ROUND(100 * MAX (CASE
						WHEN DEMOGRAPHIC = 'Couples' THEN YEARLY_SALES
						ELSE NULL
						END) / SUM(YEARLY_SALES), 2) AS COUPLES_PERCENTAGE
						
	FROM DEMOGRAPHIC_SALES
	GROUP BY 1
	ORDER BY 1
```
| calendar_year | unknown_percentage | families_percentage | couples_percentage |
|---------------|--------------------|---------------------|--------------------|
| 2018          | 41.63              | 31.99               | 26.38              |
| 2019          | 40.25              | 32.47               | 27.28              |
| 2020          | 38.55              | 32.73               | 28.72              |

***

**8. Which age_band and demographic values contribute the most to Retail sales?**
```sql
WITH RETAIL AS
	(SELECT AGE_BAND,
			DEMOGRAPHIC,
			CAST(SUM(SALES) AS numeric) AS TOTAL_SALES
		FROM CLEAN_WEEKLY_SALES
		WHERE PLATFORM = 'Retail'
			AND AGE_BAND != 'Unknown'
			AND DEMOGRAPHIC != 'Unknown' -- would not make sense to include Unknown
		GROUP BY 1, 2)
		
SELECT AGE_BAND,
	DEMOGRAPHIC,
	ROUND(TOTAL_SALES /(SELECT CAST(SUM(SALES) AS numeric) FROM CLEAN_WEEKLY_SALES) * 100, 1) AS RETAIL_PROPORTION
FROM RETAIL
ORDER BY 3 DESC
LIMIT 1
```
| age_band | demographic | retail_proportion |
|----------|------------|-------------------|
| "Retirees" | "Families" | 16.3             |

***

**9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?**
```sql
WITH ROW_WISE AS
	(SELECT PLATFORM,
			CALENDAR_YEAR,
			ROUND(AVG(AVG_TRANSACTION),
				0) AS AVG_TRANSACTION_BY_ROW
		FROM CLEAN_WEEKLY_SALES
		GROUP BY 1, 2
		ORDER BY 2, 3 DESC), 
		
-- more accurate to use this
GROUP_WISE AS
	(SELECT PLATFORM,
			CALENDAR_YEAR,
			SUM(SALES) / SUM(TRANSACTIONS) AS AVG_TRANSACTION_BY_GROUP
		FROM CLEAN_WEEKLY_SALES
		GROUP BY 1, 2
		ORDER BY 2, 3 DESC)
		
SELECT *
FROM GROUP_WISE
INNER JOIN ROW_WISE USING (PLATFORM, CALENDAR_YEAR)
```
| platform | calendar_year | avg_transaction_by_group | avg_transaction_by_row |
|----------|---------------|--------------------------|------------------------|
| "Shopify" | 2018          | 192                      | 188                    |
| "Retail"  | 2018          | 36                       | 43                     |
| "Shopify" | 2019          | 183                      | 178                    |
| "Retail"  | 2019          | 36                       | 42                     |
| "Shopify" | 2020          | 179                      | 175                    |
| "Retail"  | 2020          | 36                       | 41                     |

***

## 🧼 C. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
Using this analysis approach - answer the following questions:

**1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?**
```sql
WITH BASELINE AS
	(SELECT WEEK_DATE,
			WEEK_NUMBER,
			SUM(SALES) AS TOTAL_SALES
		FROM CLEAN_WEEKLY_SALES
		WHERE CALENDAR_YEAR = '2020'
		GROUP BY 1, 2),
		
	BEFORE_AFTER_CHANGE AS
	(SELECT SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 21 AND 24 THEN TOTAL_SALES
					END) AS BEFORE_SALES,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 26 AND 29 THEN TOTAL_SALES
					END) AS AFTER_SALES
		FROM BASELINE),
		
	CHANGE_IN_SALES AS
	(SELECT AFTER_SALES,
			BEFORE_SALES,
			AFTER_SALES - BEFORE_SALES AS ABS_DIFF,
			ROUND((AFTER_SALES - BEFORE_SALES) / BEFORE_SALES * 100,
				2) AS PERC_CHANGE
		FROM BEFORE_AFTER_CHANGE)
		
SELECT *
FROM CHANGE_IN_SALES
```
| after_sales | before_sales | abs_diff | perc_change |
|-------------|--------------|----------|-------------|
| 2334905223  | 2345878357   | -10973134| -0.47       |

***

**2. What about the entire 12 weeks before and after?**
```sql
WITH BASELINE AS
	(SELECT WEEK_DATE,
			WEEK_NUMBER,
			SUM(SALES) AS TOTAL_SALES
		FROM CLEAN_WEEKLY_SALES
		WHERE CALENDAR_YEAR = '2020'
		GROUP BY 1, 2),
		
	BEFORE_AFTER_CHANGE AS
	(SELECT SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 13 AND 24 THEN TOTAL_SALES
					END) AS BEFORE_SALES,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 26 AND 37 THEN TOTAL_SALES
					END) AS AFTER_SALES -- max week_number only 36 so missing 1 month as compared to before_sales
		FROM BASELINE),
		
	CHANGE_IN_SALES AS
	(SELECT AFTER_SALES,
			BEFORE_SALES,
			AFTER_SALES - BEFORE_SALES AS ABS_DIFF,
			ROUND((AFTER_SALES - BEFORE_SALES) / BEFORE_SALES * 100,
				2) AS PERC_CHANGE
		FROM BEFORE_AFTER_CHANGE)
		
SELECT *
FROM CHANGE_IN_SALES
```
| after_sales | before_sales | abs_diff | perc_change |
|-------------|--------------|----------|-------------|
| 6403922405  | 7126273147   | -722350742| -10.14      |

***

**3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?**
```sql
WITH BASELINE_2018 AS
	(SELECT WEEK_DATE,
			WEEK_NUMBER,
			SUM(SALES) AS TOTAL_SALES
		FROM CLEAN_WEEKLY_SALES
		WHERE CALENDAR_YEAR = '2018'
		GROUP BY 1, 2),
		
	BEFORE_AFTER_CHANGE_2018 AS
	(SELECT SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 21 AND 24 THEN TOTAL_SALES
					END) AS BEFORE_SALES_4WEEKS,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 26 AND 29 THEN TOTAL_SALES
					END) AS AFTER_SALES_4WEEKS,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 13 AND 24 THEN TOTAL_SALES
					END) AS BEFORE_SALES_12WEEKS,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 26 AND 37 THEN TOTAL_SALES
					END) AS AFTER_SALES_12WEEKS
		FROM BASELINE_2018),
		
	CHANGE_IN_SALES_2018 AS
	(SELECT '2018' AS YEAR,
	 		AFTER_SALES_4WEEKS,
			BEFORE_SALES_4WEEKS,
			AFTER_SALES_12WEEKS,
			BEFORE_SALES_12WEEKS,
			AFTER_SALES_4WEEKS - BEFORE_SALES_4WEEKS AS ABS_DIFF_4WEEKS,
			AFTER_SALES_12WEEKS - BEFORE_SALES_12WEEKS AS ABS_DIFF_12WEEKS,
			ROUND((AFTER_SALES_4WEEKS - BEFORE_SALES_4WEEKS) / BEFORE_SALES_4WEEKS * 100,
				2) AS PERC_CHANGE_4WEEKS,
			ROUND((AFTER_SALES_12WEEKS - BEFORE_SALES_12WEEKS) / BEFORE_SALES_12WEEKS * 100,
				2) AS PERC_CHANGE_12WEEKS
		FROM BEFORE_AFTER_CHANGE_2018),
		
BASELINE_2019 AS
	(SELECT WEEK_DATE,
			WEEK_NUMBER,
			SUM(SALES) AS TOTAL_SALES
		FROM CLEAN_WEEKLY_SALES
		WHERE CALENDAR_YEAR = '2019'
		GROUP BY 1, 2),
		
	BEFORE_AFTER_CHANGE_2019 AS
	(SELECT SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 21 AND 24 THEN TOTAL_SALES
					END) AS BEFORE_SALES_4WEEKS,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 26 AND 29 THEN TOTAL_SALES
					END) AS AFTER_SALES_4WEEKS,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 13 AND 24 THEN TOTAL_SALES
					END) AS BEFORE_SALES_12WEEKS,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 26 AND 37 THEN TOTAL_SALES
					END) AS AFTER_SALES_12WEEKS
		FROM BASELINE_2019),
		
	CHANGE_IN_SALES_2019 AS
	(SELECT '2019' AS YEAR,
	 		AFTER_SALES_4WEEKS,
			BEFORE_SALES_4WEEKS,
			AFTER_SALES_12WEEKS,
			BEFORE_SALES_12WEEKS,
			AFTER_SALES_4WEEKS - BEFORE_SALES_4WEEKS AS ABS_DIFF_4WEEKS,
			AFTER_SALES_12WEEKS - BEFORE_SALES_12WEEKS AS ABS_DIFF_12WEEKS,
			ROUND((AFTER_SALES_4WEEKS - BEFORE_SALES_4WEEKS) / BEFORE_SALES_4WEEKS * 100,
				2) AS PERC_CHANGE_4WEEKS,
			ROUND((AFTER_SALES_12WEEKS - BEFORE_SALES_12WEEKS) / BEFORE_SALES_12WEEKS * 100,
				2) AS PERC_CHANGE_12WEEKS
		FROM BEFORE_AFTER_CHANGE_2019),
		
	BASELINE_2020 AS
	(SELECT WEEK_DATE,
			WEEK_NUMBER,
			SUM(SALES) AS TOTAL_SALES
		FROM CLEAN_WEEKLY_SALES
		WHERE CALENDAR_YEAR = '2020'
		GROUP BY 1, 2),
		
	BEFORE_AFTER_CHANGE_2020 AS
	(SELECT SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 21 AND 24 THEN TOTAL_SALES
					END) AS BEFORE_SALES_4WEEKS,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 26 AND 29 THEN TOTAL_SALES
					END) AS AFTER_SALES_4WEEKS,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 13 AND 24 THEN TOTAL_SALES
					END) AS BEFORE_SALES_12WEEKS,
			SUM(CASE
					WHEN WEEK_NUMBER BETWEEN 26 AND 37 THEN TOTAL_SALES
					END) AS AFTER_SALES_12WEEKS
		FROM BASELINE_2020),
		
	CHANGE_IN_SALES_2020 AS
	(SELECT '2020' AS YEAR,
	 		AFTER_SALES_4WEEKS,
			BEFORE_SALES_4WEEKS,
			AFTER_SALES_12WEEKS,
			BEFORE_SALES_12WEEKS,
			AFTER_SALES_4WEEKS - BEFORE_SALES_4WEEKS AS ABS_DIFF_4WEEKS,
			AFTER_SALES_12WEEKS - BEFORE_SALES_12WEEKS AS ABS_DIFF_12WEEKS,
			ROUND((AFTER_SALES_4WEEKS - BEFORE_SALES_4WEEKS) / BEFORE_SALES_4WEEKS * 100,
				2) AS PERC_CHANGE_4WEEKS,
			ROUND((AFTER_SALES_12WEEKS - BEFORE_SALES_12WEEKS) / BEFORE_SALES_12WEEKS * 100,
				2) AS PERC_CHANGE_12WEEKS
		FROM BEFORE_AFTER_CHANGE_2020)
		
SELECT *
FROM CHANGE_IN_SALES_2018
UNION
(SELECT *
FROM CHANGE_IN_SALES_2019)
UNION
(SELECT *
FROM CHANGE_IN_SALES_2020)
ORDER BY YEAR
```
| year | after_sales_4weeks | before_sales_4weeks | after_sales_12weeks | before_sales_12weeks | abs_diff_4weeks | abs_diff_12weeks | perc_change_4weeks | perc_change_12weeks |
|------|--------------------|---------------------|---------------------|----------------------|------------------|-------------------|--------------------|---------------------|
| 2018 | 2145961036         | 2125140809          | 5976449777          | 6396562317           | 20820227         | -420112540        | 0.98               | -6.57               |
| 2019 | 2264499542         | 2249989796          | 6303557285          | 6883386397           | 14509746         | -579829112        | 0.64               | -8.42               |
| 2020 | 2334905223         | 2345878357          | 6403922405          | 7126273147           | -10973134        | -722350742        | -0.47              | -10.14              |
