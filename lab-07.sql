--Задание 1. 
--Создайте в схеме schema1 таблицу countries (справочник стран) и приведите код:
--1.	Таблица должна содержать следующие поля: country_id, country_name и region_id. Выберите для данных столбцов подходящие типы данных
--2.	Необходимо гарантировать, что в таблицу не будут введены никакие страны, кроме России, Индии, Китая, Бразилии, Казахстана, Киргизии и Белоруссии.
--3.	Столбец country_id должен быть ключевым столбцом таблицы. Значения в столбце должны вычисляться автоматически, начиная с 1 с шагом 2. 
create sequence schema1.default_id_seq
start 1
increment 2;

--4.	Значения комбинации столбцов country_id и region_id должны быть уникальными. 
create table schema1.countries (
    country_id int not null default nextval('schema1.default_id_seq'),
    country_name varchar(50) not null,
    region_id int,
    constraint available_countries check (country_name in
    ('Россия', 'Индия', 'Китай', 'Бразилия', 'Казахстан', 'Киргизия', 'Белоруссия')),
    constraint primary_key primary key (country_id),
    constraint unique_combinations unique (country_id, region_id)
);
--5.	Удалите ограничение на перечень допустимых стран
alter table schema1.countries
drop constraint available_countries;
--6.	Удалите столбец region_id
alter table schema1.countries 
drop column region_id;



--Задание 2. 
--Создайте в схеме schema1 таблицу locations (справочник адресов) со следующей структурой и приведите код:
--Поле	Тип
--location_id	numeric(4,0)
--street_address	character varying (40)
--postal_code	character varying (6)
--city	character varying (30)
--country_id	?
--1.	Создайте в таблице locations составной первичный ключ на основе столбцов location_id и country_id.
--2.	Добавьте ограничение на столбец postal_code, запрещающее ввод нечисловых значений.
--3.	Столбец country_id должен содержать только те значения, которые существуют в таблице countries в столбце country_id. 

create table schema1.locations (
	location_id numeric(4,0) not null,
	street_address varchar(40),
	postal_code varchar(6),
	city varchar(30),
	country_id int not null,
    constraint primary_key_loc primary key (location_id, country_id),
    constraint postal_code check (postal_code ~ '^[0-9]+$'),
    constraint countries_id foreign key (country_id)
    references schema1.countries(country_id)
);

--4.	Выведите столбец country_id из состава первичного ключа.

alter table schema1.locations
drop constraint primary_key_loc;
alter table schema1.locations
add constraint primary_key_loc primary key (location_id);


--Задание 3. 
--Создайте в схеме schema1 таблицу departments (справочник офисов) со следующей структурой и приведите код:
--Поле	Тип данных	Ограничения
--department_id	numeric(4,0)	not null
--department_name	character varying (30)	not null
--manager_id	numeric(6,0)	not null
--location_id	numeric(4,0)	default null::numeric
--1.	Создайте в таблице составной первичный ключ – (department_id, manager_id)

create table schema1.departments (
    department_id numeric(4,0) not null,
    department_name character varying(30) not null,
    manager_id numeric(6,0) not null,
    location_id numeric(4,0) default null::numeric,
    constraint primary_key_dep primary key (department_id, manager_id)
);

--2.	Убедитесь, что автоматически был создан индекс
select *
from pg_indexes
where schemaname = 'schema1' and tablename = 'departments';


--Задание 4. 
--Создайте в схеме schema1 таблицу jobs (справочник должностей) и приведите код:
--1.	Таблица должна содержать следующие поля: job_id, job_title, min_salary и max_salary. Выберите для данных столбцов подходящие типы данных
--2.	Значение в поле max_salary не должно превышать 25000
--3.	Значение по умолчанию для job_title – строка нулевой длины
--4.	Значение по умолчанию для min_salary - равно 8000
--5.	Дублирование данных в столбце job_id не допускается

create table schema1.jobs (
    job_id varchar(10) not null,
    job_title varchar(50) default '',
    min_salary numeric(6,0) default 8000,
    max_salary numeric(6,0),
    constraint max_salary check (max_salary<=25000),
    constraint job_id_unique unique (job_id)
);

--6.	В таблице jobs измените значение по умолчанию для столбца min_salary – 7500
alter table schema1.jobs
alter column min_salary 
set default 7500;

--Задание 5. 
--Создайте в схеме schema1 таблицу employees (список сотрудников) со следующей структурой и приведите код:
--Поле	Тип данных	Ограничения
--employee_id	decimal(6,0)	Первичный ключ
--first_name	varchar(20)	NULL
--last_name	varchar(25)	NOT NULL
--email	varchar(25)	NOT NULL
--phone_number	varchar(20)	NULL,Соответствие шаблону 8(ХХХ)ХХХ-ХХХХ
--hire_date	date	NOT NULL,Меньше или равно текущая дата
--job_id	varchar(10)	NOT NULL,
--salary	decimal(8,2)	NULL
--manager_id	decimal(6,0)	NULL
--department_id	decimal(4,0)	NULL
--
--1.	Столбец employee_id – Первичный ключ таблицы. 
--a.	При вводе данных пользователь должен иметь возможность изменять гранулярность проверки ограничения на уровне транзакции.
--2.	Столбец job_id должен содержать только те значения, которые существуют в таблице jobs в столбце job_id.  
--a.	При удалении записей в таблице jobs соответствующие записи в таблице employee должны автоматически удаляться
--b.	Любые изменения первичного ключа в таблице jobs должны отклоняться, если существуют связные записи в таблице employees 
--3.	Столбцы department_id и manager_id являются столбцами составного внешнего ключа, ссылающимися на соответствующий ключ в таблице «departments».
create table schema1.employees(
	employee_id	decimal(6,0),
	first_name varchar(20),
	last_name varchar(25) not null,
	email varchar(25) not null,
	phone_number varchar(20),
	hire_date date not null,
	job_id varchar(10) not null,
	salary decimal(8,2),
	manager_id decimal(6,0),
	department_id decimal(4,0),
	constraint primary_key_emp primary key (employee_id) deferrable initially immediate,
	constraint foreign_key_emp foreign key (job_id) 
	references schema1.jobs(job_id)
	on delete cascade,
	constraint phone check (regexp_like(phone_number, '^8\(\d{3}\)\d{3}-\d{4}$')),
	constraint data_cur check (hire_date <= current_date ),
	constraint foreign_key_dep foreign key (department_id, manager_id)
	references schema1.departments(department_id, manager_id)
);

--
--Задание 6. 
--1.	В таблице departments измените состав первичного ключа – ключ должен состоять ТОЛЬКО из столбца department_id.
--2.	Внесите изменения в состав внешнего ключа в таблице employees, ссылающийся на соответствующий ключ в таблице departments.
alter table schema1.employees
drop constraint foreign_key_dep;

alter table schema1.departments
drop constraint primary_key_dep;
alter table schema1.departments
add constraint primary_key_dep primary key (department_id);

alter table schema1.employees
add constraint foreign_key_dep foreign key (department_id)
references schema1.departments(department_id);
--3.	Удалите столбец manager_id из состава таблицы employees

alter table schema1.employees
drop column manager_id;




	

