-- PROBLEMA 1
WITH datos_usuarios AS
(
SELECT
	o.user_id,
	SUM(m.meal_price*o.order_quantity) AS revenue
FROM meals m
INNER JOIN orders o ON o.meal_id=m.meal_id
GROUP BY o.user_id
)

SELECT ROUND(AVG(revenue), 2) FROM datos_usuarios;

-- PROBLEMA 2
DBCC USEROPTIONS
SET DATEFIRST 1

WITH kpi AS
(
SELECT
	DATETRUNC(WEEK, o.order_date) AS order_date2,
	SUM(m.meal_price*o.order_quantity) AS revenue,
	COUNT(DISTINCT o.user_id) AS cantidad_usuarios
FROM meals m
INNER JOIN orders o ON m.meal_id=o.meal_id
GROUP BY DATETRUNC(WEEK, o.order_date)
)

SELECT
	order_date2,
	ROUND(revenue/cantidad_usuarios, 2) AS ARPU
FROM kpi
ORDER BY order_date2;

-- PROBLEMA 3
WITH kpi AS(
SELECT 
user_id,
COUNT(DISTINCT order_id) AS cantidad
FROM orders
GROUP BY user_id
)

SELECT CONVERT(NUMERIC, AVG(cantidad)) FROM kpi;

-- PROBLEMA 4
WITH kpi AS(
SELECT 
	 o.user_id,
	 SUM(m.meal_price*o.order_quantity) AS revenue
FROM orders o
INNER JOIN meals m ON m.meal_id=o.meal_id
GROUP BY user_id
)
SELECT 
	COUNT(DISTINCT user_id) AS cantidad,
	ROUND(revenue, -2) AS revenue_100
FROM kpi
GROUP BY ROUND(revenue, -2);

-- PROBLEMA 5
WITH hist_pedidos AS (
SELECT
	user_id,
	COUNT(DISTINCT order_id) AS pedidos
FROM orders
GROUP BY user_id
)
SELECT 
	pedidos,
	COUNT(DISTINCT user_id) AS usuarios
FROM hist_pedidos
GROUP BY pedidos
ORDER BY pedidos;

-- PROBLEMA 6
WITH buck_ingresos AS (
SELECT
	user_id,
	SUM(m.meal_price*o.order_quantity) AS revenue
FROM orders o
INNER JOIN meals m ON m.meal_id=o.meal_id
GROUP BY user_id
)
SELECT
	CASE 
		WHEN revenue<150 THEN 'ingreso_bajo'
		WHEN revenue<300 THEN 'ingreso_medio'
		ELSE 'ingreso_alto'
	END AS revenue_category,
	COUNT(DISTINCT user_id) AS users
FROM buck_ingresos
GROUP BY  CASE 
		WHEN revenue<150 THEN 'ingreso_bajo'
		WHEN revenue<300 THEN 'ingreso_medio'
		ELSE 'ingreso_alto'
	END;

-- PROBLEMA 7
WITH buck_pedidos AS (
SELECT
	user_id,
	COUNT(DISTINCT order_id) AS orders
FROM orders
GROUP BY user_id
)
SELECT 
	CASE
		WHEN orders < 8 THEN 'pedido_bajo'
		WHEN orders < 15 THEN 'pedido_medio'
		ELSE 'pedido_alto'
	END AS orders_category,
	COUNT(DISTINCT user_id) AS users
FROM buck_pedidos
GROUP BY CASE
		WHEN orders < 8 THEN 'pedido_bajo'
		WHEN orders < 15 THEN 'pedido_medio'
		ELSE 'pedido_alto'
	END;

-- PROBLEMA 8
WITH percentil_revenue AS (
SELECT
	o.user_id,
	SUM(m.meal_price*o.order_quantity) AS revenue
FROM orders o
INNER JOIN meals m ON m.meal_id=o.meal_id
GROUP BY o.user_id
)
SELECT DISTINCT
	(SELECT AVG(revenue) FROM percentil_revenue) AS promedio,
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) 
	OVER () AS p25,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue)
	OVER () AS p50,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue)
	OVER () AS p75
FROM percentil_revenue;

-- PROBLEMA 9
WITH user_revenue AS (
SELECT
	o.user_id,
	SUM(m.meal_price*o.order_quantity) AS revenue
FROM orders o
INNER JOIN meals m ON m.meal_id=o.meal_id
GROUP BY o.user_id
), 
percentil_revenue AS(
SELECT DISTINCT
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue)
	OVER () AS p25,
	PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY revenue)
	OVER () AS p50,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue)
	OVER () AS p75
FROM user_revenue
)
SELECT 
	COUNT(DISTINCT user_id) AS usuarios
FROM percentil_revenue p
CROSS JOIN user_revenue pr
WHERE pr.revenue > p.p25 AND
	  pr.revenue < p.p75;