# Project Title
Hotel Cancellation Rate Analysis

***

# Project Overview
The project aims to tackle the challenge of high cancellation rates in the hospitality industry, specifically targeting Hotel Group 88 (HG88). With cancellation rates peaking at **37%** across two properties, HG88 has partnered with SAGA Consulting Group (SAGA) to enhance operational efficiency and reduce cancellations.

SAGA will utilize data analytics to delve into cancellation complexities, segment consumers, develop prediction models, identify high-risk customers, and determine primary drivers behind cancellations. This process will culminate in actionable recommendations for HG88 to implement personalized marketing campaigns and refine business practices to mitigate high cancellation rates effectively.

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
- **Kaggle:** The dataset was obtained from [Food Delivery Data](https://www.kaggle.com/datasets/gauravmalik26/food-delivery-dataset)


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
- The dataset contained 45593 records with a total of 8515 null records. After dropping the nulls, there are 37078 remaining records.

### Delivery Person Age
- `Delivery_person_Age` was converted from a `object` to `float` type

### Delivery Person Ratings
- `Delivery_person_Ratings` was also converted from a `object` to `float` type

### Order Date and Time_Order_picked
- `Order_Date` and `Time_Orderd` was converted to `datetime` object 
- The hour from `Order_Date` and `Time_Orderd` columns were extracted so that they could be classified into `Morning`, `Afternoon`, `Evening`

### Getting distance between Restaurant and Delivery location using Latitude and Longitude Data
- Using the haversine formula, we can find the distance between 2 locations using their Latitude and Longitude data
- By using the formula, the distance between the restaurant and delivery location was obtained

### Getting the region where the Restaurant and Delivery location are in
Since this was not given explicitly in the dataset, I opted to use KMeans Clustering to determine the region

The logic for obtaining the region is as follows:
- Since this data is obtained from India, I have approximated the coordinates for the center of the North, South, East and West regions based on Google Maps
- Setting the number of clusters as 4, we are able to obtain the clusters using the KMeans clustering algorithm

### Weather Conditions
- In the original data, the `Weatherconditions` columns was written with weather infront of the weather condition
- Only the weather condition was extracted for use

### Time Taken
- In the original data, the string `mins` was included alongside the numerical time taken
- Only the numerical time taken was extracted for use

### Vehicle Condition
- In the original data, the columns contained values 0 - 2 and there was not explaination of column
- As such, I created my own condition with 0 being `Below Average`, 1 being `Average` and 2 being `Good`

### Deliver person rating
- Instead of leaving the ratings limited from 0-5, I decided to change the ratings into a satisfaction percentage using the following transformation: `ratings/5 * 100`

### Final Dataset
- At the end of all the data cleaning and preprocessing, there were 40197 rows with following 11 columns:

| Column Name           | Column Type  |
|-----------------------|--------------|
| Delivery_person_Age   | Feature      |
| Satisfaction_Perc     | Feature      |
| Weatherconditions     | Feature      |
| Road_traffic_density  | Feature      |
| Vehicle_condition     | Feature      |
| Type_of_order         | Feature      |
| Type_of_vehicle       | Feature      |
| Time_of_Day_Ordered   | Feature      |
| Distance              | Feature      |
| Region                | Feature      |
| Time_taken_mins       | Target       |

## Data Exploration
### Correlation Matrix between Numerical Variables
- All numerical data was scaled using StandardScaler for easier comparison

<img src="image.png" alt="corr" width="600" height="600" />


From the correlation matrix, we can see that there is almost no correlation between the numerical variables which is a good sign since having high correlation may lead to multicollinearity issues.

### Correlation/association between categorical variables
To test for the correlation between categorical variables, we will use the [Chi-Squared Test of Independence](https://www.jmp.com/en_sg/statistics-knowledge-portal/chi-square-test/chi-square-test-of-independence.html) and the [Cramér's V](https://www.ibm.com/docs/en/cognos-analytics/11.1.0?topic=terms-cramrs-v)

**Chi-Squared Test of Independence**
With a p-value of 0.05, the pairs that are dependent are: `Road_traffic_density` and `Time_of_Day_Orderd`, `Vehicle_condition` and `Type_of_vehicle`, `Type_of_vehicle` and `Region`

**Cramér's V**
| Variable 1           | Variable 2         | Cramér's V     |
| -------------------- | ------------------ | -------------- |
| Road_traffic_density | Time_of_Day_Orderd | 0.774          |
| Vehicle_condition    | Type_of_Vehicle    | 0.480          |
| Type_of_vehicle      | Region             | 0.0105         |

From the variables that are dependent, we can see that:
- There is very strong correlation between Road Traffic Density and Time of Day Ordered which is understandable since ordering at peak hour timings would mean high road traffic density
- There is moderate correlation between vehicle condition and type of vehicle 
- There is weak correlation between type of vehicle and region

***

# Results and Evaluation
## Model Evaluation
### Multiple Linear Regression
Regression Output Results:

<img src="image-1.png" alt="reg" width="900" height="900" />

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







