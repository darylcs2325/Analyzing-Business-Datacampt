-- PROBLEMA 1
SELECT 
	order_date,
	FORMAT(order_date, 'dd dddd, MMMM yyyy', 'es-PE') AS fecha_formateada
FROM orders
GO

SQL
SELECT 
	order_date,
	FORMAT(order_date, 'D', 'es-PE') AS fecha_formateada
FROM orders

-- PROBLEMA 2
WITH pedidos_usuarios AS (
SELECT
	user_id,
	COUNT(DISTINCT order_id) AS pedidos
FROM orders
WHERE MONTH(order_date) = '08'
GROUP BY user_id
)
SELECT TOP(3)
	user_id,
	pedidos,
	RANK() OVER (ORDER BY pedidos DESC) AS puesto
FROM pedidos_usuarios

-- PROBLEMA 3
WITH user_revenue AS (
SELECT  
	user_id,
	DATETRUNC(MONTH, o.order_date) AS fecha,
	SUM(m.meal_price*o.order_quantity) AS revenue
FROM orders o
INNER JOIN meals m ON m.meal_id=o.meal_id
WHERE MONTH(o.order_date) IN ('06', '07', '08')
GROUP BY user_id, DATETRUNC(MONTH, o.order_date)
)
SELECT 
	user_id,
	[2018-06-01], [2018-07-01], [2018-08-01]
FROM 
	(
	SELECT user_id, fecha, revenue
	FROM user_revenue
	) AS tabla
PIVOT(
	SUM(revenue) FOR fecha IN ([2018-06-01], [2018-07-01], [2018-08-01])
) AS tabla_pivot;

-- PROBLEMA 4
WITH costos AS (
SELECT
	m.eatery,
	s.stocking_date,
	SUM(m.meal_cost*s.stocked_quantity) AS costo
FROM stock s
INNER JOIN meals m ON s.meal_id=m.meal_id
WHERE MONTH(s.stocking_date) IN ('11', '12')
GROUP BY m.eatery, s.stocking_date
)
SELECT 
	eatery,
	[2018-11-01], [2018-12-01]
FROM (
	SELECT eatery, stocking_date, costo
	FROM costos
) AS tabla
PIVOT(
	SUM(costo) FOR stocking_date IN ([2018-11-01], [2018-12-01])
) AS tabla_pivot;

-- PROBLEMA 5
WITH orders_users AS (
SELECT
	m.eatery,
	DATETRUNC(QUARTER, o.order_date) AS trimestre,
	COUNT(DISTINCT o.user_id) AS usuarios
FROM orders o
INNER JOIN meals m ON o.meal_id=m.meal_id
GROUP BY m.eatery, DATETRUNC(QUARTER, o.order_date)
),
rank_users AS (
SELECT
	eatery,
	trimestre,
	usuarios,
	RANK() OVER (PARTITION BY trimestre ORDER BY usuarios DESC) AS ranking
FROM orders_users
)
SELECT
	eatery,
	[2018-04-01], [2018-07-01], [2018-10-01]
	
FROM (
	SELECT eatery, trimestre, ranking
	FROM rank_users
) AS tabla
PIVOT(
	MAX(ranking) FOR trimestre IN ([2018-04-01], [2018-07-01], [2018-10-01])
) AS tabla_pivot
