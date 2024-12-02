# Economía Unitaria
Mide el rendimiento por unidad (o usuario). Por ejemplo, en vez de hallar el ingreso promedio, se calcularía el ingreso promedio por cada usuario.

## ARPU
Average Revenue Per User, es una métrica utilizada en empresas basadas en suscripciones, telecomunicaciones, tecnología, servicios digitales y otras empresas que tienen una base de clientes recurrentes.

$$\text{ARPU} = \frac{Revenue}{cantidad\_usuarios}$$

**¿Qué nos indica?**

Cuanto nos genera, en promedio, cada cliente o usuario activo, sin considerar los costos asociados.

**¿Qué significa si aumenta o disminuye el ARPU?**

Si **aumenta**, hay un mayor ingreso por usuario (puede ser mediante el aumento de los precios, ventas cruzadas o mayor consumo por usuario). Si hay una **disminución**, puede ser por descuentos agresivos, menor consumo por usuario o pérdida de clientes de mayor valor.

**Planificación**

Sirve para tomar decisiones sobre precios, estrategias de retención, o desarrollo de productos.

**Segmentación del mercado**

Permite analizar la rentabilidad de diferentes segmentos de clientes (por region, plan de suscripción, etc.)

### Problema 1
Dave, de Finanzas, quiere estudiar el rendimiento de Delivr en términos de ingresos y pedidos por cada uno de sus usuarios. En otras palabras, quiere comprender la economía de sus unidades.

```SQL
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
```
Calculamos los ingresos totales por cada usuario, luego con esta tabla obtenemos el ingreso promedio general.

### Problema 2
A continuación, Dave quiere ver si el ARPU ha aumentado con el tiempo. Incluso si los ingresos de Delivr están aumentando, no está escalando bien si su ARPU está disminuyendo: está generando menos ingresos de cada uno de sus clientes.

```SQL
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
```
Nos aseguramos que la semana empiece por el día lunes (`SET DAYFIRST 1`), truncamos la fecha para tenerlos agrupados por semanas, además, calculamos el ingreso total y la cantidad de usuarios únicos. Posteriormente, se calcula el **ARPU**.


### Problema 3
Dave quiere agregar el valor promedio de pedidos por usuario a su estudio de economía unitaria, ya que más pedidos generalmente corresponden a más ingresos.

Calcule los pedidos promedio por usuario para Dave.

```SQL
WITH kpi AS(
SELECT 
user_id,
COUNT(DISTINCT order_id) AS cantidad
FROM orders
GROUP BY user_id
)

SELECT CONVERT(NUMERIC, AVG(cantidad)) FROM kpi;
```

---
## Histograma
Permite representar la distribución de un conjunto de datos **numéricos**. Divide los datos en intervalos (o 'bins') y muestra cuantos valores caen dentro de cada intervalo.

Si los valores (eje X) son contínuos o de alta cardinalidad, es preferible truncarlos a los decimales, centenas o millares para trabajar en intervalos. Si los valores, son discretos o de baja cardinalidad, tal vez no sería necesario truncarlos.

### Problema 4
Después de determinar que Delivr está logrando un buen desempeño en la ampliación de su modelo de negocios, 
Dave quiere explorar la distribución de los ingresos. Quiere ver si la distribución tiene forma de U o es normal
para ver cuál es la mejor manera de categorizar a los usuarios según los ingresos que generan.
Envíele a Dave una tabla de frecuencia de ingresos por usuario.

```SQL
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
```
Queremos que la frecuencia sea respecto a la cantidad de usuarios, al ser los ingresos valores contínuos y de alta cardinalidad, se trabajará en intervalos; es decir, tendremos que truncarlos (`ROUND(revenue, -2) AS revenue_100`) para poder agruparlos.
Como regla general, primero se realiza un `GROUP BY` a la variable que irá en el eje Y (`user_id`), es decir, la que será la frecuencia. Luego se utiliza `GROUP BY` a la variable que estará en el eje X (`revenue_100`), que será nuestro intervalo

### Problema 5
```SQL
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
```
En este caso queremos obtener cuantos usuarios realiza cierta cantidad de pedidos, en este caso, nuestro valor del eje X será la cantidad de pedidos (discreto y baja cardinalidad).


## Bucketing
Permite resumir la tabla de frecuencia (histograma) y presentar una distribución de un conjunto de datos de una manera más clara. En vez de agrupar por intervalos, se realiza mediante rangos o categorías (cubos) utilizando `CASE` en SQL Server.

### Problema 6
Según su análisis, Dave identificó que $150 es un buen límite para usuarios con ingresos bajos y $300 es un buen límite
para usuarios con ingresos medios. Quiere encontrar la cantidad de usuarios en cada categoría para ajustar el modelo comercial de Delivr.
Divida a los usuarios en grupos de ingresos bajos, medios y altos y obtenga el recuento de usuarios en cada grupo.
```SQL
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
```
Comenzamos de la misma forma que los histogramas, se calcula primero la cantidad de ingreso por usuarios. La segunda parte es donde cambia, en vez de truncar se categoriza (`CASE`).

### Problema 7
Dave está repitiendo su análisis de clasificación de pedidos para tener un perfil más completo de cada grupo.
Determinó que 8 pedidos es un buen límite para el grupo de pedidos bajos y 15 es un buen límite para el grupo de pedidos medianos.
Envíele a Dave una tabla de cada grupo de pedidos y cuántos usuarios hay en él.

```SQL
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
```

## Percentil
Un percentil es la medida estadística que divide un conjunto de datos en 100 partes iguales. Cada percentil indica el valor debajo del cual se encuentra un cierto porcentaje de los datos. Por ejemplo, el percentil 25 (p25) indica que el 25% de los datos son menores o iguales a a ese valor.

Los percentiles P25 y P75 se denominan cuartiles primero y tercero respectivamente. Mediante el **IQR** (Rango Intercuartílico) es una medida de dispersión que indica la amplitud del rango donde se encuentra el 50% central de los datos.
$$IQR = Q3-Q1$$
Con IQR se ignora los valores extremos, evitando los valores atípicos

Para identificar los valores atípicos se halla un rango mediante el IQR, todos los que están fuera de este rango son valores atípicos.

* Límite inferior
$$Q1-1.5*IQR$$

* Límite superior
$$Q3+1.5*IQR$$

Mediante el percentil P50 podemos obtener la mediana, si se calcula la media (`AVG()`) del conjunto de datos, podemos saber si nuestro conjunto de datos presenta una asimetría, si está sesgado positivamente (`AVG() > P50`), sesgado negativamente (`AVG() < P50`) o si es simétrico (`AVG() = P50`)


### Problema 8
Dave está terminando su estudio y quiere calcular algunas cifras más. Quiere averiguar los cuartiles de ingresos primero,
segundo y tercero. También quiere encontrar el promedio para ver en qué dirección están sesgados los datos.

Calcule los cuartiles de ingresos primero, segundo y tercero, así como el promedio.

```SQL
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
```
En **SQL SERVER**, es obligatorio el uso de `OVER()`, además estos te arrojan una tabla con valores repetidos de los percentiles por tal motivo es necesario usar una subconsulta para el cálculo del promedio y el uso de `DISTINCT` para solo obtener un resultado.

### Problema 9
El valor final que Dave desea es el recuento de usuarios en el rango intercuartil de ingresos (IQR). Los usuarios fuera del IQR
de ingresos son valores atípicos y Dave desea saber la cantidad de usuarios "típicos".
Devuelve el recuento de usuarios en el IQR de ingresos.

```SQL
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
```
Los CTE's creados son lo mismo que el problema anterior, solo que mejor ordenado. Ahora, sabemos que la tabla `percentil_revenue` solo tiene un único valor, los valores de los percentiles. Mientras que la tabla `user_revenue` tiene a todos los clientes con su respectivo ingreso generado a la empresa. Como queremos calcular la cantidad de usuarios que están dentro del **IQR**, necesitamos tener datos tanto de la tabla `user_revenue` como de `percentil_revenue`. Como no tenemos ningún campo clave, usamos `CROSS JOIN` el cual nos genera la combinación de ambas tablas, al ser solo un valor de la segunda tabla, no tendríamos problemas de datos repetidos. Solo estamos dando más campo a nuestra última consulta.

Veamos cómo se muestra esta consulta
```SQL
SELECT 
	*
FROM percentil_revenue p
CROSS JOIN user_revenue pr
```
|p25|p50|p75|user_id|revenue|
|---|---|---|---|---|
|120.68|186.50|268.31|0|262.75|
|120.68|186.50|268.31|261|203|
|...|

Con esta tabla ya podemos hacer un filtro (`WHERE`) para solo obtener la cantidad de usuarios que están dentro del intervalo del **IQR** (`WHERE pr.revenue > p.p25 AND pr.revenue < p.p75`).

