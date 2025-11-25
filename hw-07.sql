create extension btree_gist;

--Задание 1. 
--Создайте в схеме schema1 таблицу job_history (история карьерных перемещений сотрудников) со следующей структурой:
--1.	Таблица должна содержать следующие поля: employee_id, start_date, end_date, job_id и department_id, salary
--2.	Столбец employee_id не должен допускать повторяющихся значений во время вставки и изменения. При этом он должен содержать только те значения, которые существуют в таблице employees
--3.	Столбец job_id должен содержать только те значения, которые существуют в таблице jobs
--4.	Столбец department_id должен содержать только те значения, которые существуют в таблице departments
--5.	Внешние ключи должны:
--1.	Поддерживать каскадные изменения
--2.	Заменять значения ключа при удалении удаления записей из таблицы Первичного ключа NULL-значением 
--

create table schema1.job_history (
employee_id decimal(6,0) not null,
start_date date not null,
end_date date not null,
job_id varchar(10) not null,
department_id decimal(4,0),
salary numeric(8,2),
constraint unique_emp_id unique (employee_id),
constraint emp_value foreign key (employee_id)
references schema1.employees(employee_id)
on update cascade 
on delete set null,
constraint job_value foreign key (job_id)
references schema1.jobs(job_id)
on update cascade 
on delete set null,
constraint dep_value foreign key (department_id)
references schema1.departments (department_id)
on update cascade 
on delete set null
);


--6.	Внесите в структуру таблицы, необходимые изменения, чтобы иметь возможность сохранения исторических данных о карьерных перемещениях сотрудника с учетом следующих требований:
--У сотрудника может изменяться:
--1.	место работы (переходить из одного офиса в другой)
--2.	должность
--3.	зарплата
--
--При этом в один и тот же отрезок времени может существовать только одна запись о сотруднике (ограничение Exclude) 

alter table schema1.job_history 
add constraint for_dates 
        exclude using gist (
        employee_id with =,
        tsrange(start_date, end_date, '[]') with &&);

--Задание 2. 
--1.	Измените параметры внешнего ключа, созданного в таблице employees на столбце department_id таким образом, чтобы при удалении или изменении соответствующих записей из родительской таблицы значение столбца внешнего ключа становилось равным NULL.
alter table schema1.employees 
drop constraint foreign_key_dep;

alter table schema1.employees 
add constraint foreign_key_dep foreign key (department_id)
references schema1.departments(department_id) 
on update set null 
on delete set null;
--2.	Измените параметры внешнего ключа, созданного в таблице employees на столбце job_id таким образом, чтобы:
--1.	отклонялись удаления связных записей из родительской таблицы. 
--2.	обновления связных записей в родительской таблице должны каскадно поддерживаться
--3.	внешний ключ поддерживал изменение гранулярности на уровне транзакции
alter table schema1.employees 
drop constraint foreign_key_emp;

alter table schema1.employees 
add constraint foreign_key_emp foreign key (job_id)
references schema1.jobs(job_id) 
on update cascade 
on delete restrict
deferrable initially deferred;
--Задание 3. 
--1.	Создайте домен, определяющий правила ввода номера телефона. 
create domain schema1.phone_domain as varchar(20) 
check (value is null or regexp_like(value, '^8\(\d{3}\)\d{3}-\d{4}$'));
--2.	Задайте данный домен для столбца phone_number в таблице employees
alter table schema1.employees 
alter column phone_number type schema1.phone_domain;
--3.	Напишите запрос, возвращающий список ограничений для созданных вами таблиц.

select ns.nspname as schema, class.relname as "table",
con.conname as "constraint", con.condeferrable  as "deferrable"
, con.condeferred as deferred
from pg_constraint con
inner join pg_class class on class.oid = con.conrelid
inner join pg_namespace ns on ns.oid = class.relnamespace
where con.contype in ('p', 'u')
and ns.nspname != 'pg_catalog'
order by 1, 2, 3;