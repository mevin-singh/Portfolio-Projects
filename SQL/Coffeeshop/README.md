# Project Title
Coffeshop Database Exploration

***

# Project Overview
This project was an assignment of a module where I explored a coffeeshop database using PostgreSQL.

***

# Installation and Setup
## Codes and Resources Used
Software Requirements and Editor used:
- **Software Used:** PostgreSQL
- **Editor Used:**  PgAdmin
- **PgAdmin Version:** 7.8

***

# Data 
## Source Data
The coffeeshop database contains operational / transactional data from a coffee chain in NYC. The chain has several stores and a warehouse, but only 3 stores’ transactions are available in the database (stores #3, #5 and #8). The data spans a single month - April 2019. The owners of the store are keen to identify factors contributing to their chains success, and to figure out how they can improve their operations, marketing / promotions, and HR using data driven decisions.

## Description of database
The database comprises a single schema (operations) and the following tables:
| Table               | # of rows | Description                                                                                                      |
|---------------------|-----------|------------------------------------------------------------------------------------------------------------------|
| loyalty_customers   | 2,246     | Each row represents a customer on the chain’s loyalty programme.                                                  |
| products            | 88        | Each row represents a product sold by the coffee chain.                                                            |
| sales_outlets       | 11        | Each row represents an outlet in the chain, including its warehouse facility and HQ.                             |
| staff               | 55        | Each row represents a staff - managers, baristas, etc - who works in the chain.                                    |
| daily_inventory_pastry | 307    | Each row captures a quantity of pastry (product IDs #69, 70, 71, 72, 73) that is delivered to a store each morning, and the quantity sold by the end of that day. |
| transactions        | 49,894    | Each row represents an item being purchased within a retail purchase transaction.                                 |
| imported_dates      | 30        | Each row represents a day in April 2019, and contains information about that day, including what week it belongs to. |
| imported_generations| 70        | Each row represents a year of birth (from 1946 to 2015) and contains the generational category for that birth year. |