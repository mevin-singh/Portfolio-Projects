## 🌲 Case Study #7: Balanced Tree

<img src="https://8weeksqlchallenge.com/images/case-study-designs/7.png" alt="Image" width="500" height="520">

All the information regarding the case study has been sourced from the following link: [here](https://8weeksqlchallenge.com/case-study-7/)

## 📈 A. High Level Sales Analysis

**1. What was the total quantity sold for all products?**
```sql
SELECT SUM(QTY) AS TOTAL_QUANTITY
FROM BALANCED_TREE.SALES
```
Answer:
| total_qty_sold |
| -------------- |
| 45216          |

***

**2. What is the total generated revenue for all products before discounts?**
```sql
SELECT SUM(QTY * PRICE) AS TOTAL_REVENUE
FROM BALANCED_TREE.SALES
```
Answer:
| total_sales |
| ----------- |
| 1289453     |

***

**3. What was the total discount amount for all products?**
```sql
SELECT ROUND(SUM(QTY * PRICE * CAST(DISCOUNT AS numeric) / 100), 2) AS TOTAL_DISCOUNT
FROM BALANCED_TREE.SALES
```
Answer:
| total_discount |
| -------------- |
| 156229.14      |

***

## 🧾 B. Transaction Analysis

**1. How many unique transactions were there?**
```sql
SELECT COUNT(DISTINCT TXN_ID) AS UNIQUE_TXNS
FROM BALANCED_TREE.SALES
```
Answer:
| number_of_transactions |
| ---------------------- |
| 2500                   |

***

**2. What is the average unique products purchased in each transaction?**
```sql
WITH UNIQUE_PROD AS (
	SELECT TXN_ID,
	COUNT(DISTINCT PROD_ID) AS UNIQUE_PRODUCTS
FROM BALANCED_TREE.SALES
GROUP BY 1
)

SELECT ROUND(AVG(UNIQUE_PRODUCTS), 0) AS AVG_NUM
FROM UNIQUE_PROD
```
Answer:
| avg_num |
| ------- |
| 6       |

***

**3. What are the 25th, 50th and 75th percentile values for the revenue per transaction? (assuming after discounts)**
```sql
WITH REV_PER_TXN AS
	(SELECT TXN_ID,
			CAST(SUM((1 - DISCOUNT / 100) * PRICE * QTY) AS numeric) AS REVENUE
		FROM BALANCED_TREE.SALES
		GROUP BY 1)
		
SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY REVENUE) AS P25,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY REVENUE) AS P50,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY REVENUE) AS P75
FROM REV_PER_TXN
```
Answer:
| p25   | p50   | p75 |
| ----- | ----- | --- |
| 375.75| 509.5 | 647 |

***

**4. What is the average discount value per transaction?**
```sql
WITH DISC_VAL AS (
	SELECT TXN_ID,
	SUM(QTY * PRICE * CAST(DISCOUNT AS numeric) / 100) AS TOTAL_DISCOUNT
FROM BALANCED_TREE.SALES
GROUP BY 1
)

SELECT ROUND(AVG(TOTAL_DISCOUNT), 2) AS AVG_DISC
FROM DISC_VAL
```
Answer:
| avg_disc |
| -------- |
| 62.49    |

***

**5. What is the percentage split of all transactions for members vs non-members?**
```sql
WITH MEMBERSHIP AS
	(SELECT DISTINCT TXN_ID,
			MEMBER
		FROM BALANCED_TREE.SALES)
		
SELECT ROUND(CAST(SUM(CASE
							WHEN MEMBER = TRUE THEN 1
							ELSE 0
							END) AS numeric) / COUNT(*) * 100, 1) AS MEMBER_PERC,
	ROUND((1 - CAST(SUM(CASE
							WHEN MEMBER = TRUE THEN 1
							ELSE 0
							END) AS numeric) / COUNT(*)) * 100, 1) AS NON_MEMBER_PERC
FROM MEMBERSHIP
```
Answer:
| member_perc | guest_perc|
| ----------- | --------- |
| 60.2        | 39.8      |

***

**6. What is the average revenue for member transactions and non-member transactions? (assuming after discount)**
```sql
WITH REVENUE AS
	(SELECT TXN_ID,
			CASE
				WHEN MEMBER = TRUE THEN 'Member'
				ELSE 'Non-Member'
			END AS MEMBER,
	 
			SUM(PRICE * QTY * (1 - CAST(DISCOUNT AS numeric) / 100)) AS REVENUE
		FROM BALANCED_TREE.SALES
		GROUP BY 1, 2)
		
SELECT MEMBER,
	ROUND(AVG(REVENUE), 2) AS AVG_REVENUE
FROM REVENUE
GROUP BY 1
ORDER BY 2 DESC
```
Answer:
| member     | avg_revenue |
| ---------- | ----------- |
| Member     | 454.14      |
| Non-Member | 452.01      |

Since members and non-members are spending roughly the same amount, this could indicate the current customer loyalty/membership program offered at Balanced Tree may not be effective in influencing spending behaviours of members. It may be necessary to re-evaluate the benefits and value proposition of the existing membership program.

***

## 👚 C. Product Analysis

**1. What are the top 3 products by total revenue before discount?**
```sql
WITH COMBINED AS
	(SELECT PRODUCT_NAME,
			QTY * S.PRICE AS REVENUE
		FROM BALANCED_TREE.SALES AS S
		LEFT JOIN BALANCED_TREE.PRODUCT_DETAILS AS P ON S.PROD_ID = P.PRODUCT_ID)
		
SELECT PRODUCT_NAME,
	SUM(REVENUE) AS TOTAL_REVENUE
FROM COMBINED
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3
```
Answer:
| product_name                  | total_revenue |
| ----------------------------- | ------------- |
| Blue Polo Shirt - Mens        | 217683        |
| Grey Fashion Jacket - Womens  | 209304        |
| White Tee Shirt - Mens        | 152000        |

***

**2. What is the total quantity, revenue and discount for each segment?**
```sql
WITH COMBINED AS
	(SELECT SEGMENT_NAME,
			QTY,
			S.PRICE,
			DISCOUNT
		FROM BALANCED_TREE.SALES AS S
		LEFT JOIN BALANCED_TREE.PRODUCT_DETAILS AS P ON S.PROD_ID = P.PRODUCT_ID)
		
SELECT SEGMENT_NAME,
	SUM(QTY) AS TOTAL_QUANTITY,
	SUM(PRICE * QTY) AS TOTAL_REVENUE,
	ROUND(SUM(CAST(DISCOUNT AS numeric) / 100 * PRICE), 2) AS TOTAL_DISCOUNT
FROM COMBINED
GROUP BY 1
```
Answer:
| segment_name | total_quantity | total_revenue | total_discount  |
| ------------ | -------------- | ------------- | --------------- |
| Shirt        | 11265          | 406143        | 16560.31        |
| Jeans        | 11349          | 208350        | 8393.08         |
| Jacket       | 11385          | 366983        | 14647.64        |
| Socks        | 11217          | 307977        | 12495.31        |

***

**3. What is the top selling product for each segment? (assuming after discount)**
```sql
WITH COMBINED AS
	(SELECT SEGMENT_NAME,
			PRODUCT_NAME,
			QTY,
			S.PRICE,
			CAST(DISCOUNT AS numeric)
		FROM BALANCED_TREE.SALES AS S
		LEFT JOIN BALANCED_TREE.PRODUCT_DETAILS AS P ON S.PROD_ID = P.PRODUCT_ID),
		
	REVENUE_AFTER_DISCOUNT AS
	(SELECT SEGMENT_NAME,
			PRODUCT_NAME,
			ROUND(SUM(QTY * PRICE * (1 - DISCOUNT / 100)), 2) AS REVENUE
		FROM COMBINED
		GROUP BY 1, 2),
		
	RANKED AS
	(SELECT SEGMENT_NAME,
			PRODUCT_NAME,
			REVENUE,
			RANK() OVER(PARTITION BY SEGMENT_NAME ORDER BY REVENUE DESC) AS RNK
		FROM REVENUE_AFTER_DISCOUNT)
		
SELECT SEGMENT_NAME,
	PRODUCT_NAME,
	REVENUE
FROM RANKED
WHERE RNK = 1
```
Answer:
| segment_name | product_name                   | revenue   |
| ------------ | ------------------------------ | --------- |
| Jacket       | Grey Fashion Jacket - Womens   | 183912.12 |
| Jeans        | Black Straight Jeans - Womens  | 106407.04 |
| Shirt        | Blue Polo Shirt - Mens         | 190863.93 |
| Socks        | Navy Solid Socks - Mens        | 119861.64 |

***

**4. What is the total quantity, revenue and discount for each category?**
```sql
WITH COMBINED AS
	(SELECT CATEGORY_NAME,
			QTY,
			S.PRICE,
			CAST(DISCOUNT AS numeric)
		FROM BALANCED_TREE.SALES AS S
		LEFT JOIN BALANCED_TREE.PRODUCT_DETAILS AS P ON S.PROD_ID = P.PRODUCT_ID)
		
SELECT CATEGORY_NAME,
	SUM(QTY) AS TOTAL_QUANTITY,
	SUM(QTY * PRICE) AS TOTAL_REVENUE,
	ROUND(SUM(PRICE * DISCOUNT / 100), 2) AS TOTAL_DISCOUNT
FROM COMBINED
GROUP BY 1
```
Answer:
| category_name | total_quantity | total_revenue | total_discount |
| ------------- | -------------- | ------------- | --------------- |
| Mens          | 22482          | 714120        | 29055.62        |
| Womens        | 22734          | 575333        | 23040.72        |

***

**5. What is the top selling product for each category? (assuming after discount)**
```sql
WITH COMBINED AS
	(SELECT CATEGORY_NAME,
	 		PRODUCT_NAME, 
			QTY,
			S.PRICE,
			CAST(DISCOUNT AS numeric)
		FROM BALANCED_TREE.SALES AS S
		LEFT JOIN BALANCED_TREE.PRODUCT_DETAILS AS P ON S.PROD_ID = P.PRODUCT_ID),
		
	REVENUE_AFTER_DISCOUNT AS
	(SELECT CATEGORY_NAME,
	 		PRODUCT_NAME,
			ROUND(SUM(QTY * PRICE * (1 - DISCOUNT / 100)), 2) AS REVENUE
		FROM COMBINED
		GROUP BY 1, 2),
		
	RANKED AS
	(SELECT CATEGORY_NAME,
	 		PRODUCT_NAME,
			REVENUE,
			RANK() OVER(PARTITION BY CATEGORY_NAME ORDER BY REVENUE DESC) AS RNK
		FROM REVENUE_AFTER_DISCOUNT)
		
SELECT CATEGORY_NAME,
	PRODUCT_NAME,
	REVENUE
FROM RANKED
WHERE RNK = 1
```
Answer:
| category_name | product_name                   | revenue   |
| ------------- | ------------------------------ | --------- |
| Mens          | Blue Polo Shirt - Mens         | 190863.93 |
| Womens        | Grey Fashion Jacket - Womens   | 183912.12 |

***

**6. What is the percentage split of revenue by product for each segment? (assuming after discount)**
```sql
WITH COMBINED AS
	(SELECT SEGMENT_NAME,
			PRODUCT_NAME,
			QTY,
			S.PRICE,
			CAST(DISCOUNT AS numeric)
		FROM BALANCED_TREE.SALES AS S
		LEFT JOIN BALANCED_TREE.PRODUCT_DETAILS AS P ON S.PROD_ID = P.PRODUCT_ID),
		
	REVENUE_PER_PRODUCT AS
	(SELECT SEGMENT_NAME,
			PRODUCT_NAME,
			ROUND(SUM(QTY * PRICE * (1 - DISCOUNT / 100)), 2) AS PRODUCT_REVENUE
		FROM COMBINED
		GROUP BY 1, 2),
		
	REVENUE_PER_SEGMENT AS
	(SELECT SEGMENT_NAME,
			PRODUCT_NAME,
			PRODUCT_REVENUE,
			SUM(PRODUCT_REVENUE) OVER(PARTITION BY SEGMENT_NAME) AS SEGMENT_REVENUE
		FROM REVENUE_PER_PRODUCT)
		
SELECT SEGMENT_NAME,
	PRODUCT_NAME,
	PRODUCT_REVENUE,
	ROUND(PRODUCT_REVENUE / SEGMENT_REVENUE * 100, 1) AS REVENUE_SPLIT_PERC
FROM REVENUE_PER_SEGMENT
ORDER BY 1, 3 DESC
```
Answer:
| segment_name | product_name                   | product_revenue | revenue_split_perc |
| ------------ | ------------------------------ | ---------------- | ------------------ |
| Jacket       | Grey Fashion Jacket - Womens  | 183912.12        | 57.0               |
| Jacket       | Khaki Suit Jacket - Womens    | 76052.95         | 23.6               |
| Jacket       | Indigo Rain Jacket - Womens   | 62740.47         | 19.4               |
| Jeans        | Black Straight Jeans - Womens | 106407.04        | 58.1               |
| Jeans        | Navy Oversized Jeans - Womens  | 43992.39         | 24.0               |
| Jeans        | Cream Relaxed Jeans - Womens   | 32606.60         | 17.8               |
| Shirt        | Blue Polo Shirt - Mens        | 190863.93        | 53.5               |
| Shirt        | White Tee Shirt - Mens        | 133622.40        | 37.5               |
| Shirt        | Teal Button Up Shirt - Mens   | 32062.40         | 9.0                |
| Socks        | Navy Solid Socks - Mens       | 119861.64        | 44.2               |
| Socks        | Pink Fluro Polkadot Socks - Mens | 96377.73       | 35.6               |
| Socks        | White Striped Socks - Mens    | 54724.19         | 20.2               |

***

**7. What is the percentage split of revenue by segment for each category? (assuming after discount)**
```sql
WITH COMBINED AS
	(SELECT CATEGORY_NAME,
			SEGMENT_NAME,
			QTY,
			S.PRICE,
			CAST(DISCOUNT AS numeric)
		FROM BALANCED_TREE.SALES AS S
		LEFT JOIN BALANCED_TREE.PRODUCT_DETAILS AS P ON S.PROD_ID = P.PRODUCT_ID),
		
	REVENUE_PER_SEGMENT AS
	(SELECT CATEGORY_NAME,
			SEGMENT_NAME,
			ROUND(SUM(QTY * PRICE * (1 - DISCOUNT / 100)), 2) AS SEGMENT_REVENUE
		FROM COMBINED
		GROUP BY 1, 2),
		
	REVENUE_PER_CATEGORY AS
	(SELECT CATEGORY_NAME,
			SEGMENT_NAME,
			SEGMENT_REVENUE,
			SUM(SEGMENT_REVENUE) OVER(PARTITION BY CATEGORY_NAME) AS CATEGORY_REVENUE
		FROM REVENUE_PER_SEGMENT)
		
SELECT CATEGORY_NAME,
	SEGMENT_NAME,
	SEGMENT_REVENUE,
	ROUND(SEGMENT_REVENUE / CATEGORY_REVENUE * 100, 1) AS REVENUE_SPLIT_PERC
FROM REVENUE_PER_CATEGORY
ORDER BY 1, 3 DESC
```
Answer:
| category_name | segment_name | segment_revenue | revenue_split_perc |
| ------------- | ------------ | ---------------- | ------------------ |
| Mens          | Shirt        | 356548.73        | 56.8               |
| Mens          | Socks        | 270963.56        | 43.2               |
| Womens        | Jacket       | 322705.54        | 63.8               |
| Womens        | Jeans        | 183006.03        | 36.2               |

***

**8. What is the percentage split of total revenue by category?**
```sql
WITH COMBINED AS
	(SELECT CATEGORY_NAME,
			QTY,
			S.PRICE,
			CAST(DISCOUNT AS numeric)
		FROM BALANCED_TREE.SALES AS S
		LEFT JOIN BALANCED_TREE.PRODUCT_DETAILS AS P ON S.PROD_ID = P.PRODUCT_ID),
		
	REVENUE_PER_CATEGORY AS
	(SELECT CATEGORY_NAME,
			ROUND(SUM(QTY * PRICE * (1 - DISCOUNT / 100)), 2) AS CATEGORY_REVENUE
		FROM COMBINED
		GROUP BY 1),
		
	TOTAL_REVENUE_CATEGORY AS
	(SELECT CATEGORY_NAME,
	 		CATEGORY_REVENUE,
			SUM(CATEGORY_REVENUE) OVER() AS TOTAL_CATEGORY_REVENUE
		FROM REVENUE_PER_CATEGORY)
		
SELECT CATEGORY_NAME,
	ROUND(CATEGORY_REVENUE / TOTAL_CATEGORY_REVENUE * 100, 1) AS REVENUE_SPLIT_PERC
FROM TOTAL_REVENUE_CATEGORY
ORDER BY 2 DESC
```
Answer:
| category_name | revenue_split_perc |
| ------------- | ------------------ |
| Mens          | 55.4               |
| Womens        | 44.6               |

***

**9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)**
```sql
WITH COMBINED AS
	(SELECT PRODUCT_NAME,
			TXN_ID
		FROM BALANCED_TREE.SALES AS S
		LEFT JOIN BALANCED_TREE.PRODUCT_DETAILS AS P ON S.PROD_ID = P.PRODUCT_ID),

    -- getting the number of each product in each transaction	
	N_SOLD AS
	(SELECT PRODUCT_NAME,
			CAST(COUNT(DISTINCT TXN_ID) AS numeric) AS COUNTS
		FROM COMBINED
		GROUP BY 1
		ORDER BY 2 DESC),

    -- finding the total number of txns	
	TOTAL_TRANSACTIONS AS
	(SELECT CAST(COUNT(DISTINCT TXN_ID) AS numeric) AS TOTAL_TXNS
		FROM COMBINED),

    -- concat the n_sold and total_transactions table to get all columns	
	JOINED AS
	(SELECT PRODUCT_NAME,
			COUNTS,
			TOTAL_TXNS
		FROM N_SOLD
		JOIN TOTAL_TRANSACTIONS ON 1 = 1)
		
SELECT PRODUCT_NAME,
	ROUND(COUNTS / TOTAL_TXNS * 100, 1) AS PENETRATION
FROM JOINED
ORDER BY 2 DESC
```
Answer:
| product_name                   | penetration |
| ------------------------------ | ----------- |
| Navy Solid Socks - Mens        | 51.2        |
| Grey Fashion Jacket - Womens   | 51.0        |
| Navy Oversized Jeans - Womens  | 51.0        |
| White Tee Shirt - Mens         | 50.7        |
| Blue Polo Shirt - Mens         | 50.7        |
| Pink Fluro Polkadot Socks - Mens| 50.3        |
| Indigo Rain Jacket - Womens    | 50.0        |
| Khaki Suit Jacket - Womens     | 49.9        |
| Black Straight Jeans - Womens  | 49.8        |
| Cream Relaxed Jeans - Womens   | 49.7        |
| White Striped Socks - Mens      | 49.7        |
| Teal Button Up Shirt - Mens     | 49.7        |

***

**10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction? i.e select the 3 item combination and the count of the amount of times items where bought together**
```sql
WITH PRODUCTS AS
	(SELECT TXN_ID,
			PRODUCT_NAME
		FROM BALANCED_TREE.SALES AS T1
		JOIN BALANCED_TREE.PRODUCT_DETAILS AS T2 ON T1.PROD_ID = T2.PRODUCT_ID)
		
SELECT T1.PRODUCT_NAME AS PRODUCT_1,
	T2.PRODUCT_NAME AS PRODUCT_2,
	T3.PRODUCT_NAME AS PRODUCT_3,
	COUNT(*) AS TIMES_BOUGHT_TOGETHER
FROM PRODUCTS AS T1
JOIN PRODUCTS AS T2 ON T1.TXN_ID = T2.TXN_ID
AND T1.PRODUCT_NAME < T2.PRODUCT_NAME -- ensure no duplicates
JOIN PRODUCTS AS T3 ON T1.TXN_ID = T3.TXN_ID
AND T2.TXN_ID = T3.TXN_ID
WHERE T1.PRODUCT_NAME < T3.PRODUCT_NAME AND T2.PRODUCT_NAME < T3.PRODUCT_NAME -- ensure no duplicates
GROUP BY T1.PRODUCT_NAME, T2.PRODUCT_NAME, T3.PRODUCT_NAME
ORDER BY 4 DESC
LIMIT 1
```
Answer:
| product_1                      | product_2               | product_3         | times_bought_together |
| ------------------------------ | ----------------------- | ------------------ | --------------------- |
| Grey Fashion Jacket - Womens  | Teal Button Up Shirt - Mens | White Tee Shirt - Mens | 352                   |






