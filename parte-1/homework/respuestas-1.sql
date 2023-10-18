-- ## Semana 1 - Parte A


-- 1. Mostrar todos los productos dentro de la categoria electro junto con todos los detalles.
select * 
from stg.product_master 
where category = 'Electro'

-- 2. Cuales son los producto producidos en China?
select product_code, name 
from stg.product_master 
where origin = 'China' 
order by product_code

-- 3. Mostrar todos los productos de Electro ordenados por nombre.
select product_code, name 
from stg.product_master 
where category = 'Electro'
order by name

-- 4. Cuales son las TV que se encuentran activas para la venta?
select product_code, name  
from stg.product_master 
where subcategory = 'TV'
and is_active = True

-- 5. Mostrar todas las tiendas de Argentina ordenadas por fecha de apertura de las mas antigua a la mas nueva.
select * 
from stg.store_master
where country = 'Argentina'
order by start_date asc

-- 6. Cuales fueron las ultimas 5 ordenes de ventas?
select *
from stg.order_line_sale
order by date DESC
limit 5

-- 7. Mostrar los primeros 10 registros de el conteo de trafico por Super store ordenados por fecha.
select *
from stg.super_store_count
order by date
limit 10

-- 8. Cuales son los producto de electro que no son Soporte de TV ni control remoto.
select *
from stg.product_master
where subsubcategory != 'Soporte'
and subsubcategory != 'Control remoto'

select *
from stg.product_master
where subsubcategory not in ('Soporte','Control remoto') 

-- 9. Mostrar todas las lineas de venta donde el monto sea mayor a $100.000 solo para transacciones en pesos.
select *
from stg.order_line_sale
where sale > 100000
and currency = 'ARS'

-- 10. Mostrar todas las lineas de ventas de Octubre 2022.
select *
from stg.order_line_sale
where date between '2022-10-01' AND '2022-10-31';

select *
from stg.order_line_sale
where (date_part ('month',date)) = 10

-- 11. Mostrar todos los productos que tengan EAN.
select *
from stg.product_master
where ean is not null

-- 12. Mostrar todas las lineas de venta que que hayan sido vendidas entre 1 de Octubre de 2022 y 10 de Noviembre de 2022.
select *
from stg.order_line_sale
where date between '2022-10-01' AND '2022-11-10'

-- ## Semana 1 - Parte B

-- 1. Cuales son los paises donde la empresa tiene tiendas?
select distinct country as paises
from stg.store_master

-- 2. Cuantos productos por subcategoria tiene disponible para la venta?
select subcategory, count (distinct product_code)
from stg.product_master
where is_active = 'true'
group by subcategory

-- 3. Cuales son las ordenes de venta de Argentina de mayor a $100.000?
select ols.order_number, ols.sale
from stg.order_line_sale as ols
where currency = 'ARS'
and sale > 100000


-- 4. Obtener los descuentos otorgados durante Noviembre de 2022 en cada una de las monedas?
select currency, sum(promotion)
from stg.order_line_sale
where date between '2022-11-01' and '2022-11-30'
group by currency

-- 5. Obtener los impuestos pagados en Europa durante el 2022.
select currency, sum(tax)
from stg.order_line_sale
where date between '2022-01-01' and '2022-12-31'
and currency = 'EUR'
group by currency

-- 6. En cuantas ordenes se utilizaron creditos?
select count (distinct order_number) 
from stg.order_line_sale
where credit is not null

-- 7. Cual es el % de descuentos otorgados (sobre las ventas) por tienda?
select store, sum (promotion)/sum(sale) 
from stg.order_line_sale
group by store

-- 8. Cual es el inventario promedio por dia que tiene cada tienda?
select store_id, date, ((sum(initial)+sum(final))/2) 
from stg.inventory
group by store_id, date
order by store_id, date

-- 9. Obtener las ventas netas y el porcentaje de descuento otorgado por producto en Argentina.
select product, sum (sale)-sum(tax) as ventas_netas, (sum(promotion)/sum(sale)) as desc_otorgado
from stg.order_line_sale
where currency = 'ARS'
group by product
order by product

-- 10. Las tablas "market_count" y "super_store_count" representan dos sistemas distintos que usa la empresa para contar la cantidad de gente que ingresa a tienda, uno para las tiendas de Latinoamerica y otro para Europa. Obtener en una unica tabla, las entradas a tienda de ambos sistemas.
SELECT store_id, TO_CHAR(to_date(date::text, 'YYYYMMDD'), 'YYYY-MM-DD') AS date, traffic
FROM stg.market_count
UNION ALL
SELECT store_id, date, traffic
FROM stg.super_store_count;

-- 11. Cuales son los productos disponibles para la venta (activos) de la marca Phillips?
select *
from stg.product_master 
where name like ('%PHILIPS%')
and is_active = true

-- 12. Obtener el monto vendido por tienda y moneda y ordenarlo de mayor a menor por valor nominal de las ventas (sin importar la moneda).
select store, currency, sum (sale) 
from stg.order_line_sale
group by store, currency
order by sum (sale) desc

-- 13. Cual es el precio promedio de venta de cada producto en las distintas monedas? Recorda que los valores de venta, impuesto, descuentos y creditos es por el total de la linea.
select product, currency, sum (sale)/sum (quantity)
from stg.order_line_sale 
group by product, currency

-- 14. Cual es la tasa de impuestos que se pago por cada orden de venta?
select order_number, currency, coalesce(sum(tax/sale),0)
from stg.order_line_sale 
group by order_number, currency

-- ## Semana 2 - Parte A

-- 1. Mostrar nombre y codigo de producto, categoria y color para todos los productos de la marca Philips y Samsung, mostrando la leyenda "Unknown" cuando no hay un color disponible
select name, product_code, category, coalesce(color,'Unknown') as color
from stg.product_master
where upper(name) like ('%PHILIPS%') OR upper(name) like ('%SAMSUNG%')

-- 2. Calcular las ventas brutas y los impuestos pagados por pais y provincia en la moneda correspondiente.
select sm.country, sm.province, ols.currency, sum (ols.sale) as ventas_brutas, sum(ols.tax) as impuestos
from stg.order_line_sale as ols
left join stg.store_master as sm
on ols.store = sm.store_id
group by sm.country, sm.province, ols.currency
order by sm.country, sm.province, ols.currency

-- 3. Calcular las ventas totales por subcategoria de producto para cada moneda ordenados por subcategoria y moneda.
select pm.subcategory, ols.currency, sum(ols.sale)
from stg.order_line_sale as ols
left join stg.product_master as pm
on pm.product_code = ols.product
group by pm.subcategory, ols.currency
order by pm.subcategory, ols.currency
  
-- 4. Calcular las unidades vendidas por subcategoria de producto y la concatenacion de pais, provincia; usar guion como separador y usarla para ordenar el resultado.
select pm.subcategory, concat (sm.country,'-',sm.province) as lugar , sum(ols.quantity) as uni_vend
from stg.order_line_sale as ols
left join stg.store_master as sm
on sm.store_id = ols.store
left join stg.product_master as pm
on pm.product_code = ols.product
group by pm.subcategory, lugar
order by lugar


-- 5. Mostrar una vista donde se vea el nombre de tienda y la cantidad de entradas de personas que hubo desde la fecha de apertura para el sistema "super_store".
select sm.name, sum (ssc.traffic) as entradas
from stg.store_master as sm
left join stg.super_store_count as ssc
on sm.store_id = ssc.store_id 
group by sm.name
order by sm.name

-- 6. Cual es el nivel de inventario promedio en cada mes a nivel de codigo de producto y tienda; mostrar el resultado con el nombre de la tienda.
select i.store_id, sm.name, i.item_id, extract(year from i.date) as year, extract(month from i.date) as month, (avg((initial+final)/2)) as inventario
from stg.inventory as i
left join stg.store_master as sm
on sm.store_id = i.store_id 
group by i.store_id, sm.name, i.item_id, year, month
order by i.store_id, sm.name, i.item_id, year, month

-- 7. Calcular la cantidad de unidades vendidas por material. Para los productos que no tengan material usar 'Unknown', homogeneizar los textos si es necesario.
select  sum (ols.quantity) ,
	CASE
        WHEN pm.material IS NULL THEN 'UNKNOWN'
        ELSE upper (pm.material)
    END AS concat
from stg.order_line_sale as ols
left join stg.product_master as pm
on pm.product_code = ols.product 
group by 2
order by 2
 
-- 8. Mostrar la tabla order_line_sales agregando una columna que represente el valor de venta bruta en cada linea convertido a dolares usando la tabla de tipo de cambio.
select ols.*,
case
	when ols.currency = 'ARS'
	then ols.sale/fx.fx_rate_usd_peso
	when ols.currency = 'EUR'
	then ols.sale/fx.fx_rate_usd_eur
	when ols.currency = 'URU'
	then ols.sale/fx.fx_rate_usd_uru
	else ols.sale
	end as ventas_usd
from stg.order_line_sale as ols
left join stg.monthly_average_fx_rate as fx
on ols.date = fx.month


-- 9. Calcular cantidad de ventas totales de la empresa en dolares.
with ventas_usd as (
select *,
		case
	when ols.currency = 'ARS'
	then ols.sale/fx.fx_rate_usd_peso
	when ols.currency = 'EUR'
	then ols.sale/fx.fx_rate_usd_eur
	when ols.currency = 'URU'
	then ols.sale/fx.fx_rate_usd_uru
	else ols.sale
	end as ventas_usd
from stg.order_line_sale as ols
left join stg.monthly_average_fx_rate as fx
on ols.date = fx.month
)

select sum (ventas_usd)
from ventas_usd

-- 10. Mostrar en la tabla de ventas el margen de venta por cada linea. Siendo margen = (venta - descuento) - costo expresado en dolares.
select ols.*,
	case
		when ols.currency = 'ARS'
		then ((ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_peso)-c.product_cost_usd
		when ols.currency = 'EUR'
		then ((ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_eur)-c.product_cost_usd
		when ols.currency = 'URU'
		then ((ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_uru)-c.product_cost_usd
		else ols.sale-ols.promotion-c.product_cost_usd
		end as margen_usd
	
from stg.order_line_sale as ols
left join stg.monthly_average_fx_rate as fx
on ols.date = fx.month
left join stg.cost as c
on c.product_code = ols.product

-- 11. Calcular la cantidad de items distintos de cada subsubcategoria que se llevan por numero de orden.
select pm.subcategory, ols.order_number, count (distinct ols.product)  --> entiendo que es cada producto pero podría ser también "quantity"
from stg.order_line_sale as ols
left join stg.product_master as pm
on pm.product_code = ols.product
group by ols.order_number, pm.subcategory
order by ols.order_number, pm.subcategory

-- ## Semana 2 - Parte B

-- 1. Crear un backup de la tabla product_master. Utilizar un esquema llamada "bkp" y agregar un prefijo al nombre de la tabla con la fecha del backup en forma de numero entero.
CREATE SCHEMA IF NOT EXISTS bkp
    AUTHORIZATION postgres;

select *
into bkp.pm_20230924
from stg.product_master

-- 2. Hacer un update a la nueva tabla (creada en el punto anterior) de product_master agregando la leyendo "N/A" para los valores null de material y color. Pueden utilizarse dos sentencias.
update bkp.pm_20230924
set material = 'N/A' 
where material is Null

update bkp.pm_20230924 as pmb
set color = 'N/A' 
where color is Null

-- 3. Hacer un update a la tabla del punto anterior, actualizando la columa "is_active", desactivando todos los productos en la subsubcategoria "Control Remoto".
update bkp.pm_20230924 
set is_active = 'false' 
where subsubcategory = 'Control remoto'  

-- 4. Agregar una nueva columna a la tabla anterior llamada "is_local" indicando los productos producidos en Argentina y fuera de Argentina.
alter table bkp.pm_20230924
add is_local boolean

update bkp.pm_20230924 
set is_local = 'true' 
where origin = 'Argentina'

update bkp.pm_20230924 
set is_local = 'false' 
where origin != 'Argentina'
	
-- 5. Agregar una nueva columna a la tabla de ventas llamada "line_key" que resulte ser la concatenacion de el numero de orden y el codigo de producto.
alter table stg.order_line_sale 
add line_key character varying(255)  

update stg.order_line_sale 
set line_key = concat (order_number,'-',product) 
  
-- 6. Crear una tabla llamada "employees" (por el momento vacia) que tenga un id (creado de forma incremental), name, surname, start_date, end_date, phone, country, province, store_id, position. Decidir cual es el tipo de dato mas acorde.
create table stg.employees (
	id serial primary key,
	name varchar(255),
	surname varchar(255),
	start_date date,
	end_date date, 
	phone numeric (20,0), --> puede ser también un varchar porque lleva un +
	country varchar(30), 
	province varchar(30), 
	store_id smallint, 
	position varchar(30)
)  


-- 7. Insertar nuevos valores a la tabla "employees" para los siguientes 4 empleados:
    -- Juan Perez, 2022-01-01, telefono +541113869867, Argentina, Santa Fe, tienda 2, Vendedor.
    -- Catalina Garcia, 2022-03-01, Argentina, Buenos Aires, tienda 2, Representante Comercial
    -- Ana Valdez, desde 2020-02-21 hasta 2022-03-01, España, Madrid, tienda 8, Jefe Logistica
    -- Fernando Moralez, 2022-04-04, España, Valencia, tienda 9, Vendedor.

insert into stg.employees 
values 
	(default, 'Juan', 'Perez','2022-01-01',Null, 541113869867, 'Argentina', 'Santa Fe', 2, 'Vendedor'),
	(default, 'Catalina', 'Garcia', '2022-03-01', Null, Null, 'Argentina', 'Buenos Aires', 2, 'Representante Comercial'),
	(default, 'Ana', 'Valdez', '2020-02-21', '2022-03-01', Null, 'España', 'Madrid', 8, 'Jefe Logistica'),
	(default, 'Fernando', 'Moralez', '2022-04-04', Null, Null, 'España', 'Valencia', 9, 'Vendedor')
 
--No es necesario el default, el ID se genera sólo al ser autoincremental.

-- 8. Crear un backup de la tabla "cost" agregandole una columna que se llame "last_updated_ts" que sea el momento exacto en el cual estemos realizando el backup en formato datetime.
select *
into bkp.cost_bis
from stg.cost
	
alter table bkp.cost_bis
add last_updated_ts timestamp

update bkp.cost_bis 
set last_updated_ts = current_date 

select *
from bkp.cost_bis

-- 9. En caso de hacer un cambio que deba revertirse en la tabla order_line_sale y debemos volver la tabla a su estado original, como lo harias? Responder con palabras que sentencia utilizarias. (no hace falta usar codigo)
-- Seguiría los siguientes pasos:
-- 1) Aplicaría el comando BEGIN: Esto inicia una transacción en PostgreSQL. A partir de este punto, todas las operaciones que realices no se aplicarán de inmediato a la base de datos.
-- 2) Realizaría las operaciones de cambio necesarias.
-- 3) Revisaría que los datos estén correctos.
-- 4) a) Confirmar que la transacción está bien con el comando COMMIT. Esto guardará todos los cambios realizados en la transacción.
--    b) Si en algún momento durante la transacción veo que algo salió mal o necesito detener la reversión, utilizo el comando ROLLBACK en lugar de COMMIT para revertirlo.
