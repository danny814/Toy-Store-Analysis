# Toy Store SQL Analysis
## EDA and Business Tasks

__Author__: Daniel Perez <br />
__Email__: dannypere11@gmail.com <br />
__LinkedIn__: https://www.linkedin.com/in/danielperez12/ <br />

## Sales Performance Analysis

__1.__ Which products have the highest and lowest sales?

```sql
SELECT TOP 5
p.product_name,
COUNT(DISTINCT s.sale_id) AS num_sales,
SUM(s.units) AS total_units
FROM dbo.mt_products$ p
JOIN mt_sales$ s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units DESC
```
__Results:__

product_name |   num_sales  | total_units
|------------|--------------|------------|
Colorbuds|        72988 |      104368
PlayDoh Can|      64834 |      103128
Barrel O' Slime|   54078|       91663
Deck Of Cards|    68083 |      84034
Magic Sand |      39293 |      60598

```sql
SELECT TOP 5
p.product_name,
COUNT(DISTINCT s.sale_id) AS num_sales,
SUM(s.units) AS total_units
FROM dbo.mt_products$ p
JOIN mt_sales$ s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units ASC
```
__Results:__

product_name|    num_sales|   total_units
|------------|------------|---------------|
Mini Basketball Hoop|  2582|        2647
Uno Card Game       |  2599|        2710
Monopoly            |  3002|        3385
Chutes & Ladders    |  3700|        3829
Playfoam            |  2812|        4158

__2.__ Are there any seasonal or timeframe-specific patterns in sales?

__2.1__ Top 5 days of the month:

```sql
SELECT  TOP 5
DAY(dateofsale) AS day_of_month,
COUNT(DISTINCT(sale_id)) AS num_sales
FROM dbo.mt_sales$
GROUP BY DAY(dateofsale)
ORDER BY num_sales DESC
```

__Results:__

day_of_month| num_sales
|-----------|------------|
1 |           30007
15|           29225
2 |           28682
17|           28492
3 |           28199

__2.2__ Top days of the week:

```sql
SELECT DATENAME(dw,dateofsale) AS day_of_week,
COUNT(DISTINCT(sale_id)) AS num_sales
FROM dbo.mt_sales$
GROUP BY DATENAME(dw,dateofsale)
ORDER BY num_sales DESC
```

__Results:__

day_of_week |                   num_sales
|-----------------------------|------------|
Sunday|                         162164
Saturday|                       155088
Friday  |                       125053
Monday  |                       101360
Thursday|                       100361
Wednesday|                      94904
Tuesday  |                      90332

__2.3__ Highest sales/profit average by day of the week:

```sql
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
```

__Results:__

day_of_week|                    avg_num_of_sales| avg_profit
------------------------------|----------------|--------|
Sunday|                         193|              913.03
Saturday|                       186|              886.04
Friday  |                       154|              746.46
Monday  |                       132|              653.73
Thursday|                       127|              610.75
Wednesday|                      121|              582.06
Tuesday  |                      116|              558.41

__2.4__ Total sales based on season:

```sql
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
```

__Results:__

season| total_sales
|------|-----------|
spring| 250384
summer| 239242
winter| 189429
autumn| 150207

__2.5__ Total sales per month/season:

```sql
SELECT MONTH(dateofsale) AS mnth,
CASE WHEN MONTH(dateofsale) IN(3, 4, 5) THEN 'Spring'
WHEN MONTH(dateofsale) IN(6, 7, 8) THEN 'Summer'
WHEN MONTH(dateofsale) IN(9, 10, 11) THEN 'Autumn'
WHEN MONTH(dateofsale) IN(12, 1, 2) THEN 'Winter' END AS season,
COUNT(DISTINCT(sale_id)) AS num_sales
FROM dbo.mt_sales$
GROUP BY MONTH(dateofsale)
ORDER BY num_sales DESC
```

__Results:__

mnth |       season| num_sales
|-----------|------|-----------|
5|           Spring| 85706
6|           Summer| 83936
4|           Spring| 83484
7|           Summer| 83423
3|           Spring| 81194
9|           Autumn| 74797
1|           Winter| 71965
8|           Summer| 71883
2|           Winter| 69084
12|          Winter| 48380
11|          Autumn| 38959
10|          Autumn| 36451

It should be noted that months 10, 11, and 12 are at a disadvantage since the timeframe ends in September.

__3.__ Are there specific regions or stores performing exceptionally well or poorly?

```sql
SELECT TOP 5
st.store_name AS store_name,
st.regions,
COUNT(DISTINCT s.sale_id) AS total_sales
FROM dbo.mt_stores$ st
JOIN dbo.mt_sales$ s ON st.store_id = s.store_id
GROUP BY st.store_name, st.regions
ORDER BY total_sales DESC
```

__Results:__

store_name |                regions |          total_sales
|----------------------|----------------|------------------|
Maven Toys Ciudad de Mexico 2 |     Central Mexico|    29024
Maven Toys Ciudad de Mexico 1 |     Central Mexico|    24482
Maven Toys Toluca 1  |              Central Mexico|    23533
Maven Toys Guadalajara 3   |        Pacific Coast |    23384
Maven Toys Monterrey 2     |        Northern Mexico|   21300

```sql
SELECT TOP 5
st.store_name,
st.regions,
COUNT(DISTINCT s.sale_id) AS total_sales
FROM dbo.mt_stores$ st
JOIN dbo.mt_sales$ s ON st.store_id = s.store_id
GROUP BY st.store_name, st.regions
ORDER BY total_sales ASC
```

__Results:__

store_name|       regions |          total_sales
|----------|----------------|---------------------------|
Maven Toys Toluca 2   |                Central Mexico   | 12776
Maven Toys Campeche 2 |                Yucatan Peninsula| 12805
Maven Toys La Paz 1   |                Baja California|   13217
Maven Toys Zacatecas 1 |               The Bajio     |    13501
Maven Toys Cuernavaca 1 |              Central Mexico|    13643

## Inventory Management

__4.__ How often does the company experience stockouts?

```sql
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

SELECT AVG(prods) AS avg_outstocks_per_week
FROM weekly_sums
```

__Results:__

avg_outstocks_per_week|
|-----------|
11|

__5.__ Which products have the highest/lowest turnover?

```sql
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
```

__Results:__

product_name|        avg_sales|   avg_total_units
|---------------|---------------|------------------|
Colorbuds|            1377 |       1969.21
PlayDoh Can|          1223 |       1945.81
Barrel O' Slime|      1020 |       1729.49
Deck Of Cards  |      1284 |       1585.55
Magic Sand     |      741  |       1143.36

```sql
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
```

__Results:__

product_name|               avg_sales|   avg_total_units
|--------------------------|----------|-------------------|
Mini Basketball Hoop |           49|          50.9
Uno Card Game        |           53|          55.31
Monopoly             |           58|          66.37
Chutes & Ladders     |           69|          72.25
Classic Dominoes     |           80|          84.36

__6.__ Can we identify slow-moving or obsolete stock? (We'll consider an item as a 'slow-mover' if it fails to have over 100 unique sales across all 50 locations within a week.)

```sql
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
```

__Results:__

product_name|                      num_slow_weeks
|--------------------|----------------------------|
Mini Basketball Hoop |                         48
Monopoly             |                         47
Uno Card Game        |                         44
Chutes & Ladders     |                         44
Classic Dominoes     |                         32

## Store Performance and Location Analysis

__7.__ Are there any geographical patterns in sales data?

See Tableau map for more detailed analysis.

__8.__ How do different store locations/regions contribute to overall revenue? (For the sake of brevity, we'll only show the top 7 contributors.)

```sql
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

SELECT TOP 7
store_name,
SUM(total_profits) AS total_profits,
ROUND((SUM(pct)),2) AS total_pct
FROM percents
GROUP BY store_name
ORDER by total_pct DESC
```

__Results:__

store_name      | total_profits |         total_pct
|---------------|-----------------|--------------------|
Maven Toys Ciudad de Mexico 2 |     169856|                 4.23
Maven Toys Guadalajara 3      |     121571|                 3.03
Maven Toys Ciudad de Mexico 1 |     111296|                 2.77
Maven Toys Monterrey 2        |     106783|                 2.66
Maven Toys Toluca 1           |     104612|                 2.61
Maven Toys Guadalajara 4      |     102178|                 2.55
Maven Toys Hermosillo 3       |     98825 |                 2.46


## Product Portfolio Analysis

__9.__ Which product categories contribute the most to overall revenue?

```sql
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
```

__Results:__

product_category|       total_profits |         total_pct
|-----------------|--------------------|-------------------|
Toys    |                     1079527  |              26.89
Electronics  |                1001437  |              24.95
Art & Crafts |                753354   |             18.77
Games       |                 673993   |              16.79
Sports & Outdoors   |         505718   |              12.6
