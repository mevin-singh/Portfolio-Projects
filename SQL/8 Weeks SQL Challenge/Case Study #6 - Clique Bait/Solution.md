# :hook: Case Study #6 - Clique Bait 

<img src="https://8weeksqlchallenge.com/images/case-study-designs/6.png" alt="Image" width="500" height="520">

All the information regarding the case study has been sourced from the following link: [here](https://8weeksqlchallenge.com/case-study-6/)

### 1. Digital Analysis

**1. How many users are there?**
```sql
SELECT COUNT(DISTINCT USER_ID)
FROM CLIQUE_BAIT.USERS
```
Answer:
| count |
| --------------- |
| 500             |

***

**2. How many cookies does each user have on average?**
```sql
WITH COOKIE_COUNT AS
	(SELECT USER_ID,
			COUNT(DISTINCT COOKIE_ID) AS COOKIES
		FROM CLIQUE_BAIT.USERS
		GROUP BY 1)
		
SELECT ROUND(AVG(COOKIES), 2) AS AVG_COOKIES
FROM COOKIE_COUNT
```
Answer:
| avg_cookies |
| -------------------- |
| 3.56                 |

***

**3. What is the unique number of visits by all users per month?**
```sql
WITH VISITS AS
	(SELECT USER_ID,
			VISIT_ID,
			DATE_PART('month', EVENT_TIME) AS MONTH
		FROM CLIQUE_BAIT.EVENTS
		INNER JOIN CLIQUE_BAIT.USERS USING (COOKIE_ID))
		
SELECT MONTH,
	COUNT(DISTINCT VISIT_ID) AS N_UNIQUE_VISITS
FROM VISITS
GROUP BY 1
```
Answer:
| month | n_unique_visits |
|-------|-----------------|
| 1     | 876             |
| 2     | 1488            |
| 3     | 916             |
| 4     | 248             |
| 5     | 36              |

***

**4. What is the number of events for each event type?**
```sql
SELECT EVENT_TYPE,
	COUNT(*) AS N_EVENTS
FROM CLIQUE_BAIT.EVENTS
GROUP BY 1
ORDER BY 1
```
Answer:
| event_type | n_events |
|------------|----------|
| 1          | 20928    |
| 2          | 8451     |
| 3          | 1777     |
| 4          | 876      |
| 5          | 702      |

***

**5. What is the percentage of visits which have a purchase event?**
```sql
WITH COMPLETE_EVENTS AS
	(SELECT EVENT_NAME,
			VISIT_ID
		FROM CLIQUE_BAIT.EVENTS
		INNER JOIN CLIQUE_BAIT.EVENT_IDENTIFIER USING (EVENT_TYPE))
SELECT ROUND(CAST(COUNT(DISTINCT VISIT_ID) AS numeric) /
														(SELECT COUNT(DISTINCT VISIT_ID)
															FROM CLIQUE_BAIT.EVENTS) * 100, 2) AS PURCHASE_PERCENTAGE
FROM COMPLETE_EVENTS
WHERE EVENT_NAME = 'Purchase'
```
Answer:
| purchase_percentage |
|--------------------|
|       49.86        |

***

**6. What is the percentage of visits which view the checkout page but do not have a purchase event?**
```sql
WITH CHECKOUT_PURCHASE AS
	(SELECT VISIT_ID,
			MAX(CASE
					WHEN EVENT_TYPE = 1
					AND PAGE_ID = 12 THEN 1
					ELSE 0
					END) AS CHECKOUT,
	 
			MAX(CASE
					WHEN EVENT_TYPE = 3 THEN 1
					ELSE 0
					END) AS PURCHASE
	 
		FROM CLIQUE_BAIT.EVENTS
		GROUP BY VISIT_ID)
		
SELECT ROUND(100 * (1 - (CAST(SUM(PURCHASE) AS numeric) / SUM(CHECKOUT))), 2) AS PERCENTAGE
FROM CHECKOUT_PURCHASE
```
Answer:
| Percentage |
|------------|
|    15.50   |

***

**7. What are the top 3 pages by number of views?**
```sql
SELECT PAGE_ID,
	COUNT(DISTINCT VISIT_ID) AS N_VIEWS
FROM CLIQUE_BAIT.EVENTS
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3
```
Answer:
| page_id | n_views |
| ------- | ------- |
| 2       | 3174    |
| 12      | 2103    |
| 1       | 1782    |

***

**8. What is the number of views and cart adds for each product category?**
```sql
WITH COMBINED AS
	(SELECT PRODUCT_CATEGORY,
			EVENT_TYPE
		FROM CLIQUE_BAIT.EVENTS
		INNER JOIN CLIQUE_BAIT.PAGE_HIERARCHY USING (PAGE_ID))
		
SELECT PRODUCT_CATEGORY,
	SUM(CASE
			WHEN EVENT_TYPE = 1 THEN 1
			ELSE 0
			END) AS N_VIEWS,
	SUM(CASE
			WHEN EVENT_TYPE = 2 THEN 1
			ELSE 0
			END) AS N_CART_ADDS
			
FROM COMBINED
WHERE PRODUCT_CATEGORY IS NOT NULL
GROUP BY 1
```
Answer:
| product_category | n_views | n_cart_adds |
| ---------------- | ------- | ----------- |
| Luxury           | 3032    | 1870        |
| Shellfish        | 6204    | 3792        |
| Fish             | 4633    | 2789        |

***

**9. What are the top 3 products by purchases?**
```sql
WITH COMBINED AS
	(SELECT PAGE_NAME,
			EVENT_TYPE
		FROM CLIQUE_BAIT.EVENTS
		INNER JOIN CLIQUE_BAIT.PAGE_HIERARCHY USING (PAGE_ID))
		
SELECT PAGE_NAME,
	SUM(CASE
			WHEN EVENT_TYPE = 3 THEN 1
			ELSE 0
			END) AS N_PURCHASES
			
FROM COMBINED
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3
```
Answer:
| page_name | n_purchases |
| --------- | ----------- |
| Lobster   | 754         |
| Oyster    | 726         |
| Crab      | 719         |

### 2. Product Funnel Analysis
Using a single SQL query - create a new output table which has the following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?
Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
```sql
CREATE OR REPLACE VIEW PRODUCT_FUNNEL AS (

	WITH PRODUCT_EVENTS AS
	(SELECT VISIT_ID,
			PAGE_NAME AS PRODUCT_NAME,
			PRODUCT_ID,
			PRODUCT_CATEGORY,
			SUM(CASE
					WHEN EVENT_TYPE = 1 THEN 1
					ELSE 0
					END) AS PAGE_VIEWS,
	 
			SUM(CASE
					WHEN EVENT_TYPE = 2 THEN 1
					ELSE 0
					END) AS CART_ADD
	 
		FROM CLIQUE_BAIT.EVENTS
		INNER JOIN CLIQUE_BAIT.PAGE_HIERARCHY USING (PAGE_ID)
		WHERE PRODUCT_ID IS NOT NULL
		GROUP BY 1,2,3,4),
		
	PURCHASE_EVENTS AS
	(SELECT DISTINCT VISIT_ID
		FROM CLIQUE_BAIT.EVENTS
		WHERE EVENT_TYPE = 3 ),
		
	COMBINED AS
	(SELECT PRODUCT_EVENTS.VISIT_ID,
			PRODUCT_NAME,
			PRODUCT_ID,
			PRODUCT_CATEGORY,
			PAGE_VIEWS,
			CART_ADD,
			CASE
				WHEN PURCHASE_EVENTS.VISIT_ID IS NOT NULL THEN 1
				ELSE 0
			END AS PURCHASE
		FROM PRODUCT_EVENTS
		LEFT JOIN PURCHASE_EVENTS USING (VISIT_ID)),
		
	PRODUCT_FUNNEL AS
	(SELECT PRODUCT_NAME,
			PRODUCT_CATEGORY,
			SUM(PAGE_VIEWS) AS VIEWS,
			SUM(CART_ADD) AS CART_ADDS,
			SUM(CASE
					WHEN CART_ADD = 1 AND PURCHASE = 0 THEN 1
					ELSE 0
					END) AS ABANDONED,
	 
			SUM(CASE
					WHEN CART_ADD = 1 AND PURCHASE = 1 THEN 1
					ELSE 0
					END) AS PURCHASED
	 
		FROM COMBINED
		GROUP BY 1, 2)
		
SELECT *
FROM PRODUCT_FUNNEL
ORDER BY PRODUCT_NAME
)

CREATE OR REPLACE VIEW PRODUCT_CAT_FUNNEL AS (
	WITH PRODUCT_EVENTS AS
	(SELECT VISIT_ID,
			PAGE_NAME AS PRODUCT_NAME,
			PRODUCT_ID,
			PRODUCT_CATEGORY,
			SUM(CASE
					WHEN EVENT_TYPE = 1 THEN 1
					ELSE 0
					END) AS PAGE_VIEWS,
	 
			SUM(CASE
					WHEN EVENT_TYPE = 2 THEN 1
					ELSE 0
					END) AS CART_ADD
	 
		FROM CLIQUE_BAIT.EVENTS
		INNER JOIN CLIQUE_BAIT.PAGE_HIERARCHY USING (PAGE_ID)
		WHERE PRODUCT_ID IS NOT NULL
		GROUP BY 1,2,3,4),
		
	PURCHASE_EVENTS AS
	(SELECT DISTINCT VISIT_ID
		FROM CLIQUE_BAIT.EVENTS
		WHERE EVENT_TYPE = 3 ),
		
	COMBINED AS
	(SELECT PRODUCT_EVENTS.VISIT_ID,
			PRODUCT_NAME,
			PRODUCT_ID,
			PRODUCT_CATEGORY,
			PAGE_VIEWS,
			CART_ADD,
			CASE
				WHEN PURCHASE_EVENTS.VISIT_ID IS NOT NULL THEN 1
				ELSE 0
			END AS PURCHASE
		FROM PRODUCT_EVENTS
		LEFT JOIN PURCHASE_EVENTS USING (VISIT_ID)),
		
	PRODUCT_CAT_FUNNEL AS
	(SELECT PRODUCT_CATEGORY,
			SUM(PAGE_VIEWS) AS VIEWS,
			SUM(CART_ADD) AS CART_ADDS,
			SUM(CASE
					WHEN CART_ADD = 1 AND PURCHASE = 0 THEN 1
					ELSE 0
					END) AS ABANDONED,
	 
			SUM(CASE
					WHEN CART_ADD = 1 AND PURCHASE = 1 THEN 1
					ELSE 0
					END) AS PURCHASED
	 
		FROM COMBINED
		GROUP BY 1)
		
SELECT *
FROM PRODUCT_CAT_FUNNEL
ORDER BY PRODUCT_CATEGORY
)
```
Answer:
First 10 rows of `product_funnel` table:
| product_name   | product_category | views | cart_adds | abandoned | purchased |
| -------------- | ---------------- | ----- | --------- | --------- | --------- |
| Abalone        | Shellfish        | 1525  | 932       | 233       | 699       |
| Black Truffle  | Luxury           | 1469  | 924       | 217       | 707       |
| Crab           | Shellfish        | 1564  | 949       | 230       | 719       |
| Kingfish       | Fish             | 1559  | 920       | 213       | 707       |
| Lobster        | Shellfish        | 1547  | 968       | 214       | 754       |
| Oyster         | Shellfish        | 1568  | 943       | 217       | 726       |
| Russian Caviar | Luxury           | 1563  | 946       | 249       | 697       |
| Salmon         | Fish             | 1559  | 938       | 227       | 711       |
| Tuna           | Fish             | 1515  | 931       | 234       | 697       |

All rows of `product_cat_funnel` table:
| product_category | n_views | n_cart_adds |
| ---------------- | ------- | ----------- |
| Luxury           | 3032    | 1870        |
| Shellfish        | 6204    | 3792        |
| Fish             | 4633    | 2789        |

***

**1. Which product had the most views, cart adds and purchases?**
Most views:
```sql
SELECT PRODUCT_NAME,
	VIEWS 
FROM PRODUCT_FUNNEL
ORDER BY VIEWS DESC
LIMIT 1
```
Answer:
| product_name | views |
| ------------ | ----- |
| Oyster       | 1568  |

Most cart adds:
```sql
SELECT PRODUCT_NAME,
	CART_ADDS 
FROM PRODUCT_FUNNEL
ORDER BY CART_ADDS DESC
LIMIT 1
```
Answer:
| product_name | cart_adds |
| ------------ | --------- |
| Lobster      | 968       |

Most purchased:
```sql
SELECT PRODUCT_NAME,
	PURCHASED 
FROM PRODUCT_FUNNEL
ORDER BY PURCHASED DESC
LIMIT 1
```
Answer:
| product_name | purchased |
| ------------ | --------- |
| Lobster      | 754       |

***

**2. Which product was most likely to be abandoned?**
```sql
SELECT PRODUCT_NAME,
	ABANDONED
FROM PRODUCT_FUNNEL
ORDER BY ABANDONED DESC
LIMIT 1
```
Answer:
| product_name   | abandoned |
| -------------- | --------- |
| Russian Caviar | 249       |

***

**3. Which product had the highest view to purchase percentage?**
```sql
SELECT PRODUCT_NAME,
	ROUND(PURCHASED/VIEWS * 100,
		1) AS VIEW_TO_PURCHASE_RATIO
FROM PRODUCT_FUNNEL
ORDER BY 2 DESC
LIMIT 1 
```
Answer:
| product_name | view_to_purchase_ratio |
| ------------ | --------------------- |
| Lobster      | 48.7                  |

***

**4. What is the average conversion rate from view to cart add?**
```sql
SELECT ROUND(AVG(CART_ADDS / VIEWS) * 100, 1) AS AVG_CONVERSION_RATE_PERC
FROM PRODUCT_FUNNEL
```
Answer:
| avg_conversion_rate_perc |
| ------------------------ |
| 61.0                     |

***

**5. What is the average conversion rate from cart add to purchase?**
```sql
SELECT ROUND(AVG(PURCHASED / CART_ADDS) * 100, 1) AS AVG_CONVERSION_RATE_PERC
FROM PRODUCT_FUNNEL
```
Answer:
| avg_conversion_rate_perc |
| ------------------------ |
| 75.9                     |

***

### 3. Campaigns Analysis
Generate a table that has 1 single row for every unique visit_id record and has the following columns:

- user_id
- visit_id
- visit_start_time: the earliest event_time for each visit
- page_views: count of page views for each visit
- cart_adds: count of product cart add events for each visit
- purchase: 1/0 flag if a purchase event exists for each visit
- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
- impression: count of ad impressions for each visit
- click: count of ad clicks for each visit
- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

```sql
WITH COMBINED AS
	(SELECT *
		FROM CLIQUE_BAIT.EVENTS AS E
		INNER JOIN CLIQUE_BAIT.EVENT_IDENTIFIER USING (EVENT_TYPE)
		INNER JOIN CLIQUE_BAIT.USERS USING (COOKIE_ID)
		LEFT JOIN CLIQUE_BAIT.CAMPAIGN_IDENTIFIER AS CI ON E.EVENT_TIME BETWEEN CI.START_DATE AND CI.END_DATE
		LEFT JOIN CLIQUE_BAIT.PAGE_HIERARCHY USING (PAGE_ID))
		
SELECT USER_ID,
	VISIT_ID,
	MIN(EVENT_TIME) AS VISIT_START_TIME,
	CAST(SUM(CASE
				WHEN EVENT_NAME = 'Page View' THEN 1
				ELSE 0
				END) AS numeric) AS PAGE_VIEWS,
				
	CAST(SUM(CASE
				WHEN EVENT_NAME = 'Add to Cart' THEN 1
				ELSE 0
				END) AS numeric) AS CART_ADDS,
				
	CAST(SUM(CASE
				WHEN EVENT_NAME = 'Ad Click' THEN 1
				ELSE 0
				END) AS numeric)AS PURCHASE,
	CAMPAIGN_NAME,
	CAST(SUM(CASE
				WHEN EVENT_NAME = 'Ad Impression' THEN 1
				ELSE 0
				END) AS numeric) AS IMPRESSION,
				
	CAST(SUM(CASE
				WHEN EVENT_NAME = 'Ad Click' THEN 1
				ELSE 0
				END) AS numeric) AS CLICK,
	STRING_AGG(CASE
					WHEN PRODUCT_ID IS NOT NULL AND EVENT_NAME = 'Add to Cart' THEN PAGE_NAME
					ELSE NULL
					END, ', ' ORDER BY SEQUENCE_NUMBER) AS CART_PRODUCTS
FROM COMBINED
GROUP BY USER_ID,
	VISIT_ID,
	CAMPAIGN_NAME
```
Answer:
First 5 rows:
| user_id | visit_id | visit_start_time       | page_views | cart_adds | purchase | campaign_name                    | impression | click | cart_products                                              |
| ------- | -------- | ----------------------- | ---------- | --------- | -------- | -------------------------------- | ---------- | ----- | ----------------------------------------------------------- |
| 1       | "02a5d5" | 2020-02-26 16:57:26.260 | 4          | 0         | 0        | "Half Off - Treat Your Shellf(ish)" | 0          | 0     |                                                             |
| 1       | "0826dc" | 2020-02-26 05:58:37.918 | 1          | 0         | 0        | "Half Off - Treat Your Shellf(ish)" | 0          | 0     |                                                             |
| 1       | "0fc437" | 2020-02-04 17:49:49.602 | 10         | 6         | 1        | "Half Off - Treat Your Shellf(ish)" | 1          | 1     | "Tuna, Russian Caviar, Black Truffle, Abalone, Crab, Oyster" |
| 1       | "30b94d" | 2020-03-15 13:12:54.023 | 9          | 7         | 1        | "Half Off - Treat Your Shellf(ish)" | 1          | 1     | "Salmon, Kingfish, Tuna, Russian Caviar, Abalone, Lobster, Crab" |
| 1       | "41355d" | 2020-03-25 00:11:17.860 | 6          | 1         | 0        | "Half Off - Treat Your Shellf(ish)" | 0          | 0     | "Lobster"                                                   |


Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

Some ideas you might want to investigate further include:

- Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
- Does clicking on an impression lead to higher purchase rates?
- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
- What metrics can you use to quantify the success or failure of each campaign compared to each other?

[WORK IN PROGRESS]

