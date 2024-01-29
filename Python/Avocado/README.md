# Project Title
Avocado Industry Analysis

***

# Project Overview
In this project, I seek to advise a mock client, GreenGrocer in deciding if it is worthy to penetrate the Avocado industry. Thereafter, assist them in deciding which type of Avocado as well as which regions to set up shop in order to gain the maximum revenue.

***

# Installation and Setup
## Codes and Resources Used
Software Requirements and Editor used:
- **Editor Used:**  Visual Studio Code (VSCode)
- **Python Version:** 3.12.0

***

## Python Packages Used
- **Data Manipulation:** `pandas` and `numpy`
- **Data Visualization:** `matplotlib` and `seaborn`
- **Statistical Analysis:** `scipy` and `statsmodel`

***

# Data 
## Source Data
- **Kaggle:** The dataset used, 'avocado-updated-2020.csv' was acquired from Kaggle which consists of historical data from 4 January 2015 up to 17 May 2020, featuring avocado prices, sales volume, type of avocado in multiple cities, states and regions of US.
- **Statista:** The dataset of revenue from the fresh fruit industry between 2013 to 2026 (projected) was obtained from Statista, which contains the projected reveue of the fresh fruit industry for 150 countries

## Terminologies
| Category        | Description                                                                                                      |
|-----------------|------------------------------------------------------------------------------------------------------------------|
| Avocado Grades  | #4046, #4225, #4770                                                                                               |
| Avocado Type    | Conventional, Organic                                                                                            |
| Regions         | Plains, Southeast (SE), Southcentral (SC), Northeast (NE), West, Midsouth (MS), California (Cali), Great Lakes (GL) |
| Season          | Winter, Spring, Summer, Autumn                                                                                    |
| Average Price   | Average price of a single avocado in that week according to the respective locations                            |
| Total Volume    | Total number of avocados sold                                                                                     |

## Data Cleaning/Preprocessing
The data set originally contained 33,045 data listings. I first began checking for empty values, to minimize any subsequent issues due to possible errors in the data entry process. Thereafter, we removed any duplicate data present which will cause the analysis to be skewed. After cleaning the data to increase accuracy, a total of 11,273 listings was used for further analysis.

***

# Results and Evaluation
## Scoring system
To assist GreenGrocer in finding out the best region to enter, I dervied a scoring system to evaluate each of the regions in the US based on 3 variables: seasons, type and grade.


![Alt text](image-1.png)
