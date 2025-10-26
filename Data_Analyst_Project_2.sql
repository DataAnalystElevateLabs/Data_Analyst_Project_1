
drop table if exists superstore
create table superstore
(Row_ID int,
Order_ID varchar(100),
Order_Date date,
Ship_Date date,
Ship_Mode varchar(50),
Customer_ID varchar(50),
Customer_Name varchar(50),
Segment varchar(50),
Country varchar(50),
City varchar(100),
State varchar(100),
Postal_Code numeric,
Region varchar(100),
Product_ID varchar(50),
Category varchar(50),
Sub_Category varchar(50),
Product_Name varchar(150),
Sales float,
Quantity int,
Discount float,
Profit float
);

select*from superstore

--EDA--
select
*
from superstore
where row_id is null
or order_id is null
or order_date is null
or ship_date is null
or ship_mode is null
or customer_id is null
or customer_name is null
or segment is null
or country is null
or city is null
or state is null
or postal_code is null
or region is null
or product_id is null
or category is null
or sub_category is null
or product_name is null
or sales is null
or quantity is null
or discount is null
or profit is null
-- no null values--
select * from superstore

select
count(distinct row_id) from superstore

alter table superstore
add column total_sales float

update superstore
set total_sales=sales*quantity

--Profitability Analysis
--Calculate total sales, profit, and profit margin per category
select*from superstore
select
category,
round(sum(total_sales)::numeric,2) as total_revenue,
round(sum(profit*quantity)::numeric,2) as total_profit,
round(sum(profit*quantity)::numeric/sum(total_sales)::numeric*100,2) as profit_margin
from superstore
group by category

--Identify sub-categories with negative or low profit margins (<5%)
with negative_low_profit_margin
as
(select
sub_category,
round(sum(profit*quantity)::numeric/sum(total_sales)::numeric*100,2) as profit_margin
from superstore
group by sub_category
)
select
sub_category,
profit_margin
from negative_low_profit_margin
where profit_margin<=5

--Rank top 10 most profitable products overall
select*from superstore

select
product_name,
round(sum(profit*quantity)::numeric,2) as total_profits
from superstore
group by product_name
order by total_profits desc
limit 10

--Find products with high sales but low profit margins (revenue ≠ profit)
select
product_name,
round(sum(total_sales)::numeric,2) as total_revenue,
dense_rank() over(order by sum(total_sales)desc) as sales_wise_ranking,
round(sum(profit*quantity)::numeric,2) as total_profits,
round(sum(profit*quantity)::numeric/sum(total_sales)::numeric*100,2) as profit_margin,
dense_rank() over(order by (sum(profit*quantity)::numeric/sum(total_sales)::numeric*100)asc) as profit_margin_wise_ranking
from superstore
group by product_name

--C. Regional & Customer Insights
--Calculate region-wise and city-wise profit contribution
--→ Detect underperforming regions.
select*from superstore

select
region,
city,
round(sum(profit*quantity)::numeric,2) as total_profits,
concat(round(sum(profit*quantity)::numeric/(select sum(profit*quantity) from superstore)::numeric*100,4),'%') as profit_contr
from superstore
group by region,city
order by region asc,total_profits desc
--Identify top customer segments by profit contribution
select*from superstore

select
segment,
round(sum(profit*quantity)::numeric,2) as total_profit,
round(sum(profit*quantity)::numeric/(select sum(profit*quantity)from superstore)::numeric*100,2) as profit_contr
from superstore
group by segment
order by total_profit desc
--Find customers with high sales but low profit
--→ Useful for targeted pricing or loyalty programs.
select*from superstore

select
customer_id,
customer_name,
round(sum(total_sales)::numeric,2) as total_revenue,
dense_rank() over(order by sum(total_sales)desc) as sales_wise_rank,
round(sum(profit*quantity)::numeric) as total_profit,
round(sum(profit*quantity)::numeric/sum(total_sales)::numeric*100,2) as profit_margin,
dense_rank() over(order by sum(profit*quantity)asc) as profit_wise_rank
from superstore
group by customer_id,customer_name
having round(sum(profit*quantity)::numeric/sum(total_sales)::numeric*100,2)<5

--D. Discount & Pricing Impact
--Analyze how discount levels affect profit margin
select*from superstore

select
case when discount <0.1 then 'Low (0%-10%)'
when discount between 0.1 and 0.3 then 'Medium (10%-30%)'
else 'High +30%'
end as Discount_band,
round(sum(profit*quantity)::numeric/sum(total_sales)::numeric*100,2) as profit_margin
from superstore
group by Discount_band

--Find correlation between average discount and total profit per category
select
category,
round(avg(discount)::numeric*100,2) as average_discount,
round(sum(profit*quantity)::numeric,2) as total_profit
from superstore
group by 1
order by total_profit desc
--Rank categories by average discount and their impact on profit margin
select
category,
round(avg(discount)::numeric*100,2) as average_discount,
dense_rank() over(order by avg(discount)asc) as rnk,
round(sum(profit*quantity)::numeric,2) as total_profit
from superstore
group by 1
order by total_profit desc

--E. Time & Seasonality
--Compute monthly sales and profit trends
select
extract(year from order_date) as year,
extract(month from order_date) as month,
round(sum(total_sales)::numeric,2) as total_revenue,
round(sum(profit*quantity)::numeric) as total_profit
from superstore
group by 1,2
order by 1,2 asc
--Identify peak sales months and off-seasons
select
extract(year from order_date) as year,
extract(month from order_date) as month,
count(*) as total_items_sold
from superstore
group by 1,2
order by 1 asc,3 desc
--Calculate year-over-year and month over month (YoY) growth in sales and profit
with growth_table
as
(select
extract(year from order_date) as year,
extract(month from order_date) as month,
round(sum(total_sales)::numeric,2) as curr_total_revenue,
lag(round(sum(total_sales)::numeric,2),1) over(partition by extract(year from order_date)
order by extract(month from order_date)asc) as prev_month_sales,
round(sum(profit*quantity)::numeric) as curr_total_profit,
lag(round(sum(profit*quantity)::numeric,2),1) over(partition by extract(year from order_date)
order by extract(month from order_date)asc) as prev_month_profit
from superstore
group by 1,2
),growth_analysis as
(select
year,
month,
curr_total_revenue,
prev_month_sales,
round((curr_total_revenue-prev_month_sales)::numeric/prev_month_sales::numeric*100,2) as sales_perct_chng,
curr_total_profit,
prev_month_profit,
round((curr_total_profit-prev_month_profit)::numeric/prev_month_profit::numeric*100,2) as profit_perct_chng
from growth_table
)
select
year,
month,
coalesce(sales_perct_chng,0) as sales_perct_chng,
coalesce(profit_perct_chng,0) as profit_perct_chng
from growth_analysis

--F. Inventory Turnover Metrics
--Identify slow-moving vs fast-moving products (based on sales frequency)
select*from superstore
select
product_name,
count(*) as frequency,
case when count(*)>10 then 'Fat-Moving-Product'
else 'Slow-Moving_product'
end as Product_frequency_category
from superstore
group by product_name
--order by frequency desc

--Calculate average order quantity per category
select
category,
round(avg(quantity)::numeric,2) as average_quantity
from superstore
group by category
--Rank suppliers or categories by turnover ratio
select
category,
round(sum(quantity)::numeric/count(*)::numeric,2) as turnover_ratio,
dense_rank() over(order by sum(quantity)::numeric/count(*)desc) as rnk
from superstore
group by category







