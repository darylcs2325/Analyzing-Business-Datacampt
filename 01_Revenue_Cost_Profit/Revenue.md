# REVENUE
Hace referencia a la Ganancia Bruta o los ingresos, total de dinero recibido por las ventas, sin contar los costos.

## Problema 1
¡Te han contratado en Delivr como analista de datos! Una clienta acaba de llamar al equipo de Atención al cliente de Delivr; quiere comprobar si sus recibos cuadran. Según sus recibos, calculó que su factura total en Delivr es de $271 y quiere asegurarse de eso. Su ID de usuario es 15.
```SQL
SELECT 
	SUM(o.order_quantity*m.meal_price) AS revenue
FROM orders o
INNER JOIN meals m ON o.meal_id=m.meal_id
WHERE o.user_id=15
;
```
Para saber el pago total que hizo la cliente, se toma en cuenta el precio del menú (`meal_price`) por la cantidad que compró de dicho menú.

## Problema 2
El primer mes completo de operaciones de Delivr fue junio de 2018. En el lanzamiento, el equipo de marketing realizó una campaña publicitaria en canales de comida populares en la televisión, y la cantidad de anuncios aumentó cada semana hasta fin de mes. La directora de marketing le pide que la ayude a evaluar el éxito de esa campaña.


```SQL
SELECT 
	DATETRUNC(WEEK, order_date) AS delivr_week,
	SUM(M.meal_price*O.order_quantity)
FROM orders O
INNER JOIN meals M ON M.meal_id = O.meal_id

WHERE MONTH(order_date) = '06'
GROUP BY DATETRUNC(WEEK, order_date)
ORDER BY delivr_week ASC;
```
Con `DATETRUNC` podemos truncar la fecha estableciendo su `DATE_PART`, en este case es `WEEK`. Como solo queremos del **mes de junio**, hacemos un filtro que solo queremos donde `MONTH(order_date)='06'`. Cabe recalcar que para nosotros el **inicio de la semana** son los días **lunes**, por lo que es bueno verificar nuestras opciones de la sesión, mediante `DBCC USEROPTIONS`, este nos arrojará una lista de las opciones que tenemos, puede ser la siguiente

|Set Option|Value|
|---|---|
|textsize|...|
|...|...|
|datefirst|7|
|...|...|

Anteriormente, estaba configurado, por defecto, que el primer día de la semana sea domingo (7), podemos setearlo a lunes (1)

`SET DATEFIRST 1`

# COST


## Problema 1

¿Cuál es el costo total de Delivr desde que inició operaciones?

```sql
SELECT 
    SUM(s.stocked_quantity*m.meal_cost) AS CostoTotal
FROM stock s
INNER JOIN meals m ON s.meal_id=m.meal_id

```

De nuestra tabla `stock` que representa todos las compras que se ha realizado (costos), como solo vendemos lo que compramos, mediante un `INNER JOIN` se obtiene de la tabla `meals` el precio de cada menú para obtener el costo total.


## Problema 2
Alice de Finanzas quiere saber cuáles son las 5 comidas más consumidas por Delivr en términos de costo total; en otras palabras, Alice quiere saber las 5 comidas en las que Delivr ha gastado más para abastecerse.

```SQL
SELECT TOP(5)
	s.meal_id, 
	SUM(s.stocked_quantity*m.meal_cost) AS Costo
FROM stock s
INNER JOIN meals m ON s.meal_id=m.meal_id
GROUP BY s.meal_id
ORDER BY Costo DESC
```

## Problema 3
Alice quiere saber cuánto gastó Delivr por mes en promedio durante sus primeros meses (antes de septiembre de 2018). Deberá escribir dos consultas para resolver este problema:

```SQL
WITH costo_mensual AS (
SELECT s.stocking_date, SUM(s.stocked_quantity*m.meal_cost) Costo FROM stock s
INNER JOIN meals m ON s.meal_id=m.meal_id
GROUP BY s.stocking_date
HAVING MONTH(s.stocking_date) <9
)
SELECT AVG(Costo) FROM costo_mensual;
```

> [!NOTE]
Nos indica **gasto mensual promedio**, no dice **gasto promedio por cada mes**. Por lo que tenemos que calcular el gasto total de cada mes y luego de tener los gastos mensuales, calculamos su promedio. 


# PROFIT

Es la Ganancia Neta que se obtiene por nuestros servicios, es 
la que se obtiene de la resta entre $\text{Revenue} - \text{Cost}$.

## Problema 1
Delivr está renegociando sus contratos con sus restaurantes. Cuanto mayor sea la ganancia que genere un restaurante, mayor será la tarifa que Delivr está dispuesto a pagarle por la compra de comidas al por mayor.
El equipo de Desarrollo comercial le pide que averigüe cuántas ganancias genera cada restaurante para fortalecer sus posiciones de negociación.

```SQL
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
ORDER BY profit DESC
```
Puede haber una confusión a la hora de realizar el cálculo de las ganancias netas que se obtiene con cada restaurante. El error surge cuando hacemos lo siguiente, `SUM(order_quantity*(meal_price-meal_cost))` ya que estaríamos calculando el profit de la ventas individual; sin embargo, queremos del total, para ello, debemos calcular:

Ingresos totales por las ventas realizadas (`SUM(order_quantity*meal_price)`).

Gastos totales por la compra de los menus (`SUM(stocked_quantity*meal_cost`).

$\text{Ingresos} - \text{Costos}$

## Problema 2
Después de priorizar y cerrar acuerdos con los restaurantes según sus ganancias generales, Alice quiere hacer
un seguimiento de las ganancias de Delivr por mes para ver qué tan bien le está yendo. Estás aquí para ayudar.

````SQL
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
ORDER BY profit
```