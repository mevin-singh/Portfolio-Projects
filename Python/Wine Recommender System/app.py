import streamlit as st
import pandas as pd
import numpy as np
import re

from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

# Define functions
def getCategorical(X_train, data):
    categorical_variables = []
    
    for column in X_train.columns:
        if data[column].dtype == "object":
            categorical_variables.append(column)

    return categorical_variables

def transformer(categorical_variables):
    # One-hot encoding
    enc_rf = OneHotEncoder(sparse_output=False, handle_unknown="ignore")

    transformer_rf = ColumnTransformer([
        ("categorical", enc_rf, categorical_variables)
    ], remainder="passthrough")

    return transformer_rf

def transformData(data, transformer_rf):
    data_encoded_rf = pd.DataFrame(transformer_rf.fit_transform(data), columns=transformer_rf.get_feature_names_out())
    return data_encoded_rf

def renameCol(data_encoded_rf):
    data_encoded_rf.columns = data_encoded_rf.columns.str.replace(re.compile(r'categorical__|remainder__'), '', regex=True)
    return data_encoded_rf

def preprocess(X_train, X_test, data):
    categorical_variables = getCategorical(X_train, data)
    transformer_rf = transformer(categorical_variables)
    X_train_encoded_rf = transformData(X_train, transformer_rf)
    X_test_encoded_rf = transformData(X_test, transformer_rf)
    X_train_encoded_rf = renameCol(X_train_encoded_rf)
    X_test_encoded_rf = renameCol(X_test_encoded_rf)
    return X_train_encoded_rf, X_test_encoded_rf, transformer_rf

def get_inputs():
    body_options = ['Full', 'Light', 'Medium', 'Very full', 'Very light']
    acidity_options = ['High', 'Low', 'Medium']
    country_options = ['Argentina', 'Australia', 'Austria', 'Brazil', 'Bulgaria', 'Canada', 'Chile', 'Croatia', 'Czech Republic', 'France', 'Georgia', 'Germany', 'Greece', 'Hungary', 'Israel', 'Italy', 'Mexico', 'Moldova', 'New Zealand', 'Portugal', 'Romania', 'Russia', 'South Africa', 'Spain', 'Switzerland', 'United States', 'Uruguay']
    harmonize_options = ['White Meat', 'Red Meat', 'Game Meat', 'Vegetarian', 'Spicy Food', 'Seafood', 'Dessert', 'Cheese', 'Cured Meat', 'Snacks', 'Appetizer', 'Italian', 'Others']

    body = st.selectbox('Select the body of the wine you want', options=body_options)
    acidity = st.selectbox('Select the acidity level of the wine you want', options=acidity_options)
    country = st.selectbox('Select the country you want your wine from', options=country_options)
    grapes = st.number_input('Enter the number of grapes you want in your wine', value=1)
    abv = st.number_input('Enter the desired alcohol percentage of your wine', value=10.0)
    harmonize = st.multiselect('Select the type(s) of food you want your wine to pair with', options=harmonize_options)

    body = 'Body_' + body.capitalize()
    acidity = 'Acidity_' + acidity.title()
    country = 'Country_' + country.title()
    harmonize = ['Harmonize_' + word.title() for word in harmonize]

    return body, acidity, country, grapes, abv, harmonize

def get_avg_ratings():
    
    # importing ratings dataset
    ratings = pd.read_csv('XWines_Full_21M_ratings.csv')
    
    # calculating average ratings
    avg_ratings = ratings.groupby('WineID')['Rating'].mean().to_frame('Avg_Ratings').reset_index()
    avg_ratings['Avg_Ratings'] = avg_ratings['Avg_Ratings'].round(2)

    return avg_ratings

def get_recommendations(clf, catalogue, body, acidity, country, grapes, abv, harmonize):
    dict_1 = {
        body: 1,
        acidity: 1,
        country: 1,
        'ABV': abv,
        'Grapes': grapes
    }

    dict_2 = {key: 1 for key in harmonize}

    input_dict = {**dict_1, **dict_2}

    input_data = pd.DataFrame.from_dict(input_dict, orient='index').T
    columns = X_train_encoded_rf.columns
    input_data = input_data.reindex(columns, axis=1)
    input_data = input_data.fillna(0)

    predict = clf.predict(input_data)[0]

    avg_ratings = get_avg_ratings()
    combined = pd.merge(catalogue, avg_ratings, how='inner', on='WineID')
    harmonize_list = [string.replace('Harmonize_', '') for string in harmonize]

    recommendations = combined[(combined['Type'] == predict)]
    sd = recommendations['ABV'].std()
    upper_bound = abv + sd
    lower_bound = abv - sd

    country = country.replace('Country_', '')

    recommendations = recommendations[recommendations['ABV'].between(lower_bound, upper_bound, inclusive='both')]
    recommendations = recommendations[recommendations['Harmonize'].str.contains('|'.join(harmonize_list))].sort_values(by='Avg_Ratings', ascending=False).reset_index(drop=True)
    recommendations1 = recommendations.copy()
    recommendations1 = recommendations1[recommendations1['Country'] == country].head(3)

    columns_to_display = ['WineName', 'Type', 'Grapes', 'Harmonize', 'ABV', 'Body', 'Acidity', 'Country', 'Vintages', 'Avg_Ratings']


    st.write(f'Based on your preferences, the recommended type of wine is {predict} wine.')
    
    if recommendations1.empty:
        st.write(f'There are unfortunately no {predict} wines from {country} in our catalogue. Here are the top 3 {predict} wines with the highest ratings that you can try instead!')
        st.table(recommendations.head(3)[columns_to_display])

    elif len(recommendations1) == 1:
        additional_rows = recommendations[~recommendations['WineID'].isin(recommendations1['WineID'])].head(2)
        recommendations1 = pd.concat([recommendations1, additional_rows], axis=0)
        recommendations1 = recommendations1.sort_values(by='Avg_Ratings', ascending=False).reset_index(drop=True)
        st.write(f'There is only 1 {predict} wine from {country}. Here are 2 other {predict} wines that you can try!')
        st.table(recommendations1[columns_to_display])

    elif len(recommendations1) == 2:
        additional_rows = recommendations[~recommendations['WineID'].isin(recommendations1['WineID'])].head(1)
        recommendations1 = pd.concat([recommendations1, additional_rows], axis=0)
        recommendations1 = recommendations1.sort_values(by='Avg_Ratings', ascending=False).reset_index(drop=True)
        st.write(f'There are only 2 {predict} wines from {country}. Here is 1 other {predict} wine that you can try!')
        st.table(recommendations1[columns_to_display])

    else:
        st.write(f'Here are the top 3 highly rated {predict} wines from {country} that you can try!')
        st.table(recommendations1[columns_to_display])


# Load data
df = pd.read_csv('data_cleaned.csv')
catalogue = pd.read_csv('wine_catalogue.csv')

# Preprocess data
X = df.drop(columns=['Type'])
y = df['Type']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=100)
X_train_encoded_rf, X_test_encoded_rf, transformer_rf = preprocess(X_train, X_test, df)

# Train model
clf = RandomForestClassifier(criterion='entropy', 
                            max_depth=15, 
                            min_samples_leaf=2, 
                            min_samples_split=5, 
                            n_estimators=700,
                            class_weight='balanced', 
                            random_state=100)
clf.fit(X_train_encoded_rf, y_train)

# Define Streamlit app
st.set_page_config(page_title="Wine Recommender", page_icon="🍷", layout="wide")

# Custom colors
background_color = "#FAF3E0"  # Light yellow background
text_color = "#FFFFFF"  # White text
accent_color = "#993300"  # Wine-red accent

# Set background color and text color
st.markdown(
    f"""
    <style>
        .reportview-container {{
            background-color: {background_color};
            color: {text_color};
        }}
        .sidebar .sidebar-content {{
            background-color: {accent_color};
            color: {text_color};
        }}
        .sidebar .sidebar-content .stMultiSelect .stMultiSelectClear {{
            color: {accent_color};
        }}
        .block-container {{
            color: {text_color};
        }}
    </style>
    """,
    unsafe_allow_html=True,
)

# Define Streamlit app
st.title('Wine Recommender')

# Sidebar
st.sidebar.title('Navigation')
options = ['Get Recommendations', 'About']
option = st.sidebar.selectbox(label='Menu', options=options, format_func=str)

if option == 'Get Recommendations':
    st.subheader('Get Wine Recommendations')
    body, acidity, country, grapes, abv, harmonize = get_inputs()
    
    # Check if all options are selected
    all_options_selected = body is not None and acidity is not None and country is not None and grapes is not None and abv is not None and harmonize is not None
    
    if all_options_selected:
        if st.button('Run Recommender'):
            get_recommendations(clf, catalogue, body, acidity, country, grapes, abv, harmonize)
    else:
        st.write("Please select all options to run the recommender.")

elif option == 'About':
    st.subheader('About')
    st.write('Welcome to the Wine Recommender app!')
    st.write('This app helps you find the perfect wine based on your preferences.')
    st.write('Simply select your desired characteristics, and we will recommend wines for you.')
    st.write('Enjoy exploring!')
