--Лабораторная работа 4. 
--Для выполнения данной лабораторной работы необходимо установить подключение к БД dbSQL
--ВНИМАНИЕ: Вычисляемые столбцы должны иметь соответствующие наименования.Фильтрация должна выполняться на исходных столбцах (не на вычисляемых).
--Задание 1. Запросы с группировкой
--1.	Выведите номер заказа и количество в нем продуктов со скидкой (используйте filter).
select orderid as "Номер заказа",
count(*) filter (where discount > 0) as "Количество продуктов"
from "Sales"."OrderDetails"
group by orderid;
--2.	Сформируйте выборку следующего вида:
--Выборка должна содержать информацию о поставщиках, которые поставляют более 2-х продуктов в каждой категории, а также максимальную, минимальную и среднюю цену поставляемых ими продуктов
select s.companyname,c.categoryname, count(p.productid) as "products_count",
avg(p.unitprice::numeric)::money as "avg_price", max(p.unitprice::numeric)::money as "max_price", min(p.unitprice::numeric)::money as "min_price"
from "Production"."Suppliers"s
join "Production"."Products"p on p.supplierid = s.supplierid
join "Production"."Categories"c on p.categoryid = c.categoryid
group by s.companyname, c.categoryname
having count(p.productid) > 2;
--3.	Сформируйте выборку следующего вида:
--Выборка должна содержать информацию о 5 самых выгодных заказчиках, с точки зрения суммарной стоимости (с учетом скидки) сделанных ими заказов в 2006. 
select c.companyname as "Клиент", to_char(o.orderdate, 'YYYY') as "Год", count(o.orderid) as "Всего Заказов за год",
sum(od.qty*od.unitprice*(1-od.discount )) as "Общая сумма", count(distinct od.productid) as "Кол-во уникальных продуктов", count(distinct od.discount>0) as "Продуктов со скидкой"
from "Sales"."Orders"o 
join "Sales"."Customers"c on c.custid=o.custid
join "Sales"."OrderDetails"od on od.orderid=o.orderid
where o.orderdate>='2006-01-01'::date and o.orderdate<'2007-01-01'::date
group by c.companyname, to_char(o.orderdate, 'YYYY')
limit 5;
--4.	Выведите количество заказов в разрезе стран и в разрезе городов. Представьте два варианта:
--a.	Первый вариант решения должен содержать количество заказов только по странам и только по городам, а также общее количество заказов 
select c.country as "Страна", c.city as "Город", count(o.orderid) as "Количество Заказов"
from "Sales"."Customers"c
join "Sales"."Orders"o on c.custid = o.custid
group by grouping sets (c.country,c.city,())               
order by c.country, c.city;
--b.	Второй вариант – все возможные итоги (итог по стране, итог по городу, итог по стране и городу, общий итог).
select c.country as "Страна", c.city as "Город", count(o.orderid) as "Количество Заказов"
from "Sales"."Customers"c
join "Sales"."Orders"o on c.custid = o.custid
group by cube (c.country, c.city)
order by c.country, c.city;
--* Используйте соответствующее расширение GROUP BY (GROUPING SETS, CUBE, ROLLUP)
--5.	Сформируйте выборку следующего вида:
--Выборка должна содержать информацию о Заказчиках из Бразилии и Канады, которые сделали заказы весной 2007 года, при этом адрес доставки должен совпадать с адресом Заказчика (под адресом подразумевается страна и город).
--Столбец «Сумма заказов с учетом скидки» должен содержать общую стоимость заказов конкретного заказчика за указанный период
select replace(c.companyname, 'Customer ', '') as "Заказчик", (c.country ||', ' || c.city) as "Адрес клиента",(o.shipcountry ||', ' || o.shipcity) as "Адрес доставки", sum(od.qty*od.unitprice*(1-od.discount)) as "Сумма заказов с учетом скидки"
from "Sales"."Customers"c
join "Sales"."Orders"o on o.custid = c.custid
join "Sales"."OrderDetails"od on od.orderid = o.orderid
where c.country in ('Brazil', 'Canada') and o.orderdate >= '2007-03-01'::date
and o.orderdate < '2007-06-01'::date and c.country = o.shipcountry and c.city = o.shipcity
group by c.companyname,c.country,c.city, o.shipcountry, o.shipcity
order by "Сумма заказов с учетом скидки" asc;
--Задание 2. Использование оконных функций
--1.	Сформируйте выборку, следующего вида:
--Выборка должна выводить данные о заказах оформленных в сентябре 2006 года. Детали каждого заказа должны быть проранжированы в соответствие с их стоимостью.
select replace(c.companyname, 'Customer ', '') as "client", o.orderid as "order", od.productid as "product", od.unitprice as "price",
od.qty as "qty", od.qty*od.unitprice*(1-od.discount) as "Line Total",
sum(od.qty*od.unitprice*(1-od.discount)) over (partition by o.orderid) as "Order Total",
rank() over (partition by o.orderid order by (od.qty*od.unitprice*(1-od.discount)) desc) as "Line Rank"
from "Sales"."Orders"o
join "Sales"."OrderDetails"od on od.orderid = o.orderid
join "Sales"."Customers"c on c.custid=o.custid
where o.orderdate >= '2006-09-01'::date and o.orderdate < '2006-10-01'::date
order by o.orderid, "Line Rank";
    
--2.Выведите список заказчиков, проранжировав их в пределах каждой страны отдельно в порядке убывания общей стоимости сделанных заказчиком заказов. Результирующая выборка должна содержать только строки со значением ранга не более 2
select * from (select c.custid, c.companyname, c.country,
sum(od.qty*od.unitprice*(1-od.discount)) as "Order Total",
rank() over (partition by c.country order by sum(od.qty*od.unitprice*(1-od.discount)) desc) as "Rank"
from "Sales"."Customers"c
join "Sales"."Orders"o on  o.custid = c.custid
join "Sales"."OrderDetails"od on o.orderid = od.orderid
group by c.custid, c.country) as "Result"
where "Rank"<=2;

--3.	Выведите для каждого продукта его название, цену по каталогу, количество заказов, в которых данный продукт встречается, и ранг, в соответствии с частотой его присутствия в заказах
select p.productname, p.unitprice,count(od.orderid) as "qwt",
rank() over (order by count(distinct od.orderid) desc) as "rank"
from "Production"."Products"p
join "Sales"."OrderDetails"od on od.productid = p.productid
group by p.productid, p.productname, p.unitprice

--4.	Выведите одним запросом: номер заказчика, номер заказа, дату заказа, стоимость заказа, стоимость заказа за предыдущую дату по данному заказчику, разницу между стоимостью текущего заказа и предыдущего. Null значения должны быть заменены 0. При расчете стоимости заказа необходимо учитывать скидку
select o.custid, o.orderid, o.orderdate, sum(od.qty*od.unitprice*(1-od.discount))::numeric as "val",
lag(sum(od.qty*od.unitprice*(1-od.discount))::numeric, 1, 0::numeric) over (partition by o.custid order by o.orderdate) as "prevval",
sum(od.qty*od.unitprice*(1-od.discount))::numeric-lag(sum(od.qty*od.unitprice*(1-od.discount))::numeric, 1, 0::numeric) over (partition by o.custid order by o.orderdate) as "diffprev"
from "Sales"."Orders"o
join "Sales"."OrderDetails"od on o.orderid = od.orderid
group by o.custid, o.orderid, o.orderdate;

--5.	Выведите для всех заказов номер заказчика, номер заказа, дату заказа, объем заказа, процентную долю от общей стоимости всех заказов данного заказчика, нарастающий итог по заказам каждого заказчика. 
select o.custid, o.orderid, o.orderdate,
sum(od.qty*od.unitprice*(1-od.discount))::numeric as "val",
100*sum(od.qty*od.unitprice*(1-od.discount))/sum(sum(od.qty*od.unitprice*(1-od.discount))) over (partition by o.custid) as "percoftotalcust",
sum(sum(od.qty*od.unitprice*(1-od.discount))::numeric) over (partition by o.custid order by o.orderdate) as "runval"
from "Sales"."Orders"o
join "Sales"."OrderDetails"od on o.orderid = od.orderid
group by o.custid, o.orderid, o.orderdate;

--6.	Выведите для всех заказов, сделанных в 2007 году, название месяца, общий объем заказов в этом месяце, средний объем за 3 месяца (2 предыдущих и текущий) и нарастающий итого по месяцам. Воспользуйтесь представлением public."OrderValues"
select to_char(date_trunc('month', orderdate), 'Month') as "monthname",
sum("OrderTotal") as "total",
avg(sum("OrderTotal")) over (order by date_trunc('month', orderdate) rows between 2 preceding and current row ) as "avglast3months",
sum(sum("OrderTotal")) over (order by date_trunc('month', orderdate)) as "ytdval"
from public."OrderValues"
where orderdate>='2007-01-01'::date and orderdate<'2008-01-01'::date
group by date_trunc('month', orderdate)
order by date_trunc('month', orderdate);

--7.	Выведите выборку, содержащую ФИО сотрудника магазина, год и месяц, когда он оформлял заказы, стоимость оформленных в конкретном месяце заказов, стоимость оформленных в конкретном году заказов, нарастающий итог по месяцам в каждом году для каждого сотрудника и Общий итог по всем заказам оформленным конкретным сотрудником.
select (e.lastname || ' ' ||  e.firstname) as "FIO",
extract(year from o.orderdate) as "Year",
to_char(o.orderdate, 'MM')::numeric as "Month",
sum(od.qty*od.unitprice*(1-od.discount)) as "Total by Month",
sum(sum(od.qty*od.unitprice*(1-od.discount))) over (partition by e.empid, extract(year from o.orderdate)) as "Total by Year",
sum(sum(od.qty*od.unitprice*(1-od.discount))) over (partition by e.empid, extract(year from o.orderdate) order by to_char(o.orderdate, 'MM')::numeric) as "Running Total",
sum(sum(od.qty*od.unitprice*(1-od.discount))) over (partition by e.empid) as "Total by Emp"
from  "Sales"."Orders"o
join "Sales"."OrderDetails"od on o.orderid = od.orderid
join "HR"."Employees" e on o.empid = e.empid
group by e.empid, e.lastname, e.firstname, extract(year from o.orderdate), to_char(o.orderdate, 'MM')::numeric
order by e.lastname, e.firstname, "Year", to_char(o.orderdate, 'MM')::numeric;
