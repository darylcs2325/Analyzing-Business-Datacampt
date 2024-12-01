# KPI centrado en Clientes
Estos KPI miden el rendimiento y satisfacción de los clientes, así como la relación de una empresa con ellos. Se enfoca en la experiencia de cliente, retención, crecimiento y lealtad. Dependiendo del rubro que se quiera trabajar, se escogerá ciertos indicadores. Para el curso se aborda los siguientes indicadores:

* Registros
* Usuarios activos
* Crecimiento
* Retención

## Registros
Mide la capacidad de atraer a nuevos clientes o usuarios a nuestro servicio, pudiendo ser en la creación de una cuenta en la aplicación, abrir una cuenta bancaria, etc.

Por lo general, las fechas de registro se almacenan en una tabla que contiene los metadatos de los usuarios. Sin embargo, Delivr solo considera que un usuario está registrado si ha realizado al menos un pedido. La fecha de registro de un usuario de Delivr es la fecha del primer pedido de ese usuario.

### Problema 1
Bob, el gerente de relaciones con inversores de Delivr, está preparando una presentación para una reunión con posibles inversores. Quiere agregar un gráfico de líneas de registros por mes para destacar el éxito de Delivr en la captación de nuevos usuarios.

```SQL
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
```
Se requiere de dos pasos, el primero es obtener la fecha mínima de cada usuario cuando realizó el pedido, esto sería la fecha de registro del usuario; luego, ya teniendo la tabla (`WITH user_reg`) de cada usuario con su fecha de registro obtenemos la cantidad de usuarios que se registraron cada mes, para ello truncamos al mes las fechas (`DATETRUNC(MONTH, reg_date)`) y lo agrupamos, luego contamos la cantidad usuarios registrados, como en la tabla anterior se agrupó por `user_id`, ya no es necesario aplicar un `COUNT(DISTINCT user_id)`.


## Usuarios activos
Evalúa qué tan involucrados están los usuarios existentes con los servicios o productos.

**Adherencia** ($\frac{DAU}{MAU}$) : Mide el nivel de compromiso (usuarios activos) hacia el servicio, compara el porcentaje de usuarios activos diarios (DAU) frente a los usuarios activos mensual (MAU). 

Ejemplo:

DAU: 50,000 usuarios **únicos** interactuando con la aplicación diariamente.

MAU: 200,000 usuarios **únicos** interactúan al menos una vez al mes.

El 25% de los usuarios mensuales son también usuarios diarios.

### Problema 2
Bob predice que los inversores no se conformarán con los registros por mes. También querrán saber cuántos usuarios usaron realmente Delivr. Decidió incluir otro gráfico de líneas de los usuarios activos mensuales (MAU) de Delivr; le pidió que le envíe una tabla de usuarios activos mensuales.

```SQL
SELECT 
	DATETRUNC(MONTH, order_date) AS delivr_month,
	COUNT(DISTINCT user_id) AS MAU
FROM orders
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY delivr_month;
```
Se calcula la cantidad de **usuarios únicos** que interactuán por lo menos una vez al día, por tal motivo se realiza el `COUNT(DISTINCT user_id)`.

### Problema 3
Tienes una sugerencia para la presentación de Bob: en lugar de mostrar las inscripciones por mes en el gráfico de líneas, puede mostrar el total acumulado de inscripciones por mes. De esa manera, los números son más grandes, ¡y a los inversores siempre les gustan los números más grandes! Él está de acuerdo y comienzas a trabajar en una consulta que devuelve una tabla del total acumulado de inscripciones por mes.

```SQL
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
```

Hacemos uso de dos CTE (`user_reg`, `month_reg`) donde el primero tiene la fecha del primer pedido que realizó cada usuario, en nuestro caso esta fecha sería el día que se registró el usuario. La segunda tabla contiene la cantidad de registro por mes, uniendo ambas tablas podemos hacer uso de las **Windows Function** para obtener la suma acumulada por cada mes de los usuarios registrados.



### Problema 4
Carol, del equipo de Producto, notó que estás trabajando con muchos KPI centrados en el usuario para la presentación de Bob. 
Mientras estás en ello, dice, puedes ayudar a desarrollar una idea suya que involucre un KPI centrado en el usuario. 
Quiere crear un monitor que compare los MAU del mes anterior y el actual, lo que alertará al equipo de Producto si los usuarios 
activos del mes actual son menores que los del mes anterior.
Para comenzar, escribe una consulta que devuelva una tabla de MAU y el MAU del mes anterior para cada mes

```SQL
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
```
La tabla CTE `MAU` contiene la cantidad de usuarios únicos que utilizan al menos una vez la aplicación para el pedido de comida por cada mes. utilizamos esta tabla para presentar mediante un el Windows Function `LAG()` para mostrar la cantidad de `MAU` del mes anterior.

## CRECIMIENTO
Este KPI nos indica el crecimiento que tiene un campo respecto a un tiempo anterior. Para obtener este KPI, primero se debe calcular su **delta** (diferencia entre el valor actual y el anterior), luego dividirlo por el valor previo, obteniendo la **tasa de crecimiento** respecto al valor base

### Problema 5
Ahora que ha creado la base para el monitor de MAU de Carol, escriba una consulta que devuelva una tabla de meses y las diferencias de los MAU actuales y anteriores de cada mes.

Si la diferencia es negativa, hubo menos usuarios activos en el mes actual que en el mes anterior, lo que hace que el monitor genere una señal de alerta para que el equipo de productos pueda investigar.

```SQL
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
```
En la tabla `MAU` está la lista de los usuarios únicos activos mensual, luego en una nueva consulta agregamos una nueva columna que tendrá la diferencia del mes actual con la anterior para saber la cantidad de usuarios que aumentó o disminuyó.

### Problema 6
Carol está muy satisfecha con su última consulta, pero solicitó un cambio: prefiere tener la tasa de crecimiento de MAU mes a mes (MoM) en lugar de un delta bruto de MAU. De esa manera, el monitor de MAU puede tener activadores más complejos, como generar una bandera amarilla si la tasa de crecimiento es del -2 % y una bandera roja si la tasa de crecimiento es del -5 %.

Escriba una consulta que devuelva una tabla de meses y la tasa de crecimiento de MAU mes a mes para finalizar el monitor de MAU.

```SQL
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
```
En este caso, hacemos uso de un segunda tabla CTE que contiene valores de los meses anteriores, para evitar futuros problemas a la hora de utilizar el `last_mau` colocamos como valor por defecto a `1.0` ya que lo usaremos como denominador. Utilizando las tablas CTE's, calculamos la tasa de crecimiento, redondeamos los resultados a dos decimales, cabe recalcar que el uso de `ROUND()` tiene efecto cuando tratamos con valores de tipo flotante o punto decimal.

### Problema 7
Bob necesita un gráfico más para concluir su presentación. Ha hablado de la ganancia de nuevos usuarios de Delivr, sus crecientes MAU y sus altas tasas de retención. Sin embargo, falta algo. En toda la presentación, no hay una sola mención del mejor indicador de la actividad de los usuarios: ¡los pedidos de los usuarios! Cuantos más pedidos hacen los usuarios, más activos son en Delivr y más dinero genera Delivr.

Envíele a Bob una tabla con las tasas de crecimiento de pedidos intermensuales.

```SQL
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
```

Como un solo pedido puede contener varios tipos de menús, entonces vamos a encontrar varias veces un mismo `order_id` repetidos en la tablas `orders`. Como solo queremos contar la cantidad de veces que el usuario ha realizado un pedido (no importa si en un pedido hay 2 menús o solo 1), hacemos una cuenta con `DISTINCT()` del `order_id`.

## RETENCIÓN
Hasta lo último que hemos visto, hemos contados los usuarios activos, pero dentro de este grupo también están los usuarios que se registraron por primera vez, ya que solo se hizo un conteo general (`COUNT(user_id)`). Los usuarios activos se pueden dividir en tres grupos:
* Usuarios nuevos (KPI registros)
* Usuarios retenidos: Usuarios que estuvieron activos el mes anterior y se mantuvieron activos este mes.
* Usuarios resucitados: Son usuarios antiguos que estuvieron inactivos el mes anterior, pero que volvieron a la actividad este mes.

La tasa de retención es el porcentaje  de usuarios que fueron retenidos desde el úlitmo mes hasta este.

$$\text{Retention rate} = \frac{U_c}{U_p}$$

Donde,

$U_c$ es la cantidad de usuarios únicos que estaban activos tanto el mes anterior como el mes actual. $U_p$ son los usuarios únicos que estaban activos el mes anterior.



### Problema 8
Bob ha solicitado tu ayuda de nuevo ahora que has terminado con el monitor de MAU de Carol. Su reunión con inversores potenciales se acerca rápidamente y quiere terminar su presentación. Ya lo has ayudado con los gráficos de líneas de MAU y totales de inscripciones por mes; los inversores, dice Bob, estarían convencidos de que Delivr está creciendo tanto en nuevos usuarios como en MAU.

Sin embargo, Bob quiere demostrar que Delivr no solo atrae nuevos usuarios, sino que también retiene a los usuarios existentes. Envíale una tabla de tasas de retención intermensual para que pueda destacar la alta lealtad de los usuarios de Delivr.
Selecciona la columna de mes de user_monthly_activity y calcula las tasas de retención intermensual de usuarios.
```SQL
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
```
Para este caso hacemos uso de CTE, el cuál contiene los valores únicos de los usuarios y el mes en que hicieron un pedido. Usamos esta tabla para los datos de la actividad actual y la actividad de un mes previo, para esto se usa el `LEFT JOIN` el cual tomamos todos los valores del mes previo y solo los valores de la tabla de la derecha que serían los usuarios que tienen el mismo `ID` del mes siguiente que están activos.