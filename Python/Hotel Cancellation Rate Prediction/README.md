# Project Title
Hotel Cancellation Rate Analysis

***

# Project Overview
The project aims to tackle the challenge of high cancellation rates in the hospitality industry, specifically targeting Hotel Group 88 (HG88). With cancellation rates peaking at **37%** across two properties, HG88 has partnered with SAGA Consulting Group (SAGA) to enhance operational efficiency and reduce cancellations.

SAGA will utilize data analytics along with Large Language Models (LLMs), to delve into cancellation complexities, segment consumers, develop prediction models, identify high-risk customers, and determine primary drivers behind cancellations. This process will culminate in actionable recommendations for HG88 to implement personalized marketing campaigns and refine business practices to mitigate high cancellation rates effectively.

***

# Installation and Setup
## Codes and Resources Used
Software Requirements and Editor used:
- **Editor Used:**  Visual Studio Code (VSCode)
- **Python Version:** 3.12.0

## Python Packages Used
- **General Packages:** `warnings`
- **Data Manipulation:** `pandas` and `numpy`
- **Data Visualization:** `matplotlib` and `seaborn`
- **Statistical Analysis:** `scipy`
- **Machine Learning:** `scikit-learn`, `tensorflow`, `keras`, `xgboost`, `kmodes`
- **Multi-Processing:** `multiprocessing`, `joblib`

***

# Data 
## Source Data
- **Kaggle:** The dataset was obtained from [Hotel Booking Demand Data](https://www.kaggle.com/datasets/jessemostipak/hotel-booking-demand)


## Description of Dataset
| Column                          | Description                                              | Data Type         |
|---------------------------------|----------------------------------------------------------|-------------------|
| hotel                           | Indicates whether the booking is for a city hotel or resort hotel | Categorical       |
| is_canceled                     | Indicates if the booking is canceled (1) or not (0)     | Binary            |
| lead_time                       | Number of days between booking date and the arrival date | Integer           |
| arrival_date_year               | Year of arrival date                                    | Integer           |
| arrival_date_month              | Month of arrival date                                   | Categorical       |
| arrival_date_week_number        | Week number of arrival date                             | Integer           |
| arrival_date_day_of_month       | Day of the month of the arrival date                    | Integer           |
| stays_in_weekend_nights         | Number of weekend nights (Saturday or Sunday) the guest stayed or booked to stay | Integer |
| stays_in_week_ends              | Number of week nights (Monday to Friday) the guest stayed or booked to stay | Integer |
| adults                          | Number of adults                                        | Integer           |
| children                        | Number of children                                      | Integer           |
| babies                          | Number of babies                                        | Integer           |
| meal                            | Type of meal booked                                     | Categorical       |
| country                         | Country of origin                                       | Categorical       |
| market_segment                  | Market segment designation                             | Categorical       |
| distribution_channel            | Booking distribution channel                            | Categorical       |
| is_repeated_guest               | Indicates if the booking customer is a repeated guest (1) or not (0) | Categorical |
| previous_cancellations          | Number of previous bookings that were canceled by the customer | Integer     |
| previous_bookings_not_canceled  | Number of previous non-canceled bookings by the customer | Integer     |
| reserved_room_type              | Code of the reserved room type                          | Categorical       |
| assigned_room_type              | Code of the assigned room type                          | Categorical       |
| booking_changes                 | Number of changes/amendments made to the booking        | Integer           |
| deposit_type                    | Indication of the type of deposit                       | Categorical       |
| days_in_waiting                 | Number of days the booking was in the waiting list      | Integer           |
| customer_type                   | Type of customer                                        | Categorical       |
| adr                             | Average Daily Rate for the booking                      | Integer           |
| required_car_parking_spaces     | Number of car parking spaces required by the customer   | Integer           |
| total_special_requests          | Number of special requests made by the customer         | Integer           |



## Data Cleaning/Preprocessing

### Agents and Company
- The dataset lacks comprehensive information regarding agents and the company, limiting its utility. Moreover, the presence of numerous missing values in these columns (16340 and 112593 nulls respectively) may compromise the accuracy of our analysis. Thus, `agents` and `companny` columns were removed

### Reservation Status Date and Reservation Status
- `reservation_status_date` was removed as its information is available in other columns
- `reservation_status` directly gives us if the booking was cancelled so it was also removed

### Dropping NULLS
- The remaining nulls came from `children` and `country` columns, amount to 492 rows (0.4% of total rows)
- Decision was made to drop the nulls as it should not affect our analysis

### Scaling and Splitting of Data
- MinMaxScaler was used instead of StandardScaler as our data contains non-negative variables (eg. lead time, daily rate)
- The main dataset was split into training and test data using an 80/20 ratio, which was subsequently employed to train and assess the models

### Customer Segmentation using Clustering
- Since our dataset contains both categorical and numerical data, we opted to use KModes clustering to better understand the hotel industry by identifying customer segments
- Our goal for clustering is to further breakdown the data and find potential insights within clusters or engineer new features which may help with model prediction

Elbow Plot:

<img src="image.png" alt="elbow" width="900" height="900" />

Centroids of Clusters and Assigned Cluster Names by Various LLMs

<img src="image-1.png" alt="clusters" width="900" height="900" />

- Final decision was to use the responses generated by Perplexity as it provided the best justifications for segmenting the customers into 4 groups which made business sense and is consistent with our interpretation of the data
- Using this information, we aim to enable HG88 to understand their client base better and adopt specialised marketing tools for each group

### Final Dataset
- After data cleaning and preprocessing, there are a total of 28 columns (17 numerical and 7 categoricals), with 118,898 rows of data.

## Data Exploration
### Correlation Matrix between Numerical Variables

<img src="image-2.png" alt="corr" width="600" height="600" />

- The correlation heatmap indicates no signficant correlation among the variables, ensuring model stability and robustness
- Highest correlation is between `stays_in_week_nights` and `stays_in_weekend_nights` with a value of 0.49
- To further explore the reasons behind these findings, we consulted both ChatGPT and Gemini where packages deals, promotions and travel patterns were cited as potential reasons. These findings align with our intuitive understanding of the underlying dynamics

### Correlation/association between categorical variables
To test for the correlation between categorical variables, we will use the [Chi-Squared Test of Independence](https://www.jmp.com/en_sg/statistics-knowledge-portal/chi-square-test/chi-square-test-of-independence.html) and the [Cramér's V](https://www.ibm.com/docs/en/cognos-analytics/11.1.0?topic=terms-cramrs-v)

**Highly Correlated Pairs**
| Variable 1             | Variable 2             | Cramer's V |
|------------------------|------------------------|------------|
| reserved_room_type     | assigned_room_type     | 0.778      |
| market_segment         | distribution_channel   | 0.614      |
| deposit_type           | is_canceled            | 0.481      |
| arrival_date_year      | arrival_date_month     | 0.428      |
| hotel                  | assigned_room_type     | 0.391      |
| market_segment         | deposit_type           | 0.374      |
| country                | is_canceled            | 0.358      |
| market_segment         | is_repeated_guest      | 0.353      |
| hotel                  | reserved_room_type     | 0.325      |
| hotel                  | meal                   | 0.318      |
| country                | deposit_type           | 0.312      |
| distribution_channel   | is_repeated_guest      | 0.302      |
| hotel                  | country                | 0.301      |


From the variables that are dependent, we can see that:
- The highest association is between `reserved_room_type` and `assigned_room_type` with a value of 0.778. This finding is intuitive since customer typically receive the rooms they reserved during booking, barring unforeseen circumstances.

### Consumer Booking Patterns Over the Years
<img src="image-3.png" alt="booking" width="700" height="700" />

- HG88 experienced increased customer engagement and a consistent growth in total bookings over the year. However, this growth also led to a rise in cancellations, as noted by Chua (2020).
- Despite the growth rate of total bookings surpassing cancellations, the issue of cancellations remains significant. It is essential to address this concern, even though cancellation rates have declined over time.

### Month-on-Month Change in Cancellation Rates
<img src="image-4.png" alt="mom" width="700" height="700" />

- There is consistent decline in Month-on-Month cancellation rates over the years
- Cancellation ratees seem to be more stable in recent months, indicating positive progress
- This reduced volatility enhances the planning and resource allocation accuracy


### Analysis of Cancellation Rates Across HG88's Hotel Types
<img src="image-5.png" alt="mom" width="900" height="900" />

- The charts showed that City Hotel contributed significantly to the cancellation rates
- Leveraging on LLMs, 
***

# Results and Evaluation
## Model Evaluation
### Multiple Linear Regression
Regression Output Results:



- We can see from the Linear Regression model that the $R^2$ is relatively low, with a value of 0.512. This could indicate that there is non-linear relationships between the variables in the model.
- Thus, non-linear regression methods will be used subsequently.


### Non-Linear Regressors

<img src="image-2.png" alt="df" width="1200" height="200" />

- Using $R^2$ as the comparison metric, we can see that among the models, Random Forest came out to the best after tuning with an $R^2$ of 0.825. This means that using Random Forest, we can use the aforementioned features to explain 82.5% of the variation in delivery duration.


## Model Interpretation (Feature Importance)
### Random Forest

<img src="image-3.png" alt="rf" width="1200" height="500" />



### Gradient Boosting

<img src="image-4.png" alt="gb" width="1200" height="500" />



### Multi-Layer Perceptron

<img src="image-5.png" alt="gb" width="1200" height="500" />


From the feature importances plot, we can see that:
- Random Forest and Gradient Boosting placed the same importance on Satisfaction Percentage, Low traffic road density and distance. All 3 are very relevant factors that can affect delivery duration.
- For the Neural Network, the most important feature was distance and it is very clear that it can and will affect delivery duration







