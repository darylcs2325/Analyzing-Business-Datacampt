-- Problema 1
SELECT 
    SUM(s.stocked_quantity*m.meal_cost) AS CostoTotal
FROM stock s
INNER JOIN meals m ON s.meal_id=m.meal_id;

-- Problema 2
SELECT 
	SUM(o.order_quantity*m.meal_price) AS revenue
FROM orders o
INNER JOIN meals m ON o.meal_id=m.meal_id
WHERE o.user_id=15;

-- Problema 3
SELECT 
	DATETRUNC(WEEK, order_date) AS delivr_week,
	SUM(M.meal_price*O.order_quantity)
FROM orders O
INNER JOIN meals M ON M.meal_id = O.meal_id

WHERE MONTH(order_date) = '06'
GROUP BY DATETRUNC(WEEK, order_date)
ORDER BY delivr_week ASC;

-- Problema 4
SELECT 
    SUM(s.stocked_quantity*m.meal_cost) AS CostoTotal
FROM stock s
INNER JOIN meals m ON s.meal_id=m.meal_id;

-- Problema 5
SELECT TOP(5)
	s.meal_id, 
	SUM(s.stocked_quantity*m.meal_cost) AS Costo
FROM stock s
INNER JOIN meals m ON s.meal_id=m.meal_id
GROUP BY s.meal_id
ORDER BY Costo DESC;

-- Problema 6
WITH costo_mensual AS (
SELECT s.stocking_date, SUM(s.stocked_quantity*m.meal_cost) Costo FROM stock s
INNER JOIN meals m ON s.meal_id=m.meal_id
GROUP BY s.stocking_date
HAVING MONTH(s.stocking_date) <9
)
SELECT AVG(Costo) FROM costo_mensual;

-- Problema 7
WITH revenue AS
(SELECT 
	m.eatery,
	SUM(o.order_quantity*m.meal_price) AS revenue
FROM orders o
INNER JOIN meals m ON o.meal_id=m.meal_id
GROUP BY m.eatery
),
cost AS(
SELECT
	m.eatery,
	SUM(s.stocked_quantity*m.meal_cost) AS cost
FROM stock s
INNER JOIN meals m ON s.meal_id=m.meal_id
GROUP BY m.eatery)

SELECT r.eatery, (r.revenue - c.cost) AS profit FROM revenue r
INNER JOIN cost c ON r.eatery=c.eatery
ORDER BY profit DESC;

-- Problema 8
WITH revenue_months AS
(SELECT 
	DATETRUNC(MONTH, o.order_date) AS date_month,
	SUM(o.order_quantity*m.meal_price) AS revenue
FROM orders o
INNER JOIN meals m ON o.meal_id=m.meal_id
GROUP BY DATETRUNC(MONTH, o.order_date)
),
cost_months AS(
SELECT
	DATETRUNC(MONTH, s.stocking_date) AS date_month,
	SUM(s.stocked_quantity*m.meal_cost) AS cost
FROM stock s
INNER JOIN meals m ON s.meal_id=m.meal_id
GROUP BY DATETRUNC(MONTH, s.stocking_date))

SELECT r.date_month, (r.revenue - c.cost) AS profit FROM revenue_months r
INNER JOIN cost_months c ON r.date_month=c.date_month
ORDER BY profit;