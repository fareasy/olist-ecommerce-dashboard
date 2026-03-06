# olist-ecommerce-dashboard
<img width="1499" height="999" alt="Olist Sales Performance Dashboard" src="https://github.com/user-attachments/assets/c1f5d227-08de-417d-8b4e-71d00888d496" />

[Tableau Link](https://public.tableau.com/views/OlistDashboard_17725917027820/OlistCustomersDashboard?:language=enUS&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

This repository contains an end-to-end analytics project using the Olist Brazilian E-Commerce dataset. The project includes data cleaning, aggregation, fact table creation, and interactive dashboards, demonstrating skills in SQL and Tableau.

## Tools
- Database: PostgreSQL  
- SQL:
- Table creation with constraints and relationships  
- Aggregations, CTEs, and views  
- Delivery metrics and revenue calculations  
- Data Visualization: Tableau

## Project Overview

This project simulates a full analytics workflow:

1. Data Modeling & Cleaning
   - Created relational tables for orders, customers, sellers, products, payments, reviews, and geolocation.  
   - Enforced data integrity with primary keys, foreign keys, and check constraints.

2. Fact Table & Metrics
   - Built a view "vw_fact_order_items" aggregating:  
     - Item-level revenue (price + freight_value)  
     - Order-level payment (SUM(payment_value))  
     - Delivery performance metrics (delivery_days, is_late, delivery_delay_days)  
     - Customer and seller locations  
     - Review scores

3. Dashboard Analysis
   - Tableau dashboard visualizes:  
     - Monthly revenue trends  
     - Top product categories  
     - Customer and seller distribution by state  
     - Delivery performance insights  

4. Export for Analysis 
   - The fact table is exported as CSV since Tableau Public does not allow SQL connections.

## Key Metrics
- Total and item-level revenue  
- Average delivery time and late deliveries  
- Product category performance  
- Customer and seller geographic distribution  
- Order review ratings
