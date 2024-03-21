SELECT *
FROM car_sales

--Data Overview:
--What is the total number of records in the dataset?
SELECT COUNT(*)
FROM car_sales
--23906 car sales in the dataset!

--How many unique car models are represented in the dataset?

SELECT COUNT(DISTINCT model)
FROM car_sales
--154 unique car models

--What is the range of dates covered in the dataset?
SELECT MAX(date) AS max_date, MIN(date) AS min_date
FROM car_sales
--The data set ranges from January 2nd 2022 to December 31st 2023

--Data Cleaning:
--Are there any missing values in the dataset? If so, how do you plan to handle them?
SELECT COUNT(*) as no_sales, COUNT(date) as no_date, COUNT(customer_name) AS no_names, COUNT(gender) AS no_genders,
	COUNT(annual_income) AS no_incomes, COUNT(dealer_name) AS no_dealers, COUNT(company) AS no_companies, COUNT(model) AS no_models, 
	COUNT(engine) AS no_engines, COUNT(transmission) AS no_transmissions, COUNT(color) AS no_colors, COUNT(price) AS no_prices, COUNT(dealer_no) AS no_dealer_ids, 
	COUNT(body_style) AS no_body, COUNT(phone) AS no_phones, COUNT(dealer_region) AS no_regions
FROM car_sales
--There are no missing values! All columns contain 23906 records.

--Are there any duplicates in the dataset? If yes, how will you address them?
SELECT COUNT(DISTINCT car_id)
FROM car_sales
--All car_ids are unique so everything looks fine. 
--This is the only value where duplicates would not be acceptable
SELECT COUNT(DISTINCT phone)
FROM car_sales
--There are duplicate phone numbers though. Will investigate more

SELECT phone, COUNT(car_id)
FROM car_sales
GROUP BY phone
HAVING COUNT(*) > 1
--102 phone numbers are associated with more than 1 sale. They all are associated with only 2 sales.
--Will pull all info for these phone numbers to see if something is fishy

WITH multiple_sales_phones AS (SELECT phone
FROM car_sales
GROUP BY phone
HAVING COUNT(*) > 1),

multiple_sales_details AS(SELECT *
FROM car_sales
INNER JOIN multiple_sales_phones
ON car_sales.phone = multiple_sales_phones.phone
ORDER BY car_sales.phone),

joined_info AS(SELECT CONCAT(customer_name, '-', date, '-', model) AS name_date_model,
			   			CONCAT(customer_name, '-', date, '-', model, '-', color) AS name_date_model_color,
			   			CONCAT(customer_name, '-', date, '-', model, '-', engine) AS name_date_model_engine
			  FROM multiple_sales_details)

SELECT COUNT(DISTINCT name_date_model) as count_name_date_model, COUNT(DISTINCT name_date_model_color) as count_name_date_model_color,
	COUNT(DISTINCT name_date_model_engine) as count_name_date_model_engine
	FROM joined_info
--All 204 sales have unique name/date/model, name/date/model/color & name/date/model/engine variations.
--This tells me that those are not data entry mistakes but simply different sales made with the same phone number

--Are there any inconsistencies in categorical variables (e.g., Gender, Transmission, Color)? How will you standardize them?
SELECT DISTINCT color
FROM car_sales

SELECT DISTINCT transmission
FROM car_sales

SELECT DISTINCT gender
FROM car_sales
--It seems like the data set only contains 3 colors of cars: Pale White, Red & Black. 
--So no multiples variations of red which could cause an issue during analysis for example.
--Also only 2 genders and 2 transmission types.

--Exploratory Analysis:
--What is the distribution of car prices in the dataset?

SELECT max(price) AS max_price, MIN(price) AS min_price, (max(price) - MIN(price)) AS price_spread
FROM car_sales
--Sales range from only 1200$ to 85800$. A spread of 84600$ between the highest and lowest price
SELECT percentile_disc(0.25) WITHIN GROUP (ORDER BY price) AS twenty_fifth_percentile_price,
	percentile_disc(0.5) WITHIN GROUP (ORDER BY price) AS median_price,
	percentile_disc(0.75) WITHIN GROUP (ORDER BY price) AS seventy_fifth_percentile_price
FROM car_sales
--As we can see, even if the max sales price is 85800$, 75% of sales go for 34000$ or less

--Can you identify the top 5 car brands by sales volume?
SELECT company, COUNT(car_id) as sales_volume
FROM car_sales
GROUP BY company
ORDER BY sales_volume DESC
LIMIT 5
--The top 5 car brands by sales volume are: Chevrolet, Dodge, Ford, Volkswagen & Mercedes Benz
SELECT company, SUM(price) as revenue
FROM car_sales
GROUP BY company
ORDER BY revenue DESC
LIMIT 5
--The top 5 car brands by revenue are: Chevrolet, Ford, Dodge, Oldsmobile & Mercedes Benz
--Oldsmobile car must sell on average for more than Volkswagen/Mercedes since they are in the top 5 in revenue but not in sales volume.
SELECT company, ROUND(AVG(price), 0) as average_car_price
FROM car_sales
WHERE company IN ('Oldsmobile', 'Volkswagen', 'Mercedes-B')
GROUP BY company
ORDER BY average_car_price DESC
--Oldsmobile does in fact have an average price higher than Volkswagen/Mercedes

--How does the distribution of annual income vary by gender?
SELECT gender, max(annual_income) AS max_income, min(annual_income) as min_income, ROUND(avg(annual_income), 0) as average_income
FROM car_sales
GROUP BY gender

--Female car buyers earn around 10000$ less than male buyers.
--Though the lowest annual income for females is higher than for males. 
--The max income is much larger for males than females(5M$ more)
WITH income_bins AS (SELECT *, CASE WHEN
					annual_income < 25000 THEN '0-25000$'
					WHEN annual_income >= 25000 AND annual_income < 50000 THEN '25-50000$'
					WHEN annual_income >= 50000 AND annual_income < 75000 THEN '50-75000$'
					WHEN annual_income >= 75000 AND annual_income < 100000 THEN '75-100000$'
					WHEN annual_income >= 100000 AND annual_income < 125000 THEN '100-125000$'
					WHEN annual_income >= 125000 AND annual_income < 150000 THEN '125-150000$'
					WHEN annual_income >= 150000 AND annual_income < 175000 THEN '150-175000$'
					WHEN annual_income >= 175000 AND annual_income < 200000 THEN '175-200000$'
					ELSE '200000$+' END AS income_bracket
					FROM car_sales),
				
income_bins_columns AS (SELECT *, CASE WHEN income_bracket = '0-25000$' then 1 ELSE 0 END AS income0_25,
CASE WHEN income_bracket = '25-50000$' then 1 ELSE 0 END AS income25_50,
							 CASE WHEN income_bracket = '50-75000$' then 1 ELSE 0 END AS income50_75,
							 CASE WHEN income_bracket = '75-100000$' then 1 ELSE 0 END AS income75_100,
							 CASE WHEN income_bracket = '100-125000$' then 1 ELSE 0 END AS income100_125,
							 CASE WHEN income_bracket = '125-150000$' then 1 ELSE 0 END AS income125_150,
							 CASE WHEN income_bracket = '150-175000$' then 1 ELSE 0 END AS income150_175,
							 CASE WHEN income_bracket = '175-200000$' then 1 ELSE 0 END AS income175_200,
							 CASE WHEN income_bracket = '200000$+' then 1 ELSE 0 END AS income200over
							 FROM income_bins)
SELECT gender, ROUND(avg(income0_25),2) as income0_25, ROUND(avg(income25_50), 2) as income25_50, ROUND(avg(income50_75),2), ROUND(avg(income75_100),2), ROUND(avg(income100_125),2), ROUND(avg(income125_150),2), ROUND(avg(income150_175),2),
	ROUND(avg(income175_200),2), ROUND(avg(income200over),2) as income_200over
FROM income_bins_columns
GROUP BY gender
--The dataset only contains car buyers with annual income lesser than 25000$ or higher than 200000$..
--Will create new, bigger bins to gain some insights

WITH income_bins AS (SELECT *, CASE WHEN
					annual_income < 100000 THEN '0-100000$'
					WHEN annual_income >= 100000 AND annual_income < 200000 THEN '100-200000$'
					WHEN annual_income >= 200000 AND annual_income < 300000 THEN '200-300000$'
					WHEN annual_income >= 300000 AND annual_income < 400000 THEN '300-400000$'
					WHEN annual_income >= 400000 AND annual_income < 500000 THEN '400-500000$'
					WHEN annual_income >= 500000 AND annual_income < 600000 THEN '500-600000$'
					WHEN annual_income >= 600000 AND annual_income < 700000 THEN '600-700000$'
					WHEN annual_income >= 700000 AND annual_income < 800000 THEN '700-800000$'
					ELSE '800000$+' END AS income_bracket
					FROM car_sales),
				
income_bins_columns AS (SELECT *, CASE WHEN income_bracket = '0-100000$' then 1 ELSE 0 END AS income0_100,
CASE WHEN income_bracket = '100-200000$' then 1 ELSE 0 END AS income100_200,
							 CASE WHEN income_bracket = '200-300000$' then 1 ELSE 0 END AS income200_300,
							 CASE WHEN income_bracket = '300-400000$' then 1 ELSE 0 END AS income300_400,
							 CASE WHEN income_bracket = '400-500000$' then 1 ELSE 0 END AS income400_500,
							 CASE WHEN income_bracket = '500-600000$' then 1 ELSE 0 END AS income500_600,
							 CASE WHEN income_bracket = '600-700000$' then 1 ELSE 0 END AS income600_700,
							 CASE WHEN income_bracket = '700-800000$' then 1 ELSE 0 END AS income700_800,
							 CASE WHEN income_bracket = '800000$+' then 1 ELSE 0 END AS income800over
							 FROM income_bins)
SELECT gender, ROUND(avg(income0_100),2) as income0_100, ROUND(avg(income100_200), 2) as income100_200, ROUND(avg(income200_300),2) as income200_300, ROUND(avg(income300_400),2) as income300_400, ROUND(avg(income400_500),2) as income400_500, ROUND(avg(income500_600),2) as income500_600, ROUND(avg(income600_700),2) as income600_700,
	ROUND(avg(income700_800),2) as income700_800, ROUND(avg(income800over),2) as income800over
FROM income_bins_columns
GROUP BY gender
--As we can see here, 41% of female car buyers in our dataset have an annual income between 100 and 800k$
--For males, that income bracket only makes up 30% of the population.


--What are the most common car body types in the dataset?
SELECT body_style, COUNT(*) as no_body
FROM car_sales
GROUP BY body_style
ORDER BY no_body DESC
--SUV is the most common body style sold. Close second is hatchback, with a significant gap with 3rd place(Sedan)

--Data Relationships:
--Is there a correlation between annual income and car price?
SELECT corr(annual_income, price) as correlation_income_price
FROM car_sales
--With a coefficient of only 0.01, we can conclude there is no correlation between the annual income and car prices.
--Which seems unrealistic. The dataset looks like it was generated pretty randomly.

--Are there any noticeable patterns in sales based on transmission type?
WITH total_sales AS (SELECT COUNT(*) as total_sales
					FROM car_sales)

SELECT transmission, COUNT(transmission) as no_sales, ROUND(COUNT(transmission)::numeric/(SELECT total_sales FROM total_sales), 2) as percent_total_sales
FROM car_sales
GROUP BY transmission
--53% of sales are for Automatic cars
SELECT transmission, EXTRACT(QUARTER FROM date) as quarter_of_sale, COUNT(transmission) as no_sales
FROM car_sales
GROUP BY transmission, quarter_of_sale
ORDER BY no_sales DESC
--For both transmission types, the 4th quarter generates the most sales. 
SELECT transmission, EXTRACT(MONTH FROM date) as month_of_sale, COUNT(transmission) as no_sales
FROM car_sales
GROUP BY transmission, month_of_sale
ORDER BY no_sales DESC
--The top 3 months with most sales were for Automatic cars. December, November and September.
WITH transmission_sales AS (SELECT gender, transmission, COUNT(transmission) as no_sales
FROM car_sales
GROUP BY gender, transmission),

transmission_gender_sales_with_totals AS (SELECT gender, transmission, no_sales, SUM(no_sales) OVER(PARTITION by gender) AS total_sales
FROM transmission_sales
ORDER BY no_sales DESC)

SELECT gender, transmission, no_sales, total_sales, ROUND((no_sales/total_sales), 4)*100 AS percent_sales
FROM transmission_gender_sales_with_totals
ORDER BY no_sales DESC
--There doesnt seem to be a difference between male/female buying patterns in terms of transmission chosen.
--Both genders buy each types of transmissions at the same rate: 47% manual, 52% automatic

--How does the distribution of car colors vary by geographic region?
WITH color_by_region AS (SELECT dealer_region, color, count(*) as count_color
FROM car_sales
GROUP BY dealer_region, color
ORDER BY dealer_region, count_color DESC),

color_by_region_totals AS(SELECT dealer_region, color, count_color, SUM(count_color) OVER (PARTITION BY dealer_region) as total_sales_region
FROM color_by_region)

SELECT dealer_region, color, ROUND((count_color/total_sales_region), 4)*100 AS percent_sales_dealer_region
FROM color_by_region_totals
ORDER BY percent_sales_dealer_region DESC
--In all the dealer regions, Pale white is the most popular color.
--Aurora is where Pale white is the most popular, with 48.80% of their sales being in that color
--Red is the least popular color in every region as well.
--Greenville is where Red is the least popular, with only 19.47% of car sold having that color.

--Sales Performance Analysis:
--What is the total revenue generated from car sales in the dataset?
SELECT SUM(price) AS total_revenue
FROM car_sales
--671,525,465$ generated in revenue throughout all the dataset

--Can you identify the top-performing dealers based on total sales amount?
SELECT dealer_name, COUNT(*) as total_sales, SUM(price) as total_revenue
FROM car_sales
GROUP BY dealer_name
ORDER BY total_revenue DESC
--There are 10 dealers that brought in over 34M$ in revenue.
--These dealer also all had over 1200 sales on record

--Is there a seasonal trend in car sales based on transaction dates?
WITH sales_2023_month AS(SELECT EXTRACT(YEAR FROM date) AS year, EXTRACT(MONTH FROM date) AS month, COUNT(*) as total_sales, SUM(price) as total_revenue
FROM car_sales
WHERE EXTRACT(YEAR FROM date) = 2023
GROUP BY year, month
ORDER BY total_revenue DESC),
sales_2022_month AS(SELECT EXTRACT(YEAR FROM date) AS year, EXTRACT(MONTH FROM date) AS month, COUNT(*) as total_sales, SUM(price) as total_revenue
FROM car_sales
WHERE EXTRACT(YEAR FROM date) = 2022
GROUP BY year, month
ORDER BY total_revenue DESC),
sales_22_23 AS (SELECT y23.month, y22.total_sales as sales_2022, y23.total_sales as sales_2023, y22.total_revenue as revenue_2022, y23.total_revenue as revenue_2023
FROM sales_2023_month as y23
LEFT JOIN sales_2022_month as y22
ON y23.month = y22.month
ORDER BY revenue_2023 DESC)

SELECT *, ROUND(revenue_2023::numeric/revenue_2022, 2)-1 AS percent_revenue_increase
FROM sales_22_23
ORDER BY percent_revenue_increase DESC
--In 2022, the later months of the year generated the most sales(August to December)
--For 2023, that trend is still noticeable, but May-June-July overtook August & October in total revenue.
--In 2023, 4 months had a revenue increase higher than 40%: January, May, June & July

--Customer Insights:
--What is the gender distribution of car buyers?
WITH count_gender AS(SELECT gender, COUNT(*)  sales_gender
					 FROM car_sales
					GROUP BY gender),
count_gender_total as(SELECT gender, SUM(sales_gender) as total_sales
					 FROM count_gender)
					 
SELECT *, ROUND(count_gender.sales_gender/total_sales, 2)*100 as percent_sales
FROM count_gender_total
GROUP BY gender
--Are there any differences in purchasing behavior between male and female customers?
SELECT gender, avg(price) as average_price
FROM car_sales
GROUP BY gender
--Female buyers tend to buy cars slightly more expensive on average(238$ more expensive)
WITH male_total_orders AS (SELECT COUNT(*) as male_total
						  FROM car_sales
						   WHERE gender = 'Male'),
female_total_orders AS (SELECT COUNT(*) as female_total
						  FROM car_sales
						   WHERE gender = 'Female'),						   
gender_color_count_color AS(SELECT gender, color, COUNT(*) as color_sales
FROM car_sales
GROUP BY gender, color
ORDER BY color_sales DESC, color)

SELECT gender, color, color_sales, CASE WHEN gender = 'Male' THEN ROUND(color_sales::numeric/(SELECT male_total_orders.male_total FROM male_total_orders), 2)*100
WHEN gender = 'Female' THEN ROUND(color_sales::numeric/(SELECT female_total_orders.female_total FROM female_total_orders), 2)*100 END AS gender_percent_sales
FROM gender_color_count_color
GROUP BY gender, color, color_sales
ORDER BY gender_percent_sales DESC
--The color distribution between gender is also almost the same. 
--Pale with is only slightly preferred by Females(48% of sales vs. 47% of sales by Males)

--Can you identify any patterns in the annual income of customers based on the car brand they purchase?

SELECT company, ROUND(avg(annual_income), 2) as average_income, ROUND(avg(price), 2) as average_price
FROM car_sales
GROUP BY company
ORDER BY average_income DESC
--Cadillac is the most expensive car brand on average, and it's alse the brand where buyers have the highest average income.
--The opposite is not true though. 
--Hyundai is the brand with the lowest average price, but the one with the second highest buyer's income.

--Geographic Analysis:
--Which region has the highest number of car sales?
SELECT dealer_region, COUNT(*) as no_sales
FROM car_sales
GROUP BY dealer_region
ORDER BY no_sales DESC
--Austin is the top selling region, with over 300 sales more than the 2nd highest selling region(Janesville)

--Is there any significant difference in car prices across different regions?
SELECT dealer_region, ROUND(avg(price), 2) as average_price
FROM car_sales
GROUP BY dealer_region
ORDER BY average_price DESC
--Austin is also where the average price per car is the highest.
--With the highest average car price and the most sales happening in the Austin region, we can conclude this is a high value region.
--Higher attention and care should be put in Austin to maximize sales there.

--Are there any particular car models more popular in certain regions?
WITH sales_total_region AS (SELECT dealer_region, COUNT(*) as total_region_sales
						   FROM car_sales
						   GROUP BY dealer_region),

sales_region_avg_price AS (SELECT car_sales.dealer_region, company, model, COUNT(*) as no_sales, ROUND(avg(price), 2) as average_price, SUM(price) as total_revenue
FROM car_sales
LEFT JOIN sales_total_region
ON car_sales.dealer_region = sales_total_region.dealer_region
GROUP BY car_sales.dealer_region, company, model
ORDER BY no_sales DESC),

region_price_revenue_region_sales AS (SELECT sales_region_avg_price.dealer_region, company, model, no_sales, average_price, total_revenue, SUM(total_revenue) OVER(PARTITION BY dealer_region) as total_region_sales
FROM sales_region_avg_price
ORDER BY total_revenue DESC)

SELECT dealer_region, company, model, no_sales, average_price, total_revenue, total_region_sales, ROUND(total_revenue::numeric/total_region_sales,4)*100 as percent_region_sales
FROM region_price_revenue_region_sales
ORDER BY percent_region_sales DESC
LIMIT 50
--11 car models account for more than 2% of their region's total sales.
--The Lexus LS400 appears 4 times in that top 11. 
--The Scottsdale, Janesville and Austin dealer_regions also appear multiple times in that top 11.
--These regions seem to have more concentrated sales accross fewer models


WITH sales_total_region AS (SELECT dealer_region, COUNT(*) as total_region_sales
						   FROM car_sales
						   GROUP BY dealer_region),

sales_region_avg_price AS (SELECT car_sales.dealer_region, company, model, COUNT(*) as no_sales, ROUND(avg(price), 2) as average_price, SUM(price) as total_revenue
FROM car_sales
LEFT JOIN sales_total_region
ON car_sales.dealer_region = sales_total_region.dealer_region
GROUP BY car_sales.dealer_region, company, model
ORDER BY no_sales DESC),

region_price_revenue_region_sales AS (SELECT sales_region_avg_price.dealer_region, company, model, no_sales, average_price, total_revenue, SUM(total_revenue) OVER(PARTITION BY dealer_region) as total_region_sales
FROM sales_region_avg_price
ORDER BY total_revenue DESC),

percent_region_sales as (SELECT dealer_region, company, model, no_sales, average_price, total_revenue, total_region_sales, ROUND(total_revenue::numeric/total_region_sales,4)*100 as percent_region_sales
FROM region_price_revenue_region_sales
ORDER BY percent_region_sales DESC
LIMIT 25)

SELECT company, model, COUNT(model), avg(percent_region_sales.percent_region_sales) as avg_percent_region_sales
FROM percent_region_sales
GROUP BY company, model
ORDER BY COUNT(model) DESC
--Here we can see that the Lexus LS400 is the model that appears most often in the top 25 ranking of cars that represent the highest share of total dealer_region revenue.
--On average, it represents 2.19% of those dealer_regions' revenue

--Dealer Performance:
--How does the average sale price vary across different dealers?
SELECT dealer_name, AVG(price) as average_price
FROM car_sales
GROUP BY dealer_name
ORDER BY average_price DESC
--The average price doesn't vary a ton by dealer.
--The highest car price average is 28769$ at U-Haul CO and the lowest is 27217$ at Buddy Stobeck's

SELECT dealer_name, MAX(price) as max_price, MIN(price) as min_price, (MAX(price)-MIN(price)) as price_spread
FROM car_sales
GROUP BY dealer_name
ORDER BY price_spread DESC
--Rabun used car sales has the largest spread between their highest and lowest priced sold cars, with a difference of 84151$!

WITH dealer_spread as (SELECT dealer_name, MAX(price) as max_price, MIN(price) as min_price, (MAX(price)-MIN(price)) as price_spread
FROM car_sales
GROUP BY dealer_name
ORDER BY price_spread DESC)

SELECT AVG(price_spread)
FROM dealer_spread
--The average dealer price spread is 77271$

--Are there any dealers with consistently high or low sales prices compared to others?
--As seen before, not really.

--Is there a correlation between dealer experience (measured by the number of sales) and average sale price?
WITH dealer_sales_avgprice AS (SELECT dealer_name, COUNT(*) AS no_sales, AVG(price) as average_price
FROM car_sales
GROUP BY dealer_name)

SELECT corr(no_sales, average_price)
FROM dealer_sales_avgprice
--There is a positive, moderate correlation between number of sales and average_price(0.34).
--Dealers with more sales tend to have a higher average sales price.

SELECT dealer_name, company, COUNT(*) as total_sales, avg(price) as average_price, SUM(price) AS total_revenue
FROM car_sales
GROUP BY dealer_name, company
ORDER BY total_sales DESC
--The top 20 of top car brands by dealer, are all either Ford, Chevrolet or Dodge. 

--Trend Analysis:
--Can you identify any trends in the popularity of car models over time?
--Is there a noticeable trend in the average price of cars over the years?
--Are there any patterns in the distribution of car body types over the years?

--Customer Satisfaction:
--Is there any relationship between customer satisfaction (measured through repeat purchases) and the car model they initially bought?
WITH multiple_sales_phones AS (SELECT phone
FROM car_sales
GROUP BY phone
HAVING COUNT(*) > 1),

multiple_sales_ranked as (SELECT *, RANK() OVER(PARTITION by car_sales.phone ORDER BY date) as order_purchase
FROM car_sales
INNER JOIN multiple_sales_phones
ON car_sales.phone = multiple_sales_phones.phone
ORDER BY car_sales.phone, dealer_name)

SELECT gender, dealer_name, company, transmission, color, body_style, dealer_region, COUNT(*)
FROM multiple_sales_ranked
WHERE order_purchase = 1
GROUP BY CUBE(gender, dealer_name, company, transmission, color, body_style, dealer_region)
ORDER BY COUNT(*) DESC

--
--Are there any common complaints or feedback from customers that can be extracted from the dataset?
--How does customer satisfaction vary across different dealers or regions?

