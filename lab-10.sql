--Лабораторная 10. 
--
--Задание 1.
--1.	В схеме schema2 создайте таблицу на основе следующего запроса:

create schema schema2;
create table schema2.random_table as
select 1000000.0 * random() as random,
       a::float8 as sequential,
       1.0 as value
from generate_series(1, 1000000) as a;


--2.	Запустите сбор статистики для созданной таблицы. Какой оператор вы использовали?
analyze schema2.random_table;
--3.	Напишите 2 запроса для получения суммы по столбцу value для поднаборов записей, отфильтрованных на основе столбцов:
--a.	random в диапазоне от 0 до 100
select sum(value)
from schema2.random_table
where random>=0 and random<=100;

--b.	sequential также в диапазоне о 0 до 100
select sum(value)
from schema2.random_table
where sequential>=0 and sequential<=100;

--4.	Заполните таблицу базовыми значениями времени выполнения запросов при разных значениях верхней границы диапазона 
explain analyze
select sum(value)
from schema2.random_table
where random>=0 and random<=100000;
explain analyze				
select sum(value)
from schema2.random_table
where sequential>=0 and sequential<=100000;
select count(*)
from schema2.random_table
where random>=0 and random<=100;
select count(*)
from schema2.random_table
where sequential>=0 and sequential<=100000;

--Верхняя граница    Время выполнения   Кол-во записей  Время выполнения         Кол-во записей
--                  (фильтр по random)  (random)       (фильтр по sequential)      (sequential)
--                   
--100                 196.041 ms         102              194.091 ms                100
--1000                136.624 ms         999              115.612 ms                1000
--10000               117.234 ms         9999             157.803 ms                10000
--100000              198.176 ms         99849            134.697 ms                100000 

--5.	Создайте следующие индексы
CREATE INDEX btree_random_x ON schema2.random_table (random);
CREATE INDEX btree_sequential_x ON schema2.random_table (sequential);
CREATE INDEX brin_random_x ON schema2.random_table USING BRIN (random);
CREATE INDEX brin_sequential_x ON schema2.random_table USING BRIN (sequential);
--6.	Оцените размер табличных данных и размеры созданных индексов, используя функцию pg_relation_size. Сделайте выводы
select pg_relation_size('schema2.random_table');
select pg_relation_size('schema2.btree_random_x');
select pg_relation_size('schema2.brin_random_x');
select pg_relation_size('schema2.brin_sequential_x');
select pg_relation_size('schema2.btree_sequential_x');
--Объект	                      Размер
--Таблица                    	52428800
--Индекс btree_random_x  	    22487040
--Индекс brin_random_x	        24576
--Индекс btree_sequential_x	    22487040
--Индекс brin_sequential_x	    24576
--
--7.	Проверьте, как изменится размер BRIN-индекса при уменьшении значения pages_per_range
drop index schema2.brin_random_x;
create index brin_random_x on schema2.random_table using BRIN (random) with (pages_per_range = 16);
select pg_relation_size('schema2.brin_random_x'); --32768, то есть размер увеличился

drop index schema2.brin_sequential_x;
create index brin_sequential_x on schema2.random_table using BRIN (sequential) with (pages_per_range = 16);
select pg_relation_size('schema2.brin_sequential_x'); --32768, тоже увеличился

--8.	Удалите все индексы
drop index schema2.brin_random_x;
drop index schema2.brin_sequential_x;
drop index schema2.btree_random_x;
drop index schema2.btree_sequential_x;
--9.	Создавая каждый индекс в отдельности, проанализируйте планы выполнения и зафиксируйте время выполнения запросов (п.3)
--Верхняя граница	BTree Rand	  BTree Seq	  BRIN Rand	  BRIN Seq
--100		        0.528 ms      0.066 ms    112.454 ms    2.048 ms 
--1000			    3.345 ms	  0.384 ms     58.618 ms   4.155 ms
--10000				18.505 ms     2.958 ms    60.906 ms    3.824 ms
--100000			50.169 ms	  31.835 ms   136.869 ms   24.176 ms

create index btree_random_x on schema2.random_table (random);
analyze schema2.random_table;
explain analyze
select sum(value)
from schema2.random_table
where random>=0 and random<=100000;
drop index schema2.btree_random_x;

create index btree_sequential_x on schema2.random_table (sequential);
analyze schema2.random_table;
explain analyze
select sum(value)
from schema2.random_table
where sequential>=0 and sequential<=100;
drop index schema2.btree_sequential_x;

create index brin_random_x on schema2.random_table USING BRIN (random);
analyze schema2.random_table;
explain analyze
select sum(value)
from schema2.random_table
where random>=0 and random<=100000;
drop index schema2.brin_random_x;

create index brin_sequential_x on schema2.random_table USING BRIN (sequential);
analyze schema2.random_table;
explain analyze
select sum(value)
from schema2.random_table
where sequential>=0 and sequential<=100000;
drop index schema2.brin_sequential_x;


--10.	Использовал ли сервер BRIN-индекс при фильтрации по столбцу random? 
--нет, он использовал  Parallel Seq Scan on random_table 
--11.	Измерьте производительность запроса, использующего фильтр по столбцу sequential, при использовании различных значений параметра pages_per_range (PPR) для BRIN-индекса 
--Rows	      PPR=128	  PPR=64      PPR=32        PPR=16        PPR=8	      PPR=4
--100		 2.067 ms      1.152 ms    1.058 ms	    0.384 ms	0.366 ms	0.663 ms
--1000		 2.223 ms     1.236 ms    1.269 ms      0.679 ms    0.531 ms	0.705 ms
--10000      3.522 ms      2.729 ms    4.175 ms	    2.717 ms	2.757 ms	3.040 ms
--100000     24.422 ms    27.574 ms   24.724 ms     25.582 ms   25.608 ms  24.379 ms
				
create index brin_sequential_x on schema2.random_table USING BRIN (sequential) with (pages_per_range = 128);
analyze schema2.random_table;
explain analyze
select sum(value)
from schema2.random_table
where sequential>=0 and sequential<=100;
drop index schema2.brin_sequential_x;

--Задание 2. Методы доступа к данным
--12.	Создайте тестовую таблицу schema2.OrderDetails на основе следующего запроса:

create table schema2.OrderDetails as
SELECT round(random()*100) as order_id, 
'Product ' || round(random()*100)::char(3) as product_name,
random()*100::money as price, order_date
from generate_series('2022-01-01','2023-12-31', INTERVAL '1 day') as order_date, 
generate_series(1, 5) as id;

--13.	Обновите содержимое столбца order_date:
--a.	Дата заказа должна быть равна самой ранней из всех дат данного заказа
update schema2.OrderDetails od
set order_date = d.min_date
from (select order_id, min(order_date) as min_date
    from schema2.OrderDetails group by order_id) d
WHERE od.order_id = d.order_id;

--14.	Напишите запрос, возвращающий количество записей и количество уникальных товаров в каждом заказе.
select order_id, count(*) as cnt, count(distinct product_name) as unique_products
from schema2.OrderDetails
group by order_id;

--a.	Какой план использовался для выполнения запроса?
--Seq Scan on orderdetails
explain analyze
select order_id, count(*) as cnt, count(distinct product_name) as unique_products
from schema2.OrderDetails
group by order_id;

--15.	Напишите запрос, извлекающий все записи из всех столбцов таблицы. Какой метод доступа использовался?
--Seq Scan on orderdetails
explain analyze
select * from schema2.OrderDetails;

--16.	Напишите запрос, извлекающий заказы за 22 января 2022 года. Какой метод доступа использовался?
--Seq Scan on orderdetails  
explain analyze
select * from schema2.OrderDetails
where order_date='2022-01-22';
--17.	Создайте B-Tree индекс на столбец order_date.
create index order_date_btree on schema2.OrderDetails(order_date);

--18.	Повторите выполнение запроса из п. 5. 
explain analyze
select * from schema2.OrderDetails
where order_date='2022-01-22';
--a.	Какой метод доступа использовался?
--  Bitmap Index Scan 
--b.	Объясните результат
--сервер выбирает такой план выполнения, так как созданный индекс упрощает фильтрацию по дате

--19.	Используя параметры enable_seqscan, enable_indexscan, enable_indexonlyscan, enable_bitmapscan
--a.	Оцените затраты при выполнении данного запроса с использованием различных методов доступа
set enable_seqscan = on;
set enable_indexscan = on;
set enable_bitmapscan = on;
set enable_indexonlyscan = on;

explain 
select * from schema2.OrderDetails
where order_date='2022-01-22'; 
--on off off off: Seq Scan on orderdetails 
-- off on on on: Bitmap Index Scan 
--off on off on: Index Scan 
-- off off off off: Bitmap Heap Scan 
-- off off off on:   Bitmap Index Scan 
-- on on on on:    Bitmap Index Scan

--b.	Cделайте выводы
--при данной конкретной выборке сервер наиболее часто выбирает план выполнения Bitmap Index Scan, при этом при
-- его отключении выбирается Index Scan
--Index Only Scan не используется вообще 


--20.	Создайте hash-индекс на столбец order_date.
create index order_date_hash on schema2.OrderDetails using hash(order_date);

--21.	Повторите выполнение запроса из п.5. 
--a.	Какой индекс использовался при выполнении запроса? 
-- Bitmap Index Scan on order_date_hash 
explain analyze
select * from schema2.OrderDetails
where order_date='2022-01-22';
--b.	Объясните результат
--фильтрация по условию "равенство" чего-либо (в данном случае даты) это идеальный случай для использования hash индекса.
--22.	Измените условие фильтрации для извлечения всех заказов за даты, предшествующие 22 января 2022 года.
--a.	Какой индекс использовался при выполнении запроса? 
--Seq Scan on orderdetails
explain analyze
select * from schema2.OrderDetails
where order_date<'2022-01-22';
--b.	Объясните результат
--hash индекс не подходит для использования при условии фильтрации по диапазону, поэтому сервер выбирает Seq Scan как наиболее подходящий

--23.	Какой тип индекса может быть полезен для запроса, извлекающего данные ТОЛЬКО:
--a.	по заказу 34? 
--Hash индекс
--b.	По заказам за январь 2022 года?
--B-Tree индекс
--c.	По товару 
--если товар выбирается по id или какому-то индентификатору, то B-Tree индекс
--если товар ищется по названию, то GIN индекс

--Задание 3. Способы соединения
--1.	Создайте новую таблицу schema2.products на основе выборки уникальных продуктов из таблицы orders
create table schema2.products as 
select distinct product_name
from schema2.OrderDetails;

--2.	Добавьте в таблицу products столбец id с автоматически генерируемыми значениями (IDENTITY)
alter table schema2.products
add column id int generated always as identity;

--3.	Модифицируйте структуру таблицы OrderDetails:
--a.	Добавьте столбец id_product. Тип данных должен соответствовать типу данных столбца id таблицы products
alter table schema2.OrderDetails
add column id_product int;

--b.	Значения в столбце id_product должны содержать код соответствующего продукта из таблицы products
update schema2.OrderDetails od
set id_product = p.id
from schema2.products p where od.product_name = p.product_name;

--c.	Удалите столбец product_name
alter table schema2.OrderDetails
drop column product_name;
--4.	Напишите запрос, который извлекает номер заказа, наименование продукта, цену продукта в заказе, дату заказа.
select od.order_id, p.product_name, od.price, od.order_date
from schema2.OrderDetails od
join schema2.products p on od.id_product = p.id;

--a.	Какой план использовался для выполнения запроса?
-- Seq Scan 
explain analyze
select od.order_id, p.product_name, od.price, od.order_date
from schema2.OrderDetails od
join schema2.products p on od.id_product = p.id;
--b.	Какой способ соединения используется в плане?
--Hash Join
--5.	Создайте индексы на столбцах id_product в таблице OrderDetails и id таблицы products 
create index id_product_idx on schema2.OrderDetails(id_product);
create index id_idx on schema2.products(id);

--6.	Повторно выполните запрос
explain analyze
select od.order_id, p.product_name, od.price, od.order_date
from schema2.OrderDetails od
join schema2.products p on od.id_product = p.id;
--a.	Какой план использовался для выполнения запроса?
--b.	Есть ли отличия от ранее использованного плана?
--нет, ничего не изменилось
--7.	Напишите запрос, который извлекает продукты, которых нет в 1 заказе. Запрос должен возвращать номер заказа и название продукта
explain analyze
select od.order_id, p.product_name
from schema2.products p
left join schema2.OrderDetails od on od.id_product = p.id and od.order_id = 1
where od.id_product is null;

--a.	Какой план использовался для выполнения запроса?
--Seq Scan 
--b.	Какой способ соединения используется в плане?
--Hash Right Anti Join
--8.	Используя параметры сервера, связанные со способами объединения поэкспериментируйте с выполнением запросов и обратите внимание на характеристики планов выполнения

--off on on: Merge Anti Join, Seq Scan 
--off off on: Nested Loop Anti Join,   Seq Scan
--off off off: Nested Loop Anti Join , Seq Scan
--off on off: Merge Anti Join , Seq Scan
--on off on: Hash Right Anti Join, Seq Scan
--on on off: Hash Right Anti Join, Seq Scan
set enable_hashjoin = on;
set enable_mergejoin = off;
set enable_nestloop = on;

explain analyze
select od.order_id, p.product_name
from schema2.products p
left join schema2.OrderDetails od on od.id_product = p.id and od.order_id = 1
where od.id_product is null;