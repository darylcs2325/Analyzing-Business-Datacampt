# Analyzing-Business-Datacampt
Desarrollo del curso Analyzing Business Data, en SQL Server


# Explicación de la Data

Se tiene tres archivos `.csv` que son de la empresa Delivr. Esta empresa se dedica a la entrega de comida, permitiendo al usuario solicitar diferentes restaurantes.

Delivr se suministra por varios restaurantes a los cuales le compra diferentes comidas, mediante un contrato con los restaurantes, con el cual compra grandes cantidades de comida a un precio menor.

## Meals

En este archivo `.csv` se tiene una lista de todos los menús con el nombre del restaurante (`eatery`), su precio de venta (`meal_price`) y precio de costo (`meal_cost`).

## Orders

Es una tabla con todos los pedidos que realizaron los clientes, en el cual se muestra el id del cliente (`user_id`), el id de la orden (`order_id`), el tipo de menú que pidió (`meal_id`) y la cantidad de ese menú que pidió (`order_quantity`) y la fecha en que realizaron el pedido (`order_date`).

## Stock

Es la lista de lo que se tiene la cantidad de comida que se compra a los restaurantes, esta compra se realiza el 1er día de cada mes. Se indica la fecha en que se realizó la compra (`stocking_date`), el tipo de menú (`meal_id`) y la cantidad que se compró de ese menú (`stocked_quantity`).