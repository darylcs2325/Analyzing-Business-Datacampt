# Generación de reportes ejecutivos
En este capítulo se verá nuevas funciones para tener un reporte legible.

## Fechas
El objetivo es pasar una columna de tipo `DATETIME` a uno del estilo *lunes 02 de diciembre del 2024* o *lun 01-dic 2024*. Un formato entendible para cualquier usuario.

En **SQL Server** se utiliza `CONVERT()` para convertir un tipo de dato a otro, a diferencia de `CAST()`, hay más opciones para fechas. También existe `FORMAT(dato, format, cultura)`, que es una función general para dar un formato a los tipos de datos.

## RANK()
Este es un **Windows Function**, el cual "ranquea" los datos, indicando quien es el 1ro, 2do, 3ro, etc.
`RANK() OVER (ORDER BY <column_name>)`

### Problema 1
Eve, del equipo de Business Intelligence (BI), te informa que necesitará tu ayuda para escribir consultas para los informes.
Los informes son leídos por ejecutivos de alto nivel, por lo que deben ser lo más legibles y rápidos de escanear posible. 
Eve te dice que el formato de fecha preferido por los ejecutivos de alto nivel es algo así como viernes 01, junio de 2018 para el 01/06/2018.
```SQL
SELECT 
	order_date,
	FORMAT(order_date, 'dd dddd, MMMM yyyy', 'es-PE') AS fecha_formateada
FROM orders
```
```SQL
SELECT 
	order_date,
	FORMAT(order_date, 'D', 'es-PE') AS fecha_formateada
FROM orders
```
Para lo que nos pide, el primer bloque de código es el correcto, el segundo es para uno de estilo `viernes, 1 de junio de 2018`, muy parecido y con poco código.

### Problema 2
Eve te dice que quiere informar qué ID de usuario tienen más pedidos cada mes. No quiere mostrar números largos, 
que solo distraerán a los ejecutivos de nivel C, por lo que solo quiere mostrar sus rangos. El primer puesto corresponde 
al usuario con más pedidos, el segundo puesto corresponde al usuario con el segundo puesto, y así sucesivamente.
Envíale a Eve una lista de los 3 primeros ID de usuario por pedidos en agosto de 2018 con sus rangos.

```SQL
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
```
Como todos los datos son del 2018, solo se filtra el mes; también se puede hacer con `DATETRUNC` en caso que hubiese más años.

Obtenemos los usuarios con su cantidad de pedidos y luego lo "ranqueamos"

## PIVOT
Cuando queremos remodelar nuestro conjunto de datos, con el fin de pasar una fila a columna (transponer). Esta rotación se realiza entorno a una columna pivote. Esto es conveniente en casos donde una o más columnas se repiten con un mismo valor (producto, año, mes, region, etc)
![alt text](image.png)

**Sintáxis**
```SQL
SELECT [columnas fijas],
       [valor_pivot_1], [valor_pivot_2], ...
FROM (
    -- Subconsulta que obtiene los datos a pivotear
    SELECT columna_clave, columna_a_convertir, valor
    FROM tabla
) AS source_table
PIVOT (
    -- Operación de agregación (SUM, AVG, COUNT, etc.)
    agregacion(valor) FOR columna_a_convertir IN ([valor_pivot_1], [valor_pivot_2], ...)
) AS pivot_table;
```

### Problema 3
A continuación, Eve te dice que los ejecutivos de nivel C prefieren las tablas anchas en lugar de las largas porque son más fáciles de escanear. 
Ella preparó un informe de muestra de los ingresos de los usuarios por mes, en el que se detallan los ingresos de los primeros 5 ID de usuario
desde junio hasta agosto de 2018. Los ejecutivos le pidieron que dinamizara la tabla por mes. Ella te delegó esa tarea.
Dinamiza la consulta de ingresos de usuarios por mes de modo que el ID de usuario sea una fila y cada mes desde junio hasta agosto de 2018 sea una columna.

```SQL
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
) AS tabla_pivot
;
```
Se genera la tabla de usuarios y los ingresos generados a la empresa.

Se indica el nombre de la tabla que se mantendrá (`user_id`), el nombre de las columnas que se generará (estas son los valores de la columna fecha `[2018-06-01], [2018-07-01], [2018-08-01]`). En la subconsulta, el `SELECT user_id, fecha, revenue` indica la **columna clave**, **columna a convertir**, **valor**, respectivamente. Finalmente, se realiza un `PIVOT` el cual indica el **valor** que estarán en las columnas generadas que pertenecen a la columna `fecha`

### Problema 4
Los ejecutivos de nivel C le dicen a Eve que quieren un informe sobre los costos totales por restaurante en los últimos dos meses.
Primero, escriba una consulta para obtener los costos totales por restaurante en noviembre y diciembre de 2018, luego haga una pivotación por mes.
```SQL
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
```

## Redactar un informe
Los informes son leidos por los altos ejecutivos, por tal motivo, es necesario presentar uno que sea de fácil lectura. Aquí algunos consejos:

* Formato de fechas redactables (lunes 02 de diciembre del 2024, o parecidos)
* Redondear a dos decimales, si es necesario.
* Si la tabla es larga (muchas filas, pocas columnas) ver si es posible realizar un Pivot, tomando como columna clave a la fecha, producto, region, etc.
* Ordenar los valores si es posible o necesario agregar `RANK()`.

### Problema 5
Eve quiere elaborar un informe ejecutivo final sobre las clasificaciones de los restaurantes según la cantidad de usuarios 
únicos que realizan pedidos en ellos por trimestre. Dijo que se encargará de la dinámica, por lo que solo necesita preparar 
la tabla de origen para que ella realice la dinámica.
Envíe a Eve una tabla de usuarios únicos que realizan pedidos por restaurante y por trimestre.
```SQL
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
```
Primero se  obtiene la tabla de restaurantes con la cantidad de usuarios que han pedido, estos agrupados por trimestres. Luego se realiza un `RANK()` particionando por trimestres; es decir, cada trimestre tendrá un propio ranking de los restaurantes con mayor pedidos. Finalmente, se realiza un `PIVOT()` separando por el trimestre y en valor estará el ranking de cada restaurante que tuvo en cada trimestre.