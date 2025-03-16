import pandas as pd

def normalize_to_100(series):
    # normalise to 0-100
    min_val = series.min()
    max_val = series.max()
    if max_val == min_val:
        return series.map(lambda x: 50)  # return mid value if all values are the same
    return ((series - min_val) / (max_val - min_val)) * 100

def investment_potential(data):
    """
    Calculates an investment potential score for each property and returns the top 20 suburbs with the highest potential.
    All components are normalized to 0-100 scale, with the following weights:
    - Property price growth (40%)
    - Rental yield (30%)
    - Location demand (20%)
    - Affordability (10%)
    """
    WEIGHT_PRICE_GROWTH = 0.4
    WEIGHT_RENTAL_YIELD = 0.3
    WEIGHT_LOCATION_DEMAND = 0.2
    WEIGHT_AFFORDABILITY = 0.1

    data.columns = data.columns.str.strip()

    req_columns = ['price', 'property_inflation_index', 'suburb_median_income', 'km_from_cbd', 'suburb']
    
    # missing cols (if any)
    if not all(col in data.columns for col in req_columns):
        print("Missing required columns")
        return pd.DataFrame()
    
    # calc raw values first
    price_growth = data['property_inflation_index']
    rental_yield = (data['suburb_median_income'] * 0.3 * 12) / data['price'] * 100
    location_demand = 1 / (data['km_from_cbd'] + 1) * 100
    affordability = data['suburb_median_income'] / data['price'] * 100

    # normalize each component to 0-100 
    price_growth_norm = normalize_to_100(price_growth)
    rental_yield_norm = normalize_to_100(rental_yield)
    location_demand_norm = normalize_to_100(location_demand)
    affordability_norm = normalize_to_100(affordability)

    # calculate investment score
    data["investment_score"] = (WEIGHT_PRICE_GROWTH * price_growth_norm + 
                              WEIGHT_RENTAL_YIELD * rental_yield_norm + 
                              WEIGHT_LOCATION_DEMAND * location_demand_norm + 
                              WEIGHT_AFFORDABILITY * affordability_norm)
            
    top_suburbs = data.sort_values(by="investment_score", ascending=False).head(20)[["suburb", "investment_score"]]
    top_suburbs = top_suburbs.reset_index(drop=True)

    return top_suburbs