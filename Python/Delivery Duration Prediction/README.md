# Project Title
Delivery Duration Prediction

***

# Project Overview
This project aims to find out and investigate the relevant factors that can affect food delivery duration. Since this is a regression tasks, regression models such as **Multiple Linear Regression**, **Random Forest Regression**, **Gradient Boosting Regression** and **Neural Network Regression** will be used.

By first carrying out some data cleaning and preprocessing before building the models, we will see which of the aforementioned models are the best to describe this dataset. We would also see which are the features that are the most important/relevant in explaining the delivery duration.

***

# Installation and Setup
## Codes and Resources Used
Software Requirements and Editor used:
- **Editor Used:**  Visual Studio Code (VSCode)
- **Python Version:** 3.12.0

## Python Packages Used
- **General Packages:** `itertools`, `re`, `math`
- **Data Manipulation:** `pandas` and `numpy`
- **Data Visualization:** `matplotlib` and `seaborn`
- **Statistical Analysis:** `scipy` and `statsmodels`
- **Machine Learning:** `scikit-learn`

***

# Data 
## Source Data
- **Kaggle:** The dataset was obtained from [Food Delivery Data](https://www.kaggle.com/datasets/gauravmalik26/food-delivery-dataset)


## Description of Dataset
| Column Name               | Column Type  |
|---------------------------|--------------|
| Delivery_person_ID        | String       |
| Delivery_person_Age       | Float        |
| Delivery_person_Ratings   | Float        |
| Restaurant_latitude       | Float        |
| Restaurant_longitude      | Float        |
| Delivery_location_latitude| Float        |
| Delivery_location_longitude| Float       |
| Order_Date                | Datetime     |
| Time_Ordered              | String       |
| Time_Order_picked         | String       |
| Weather_conditions        | String       |
| Road_traffic_density      | String       |
| Vehicle_condition         | String       |
| Type_of_order             | String       |
| Type_of_vehicle           | String       |
| Multiple_deliveries       | String       |
| Festival                  | String       |
| City                      | String       |
| Time_taken(min)           | Float        |


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
- Instead of leaving the ratings from limited from 0-5, I decided to change the ratings into a satisfaction percentage using the following transformation: `ratings/5 * 100`

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



***

# Results and Evaluation
## Model Evaluation
