--Задание 1. SELECT к нескольким таблицам
--Фильтрация должна производится на исходных данных столбцов (не на вычисляемых выражениях)!
--1.	Выведите информацию о тех транспортных компаниях, которые доставляли заказы в декабре 2006 года в Швецию, а в декабре 2007 года в Данию
select s.*, o.shippeddate, o.shipcountry
from "Sales"."Shippers"s
join "Sales"."Orders"o on s.shipperid=o.shipperid
where (o.shipcountry = 'Sweden' and o.shippeddate >= '2006-12-01'::date and o.shippeddate < '2007-01-01'::date)
    or (o.shipcountry = 'Denmark' and o.shippeddate >= '2007-12-01'::date
     and o.shippeddate < '2008-01-01'::date);
--
--2.	Сформируйте выборку следующего вида:
--
--В столбцах Название продукта и Поставщик необходимо исключить слова Product и Supplier, соответственно.
--В выборке должны присутствовать только те продукты, которые относятся к категориям с 1 по 5 и при этом их поставщики находятся в Европе.
select 
replace(productname, 'Product', '') as "Название продукта" , unitprice as "Цена" ,
c.categoryname as "Категория", replace(s.companyname, 'Supplier', '') as "Поставщик",
    s.phone as "Телефон", s.country as "Страна"
from "Production"."Products" p
join "Production"."Categories" c on p.categoryid=c.categoryid 
join "Production"."Suppliers" s on p.supplierid=s.supplierid
where p.categoryid>=1 and p.categoryid<=5 and s.country in ('Spain', 'UK','Finland', 'Denmark' ,'Russia', 'Germany', 'Italy', 'Netherlands', 'Norway', 'France', 'Sweden');
-- 3.	Сформируйте выборку следующего вида:
--В столбцах Название продукта и Заказчик необходимо исключить слова Product и Customer, соответственно 
--В столбце Стоимость с учетом скидки необходимо рассчитать сумму, которую должен заплатить за данный товар клиент с учетом количества товара и предоставленной скидки
--Выборка должна содержать информацию о Заказчиках из Бразилии и Канады, которые сделали заказы весной 2007 года, при этом адрес доставки должен совпадать с адресом Заказчика (под адресом подразумевается страна и город).
select replace(c.companyname, 'Customer', '') as "Заказчик",
    (c.country || ',' || c.city) as "Адрес клиента", (o.shipcountry || ',' || o.shipcity) as "Адрес доставки",
replace(p.productname, 'Product', '') as "Название продукта",
    od.unitprice*od.qty *(1-od.discount) as "Стоимость с учетом скидки" 
from "Sales"."Customers" c
join "Sales"."Orders" o on o.custid= c.custid
join "Sales"."OrderDetails" od on od.orderid=o.orderid
join "Production"."Products" p on p.productid=od.productid 
where o.shipcity =c.city and o.shipcountry=c.country and (c.country='Canada' or c.country='Brazil') and o.orderdate>='2007-03-01'::date and o.orderdate<='2007-05-31'::date

--4.	Сформируйте выборку следующего вида:
--Выборка должна содержать набор уникальных записей с информацией о сотрудниках магазина и их клиентах при условии, что:
--a)	Сотрудник является мужчиной
--b)	Сотрудник проживает в том же городе где находится клиент (Учтите тот факт, что в разных странах могут быть города с одинаковыми названиями)
--c)	Должность сотрудника и должность контактного лица клиента совпадают
select distinct e.lastname||', '||e.firstname as "Сотрудник", e.title as "Должность сотрудника" , c.companyname as "Клиент", c.contactname as "Контакт", c.contacttitle as "Должность контакта"
from "HR"."Employees"e
join "Sales"."Customers"c on (e.city=c.city and c.country=e.country)
join "Sales"."Orders"o on o.custid=c.custid 
where e.title=c.contacttitle and e.titleofcourtesy in ('MR', 'mr', 'Mr.', 'Dr.');
--5.	Выведите полную информацию о сотрудниках, которые не оформили ни одного заказа
select e.* 
from "HR"."Employees"e 
left join "Sales"."Orders"o on e.empid=o.empid where o.orderid is null;

--6.	Напишите запрос, возвращающий список заказов, которые не являются международными (страна доставки заказа и страна клиента совпадают)
select o.*
from "Sales"."Orders"o 
join "Sales"."Customers" c on o.custid=c.custid 
where o.shipcountry=c.country;
--
--7.	Выведите информацию о тех товарах, которые никогда не продавались (не вошли ни в один заказ)

 select p.productname, c.categoryname, s.companyname, p.unitprice , p.discontinued  
 from "Production"."Products"p
 join "Production"."Categories" c on c.categoryid =p.categoryid 
 join "Production"."Suppliers" s on s.supplierid =p.supplierid 
 left join "Sales"."OrderDetails"od on p.productid=od.productid 
 where od.productid is null;

--8.	Выведите уникальный список сотрудников, у которых есть в подчинении другие сотрудники
select distinct e.empid, e.lastname , e.firstname , e.title  from "HR"."Employees"e 
join "HR"."Employees" ee on e.empid =ee.mgrid ;
----9.	Сформируйте выборки следующего вида:
----
----a.	Выборка должна содержать уникальный список товаров, которые находятся в одной категории и при этом имеют одинаковую цену
select distinct p.productid, p.productname, p.supplierid , p.categoryid , p.unitprice ,
    p.discontinued  from "Production"."Products" p 
join "Production"."Products" p1 on p.categoryid =p1.categoryid 
    and p.unitprice =p1.unitprice and p.productid <>p1.productid ; 
----b.	Выборка должна содержать уникальный список товаров, которые поставляются одним и тем же поставщиком и при этом имеют одинаковую цену
select distinct p.productid, p.productname, p.supplierid , p.categoryid ,
    p.unitprice , p.discontinued  from "Production"."Products" p 
join "Production"."Products" p1 on p.supplierid  =p1.supplierid  
    and p.unitprice =p1.unitprice and p.productid <>p1.productid ; 
----c.	Выборка должна содержать уникальный список товаров, которые находятся в одной категории, поставляются одним и тем же поставщиком и при этом имеют одинаковую цену
select distinct p.productid, p.productname, p.supplierid , p.categoryid ,
    p.unitprice , p.discontinued  from "Production"."Products" p 
join "Production"."Products" p1 on p.categoryid =p1.categoryid 
    and p.supplierid  =p1.supplierid  and p.unitprice =p1.unitprice and p.productid <>p1.productid ; 
----d.	Выборка должна содержать уникальный список товаров, которые находятся в одной категории, поставляются одним и тем же поставщиком и при этом имеют разную цену
select distinct p.productid, p.productname, p.supplierid , p.categoryid ,
    p.unitprice , p.discontinued  from "Production"."Products" p 
join "Production"."Products" p1 on p.categoryid =p1.categoryid
    and p.supplierid  =p1.supplierid  and p.unitprice<>p1.unitprice  ; 


