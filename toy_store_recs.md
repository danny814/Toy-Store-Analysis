# Toy Store SQL Analysis

## Analysis-Based Recommendations 

### 1. Sales Performance Analysis

__1.0 Optimize inventory levels based on high-demand products.__<br />
 The top 5 sellers across all store locations are:

1. Colorbuds
2. PlayDoh Can
3. Barrel O' Slime
4. Deck Of Cards
5. Magic Sand 

Stock levels for these products in particular should be increased so that there are no stockouts and subsequent gaps in their sales.

__1.1 Adjusting marketing strategies to capitalize on seasonal trends.__ <br />
The top 5 days of the month for sales are as follows:

day_of_month| num_sales
|-----------|------------|
1 |           30007
15|           29225
2 |           28682
17|           28492
3 |           28199

We notice that these days are those which are closest to the 15th and the 1st of each month, which is when most biweekly paychecks are deposited. Weekends (specifically, Saturday and Sunday) have shown significantly more sales than weekdays, which should also have an effect on promotion/sale dates. Sales and promotions should begin just before or on the 15th and the 1st to maximize potential profits around this trend.

### 2. Inventory Management

__2.0 Optimization of the current inventory system.__ <br/>
In its current state, the inventory restocking system shows room for improvement. Based on the data within the timeframe, we observed an average of 11 stockouts per week per store. Steps should be taken to increase the quantity of items restocked to achieve the minimum amount of restocking trips and the maximum return. Minimum stock levels for products should be established based on historical sales data (average units per week) to reduce the potential for stockouts. These minimums should be dynamic  and adjust according to changes in average weekly units. 

Once these dynamic minimums are established for each product at each store, an automatic restocking system should be prototyped at locations on both ends of the success spectrum. With enough success and modifications, the system can be implemented across all chain locations.

__2.1 Approach for slow-movers.__<br />

Slow movers' effect on profit loss will be reduced with the introduction of the dynamic minimums system. Discounts and promotions (such as 25% off, reduced price with the purchase of a more popular product, etc.) can be used in conjunction for very slow and obsolete products to reduce shelf life. Products that have consistently proved to be slow movers can be labeled as obsolete and considered for replacement/removal. For instance, the following products have consistently sold less than 100 times across all 50 store locations per week:

product_name|                      num_slow_weeks
|--------------------|----------------------------|
Mini Basketball Hoop |                         48
Monopoly             |                         47
Uno Card Game        |                         44
Chutes & Ladders     |                         44
Classic Dominoes     |                         32

Replacement of products should be geared towards more popular/consistent products.

### 3. Store Performance and Location Analysis

__3.0 Reallocating resources to high-performing locations.__<br/>

Resources and minimum staff levels should reflect a store's average sales volume. Similar to the dynamic restocking system, a store's average volume can be used to base minimum resources/staff needed in a given week.

__3.1 Adjust marketing strategies based on regional preferences.__<br />

Preferences of both regions of Mexico and states of Mexico should be considered for future marketing strategies. Promotions should reflect regional/state preferences to best reflect customer preferences. More customer data should be collected and utilized to create more targeted marketing strategies. Such can be achieved with loyalty programs, store credit-cards, email subscriptions, app usage, and purchase histories.

### 4. Product Portfolio Analysis

__4.0 Allocate resources to promote and develop high-performing product categories.__ <br />

Products deemed obsolete should be replaced by products with similar aspects to those in the highest-performing categories. Resources should be reallocated towards the best performing brands and product lines to maximize sales potential and minimize wasted shelf space.

