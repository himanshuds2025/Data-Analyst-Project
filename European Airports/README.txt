Dataset : https://www.kaggle.com/datasets/lunthu/european-airlines-routes/data

Structural Criticality of European Airports
Project Overview

This project analyzes how structurally important European airports are within the air transport network, not just how busy they are.

Instead of passenger counts or traffic volume, the focus is on network impact:

Which airports matter the most for connectivity

Which ones would cause disproportionate damage if removed

Which airports quietly control routes even if they’re not the busiest

The goal is to separate “busy airports” from “critical airports.”

Data & Approach

Raw airport and route data was cleaned and processed in Python (Jupyter Notebook)

A network graph was built where:

Airports = nodes

Routes = edges

Network metrics were calculated and normalized

Final, cleaned output was exported as CSV and used in Power BI for visualization

Metrics (Plain English)

The original network terms were renamed to be understandable to non-technical users:

Original Term	Used Name	Meaning
final_score	Importance	Overall structural importance of the airport
impact_norm	Damage if Closed	How much the network breaks if this airport is removed
betweenness	Route Control	How often this airport sits on key paths between others
degree_norm	Direct Links	How many direct connections the airport has

All metrics are normalized (0–1) for fair comparison.

Visualizations (Power BI)
1. Map : Where Structural Risk Is Concentrated

Shows European airports geographically

Bubble size reflects Damage if Closed

Purpose: identify regions where network failure risk is concentrated

2. Ranked Table : Airports by Structural Impact

Airports ranked by Importance

Includes all key metrics side by side

This is the main “decision-making” visual

3. Scatter Plot : Busy vs Critical Airports

X-axis: Direct Links

Y-axis: Damage if Closed

Highlights airports that:

Aren’t very busy

But are structurally dangerous to lose