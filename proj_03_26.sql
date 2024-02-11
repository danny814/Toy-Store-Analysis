-- four tables: inventory, products, sales, and stores

-- nulls from inventory

SELECT *
FROM dbo.mt_inventory$
WHERE Store_ID IS NULL
OR Product_ID IS NULL
OR Stock_On_Hand IS NULL

-- nulls from products

SELECT Product_ID, Product_Name, Product_Category, Product_Cost, Product_Price
FROM dbo.mt_products$
WHERE Product_ID IS NULL
OR Product_Name IS NULL
OR Product_Category IS NULL
OR Product_Cost IS NULL
OR Product_Price IS NULL

-- nulls from sales
-- renaming date column first

SP_RENAME 'dbo.mt_sales$.Date', 'dateofsale'

SELECT Sale_ID, dateofsale, Store_ID, Product_ID, Units
FROM dbo.mt_sales$
WHERE Sale_ID IS NULL
OR dateofsale IS NULL
OR Store_ID IS NULL
OR Product_ID IS NULL
OR Units IS NULL

-- nulls from stores

SELECT Store_ID, Store_Name, Store_City, Store_Location, Store_Open_Date
FROM mt_stores$
WHERE Store_ID IS NULL
OR Store_Name IS NULL
OR Store_City IS NULL
OR Store_Location IS NULL
OR Store_Open_Date IS NULL

-- dupes from sales - 98,103 rows containing multiple instances in sales

SELECT dateofsale, Store_ID, Product_ID, Units,
COUNT(*) AS occurrences
FROM dbo.mt_sales$
GROUP BY dateofsale, Store_ID, Product_ID, Units
HAVING COUNT(*) > 1

-- test - 829,262 total rows in sales

SELECT COUNT(*)
FROM dbo.mt_sales$


-- test: finding first iteration with MIN(Sale_ID)

SELECT * FROM dbo.mt_sales$
WHERE Sale_ID IN (
   SELECT MIN(Sale_ID)
   FROM dbo.mt_sales$
   GROUP BY dateofsale, Store_ID, Product_ID, Units
)

-- implies that only 103,753 rows (12.5% of total sales) are not duplicates... we will assume that all sales are non-duplicates,
-- but this matter should be investigated further with more precise datesofsale and/or foreign keys

-- lower() column names in each table

-- inventory

SP_RENAME 'dbo.mt_inventory$.Store_ID', 'store_id'
SP_RENAME 'dbo.mt_inventory$.Product_ID', 'product_id'
SP_RENAME 'dbo.mt_inventory$.Stock_On_Hand','stock_on_hand'

-- products

SP_RENAME 'dbo.mt_products$.Product_ID','product_id'
SP_RENAME 'dbo.mt_products$.Product_Name','product_name'
SP_RENAME 'dbo.mt_products$.Product_Category','product_category'
SP_RENAME 'dbo.mt_products$.Product_Cost','product_cost'
SP_RENAME 'dbo.mt_products$.Product_Price','product_price'

-- sales

SP_RENAME 'dbo.mt_sales$.Sale_ID','sale_id'
SP_RENAME 'dbo.mt_sales$.Store_ID','store_id'
SP_RENAME 'dbo.mt_sales$.Product_ID','product_id'
SP_RENAME 'dbo.mt_sales$.Units','units'

-- stores

SP_RENAME 'dbo.mt_stores$.Store_ID','store_id'
SP_RENAME 'dbo.mt_stores$.Store_Name','store_name'
SP_RENAME 'dbo.mt_stores$.Store_City','store_city'
SP_RENAME 'dbo.mt_stores$.Store_Location','store_location'
SP_RENAME 'dbo.mt_stores$.Store_Open_Date','store_open_date'

-- inventory basic eda

SELECT store_id,
COUNT(DISTINCT product_id) AS prods,
ROUND((STDEV(stock_on_hand)),2) AS stock_stdev,
ROUND((AVG(stock_on_hand)),2) AS avg_stock,
MIN(stock_on_hand) AS min_stock,
MAX(stock_on_hand) AS max_stock
FROM dbo.mt_inventory$
GROUP BY store_id
ORDER BY store_id

-- unique store_id

SELECT DISTINCT(store_id)
FROM dbo.mt_inventory$
ORDER BY store_id

-- unique prod_id

SELECT DISTINCT(product_id)
FROM dbo.mt_inventory$
ORDER BY product_id

-- products basic eda

SELECT COUNT(DISTINCT(product_id)) AS unique_prod_ids,
COUNT(DISTINCT(product_name)) AS unique_prod_names,
COUNT(DISTINCT(product_category)) AS unique_prod_cats
FROM dbo.mt_products$

-- creation of profit column within prods

SELECT *,
ROUND((product_price - product_cost),2) AS profit
FROM dbo.mt_products$

-- sales basic eda

SELECT COUNT(DISTINCT sale_id) AS unique_sales,
COUNT(DISTINCT dateofsale) AS unique_dos,
COUNT(DISTINCT store_id) AS unique_stores,
COUNT(DISTINCT product_id) AS unique_prods,
COUNT(DISTINCT units) AS unique_qtys
FROM dbo.mt_sales$

-- beginning and ending of sales timeframe

SELECT MIN(dateofsale) AS beg_of_timeframe,
MAX(dateofsale) AS end_of_timeframe
FROM dbo.mt_sales$

-- stores

SELECT *
FROM dbo.mt_stores$

-- stores basic eda

SELECT COUNT(DISTINCT store_id) AS uniq_store_ids,
COUNT(DISTINCT store_name) AS uniq_store_names,
COUNT(DISTINCT store_city) AS uniq_cities,
COUNT(DISTINCT store_location) AS store_types,
COUNT(DISTINCT store_open_date) AS uniq_openings
FROM dbo.mt_stores$

-- task 01: product categories driving profit

WITH prof AS
(
SELECT product_id,
product_category, 
ROUND((product_price - product_cost),2) AS profits
FROM dbo.mt_products$
),

sums AS
(
SELECT (SUM(s.units) * (p.profits)) AS total_profits,
p.product_category
FROM prof p
JOIN mt_sales$ s ON p.product_id = s.product_id
GROUP BY p.product_category, p.profits
),

pcts AS
(
SELECT product_category,
SUM(total_profits) AS total_profits,
(SUM(total_profits) * 100) / SUM(total_profits) OVER() AS pct
FROM sums
GROUP BY product_category, total_profits
)

SELECT product_category,
SUM(total_profits) AS total_profits,
ROUND((SUM(pct)),2) AS total_pct
FROM pcts
GROUP BY product_category
ORDER BY total_pct DESC

-- is this true across store locations?

WITH prof AS
(
SELECT product_id,
product_category, 
ROUND((product_price - product_cost),2) AS profits
FROM dbo.mt_products$
),

sums AS
(
SELECT
(SUM(s.units) * (p.profits)) AS total_profits,
p.product_category,
st.store_name
FROM prof p
JOIN mt_sales$ s ON p.product_id = s.product_id
JOIN mt_stores$ st ON st.store_id = s.store_id
GROUP BY p.product_category, p.profits, st.store_name
),

rankings AS
(
SELECT product_category,
ROW_NUMBER () OVER (
PARTITION BY store_name
ORDER BY total_profits DESC) rn_test,
store_name,
SUM(total_profits) AS total_profits
FROM sums
GROUP BY store_name, product_category, total_profits
)

SELECT store_name,
product_category,
total_profits
FROM rankings
WHERE rn_test = 1
ORDER BY total_profits DESC

-- task 02: seasonality and/or trends

SELECT DAY(dateofsale) AS day_of_month,
COUNT(DISTINCT(sale_id)) AS num_sales
FROM dbo.mt_sales$
GROUP BY DAY(dateofsale)
ORDER BY num_sales DESC

-- we see that top 10 days for sales are within 5 days of the 15th and the 1st,
-- which is typically when people with biweekly pay receive their checks

SELECT DATENAME(dw,dateofsale) AS day_of_week,
COUNT(DISTINCT(sale_id)) AS num_sales
FROM dbo.mt_sales$
GROUP BY DATENAME(dw,dateofsale)
ORDER BY num_sales DESC

-- weekends have the most total unique sales
-- we can also check avg profit and avg sales for each day of week

WITH prof AS
(
SELECT product_id,
ROUND((product_price - product_cost),2) AS profits
FROM dbo.mt_products$
),

sums AS
(
SELECT s.dateofsale,
COUNT(DISTINCT(s.sale_id)) AS num_sales,
(SUM(s.units) * (p.profits)) AS total_profits
FROM prof p
JOIN mt_sales$ s ON p.product_id = s.product_id
GROUP BY s.dateofsale,p.profits
)

SELECT DATENAME(dw,sums.dateofsale) AS day_of_week,
AVG(num_sales) AS avg_num_of_sales,
ROUND((AVG(total_profits)),2) AS avg_profit
FROM sums
JOIN mt_sales$ s ON s.dateofsale = sums.dateofsale
GROUP BY DATENAME(dw,sums.dateofsale)
ORDER BY avg_num_of_sales DESC

-- weekends are still on top for both avgs
-- let's check seasonality

-- sanity check

SELECT MIN(dateofsale) AS min_d,
MAX(dateofsale) AS max_d
FROM dbo.mt_sales$

-- about 1.83 years of data according to timeframe

-- total num sales per season

WITH snss AS
(
SELECT CASE WHEN MONTH(dateofsale) IN(3, 4, 5) THEN 'spring'
WHEN MONTH(dateofsale) IN(6, 7, 8) THEN 'summer'
WHEN MONTH(dateofsale) IN(9, 10, 11) THEN 'autumn'
WHEN MONTH(dateofsale) IN(12, 1, 2) THEN 'winter' END AS season,
COUNT(DISTINCT(sale_id)) AS num_sales
FROM dbo.mt_sales$
GROUP BY dateofsale
)
SELECT season,
SUM(num_sales) AS total_sales
FROM snss
GROUP BY season
ORDER BY total_sales DESC

-- total sales per month/season

SELECT MONTH(dateofsale) AS mnth,
CASE WHEN MONTH(dateofsale) IN(3, 4, 5) THEN 'Spring'
WHEN MONTH(dateofsale) IN(6, 7, 8) THEN 'Summer'
WHEN MONTH(dateofsale) IN(9, 10, 11) THEN 'Autumn'
WHEN MONTH(dateofsale) IN(12, 1, 2) THEN 'Winter' END AS season,
COUNT(DISTINCT(sale_id)) AS num_sales
FROM dbo.mt_sales$
GROUP BY MONTH(dateofsale)
ORDER BY num_sales DESC

-- spring and summer are the most popular months for num unique sales
-- we should note that 10, 11, and 12 are at a disadvantage since the timeframe ends in September

-- task 03: out of stock holdups

WITH zeros AS
(
SELECT *
FROM dbo.mt_inventory$
WHERE stock_on_hand = 0
)

SELECT s.store_name,
COUNT(DISTINCT(z.product_id)) AS num_products,
SUM(z.stock_on_hand) AS stock_on_hand
FROM dbo.mt_stores$ s
JOIN dbo.mt_inventory$ i ON s.store_id = i.store_id
JOIN zeros z ON z.store_id = s.store_id
GROUP BY s.store_name
ORDER BY num_products DESC

-- q1: which products have the lowest and highest sales?

SELECT TOP 5
p.product_name,
COUNT(DISTINCT s.sale_id) AS num_sales,
SUM(s.units) AS total_units
FROM dbo.mt_products$ p
JOIN mt_sales$ s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units DESC

-- q1

SELECT TOP 5
p.product_name,
COUNT(DISTINCT s.sale_id) AS num_sales,
SUM(s.units) AS total_units
FROM dbo.mt_products$ p
JOIN mt_sales$ s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units ASC

-- q2: are there any seasonal patterns in sales?
-- see task 02

-- q3: are there specific regions or stores performing exceptionally well or poorly?

SELECT DISTINCT store_city
FROM dbo.mt_stores$


-- inserting data into coords table for region eval
-- see map and insert regions into new col as well


-- store evaluation (top total sales)

SELECT TOP 5
st.store_name AS store_name,
st.regions,
COUNT(DISTINCT s.sale_id) AS total_sales
FROM dbo.mt_stores$ st
JOIN dbo.mt_sales$ s ON st.store_id = s.store_id
GROUP BY st.store_name, st.regions
ORDER BY total_sales DESC

-- store evaluation (bottom total sales)

SELECT TOP 5
st.store_name,
st.regions,
COUNT(DISTINCT s.sale_id) AS total_sales
FROM dbo.mt_stores$ st
JOIN dbo.mt_sales$ s ON st.store_id = s.store_id
GROUP BY st.store_name, st.regions
ORDER BY total_sales ASC

-- store evaluation (total by month)

SELECT
st.store_name,
COUNT(DISTINCT s.sale_id) AS total_sales,
MONTH(s.dateofsale) AS mnth
FROM dbo.mt_stores$ st
JOIN dbo.mt_sales$ s ON st.store_id = s.store_id
GROUP BY st.store_name, MONTH(s.dateofsale)
ORDER BY mnth

-- q4: how often does the company experience stockouts?

SELECT COUNT(DISTINCT i.product_id) AS prods,
DATEPART(wk, s.dateofsale) AS wk
FROM dbo.mt_inventory$ i
JOIN dbo.mt_sales$ s ON i.product_id = s.product_id
AND i.store_id = s.store_id
WHERE i.stock_on_hand = 0
GROUP BY DATEPART(wk, s.dateofsale)
ORDER BY wk

-- find weekly avg from this

WITH weekly_sums AS 
(
SELECT COUNT(DISTINCT i.product_id) AS prods,
DATEPART(wk, s.dateofsale) AS wk
FROM dbo.mt_inventory$ i
JOIN dbo.mt_sales$ s ON i.product_id = s.product_id
AND i.store_id = s.store_id
WHERE i.stock_on_hand = 0
GROUP BY DATEPART(wk, s.dateofsale)
)

SELECT AVG(prods) AS avg_prods
FROM weekly_sums

-- 11 outstocks per week on avg across all locations

-- q5: which prods have the highest/lowest inventory turnover?

WITH weekly_totals AS
(
SELECT
p.product_name,
COUNT(DISTINCT s.sale_id) AS sales,
SUM(s.units) AS total_units,
DATEPART(wk, dateofsale) AS wek
FROM dbo.mt_sales$ s
JOIN dbo.mt_products$ p ON p.product_id = s.product_id
GROUP BY p.product_name, DATEPART(wk, dateofsale)
)

SELECT TOP 5
product_name,
AVG(sales) AS avg_sales,
ROUND((AVG(total_units)),2) AS avg_total_units
FROM weekly_totals
GROUP BY product_name
ORDER BY avg_total_units DESC

-- lowest weekly turnover

WITH weekly_totals AS
(
SELECT
p.product_name,
COUNT(DISTINCT s.sale_id) AS sales,
SUM(s.units) AS total_units,
DATEPART(wk, dateofsale) AS wek
FROM dbo.mt_sales$ s
JOIN dbo.mt_products$ p ON p.product_id = s.product_id
GROUP BY p.product_name, DATEPART(wk, dateofsale)
)

SELECT TOP 5
product_name,
AVG(sales) AS avg_sales,
ROUND((AVG(total_units)),2) AS avg_total_units
FROM weekly_totals
GROUP BY product_name
ORDER BY avg_total_units ASC

-- q6: slow or obselete stock

WITH slowest_sellers AS
(
SELECT p.product_name,
DATEPART(wk, s.dateofsale) AS wek
FROM mt_products$ p
JOIN mt_sales$ s ON p.product_id = s.product_id
GROUP BY p.product_name, DATEPART(wk, s.dateofsale)
HAVING COUNT(DISTINCT s.sale_id) < 100
)

SELECT TOP 5
product_name,
COUNT(DISTINCT wek) AS num_slow_weeks
FROM slowest_sellers
GROUP BY product_name
ORDER BY num_slow_weeks DESC

-- q7: are there any geographical patterns in the sales data?

ALTER TABLE dbo.mt_stores$
    ADD regions AS (CASE 
                        WHEN store_city IN('La Paz', 'Mexicali') THEN 'Baja California'
                        WHEN store_city IN('Hermosillo','Santiago','Chihuahua','Saltillo','Monterrey','Ciudad Victoria','Durango','Culican','Culiacan') THEN 'Northern Mexico'
                        WHEN store_city IN('Tuxtla Gutierrez','Villahermosa','Merida','Campeche','Chetumal') THEN 'Yucatan Peninsula'
                        WHEN store_city IN('Oaxaca','Chilpancingo','Chilpancigo','Morelia','Guadalajara') THEN 'Pacific Coast'
                        WHEN store_city IN('Xalapa','Toluca','Pachuca','Cuernavaca','Ciudad de Mexico','Cuidad de Mexico','Puebla') THEN 'Central Mexico'
                        WHEN store_city IN('Aguascalientes','Zacatecas','San Luis Potosi','Guanajuato') THEN 'The Bajio'
                        ELSE 'Invalid'
                     END);

-- sanity checks

SELECT *
FROM mt_stores$
WHERE regions = 'Invalid'

ALTER TABLE dbo.mt_stores$
	DROP COLUMN region,regional

SELECT *
FROM mt_stores$

ALTER TABLE dbo.mt_stores$
    ADD ste AS (CASE 
                        WHEN store_city = 'La Paz' THEN 'Baja California Sur'
						WHEN store_city = 'Mexicali' THEN 'Baja California'
						WHEN store_city = 'Hermosillo' THEN 'Sonora'
						WHEN store_city = 'Santiago' THEN 'Nuevo Leon'
						WHEN store_city = 'Chihuahua' THEN 'Chihuahua'
						WHEN store_city = 'Saltillo' THEN 'Coahuila'
						WHEN store_city = 'Monterrey' THEN 'Nuevo Leon'
						WHEN store_city = 'Ciudad Victoria' THEN 'Tamaulipus'
						WHEN store_city = 'Durango' THEN 'Durango'
						WHEN store_city IN('Culican','Culiacan') THEN 'Sinaloa'
                        WHEN store_city = 'Tuxtla Gutierrez' THEN 'Chiapas'
						WHEN store_city = 'Villahermosa' THEN 'Tabasco'
						WHEN store_city = 'Merida' THEN 'Yucatan'
						WHEN store_city = 'Campeche' THEN 'Campeche'
						WHEN store_city = 'Chetumal' THEN 'Quintana Roo'
						WHEN store_city = 'Oaxaca' THEN 'Oaxaca'
						WHEN store_city IN('Chilpancingo','Chilpancigo') THEN 'Guerrero'
						WHEN store_city = 'Morelia' THEN 'Michoacan'
						WHEN store_city = 'Guadalajara' THEN 'Jalisco'
						WHEN store_city = 'Xalapa' THEN 'Veracruz'
						WHEN store_city = 'Toluca' THEN 'Estado de Mexico'
						WHEN store_city = 'Pachuca' THEN 'Hidalgo'
						WHEN store_city = 'Cuernavaca' THEN 'Morelos'
						WHEN store_city IN('Ciudad de Mexico', 'Cuidad de Mexico') THEN 'Ciudad de Mexico'
						WHEN store_city = 'Puebla' THEN 'Puebla'
						WHEN store_city = 'Aguascalientes' THEN 'Aguascalientes'
						WHEN store_city = 'Zacatecas' THEN 'Zacatecas'
						WHEN store_city = 'San Luis Potosi' THEN 'San Luis Potosi'
						WHEN store_city = 'Guanajuato' THEN 'Guanajuato'
                        ELSE 'Invalid'
                     END);

-- sanity checks

SELECT *
FROM mt_stores$
WHERE ste = 'Invalid'

ALTER TABLE mt_stores$
	DROP COLUMN stte

SELECT *
FROM mt_stores$

-- see tableau for more details

-- q8: how do different store locations contribute to overall sales?

WITH prof AS
(
SELECT product_id,
product_category, 
ROUND((product_price - product_cost),2) AS profits
FROM dbo.mt_products$
),

sums AS
(
SELECT
(SUM(s.units) * (p.profits)) AS total_profits,
st.store_name
FROM prof p
JOIN mt_sales$ s ON p.product_id = s.product_id
JOIN mt_stores$ st ON st.store_id = s.store_id
GROUP BY st.store_name, p.profits
),

percents AS 
(
SELECT su.store_name,
SUM(su.total_profits) AS total_profits,
(su.total_profits * 100 / SUM(su.total_profits) OVER()) AS pct
FROM sums su
GROUP BY su.store_name, total_profits
)

SELECT
store_name,
SUM(total_profits) AS total_profits,
ROUND((SUM(pct)),2) AS total_pct
FROM percents
GROUP BY store_name
ORDER by total_pct DESC

-- q10: which product categories contribute the most to overall revenue?

-- see task 01

-- adding grouped data to mt_stores for analysis within tableau

ALTER TABLE mt_stores$
	ADD total_sales INT

-- adding new calculated columm

WITH salesdata AS 
(
SELECT st.store_id,
COUNT(DISTINCT s.sale_id) AS total_sales
FROM dbo.mt_stores$ st
JOIN dbo.mt_sales$ s ON st.store_id = s.store_id
GROUP BY st.store_id
)

UPDATE st
SET st.total_sales = sd.total_sales
FROM dbo.mt_stores$ st
JOIN salesdata sd ON st.store_id = sd.store_id

-- sanity check

SELECT *
FROM mt_stores$
ORDER BY total_sales DESC

-- adding profits column

ALTER TABLE mt_stores$
	ADD total_profit INT

-- adding data to calc column total_profit

WITH prof AS
(
SELECT product_id,
product_category, 
ROUND((product_price - product_cost),2) AS profits
FROM dbo.mt_products$
),

sums AS
(
SELECT
(SUM(s.units) * (p.profits)) AS total_profits,
st.store_name
FROM prof p
JOIN mt_sales$ s ON p.product_id = s.product_id
JOIN mt_stores$ st ON st.store_id = s.store_id
GROUP BY st.store_name, p.profits
),

percents AS 
(
SELECT su.store_name,
SUM(su.total_profits) AS total_profits,
(su.total_profits * 100 / SUM(su.total_profits) OVER()) AS pct
FROM sums su
GROUP BY su.store_name, total_profits
),

final AS
(
SELECT
store_name,
SUM(total_profits) AS total_profits,
ROUND((SUM(pct)),2) AS total_pct
FROM percents
GROUP BY store_name
)

UPDATE st
SET st.total_profit = f.total_profits
FROM dbo.mt_stores$ st
JOIN final f ON st.store_name = f.store_name

-- sanity check

SELECT *
FROM mt_stores$
ORDER BY total_sales DESC