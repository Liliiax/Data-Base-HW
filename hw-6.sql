--Задание 1
--Создайте в схеме schema1 таблицу offices (справочник офисов) со следующей
--структурой и приведите код: Поле Тип данных Ограничения office_id numeric(4,0) not office_name character varying (30) not office_country character varying (30) not office_city character varying (30) not manager_nme character varying (50) not
create table schema1.offices (
office_id numeric(4,0) not null,
office_name character varying(30) not null,
office_country character varying(30) not null,
office_city character varying(30) not null,
manager_name character varying(50) not null
);

--Задание 2
--1
--Добавьте в таблицу столбец для хранения номера телефона. Какой тип данных
--наиболее подходит для такого столбца?
alter table schema1.offices 
add column phone_number varchar(20);

--2
--Измените тип данных столбца таким образом, чтобы можно было сохранять
--несколько номеров телефонов, с возможностью указания типа телефона (основной,
--дополнительный и т.д.).
--Какой тип данных наиболее подходит для такого столбца?
alter table schema1.offices
alter column phone_number type jsonb
using to_jsonb(array[phone_number]);

--3
--Добавьте в таблицу столбец для хранения списка номеров кабинетов, где
--располагаются сотрудники офиса.
--Какой тип данных наиболее подходит для такого столбца?
alter table schema1.offices
add column cabinets int[];
--
--Задание 3
--1
--Создайте представление, которое предоставляет информацию об офисах: код офиса,
--наименование офиса, страна, город
create view schema1.offices_pr as
select office_id, office_name, office_country, office_city
from schema1.offices;
--
--2
--Проверьте:
--a.
--что при обращении к представлению вы получаете выборку необходимого вида.
select * 
from schema1.offices_pr;
--
--b.
--какой план выполнения использовал оптимизатор?
explain select * from schema1.offices_pr; 
--Ответ: Seq Scan on offices  (cost=0.00..13.30 rows=330 width=111)


--3
--Измените представление, исключив из него столбец код офиса.
--a.
--Каков результат? Объясните результат
create or replace view schema1.offices_pr as
select office_name, office_country, office_city
from schema1.offices;

Результат: SQL Error [42P16]: ERROR: cannot drop columns from view

--b.
--Каким образом можно добиться нужного результата?
drop view schema1.offices_pr;

create view schema1.offices_pr as
select office_name, office_country, office_city
from schema1.offices;
--
--4
--Измените представление, добавив в него фамилию руководителя
create or replace view schema1.offices_pr as
select office_name, office_country, office_city, manager_name
from schema1.offices;
--Задание 4
--1
--Создайте представление, которое возвращает все столбцы из таблицы offices
--(используйте символ * - звездочка).
create view schema1.offices_all as
select *
from schema1.offices;

--2
--Проверьте:
--a.
--что при обращении к представлению вы получаете выборку необходимого вида.
select * from schema1.offices_all;

--b.
--какой план выполнения использовал оптимизатор
explain select * from schema1.offices_all;
--Ответ: Seq Scan on offices  (cost=0.00..13.30 rows=330 width=218)
--3
--Добавьте в таблицу offices столбец email.
alter table schema1.offices
add column email varchar(40);

--4
--Напишите запрос к созданному представлению.
--a.
--включает ли результирующая выборка email? Объясните результат
select * 
from schema1.offices_all;
--Ответ: нет, столбца email нет, так как добавляемые после создания 
--предсатвления в таблицу столбцы не являются частью представления
--b.
--какой план выполнения использовал оптимизатор
explain select * 
from schema1.offices_all;
--Ответ:
--Seq Scan on offices  (cost=0.00..12.80 rows=280 width=218)
--Задание 5
--1.	Создайте изменяемое представление, которое будет позволять работать только с офисами из определенного города (например, Санкт-Петербург). 
create view schema1.offices_spb as
select *
from schema1.offices
where office_city = 'Санкт-Петербург';
--
--2.	Проверьте: 
--a.	что при обращении к представлению вы получаете выборку необходимого вида.
select * 
from schema1.offices_spb;
--
--b.	какой план выполнения использовал оптимизатор
explain select * 
from schema1.offices_spb;
--Ответ: Seq Scan on offices  (cost=0.00..13.50 rows=1 width=256)

--3.	Что необходимо сделать, чтобы данное представление позволяло изменять/добавлять только записи об офисах из указанного города?
create or replace view schema1.offices_spb as
select *
from schema1.offices
where office_city = 'Санкт-Петербург'
with local check option; 
