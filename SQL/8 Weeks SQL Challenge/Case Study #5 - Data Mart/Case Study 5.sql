/* 
	1: Data Cleansing Steps
*/

/* 
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

Convert the week_date to a DATE format
Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
Add a month_number with the calendar month for each week_date value as the 3rd column
Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

segment	age_band
1	    Young Adults
2	    Middle Aged
3 or 4	Retirees

Add a new demographic column using the following mapping for the first letter in the segment values:
segment	demographic
C	Couples
F	Families

Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
*/
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
						ELSE REGEXP_REPLACE(SEGMENT, '\D', '', 'g')
					END AS SEGMENT_NUMBER,
			 
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

/* 
	2. Data Exploration
*/

-- 1. What day of the week is used for each week_date value?
SELECT DISTINCT TO_CHAR(WEEK_DATE, 'Day') AS DAY_NAME
FROM CLEAN_WEEKLY_SALES

-- 2. What range of week numbers are missing from the dataset?
WITH FULL_WEEK_NUMBERS AS
	(SELECT *
		FROM GENERATE_SERIES(1, 52) AS WEEK_NUM)
		
SELECT WEEK_NUM
FROM FULL_WEEK_NUMBERS
WHERE WEEK_NUM NOT IN
		(SELECT DISTINCT WEEK_NUMBER
			FROM CLEAN_WEEKLY_SALES)

-- 3. How many total transactions were there for each year in the dataset?
SELECT CALENDAR_YEAR,
	SUM(TRANSACTIONS) AS TOTAL_TRANSACTIONS
FROM CLEAN_WEEKLY_SALES
GROUP BY 1
ORDER BY 1

-- 4. What is the total sales for each region for each month?
SELECT REGION,
	MONTH_NUMBER,
	SUM(SALES) AS TOTAL_SALES
FROM CLEAN_WEEKLY_SALES
GROUP BY 1, 2
ORDER BY 2, 3 DESC

-- 5. What is the total count of transactions for each platform
SELECT PLATFORM,
	SUM(TRANSACTIONS) AS TOTAL_TRANSACTIONS
FROM CLEAN_WEEKLY_SALES
GROUP BY 1
ORDER BY 2 DESC

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
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


-- 7. What is the percentage of sales by demographic for each year in the dataset?
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
	

-- 8. Which age_band and demographic values contribute the most to Retail sales?
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

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
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

/* 
	3. Before & After Analysis
*/

/* 
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
Using this analysis approach - answer the following questions:
*/

-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
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

-- 2. What about the entire 12 weeks before and after?
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

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
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