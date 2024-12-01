-- Problema 1
WITH user_reg AS
(
SELECT 
	user_id,
	MIN(order_date) AS reg_date
FROM orders
GROUP BY user_id
)

SELECT 
	DATETRUNC(MONTH, reg_date),
	COUNT(user_id) AS nuevos
FROM user_reg
GROUP BY DATETRUNC(MONTH, reg_date)
ORDER BY nuevos;

-- PROBLEMA 2
SELECT 
	DATETRUNC(MONTH, order_date) AS delivr_month,
	COUNT(DISTINCT user_id) AS MAU
FROM orders
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY delivr_month;

-- PROBLEMA 3
WITH user_reg AS
(SELECT  
	user_id,
	MIN(order_date) AS date_reg
FROM orders
GROUP BY user_id
),
month_reg AS
(
	SELECT
		DATETRUNC(MONTH, date_reg) AS date_month,
		COUNT(user_id) AS cantidad 
	FROM user_reg
	GROUP BY DATETRUNC(MONTH, date_reg)
)

SELECT 
	date_month,
	cantidad,
	SUM(cantidad) OVER (ORDER BY date_month)
FROM month_reg
ORDER BY date_month;

-- PROBLEMA 4
WITH MAU AS(
SELECT 
	DATETRUNC(MONTH, order_date) AS mes,
	COUNT(DISTINCT user_id) AS usuarios_activos
FROM orders
GROUP BY DATETRUNC(MONTH, order_date)
)
SELECT 
	mes,
	usuarios_activos,
	LAG(usuarios_activos, 1, 0) OVER (ORDER BY usuarios_activos)
FROM MAU
ORDER BY mes
;

-- PROBLEMA 5
WITH MAU AS 
(
SELECT 
	DATETRUNC(MONTH, order_date) AS mes,
	COUNT(DISTINCT user_id) AS mau
FROM orders
GROUP BY DATETRUNC(MONTH, order_date)
)
SELECT 
	mes,
	mau,
	mau - LAG(mau, 1, 0) OVER (ORDER BY mes) AS delta
FROM MAU
ORDER BY mes;

-- PROBLEMA 6
WITH MAU AS 
(
SELECT 
	DATETRUNC(MONTH, order_date) AS mes,
	CONVERT(NUMERIC, COUNT(DISTINCT user_id)) AS mau
FROM orders
GROUP BY DATETRUNC(MONTH, order_date)
),
LAG_MAU AS
(
SELECT
	mes,
	mau,
	LAG(mau, 1, 1.0) OVER (ORDER BY mes) AS last_mau
FROM MAU
)
SELECT 
	mes,
	mau,
	ROUND((mau - last_mau)/last_mau, 2) AS growth
FROM LAG_MAU
ORDER BY mes;

-- PROBLEMA 7
WITH pedidos_mensual AS
(SELECT
	DATETRUNC(MONTH, order_date) AS mes,
	COUNT(DISTINCT order_id) AS pedidos
FROM orders
GROUP BY DATETRUNC(MONTH, order_date)
),
lag_pedidos AS
(
SELECT 
	mes,
	CAST(pedidos AS NUMERIC(10,2)) AS pedidos,
	LAG(pedidos, 1, 1.0) OVER (ORDER BY mes) AS pedidos_anterior
FROM pedidos_mensual
)

SELECT
	mes,
	pedidos,
	pedidos_anterior,
	ROUND((pedidos-pedidos_anterior)/pedidos_anterior, 2)
FROM lag_pedidos;

-- PROBLEMA 8
WITH actividad_mensual_usuarios AS(
SELECT DISTINCT
	DATETRUNC(MONTH, order_date) AS mes,
	user_id
FROM orders
)
SELECT 
	previo.mes,
	COUNT(previo.user_id) AS previo,
	COUNT(actual.user_id) AS actual,
	ROUND(CAST(COUNT(actual.user_id) AS FLOAT)/CAST(COUNT(previo.user_id) AS FLOAT), 2)
FROM actividad_mensual_usuarios previo
LEFT JOIN actividad_mensual_usuarios actual
ON previo.user_id=actual.user_id
	AND previo.mes=DATEADD(MONTH, -1, actual.mes)
GROUP BY previo.mes
ORDER BY previo.mes


SELECT DISTINCT
	DATETRUNC(MONTH, order_date) AS mes,
	user_id
FROM orders;
