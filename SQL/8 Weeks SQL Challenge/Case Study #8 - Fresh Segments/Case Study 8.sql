/*
	1. Data Exploration and Cleansing
*/
-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
ALTER TABLE fresh_segments.interest_metrics 
ALTER COLUMN month_year TYPE DATE USING TO_DATE(month_year, 'MM-YYYY')

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT MONTH_YEAR,
	COUNT(*) AS N_RECORDS
FROM FRESH_SEGMENTS.INTEREST_METRICS
GROUP BY 1
ORDER BY 1

-- 3. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
SELECT COUNT(DISTINCT INTEREST_ID)
FROM FRESH_SEGMENTS.INTEREST_METRICS
WHERE CAST(INTEREST_ID AS numeric) NOT IN
		(SELECT ID
			FROM FRESH_SEGMENTS.INTEREST_MAP)

-- 4. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT COUNT(DISTINCT ID) AS RECORD_COUNT
FROM FRESH_SEGMENTS.INTEREST_MAP

-- 5. What sort of table join should we perform for our analysis and why? 
--Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
-- 6. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

/*
	2. Interest Analysis
*/ 
-- 1. Which interests have been present in all month_year dates in our dataset?
WITH UNIQUE_APPEARANCES AS
	(SELECT INTEREST_ID,
			COUNT(DISTINCT MONTH_YEAR) AS N_APPEARANCES
		FROM FRESH_SEGMENTS.INTEREST_METRICS
		GROUP BY 1)
		
SELECT INTEREST_NAME
FROM UNIQUE_APPEARANCES AS A
INNER JOIN FRESH_SEGMENTS.INTEREST_MAP AS B ON CAST(A.INTEREST_ID AS numeric) = B.ID
WHERE N_APPEARANCES =
		(SELECT COUNT(DISTINCT MONTH_YEAR)
			FROM FRESH_SEGMENTS.INTEREST_METRICS)
ORDER BY 1 
--limit 5

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
WITH INTEREST_MONTHS AS
	(SELECT INTEREST_ID,
			COUNT(INTEREST_ID) AS TOTAL_MONTHS
		FROM FRESH_SEGMENTS.INTEREST_METRICS
		WHERE INTEREST_ID IS NOT NULL
		GROUP BY 1),
		
	INTEREST_COUNTS AS
	(SELECT TOTAL_MONTHS,
			COUNT(DISTINCT INTEREST_ID) AS INTEREST_COUNT
		FROM INTEREST_MONTHS
		GROUP BY 1)
		
SELECT TOTAL_MONTHS,
	INTEREST_COUNT,
	ROUND(100 * SUM(INTEREST_COUNT) OVER (ORDER BY TOTAL_MONTHS DESC) / -- Create running total field using cumulative values of interest count
 (SUM(INTEREST_COUNT) OVER ()),2) AS CUMULATIVE_PERCENTAGE
FROM INTEREST_COUNTS
ORDER BY 3 

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
WITH COMBINED AS
	(SELECT ID,
			INTEREST_NAME
		FROM FRESH_SEGMENTS.INTEREST_MAP AS IMAP
		LEFT JOIN FRESH_SEGMENTS.INTEREST_METRICS AS IMET ON IMAP.ID = CAST(IMET.INTEREST_ID AS numeric)
		GROUP BY 1, 2
		HAVING COUNT(INTEREST_ID) < 6)
		
SELECT COUNT(INTEREST_NAME) AS N_REMOVED
FROM COMBINED

-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
SELECT
    im.month_year,
    COUNT(CASE WHEN cast(im.interest_id AS int) IN (SELECT cast(interest_id AS int) FROM fresh_segments.interest_metrics GROUP BY 1 HAVING COUNT(interest_id) < 6) THEN 1 END) AS number_of_excluded_interests,
    i.number_of_included_interests,
    ROUND(100.0 * COUNT(CASE WHEN cast(im.interest_id AS int) IN (SELECT cast(interest_id AS int) FROM fresh_segments.interest_metrics GROUP BY 1 HAVING COUNT(interest_id) < 6) THEN 1 END) / i.number_of_included_interests, 1) AS percent_of_excluded
FROM
    fresh_segments.interest_metrics AS im
    JOIN (
        SELECT
            month_year,
            COUNT(interest_id) AS number_of_included_interests
        FROM
            fresh_segments.interest_metrics
        WHERE
            month_year IS NOT NULL
            AND cast(interest_id as int) IN (SELECT cast(interest_id as int) FROM fresh_segments.interest_metrics GROUP BY 1 HAVING COUNT(interest_id) > 5)
        GROUP BY
            1
    ) i ON im.month_year = i.month_year
WHERE
    im.month_year IS NOT NULL
    AND cast(interest_id as int) IN (SELECT cast(interest_id as int) FROM fresh_segments.interest_metrics GROUP BY 1 HAVING COUNT(interest_id) < 6)
GROUP BY
    1, 3
ORDER BY
    1
	
-- 5. After removing these interests - how many unique interests are there for each month?
SELECT MONTH_YEAR,
	COUNT(INTEREST_ID) AS NUMBER_OF_INTERESTS
FROM FRESH_SEGMENTS.INTEREST_METRICS AS IM
WHERE MONTH_YEAR IS NOT NULL
	AND CAST(INTEREST_ID AS int) IN
		(SELECT CAST(INTEREST_ID AS int)
			FROM FRESH_SEGMENTS.INTEREST_METRICS
			WHERE INTEREST_ID = IM.INTEREST_ID
			GROUP BY 1
			HAVING COUNT(*) > 5)
GROUP BY 1
ORDER BY 1

/*
	3. Segment Analysis
*/ 
-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
WITH TOP_10 AS
	(SELECT *
		FROM
			(SELECT T1.MONTH_YEAR,
					T2.INTEREST_NAME,
					T1.COMPOSITION,
					RANK() OVER (PARTITION BY T2.INTEREST_NAME ORDER BY COMPOSITION DESC) AS INTEREST_RANK
				FROM FRESH_SEGMENTS.INTEREST_METRICS AS T1
				JOIN FRESH_SEGMENTS.INTEREST_MAP AS T2 ON CAST(T1.INTEREST_ID AS INT) = T2.ID
				WHERE T1.MONTH_YEAR IS NOT NULL ) RANKED_INTERESTS
		WHERE INTEREST_RANK = 1
		ORDER BY COMPOSITION DESC
		LIMIT 10),
		
	BOTTOM_10 AS
	(SELECT *
		FROM
			(SELECT T1.MONTH_YEAR,
					T2.INTEREST_NAME,
					T1.COMPOSITION,
					RANK() OVER (PARTITION BY T2.INTEREST_NAME ORDER BY COMPOSITION ASC) AS INTEREST_RANK
				FROM FRESH_SEGMENTS.INTEREST_METRICS AS T1
				JOIN FRESH_SEGMENTS.INTEREST_MAP AS T2 ON CAST(T1.INTEREST_ID AS INT) = T2.ID
				WHERE T1.MONTH_YEAR IS NOT NULL ) RANKED_INTERESTS
		WHERE INTEREST_RANK = 1
		ORDER BY COMPOSITION
		LIMIT 10)
		
SELECT *
FROM TOP_10
UNION
SELECT *
FROM BOTTOM_10

-- 2. Which 5 interests had the lowest average ranking value?
WITH COMBINED AS
	(SELECT INTEREST_NAME,
			T1.RANKING
		FROM FRESH_SEGMENTS.INTEREST_METRICS AS T1
		JOIN FRESH_SEGMENTS.INTEREST_MAP AS T2 ON T1.INTEREST_ID :: int = T2.ID
		WHERE T1.MONTH_YEAR IS NOT NULL )
		
SELECT INTEREST_NAME,
	ROUND(AVG(RANKING),
		1) AS AVG_RANKING,
	COUNT(*) AS N_RECORDS
FROM COMBINED
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5

-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
WITH COMBINED AS
	(SELECT INTEREST_NAME,
			CAST(T1.PERCENTILE_RANKING AS NUMERIC) AS PERCENTILE_RANKING
		FROM FRESH_SEGMENTS.INTEREST_METRICS AS T1
		JOIN FRESH_SEGMENTS.INTEREST_MAP AS T2 ON T1.INTEREST_ID :: int = T2.ID
		WHERE T1.MONTH_YEAR IS NOT NULL)
		
SELECT INTEREST_NAME,
	MAX(PERCENTILE_RANKING) AS MAX_RANK,
	MIN(PERCENTILE_RANKING) AS MIN_RANK,
	STDDEV(PERCENTILE_RANKING) AS SD,
	COUNT(*) AS N_RECORDS
FROM COMBINED
GROUP BY 1
ORDER BY 4 DESC NULLS LAST
LIMIT 5

-- 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
WITH TOP5_LARGEST AS
	(WITH COMBINED AS
			(SELECT INTEREST_NAME,
					T2.ID,
					CAST(T1.PERCENTILE_RANKING AS NUMERIC) AS PERCENTILE_RANKING
				FROM FRESH_SEGMENTS.INTEREST_METRICS AS T1
				JOIN FRESH_SEGMENTS.INTEREST_MAP AS T2 ON CAST(T1.INTEREST_ID AS int) = T2.ID
				WHERE T1.MONTH_YEAR IS NOT NULL) 
	 
		SELECT INTEREST_NAME,
			ID,
			MAX(PERCENTILE_RANKING) AS MAX_RANK,
			MIN(PERCENTILE_RANKING) AS MIN_RANK,
			STDDEV(PERCENTILE_RANKING) AS SD,
			COUNT(*) AS N_RECORDS
		FROM COMBINED
		GROUP BY 1, 2
		ORDER BY 5 DESC NULLS LAST
		LIMIT 5),
		
	MAX_DATE_CTE AS
	(SELECT INTEREST_NAME,
			MAX_RANK,
			MONTH_YEAR AS MAX_DATE
		FROM TOP5_LARGEST AS T1
		LEFT JOIN FRESH_SEGMENTS.INTEREST_METRICS AS T2 ON T1.ID = CAST(T2.INTEREST_ID AS int)
		AND T1.MAX_RANK = T2.PERCENTILE_RANKING),
		
	MIN_DATE_CTE AS
	(SELECT INTEREST_NAME,
			MIN_RANK,
			MONTH_YEAR AS MIN_DATE
		FROM TOP5_LARGEST AS T1
		LEFT JOIN FRESH_SEGMENTS.INTEREST_METRICS AS T2 ON T1.ID = CAST(T2.INTEREST_ID AS int)
		AND T1.MIN_RANK = T2.PERCENTILE_RANKING)
		
SELECT INTEREST_NAME,
	MAX_RANK,
	MAX_DATE,
	MIN_RANK,
	MIN_DATE
FROM MIN_DATE_CTE
INNER JOIN MAX_DATE_CTE USING (INTEREST_NAME)
ORDER BY 1

-- 5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

/*
	4. Index Analysis
*/

-- 1. What is the top 10 interests by the average composition for each month?
WITH COMBINED AS
	(SELECT INTEREST_NAME,
			T1.MONTH_YEAR,
			ROUND(CAST(COMPOSITION AS numeric) / CAST(INDEX_VALUE AS NUMERIC),
				2) AS AVERAGE_COMPOSITION
		FROM FRESH_SEGMENTS.INTEREST_METRICS AS T1
		JOIN FRESH_SEGMENTS.INTEREST_MAP AS T2 ON CAST(T1.INTEREST_ID AS int) = T2.ID
		WHERE T1.MONTH_YEAR IS NOT NULL),
		
	RANKED_MONTHLY AS
	(SELECT INTEREST_NAME,
			MONTH_YEAR,
			AVERAGE_COMPOSITION,
			RANK() OVER(PARTITION BY MONTH_YEAR ORDER BY AVERAGE_COMPOSITION DESC) AS RNK
		FROM COMBINED)
		
SELECT MONTH_YEAR,
	INTEREST_NAME,
	AVERAGE_COMPOSITION,
	RNK
FROM RANKED_MONTHLY
WHERE RNK <= 10
ORDER BY 1, 3 DESC

-- 2. What is the average of the average composition for the top 10 interests for each month?
WITH TOP10_INTERESTS AS 
( WITH COMBINED AS
	(SELECT INTEREST_NAME,
			T1.MONTH_YEAR,
			ROUND(CAST(COMPOSITION AS NUMERIC) / CAST(INDEX_VALUE AS NUMERIC),
				2) AS AVERAGE_COMPOSITION
		FROM FRESH_SEGMENTS.INTEREST_METRICS AS T1
		JOIN FRESH_SEGMENTS.INTEREST_MAP AS T2 ON CAST(T1.INTEREST_ID AS int) = T2.ID
		WHERE T1.MONTH_YEAR IS NOT NULL),
 
	RANKED_MONTHLY AS
	(SELECT INTEREST_NAME,
			MONTH_YEAR,
			AVERAGE_COMPOSITION,
			RANK() OVER(PARTITION BY MONTH_YEAR ORDER BY AVERAGE_COMPOSITION DESC) AS RNK
		FROM COMBINED)
						 
SELECT MONTH_YEAR,
	INTEREST_NAME,
	AVERAGE_COMPOSITION,
	RNK
FROM RANKED_MONTHLY
WHERE RNK <= 10
ORDER BY 1, 3 DESC
)

SELECT MONTH_YEAR, ROUND(AVG(AVERAGE_COMPOSITION), 2) AS AVERAGE_OF_AVERAGE_COMPOSITION
FROM TOP10_INTERESTS
GROUP BY 1

-- 3. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
WITH TOP_AVG_COMPOSITION AS (
	SELECT INTEREST_NAME,
			T1.MONTH_YEAR,
			ROUND(CAST(COMPOSITION AS numeric) / CAST(INDEX_VALUE AS NUMERIC),
				2) AS AVERAGE_COMPOSITION,
			RANK() OVER(PARTITION BY MONTH_YEAR ORDER BY ROUND(CAST(COMPOSITION AS NUMERIC) / CAST(INDEX_VALUE AS NUMERIC), 2) DESC) AS RNK
		FROM FRESH_SEGMENTS.INTEREST_METRICS AS T1
		JOIN FRESH_SEGMENTS.INTEREST_MAP AS T2 ON CAST(T1.INTEREST_ID AS int) = T2.ID
		WHERE T1.MONTH_YEAR IS NOT NULL
),

ROLLING_3M AS
	(SELECT MONTH_YEAR,
			INTEREST_NAME,
			AVERAGE_COMPOSITION AS MAX_COMPOSITION,
			ROUND(AVG(AVERAGE_COMPOSITION) OVER(ORDER BY MONTH_YEAR ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS "3_month_moving_avg"
		FROM TOP_AVG_COMPOSITION
		WHERE RNK = 1 ),
		
	LAGS AS
	(SELECT *,
			LAG(INTEREST_NAME, 1) OVER(ORDER BY MONTH_YEAR) AS INTEREST_1,
			LAG(INTEREST_NAME, 2) OVER(ORDER BY MONTH_YEAR) AS INTEREST_2,
			LAG(MAX_COMPOSITION, 1) OVER(ORDER BY MONTH_YEAR) AS COMP_1,
			LAG(MAX_COMPOSITION, 2) OVER(ORDER BY MONTH_YEAR) AS COMP_2
		FROM ROLLING_3M)
		
SELECT MONTH_YEAR,
	INTEREST_NAME,
	MAX_COMPOSITION,
	"3_month_moving_avg",
	INTEREST_1 || ': ' || COMP_1 AS "1_month_ago",
	INTEREST_2 || ': ' || COMP_2 AS "2_months_ago"
FROM LAGS
WHERE MONTH_YEAR BETWEEN '2018-09-01' AND '2019-08-01'