## :orange: Case Study #8: Fresh Segments

<img src="https://8weeksqlchallenge.com/images/case-study-designs/8.png" alt="Image" width="500" height="520">

All the information regarding the case study has been sourced from the following link: [here](https://8weeksqlchallenge.com/case-study-8/)

## 🧼 A. Data Exploration and Cleansing

**1. Update the `fresh_segments.interest_metrics` table by modifying the `month_year` column to be a `date` data type with the start of the month**
```sql
ALTER TABLE fresh_segments.interest_metrics 
ALTER COLUMN month_year TYPE DATE USING TO_DATE(month_year, 'MM-YYYY')
```
First 5 rows:
| _month | _year | month_year | interest_id | composition | index_value | ranking | percentile_ranking |
| ------ | ----- | ---------- | ----------- | ----------- | ----------- | ------- | ------------------ |
| 7      | 2018  | 2018-07-01 | 32486       | 11.89       | 6.19        | 1       | 99.86              |
| 7      | 2018  | 2018-07-01 | 6106        | 9.93        | 5.31        | 2       | 99.73              |
| 7      | 2018  | 2018-07-01 | 18923       | 10.85       | 5.29        | 3       | 99.59              |
| 7      | 2018  | 2018-07-01 | 6344        | 10.32       | 5.1         | 4       | 99.45              |
| 7      | 2018  | 2018-07-01 | 100         | 10.77       | 5.04        | 5       | 99.31              |

***

**2. What is count of records in the `fresh_segments.interest_metrics` for each `month_year` value sorted in chronological order (earliest to latest) with the `null` values appearing first?**
```sql
SELECT MONTH_YEAR,
	COUNT(*) AS N_RECORDS
FROM FRESH_SEGMENTS.INTEREST_METRICS
GROUP BY 1
ORDER BY 1 NULLS FIRST
```
Answer:
| month_year | n_records |
|------------|-----------|
| nulls      | 1194      |
| 2018-07-01 | 729       |
| 2018-08-01 | 767       |
| 2018-09-01 | 780       |
| 2018-10-01 | 857       |
| 2018-11-01 | 928       |
| 2018-12-01 | 995       |
| 2019-01-01 | 973       |
| 2019-02-01 | 1121      |
| 2019-03-01 | 1136      |
| 2019-04-01 | 1099      |
| 2019-05-01 | 857       |
| 2019-06-01 | 824       |
| 2019-07-01 | 864       |
| 2019-08-01 | 1149      |

***

**3. What do you think we should do with these `null` values in the `fresh_segments.interest_metrics`?**
Answer:
We could remove the nulls or replace it with the mean/median/mode or do a back-fill or forward-fill. We should check the percentage of nulls are high to ensure removing nulls does not impact the data.
```sql
SELECT 
  ROUND(100 * (SUM(CASE WHEN interest_id IS NULL THEN 1 END) * 1.0 /
    COUNT(*)),2) AS null_perc
FROM FRESH_SEGMENTS.INTEREST_METRICS
```
|null_perc|
|---------|
|   8.36  |

Since the percentage of nulls is rather low, we can simply filter away the nulls in the subsequent analyses.

***

**4. How many `interest_id` values exist in the `fresh_segments.interest_metrics` table but not in the `fresh_segments.interest_map` table? What about the other way around?**
```sql
WITH NOT_IN_MAP AS
	(SELECT COUNT(INTEREST_ID) AS N_METRICS_IDS
		FROM FRESH_SEGMENTS.INTEREST_METRICS
		WHERE NOT EXISTS
				(SELECT ID
					FROM FRESH_SEGMENTS.INTEREST_MAP
					WHERE FRESH_SEGMENTS.INTEREST_METRICS.INTEREST_ID::NUMERIC = FRESH_SEGMENTS.INTEREST_MAP.ID) ),

	NOT_IN_METRICS AS
	(SELECT COUNT(ID) AS N_MAP_IDS
		FROM FRESH_SEGMENTS.INTEREST_MAP
		WHERE NOT EXISTS
				(SELECT INTEREST_ID
					FROM FRESH_SEGMENTS.INTEREST_METRICS
					WHERE FRESH_SEGMENTS.INTEREST_METRICS.INTEREST_ID::NUMERIC = FRESH_SEGMENTS.INTEREST_MAP.ID) )

SELECT *
FROM NOT_IN_MAP,
	NOT_IN_METRICS
```
Answer:
| n_metrics_ids | n_map_ids |
|--------------:|----------:|
|             0 |         7 |

***

**5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table**
```sql
SELECT COUNT(DISTINCT ID) AS RECORD_COUNT
FROM FRESH_SEGMENTS.INTEREST_MAP
```
Answer:
| Record Count |
|--------------|
|     1209     |

***

**6. What sort of table join should we perform for our analysis and why?**
From question 4 above, we can see that there are 7 ids in the `interest_map` table that is not in the `interest_metrics` table. Thus, I would use a `left join` to keep all the values in `interest_map` table and match those in the `interest_metrics` table.

***

## 📚 B. Interest Analysis
  
**1. Which interests have been present in all `month_year` dates in our dataset?**
```sql
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
```
Answer:
First 5 rows:
| Interest Name                    |
| --------------------------------|
| Accounting & CPA Continuing Education Researchers |
| Affordable Hotel Bookers         |
| Aftermarket Accessories Shoppers |
| Alabama Trip Planners            |
| Alaskan Cruise Planners          |

***

**2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?**
```sql
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
```
Answer:
| total_months | interest_count | cumulative_percentage |
| ------------ | -------------- | --------------------- |
| 14           | 480            | 39.93                 |
| 13           | 82             | 46.76                 |
| 12           | 65             | 52.16                 |
| 11           | 95             | 60.07                 |
| 10           | 85             | 67.14                 |
| 9            | 95             | 75.04                 |
| 8            | 67             | 80.62                 |
| 7            | 90             | 88.10                 |
| 6            | 33             | 90.85                 |
| 5            | 38             | 94.01                 |
| 4            | 32             | 96.67                 |
| 3            | 15             | 97.92                 |
| 2            | 12             | 98.92                 |
| 1            | 13             | 100.00                |

Interests with a total of 6 months will cross the 90th percentile.

***

**3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?**
```sql
WITH COMBINED AS
	(SELECT ID,
			INTEREST_NAME
		FROM FRESH_SEGMENTS.INTEREST_MAP AS IMAP
		LEFT JOIN FRESH_SEGMENTS.INTEREST_METRICS AS IMET ON IMAP.ID = CAST(IMET.INTEREST_ID AS numeric)
		GROUP BY 1, 2
		HAVING COUNT(INTEREST_ID) < 6)
		
SELECT COUNT(INTEREST_NAME) AS N_REMOVED
FROM COMBINED
```
Answer:
|n_removed |
|--------------|
|     117     |

***

**4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.**
There could be very solid reasons for removing data items after fewer than 6 months. These could indicate that the data is missing, recently implemented, or inconsistent.

***

**5. After removing these interests - how many unique interests are there for each month?**
```sql
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
```
Answer:
| month_year | number_of_interests |
| ---------- | -------------------- |
| 2018-07-01 | 709                  |
| 2018-08-01 | 752                  |
| 2018-09-01 | 774                  |
| 2018-10-01 | 853                  |
| 2018-11-01 | 925                  |
| 2018-12-01 | 986                  |
| 2019-01-01 | 966                  |
| 2019-02-01 | 1072                 |
| 2019-03-01 | 1078                 |
| 2019-04-01 | 1035                 |
| 2019-05-01 | 827                  |
| 2019-06-01 | 804                  |
| 2019-07-01 | 836                  |
| 2019-08-01 | 1062                 |

***

## 🧩 C. Segment Analysis
**1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year**
```sql
WITH TOP_10 AS
	(SELECT *, 'top_10' AS RANKING
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
	(SELECT *, 'bottom_10' AS RANKING 
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
ORDER BY MONTH_YEAR, RANKING
```
Answer:
| month_year | interest_name | composition | interest_rank | ranking |
| ---------- | ------------- | ----------- | -------------- | ------- |
| 2018-07-01 | Luxury Retail Shoppers | 17.19 | 1 | top_10 |
| 2018-07-01 | Furniture Shoppers | 17.44 | 1 | top_10 |
| 2018-07-01 | Gym Equipment Owners | 18.82 | 1 | top_10 |
| 2018-07-01 | Luxury Hotel Guests | 14.1 | 1 | top_10 |
| 2018-07-01 | Cosmetics and Beauty Shoppers | 14.23 | 1 | top_10 |
| 2018-07-01 | Shoe Shoppers | 14.91 | 1 | top_10 |
| 2018-07-01 | Luxury Retail Researchers | 13.97 | 1 | top_10 |
| 2018-08-01 | Readers of Jamaican Content | 1.52 | 1 | bottom_10 |
| 2018-10-01 | Luxury Boutique Hotel Researchers | 15.15 | 1 | top_10 |
| 2018-12-01 | Work Comes First Travelers | 21.2 | 1 | top_10 |
| 2018-12-01 | Luxury Bedding Shoppers | 15.05 | 1 | top_10 |
| 2019-03-01 | World of Warcraft Enthusiasts | 1.52 | 1 | bottom_10 |
| 2019-04-01 | United Nations Donors | 1.52 | 1 | bottom_10 |
| 2019-04-01 | Minnesota Vikings Fans | 1.52 | 1 | bottom_10 |
| 2019-05-01 | Mowing Equipment Shoppers | 1.51 | 1 | bottom_10 |
| 2019-05-01 | Beer Aficionados | 1.52 | 1 | bottom_10 |
| 2019-05-01 | Philadelphia 76ers Fans | 1.52 | 1 | bottom_10 |
| 2019-05-01 | Gastrointestinal Researchers | 1.52 | 1 | bottom_10 |
| 2019-06-01 | New York Giants Fans | 1.52 | 1 | bottom_10 |
| 2019-06-01 | Disney Fans | 1.52 | 1 | bottom_10 |

***

**2. Which 5 interests had the lowest average ranking value?**
```sql
WITH COMBINED AS
	(SELECT INTEREST_NAME,
			T1.RANKING
		FROM FRESH_SEGMENTS.INTEREST_METRICS AS T1
		JOIN FRESH_SEGMENTS.INTEREST_MAP AS T2 ON CAST(T1.INTEREST_ID AS int) = T2.ID
		WHERE T1.MONTH_YEAR IS NOT NULL )
		
SELECT INTEREST_NAME,
	ROUND(AVG(RANKING),
		1) AS AVG_RANKING,
	COUNT(*) AS N_RECORDS
FROM COMBINED
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5
```
Answer:
| interest_name                       | avg_ranking | n_records |
| ----------------------------------- | ----------- | --------- |
| Hearthstone Video Game Fans         | 1141.0      | 1         |
| The Sims Video Game Fans            | 1135.0      | 1         |
| Hair Color Shoppers                 | 1110.0      | 4         |
| Grand Theft Auto Video Game Fans    | 1110.0      | 2         |
| Bigfoot Folklore Enthusiasts        | 1078.0      | 2         |

***

**3. Which 5 interests had the largest standard deviation in their percentile_ranking value?**
```sql
WITH COMBINED AS
	(SELECT INTEREST_NAME,
			CAST(T1.PERCENTILE_RANKING AS NUMERIC) AS PERCENTILE_RANKING
		FROM FRESH_SEGMENTS.INTEREST_METRICS AS T1
		JOIN FRESH_SEGMENTS.INTEREST_MAP AS T2 ON T1.INTEREST_ID :: int = T2.ID
		WHERE T1.MONTH_YEAR IS NOT NULL)
		
SELECT INTEREST_NAME,
	MAX(PERCENTILE_RANKING) AS MAX_RANK,
	MIN(PERCENTILE_RANKING) AS MIN_RANK,
	ROUND(STDDEV(PERCENTILE_RANKING), 2) AS SD,
	COUNT(*) AS N_RECORDS
FROM COMBINED
GROUP BY 1
ORDER BY 4 DESC NULLS LAST
LIMIT 5
```
Answer:
| interest_name                               | max_rank | min_rank | sd    | n_records |
| ------------------------------------------- | -------- | -------- | ----- | --------- |
| Blockbuster Movie Fans                      | 60.63    | 2.26     | 41.27 | 2         |
| Android Fans                                | 75.03    | 4.84     | 30.72 | 5         |
| TV Junkies                                  | 93.28    | 10.01    | 30.36 | 5         |
| Techies                                     | 86.69    | 7.92     | 30.18 | 6         |
| Entertainment Industry Decision Makers      | 86.15    | 11.23    | 28.97 | 6         |

***

**4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?**
```sql
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
```
Answer:
| interest_name | max_rank | max_date   | min_rank | min_date   |
| ------------- | -------- | ---------- | -------- | ---------- |
| Android Fans  | 75.03    | 2018-07-01 | 4.84     | 2019-03-01 |
| Blockbuster Movie Fans | 60.63 | 2018-07-01 | 2.26 | 2019-08-01 |
| Entertainment Industry Decision Makers | 86.15 | 2018-07-01 | 11.23 | 2019-08-01 |
| TV Junkies    | 93.28    | 2018-07-01 | 10.01    | 2019-08-01 |
| Techies       | 86.69    | 2018-07-01 | 7.92     | 2019-08-01 |

During this period of time, the ranking of these 5 interests increased significantly, with all almost being in the top 10.

***

**5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?**
The customers in this segment have a strong affinity for travel, particularly luxury travel, and may include business travelers. They also have a preference for a luxurious lifestyle and are interested in sports. To effectively target this segment, we should showcase products and services related to luxury travel and lifestyle, such as furniture, cosmetics, and apparel. It's important to avoid promoting budget-oriented products or services, as well as those related to random interests like computer games or astrology. 

Additionally, we should exclude topics related to locations that are outside of the customers' interests, as they may have already visited these places and are not interested in returning. Furthermore, we can exclude topics related to long-term needs and products that the customers may have already purchased, such as luxury furniture or gym equipment. In general, our focus should be on high-value interests within this segment, while continuously monitoring customer engagement to identify when their interests change.

***

## 👆🏻 D. Index Analysis

**1. What is the top 10 interests by the average composition for each month?**
```sql
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
```
For the first 20 rows:
| month_year | interest_name | average_composition | rnk |
| ---------- | ------------- | ------------------- | --- |
| 2018-07-01 | Las Vegas Trip Planners | 7.36 | 1 |
| 2018-07-01 | Gym Equipment Owners | 6.94 | 2 |
| 2018-07-01 | Cosmetics and Beauty Shoppers | 6.78 | 3 |
| 2018-07-01 | Luxury Retail Shoppers | 6.61 | 4 |
| 2018-07-01 | Furniture Shoppers | 6.51 | 5 |
| 2018-07-01 | Asian Food Enthusiasts | 6.10 | 6 |
| 2018-07-01 | Recently Retired Individuals | 5.72 | 7 |
| 2018-07-01 | Family Adventures Travelers | 4.85 | 8 |
| 2018-07-01 | Work Comes First Travelers | 4.80 | 9 |
| 2018-07-01 | HDTV Researchers | 4.71 | 10 |
| 2018-08-01 | Las Vegas Trip Planners | 7.21 | 1 |
| 2018-08-01 | Gym Equipment Owners | 6.62 | 2 |
| 2018-08-01 | Luxury Retail Shoppers | 6.53 | 3 |
| 2018-08-01 | Furniture Shoppers | 6.30 | 4 |
| 2018-08-01 | Cosmetics and Beauty Shoppers | 6.28 | 5 |
| 2018-08-01 | Work Comes First Travelers | 5.70 | 6 |
| 2018-08-01 | Asian Food Enthusiasts | 5.68 | 7 |
| 2018-08-01 | Recently Retired Individuals | 5.58 | 8 |
| 2018-08-01 | Alabama Trip Planners | 4.83 | 9 |
| 2018-08-01 | Luxury Bedding Shoppers | 4.72 | 10 |

***

**2. What is the average of the average composition for the top 10 interests for each month?**
```sql
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
```
Answer:
| month_year | average_of_average_composition |
| ---------- | ------------------------------- |
| 2018-07-01 | 6.04                            |
| 2018-08-01 | 5.95                            |
| 2018-09-01 | 6.90                            |
| 2018-10-01 | 7.07                            |
| 2018-11-01 | 6.62                            |
| 2018-12-01 | 6.65                            |
| 2019-01-01 | 6.32                            |
| 2019-02-01 | 6.58                            |
| 2019-03-01 | 6.12                            |
| 2019-04-01 | 5.75                            |
| 2019-05-01 | 3.54                            |
| 2019-06-01 | 2.43                            |
| 2019-07-01 | 2.77                            |
| 2019-08-01 | 2.63                            |

***

**3. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.**
```sql
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
```
Answer:
| month_year | interest_name               | max_composition | 3_month_moving_avg | 1_month_ago                    | 2_months_ago                   |
| ---------- | --------------------------- | ----------------| ------------------- | ------------------------------ | ------------------------------ |
| 2018-09-01 | Work Comes First Travelers  | 8.26           | 7.61               | Las Vegas Trip Planners: 7.21 | Las Vegas Trip Planners: 7.36 |
| 2018-10-01 | Work Comes First Travelers  | 9.14           | 8.20               | Work Comes First Travelers: 8.26| Las Vegas Trip Planners: 7.21 |
| 2018-11-01 | Work Comes First Travelers  | 8.28           | 8.56               | Work Comes First Travelers: 9.14| Work Comes First Travelers: 8.26|
| 2018-12-01 | Work Comes First Travelers  | 8.31           | 8.58               | Work Comes First Travelers: 8.28| Work Comes First Travelers: 9.14|
| 2019-01-01 | Work Comes First Travelers  | 7.66           | 8.08               | Work Comes First Travelers: 8.31| Work Comes First Travelers: 8.28|
| 2019-02-01 | Work Comes First Travelers  | 7.66           | 7.88               | Work Comes First Travelers: 7.66| Work Comes First Travelers: 8.31|
| 2019-03-01 | Alabama Trip Planners       | 6.54           | 7.29               | Work Comes First Travelers: 7.66| Work Comes First Travelers: 7.66|
| 2019-04-01 | Solar Energy Researchers    | 6.28           | 6.83               | Alabama Trip Planners: 6.54    | Work Comes First Travelers: 7.66|
| 2019-05-01 | Readers of Honduran Content | 4.41           | 5.74               | Solar Energy Researchers: 6.28| Alabama Trip Planners: 6.54    |
| 2019-06-01 | Las Vegas Trip Planners     | 2.77           | 4.49               | Readers of Honduran Content: 4.41| Solar Energy Researchers: 6.28|
| 2019-07-01 | Las Vegas Trip Planners     | 2.82           | 3.33               | Las Vegas Trip Planners: 2.77   | Readers of Honduran Content: 4.41|
| 2019-08-01 | Cosmetics and Beauty Shoppers|2.73          |2.77                | Las Vegas Trip Planners:2.82   | Las Vegas Trip Planners:2.77   |
