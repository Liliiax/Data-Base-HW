--Задание 1. Основы языка pl/pgSQL
--1.	Напишите анонимный блок для вывода элементов из двумерного массива. Для этого объявите переменную и передайте ей двумерный массивARRAY[ARRAY[ 10, 20, 30], ARRAY[100,200,300]]
--В исполняемой секции блока (BEGIN … END) с помощью цикла организуйте поэлементный вывод
do $$
declare
    arr integer[][] := array[array[10, 20, 30], array[100, 200, 300]];
begin
    for i in 1..2 loop
        for j in 1..3 loop
            raise notice 'arr[%][%] = %', i, j, arr[i][j];
        end loop;
    end loop;
end;
$$;

--вывод: 

--arr[1][1] = 10
--arr[1][2] = 20
--arr[1][3] = 30
--arr[2][1] = 100
--arr[2][2] = 200
--arr[2][3] = 300


--2.	C помощью средств pl\pgsql, напишите анонимный блок, выводящий следующие сообщения:
do $$
declare
	str varchar(20);
begin
    for i in 1..5 loop
		str := '';
		for j in 1..i loop
			str := str || j || ' ';
		end loop;
	raise notice 'NOTICE: %', str;
    end loop;
	for i in reverse 5..1 loop
		str := '';
		for j in 1..i loop
			str := str || j || ' ';
		end loop;
	raise notice 'NOTICE: %', str;
    end loop;
    raise notice 'DO';
end;
$$;

--вывод: 
--NOTICE: 1 
--NOTICE: 1 2 
--NOTICE: 1 2 3 
--NOTICE: 1 2 3 4 
--NOTICE: 1 2 3 4 5 
--NOTICE: 1 2 3 4 5 
--NOTICE: 1 2 3 4 
--NOTICE: 1 2 3 
--NOTICE: 1 2 
--NOTICE: 1 
--DO

--3.	Напишите анонимный блок, который подсчитывает сколько требуется работать в компании, чтобы получать 6-ти значную зарплату. Стартовая зарплата 500$ каждый год рост 10%. Вывести сообщение: «Имея стартовую зарплату [зарплата], надо работать [кол-во лет] лет, чтобы достичь 6-тизначных цифр: [конечная зарплата].».

do $$
declare
    start_salary numeric := 500;
    salary numeric := 500;
    years int := 0;
begin
    while salary < 100000 loop
        salary := salary * 1.10;
        years := years + 1;
    end loop;
    raise notice 'Имея стартовую зарплату %, надо работать % лет, чтобы достичь 6-тизначных цифр: %.', 
                  start_salary, years, round(salary, 3);
end;
$$;
--вывод:
--Имея стартовую зарплату 500, надо работать 56 лет, чтобы достичь 6-тизначных цифр: 103982.528.


--Задание 2. Создание функций и процедур на языке SQL
--
--1.	Создайте скалярную функцию. Функция должна принимать произвольную дату и возвращать количество дней между полученной датой и текущей датой. Протестируйте созданную функцию. Приведите код
create function days(input_date DATE)
returns int as
$$
    select abs(input_date - current_date);
$$ language sql;

select days('2025-02-05');

--2.	Создайте функцию. Функция должна принимать название города, а возвращать список подразделений, расположенных в указанном городе, и количество сотрудников в этих подразделениях.Протестируйте созданную функцию. Приведите код
create function get_departments(city varchar)
returns table(department varchar, emp_cnt int) as
$$
    select d.department_name, count(e.employee_id)
    from schema1.departments d
    left join schema1.employees e on d.department_id = e.department_id
	join schema1.locations l on l.location_id=d.location_id 
    where l.city = city
    group by d.department_id, d.department_name;
$$ language sql;

select get_departments('Saint P.');
--вывод: 
--(AI,1)
--(AI,8) ps: это не ошибка, это таблица департаментов кривая...


--3.	Создайте функцию. Функция должна принимать идентификатор должности, а возвращать название должности и количество сотрудников, занимающих эту должность.Протестируйте созданную функцию. Приведите код
create function get_job(id_job varchar)
returns table(job_title varchar, emp_cnt int) as
$$
    select j.job_title, count(e.employee_id)
    from schema1.jobs j
    left join schema1.employees e on j.job_id = e.job_id
    where j.job_id = id_job
    group by j.job_id, j.job_title;
$$ language sql;

select get_job('ML');
--вывод:
--(Programmer,6)

--4.	Создайте процедуру для добавления новой должности в БД.

create procedure add_job(id_job varchar(10), title varchar(50), salary_min numeric(6), salary_max numeric(6))
as $$
    insert into schema1.jobs (job_id, job_title, min_salary, max_salary) 
    values (id_job, title, salary_min, salary_max);
$$ language sql;

call add_job('EC', 'Economist', 1000, 10000);

--5.	Создайте в вашей БД 2 таблицы: таблицу пользователей users и таблицу друзей пользователей friend
create table public.users (
    user_id serial4 primary key,
    user_name text,
    user_added timestamptz
);

create table public.friends (
    user_id int not null,
    friend_id int not null,
    constraint fk_user foreign key (user_id) 
    references public.users(user_id), 
    constraint fk_friends foreign key (friend_id) 
    references public.users(user_id) 
);
--a.	Заполните таблицы данными
insert into public.users values 
(1, 'Draco Malfoy', current_timestamp),
(2, 'Harry Potter', current_timestamp), 
(3, 'Dobby', current_timestamp),
(4, 'Santa Claus', current_timestamp);

insert into public.friends values 
(1,4), (2,3), (2,4);

--b.	Создайте функцию, которая будет принимать номер пользователя, а выводить идентификатор пользователя и массив всех его друзей

create function get_friends(id_user int)
returns table(id_user int, friendss int[]) as
$$
	select u.user_id, array_agg(f.friend_id) 
    from public.users u
    left join public.friends f on u.user_id = f.user_id
    where u.user_id = id_user
    group by u.user_id;
$$ language sql;

select get_friends(1);
select get_friends(3);
select get_friends(2);