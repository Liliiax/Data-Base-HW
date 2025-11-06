--Задание 2
--create schema schema1;

--Задание 3
--create table schema1.test (
--name varchar(20) not null,
--price numeric(5,2) null
--);

--Задание 3а
select pg_relation_filepath('schema1.test');

--Задание 3b:  oid - уникальный идентификатор , relfilenode - ID файла в котором хранятся данные таблицы ,
--reltablespace - oid таблицы пространства, reltoastrelid - oid связанной toast таблицы 
select oid, relfilenode, reltablespace, reltoastrelid
from pg_class
where relname='test'; 

--Задание 3с
insert into schema1.test (name, price) values ('Apple', 1.52);
insert into schema1.test (name, price) values ('Orange', 4.097);
insert into schema1.test (name, price) values ('Peach', 9.5234);
insert into schema1.test (name, price) values ('Banana', 2.2);

--Задание 3d: два знака после запятой, так как мы задали соответствующий тип данных numeric(5,2)
select * from schema1.test;

--Задание 3e
update schema1.test set price='NaN' where name='Peach';
--Задание 3f : столбец со значением 'NaN' идет самым первым, так как postgres считает, что он больше, чем числовой тип
select * from schema1.test order by price desc;


--Задание 4
create temporary table tmp_test
as select * from schema1.test;

--временная таблица хранится в схеме pg_temp_8:
select n.nspname , c.relname
from pg_class c
join pg_namespace n on c.relnamespace = n.oid
where c.relname = 'tmp_test'; 

--Задание 4а
SELECT c1.oid, c1.reltoastrelid, c2.relname
FROM pg_class AS c1
LEFT JOIN pg_class AS c2
ON c1.reltoastrelid = c2.oid
WHERE c1.relname = 'tmp_test';

--Задание 4b
alter table tmp_test
add column price_discount numeric(5,2)
generated always as (price* 0.8) stored;

--Задание 4c
alter table tmp_test 
alter column name type text;

--Задание 4d
SELECT c1.oid, c1.reltoastrelid, c2.relname
FROM pg_class AS c1
LEFT JOIN pg_class AS c2
ON c1.reltoastrelid = c2.oid
WHERE c1.relname = 'tmp_test'; --таблица есть relname: pg_toast_21417 reltoastrelid: 21432, так как появился столбец, в котором потенциально могут храниться очень большие данные (text)

--Задание 4e
alter table tmp_test 
alter column name type varchar(30);

--Задание 4f
SELECT c1.oid, c1.reltoastrelid, c2.relname
FROM pg_class AS c1
LEFT JOIN pg_class AS c2
ON c1.reltoastrelid = c2.oid
WHERE c1.relname = 'tmp_test'; --таблицы нет relname: NULL reltoastrelid: 0, так как все данные ограничены и точно будут помещаться 


--Задание 4gh: таблица tmp_test не доступна, так как это временная таблица и она 
--доступна только во время сессии, когда была создана. Во время новой сессии доступна таблица
--test

--Задание 5

create unlogged table schema1.teacher (
    teacher_id serial  not null,
    first_name varchar null,
    last_name varchar not null,
    birthday date not null,
    phone varchar null,
    title varchar null
);

--Задание 5а

alter table schema1.teacher 
add column middle_name varchar;

--Задание 5b 
alter table schema1.teacher
drop column middle_name;

--Задание 5c

alter table schema1.teacher
rename column birthday to birth_date;

--Задание 5d

alter table schema1.teacher 
alter column phone type text[]
using phone::text[];

--Задание 6
drop table schema1.test; 
drop table schema1.teacher;