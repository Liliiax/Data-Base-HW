--Лабораторная 9
--Работайте с вашей БД
--Задание 1 Модификация данных в БД
--1 Добавьте в таблицу jobs запись с учетом заданных в таблице ограничений целостности. Используйте конструктор VALUES. Приведите код.
insert into schema1.jobs (job_id, job_title, min_salary, max_salary)
values ('ML', 'Programmer', 1000, 10000);

--2 Напишите ОДИН оператор Insert, для добавления в таблицу jobs 2 записей. Приведите код:
--a. одна запись должна соответствовать ограничениям целостности
--b. одна запись должна нарушать одно или несколько ограничений целостности.
insert into schema1.jobs (job_id, job_title, min_salary, max_salary)
values ('AI', 'Programmer', 5000, 10000), (NULL, 'Programmer', 10000, 5000000);
--c. Каков результат?

--Ответ: из-за ошибки никакие данные не добавятся

--3 Добавьте в таблицу countries (справочник стран) 3 страны. Приведите код
insert into schema1.countries (country_id, country_name)
values (1, 'Russia'), (2, 'United States'), (3, 'England');

--4 Добавьте в таблицу addresses по 2 адреса для каждой страны.
--a. Для ввода данных в столбец country_id используйте подзапрос к таблице countries. Подзапрос должен возвращать country_id по названию страны

--Rem.: я не вижу у себя в бд таблицу addresses, но есть очень похожая таблица locations...

insert into schema1.locations (location_id, street_address,  postal_code,city, country_id)
values (1, 'Marata str. 86', '62843', 'Saint P.', (select country_id from schema1.countries where country_name = 'Russia')),
    (2, 'Italiyanskaya str. 8', '38488', 'Saint P.', (select country_id from schema1.countries where country_name = 'Russia')),
    (3, 'Park Avenue, 70', '38888','New York', (select country_id from schema1.countries where country_name = 'United States')),
    (4, 'Park Avenue, 16',  '38885', 'New Yprk', (select country_id from schema1.countries where country_name = 'United States')),
    (5, '4 Privet Drive', '07773','Little Whinging',  (select country_id from schema1.countries where country_name = 'England')),
    (6, '6 Privet Drive', '36665','Little Whinging',  (select country_id from schema1.countries where country_name = 'England'));

--5 Добавьте в таблицу employees сведения о 3 сотрудниках. Приведите код:
--a. У каждого сотрудника должно быть определено не менее 2 номеров телефонов.

insert into schema1.employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, department_id)
values (1, 'Harry', 'Potter', 'h.p@mail.ru', array['8(800)555-3535'::schema1.phone_domain, '8(900)666-3636'::schema1.phone_domain], '2001-07-31', 'WIZ', 6000, 6),
    (2, 'Steve', 'Harrington', 'steve.harrington@mail.ru', array['8(800)545-3535'::schema1.phone_domain, '8(900)646-3636'::schema1.phone_domain], '1983-07-31', 'AI', 5000, 6),
    (3, 'Damon', 'Salvatore', 'damon.salvatore@mail.ru', array['8(800)565-3535'::schema1.phone_domain, '8(900)676-3636'::schema1.phone_domain], '1861-07-31', 'ML', 5000, 6);

--b.Успешна ли ваша попытка?
--Ответ: нет, так как таблица не поддерживает сейчас хранение нескольких номеров телефона для одного сотрудника, также таблица департаментов пустая, из-за этого также происходит ошибка,
-- так как мы ссылаемся на несуществующий департамент

--c. Что необходимо для заполнения таблицы employees данными?
-- Ответ: изменить структуру таблицы или изменить добавляемые данные, а также добавить данные в таблицу департаментов.
-- структура таблицы изменяется ниже в задании 7, так что здесь изменим добавляемые данные

insert into schema1.departments (department_id, department_name, manager_id, location_id) 
values (1, 'ML', 2, 1);

insert into schema1.departments (department_id, department_name, manager_id, location_id) 
values (2, 'AI', 2, 1);

insert into schema1.employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, department_id)
values (1, 'Harry', 'Potter', 'h.p@mail.ru','8(800)555-3535'::schema1.phone_domain, '2001-07-31', 'ML', 6000, 1),
    (2, 'Steve', 'Harrington', 'steve.harrington@mail.ru',  '8(900)646-3636'::schema1.phone_domain, '1983-07-31', 'ML', 5000, 1),
    (3, 'Damon', 'Salvatore', 'damon.salvatore@mail.ru', '8(900)676-3636'::schema1.phone_domain, '1861-07-31', 'ML', 5000, 1);

--6 Удалите из таблицы countries 1 запись. Приведите код. Объясните полученный результат.
delete from schema1.countries where country_name='England'; 
-- Ответ: выдает ошибку, так как на данную запись ссылается другая таблица (locations)

--7   таблице employees столбец телефон должен поддерживать сохранение массива элементов. При этом каждый элемент массива должен соответствовать требованиям валидации: номер телефона должен соответствовать маске – 8(XXX)XXX-XXXX
alter table schema1.employees 
alter column phone_number type schema1.phone_domain[] 
using array[phone_number]::schema1.phone_domain[];

--8 Добавьте первому сотруднику дополнительный номер телефона.

update schema1.employees 
set phone_number = array_append(phone_number, '8(800)333-7373'::schema1.phone_domain)
where employee_id = 1;

--update schema1.employees 
--set phone_number = array_append(phone_number, '8(800)333-7373'::schema1.phone_domain)
--where employee_id = 2;

--update schema1.employees 
--set phone_number = array_append(phone_number, '8(800)333-7373'::schema1.phone_domain)
--where employee_id = 3;


--9 Измените у второго сотрудника номер 2 телефона (используйте указатель на соответствующий элемент массива)

update schema1.employees 
set phone_number[2] = '8(924)333-5555'::schema1.phone_domain
where employee_id = 2;

--10 У третьего сотрудника удалите 2-ой телефон из списка телефонов.

update schema1.employees 
set phone_number = array_remove(phone_number, phone_number[2])
where employee_id = 3;

--11 Создайте в таблице deparments внешний ключ для связи с таблицей addresses. Внешний ключ не должен «обращать внимания» на уже существующие данные в таблице deparments

alter table schema1.departments 
add constraint fk_departments foreign key (location_id) 
references schema1.locations(location_id)
not valid;

--12 Измените название существующего департамента. Приведите код и результат выполнения операции.
update schema1.departments 
set department_name = 'AI' 
where department_name = 'ML';
--результат: название изменилось 

--13 Удалите из таблицы addresses все адреса. Приведите код. Объясните результат выполнения операция.

delete from schema1.locations; --завершается ошибкой, так как на данную таблицу ссылается внешний ключ

--SQL Error [23503]: ERROR: update or delete on table "locations" violates foreign key constraint "fk_departments" on table "departments"
--Подробности: Key (location_id)=(1) is still referenced from table "departments".
  
  
--Задание 2 Управление транзакциями
--Режим AUTOCOMMIT
--1 Используя режим AUTOCOMMIT внесите в таблицу Страны 2 города в рамках одного оператора:
--a. Одна запись должна быть корректной
--b. Вторая – содержать не корректные данные
insert into schema1.countries (country_id, country_name) 
values (4, 'France'), (null, 'Spain');

--2 Каков результат? Сохранилась ли корректная запись в БД? Почему?

-- Результат: ошибка,  ERROR: null value in column "country_id" of relation "countries" violates not-null constraint
-- никакие данные не сохранились так как в данном режиме один оператор - отдельная транзакция, из-за ошибки в одном из вставляемых объектов откатывается весь оператор

--3 Используя режим AUTOCOMMIT добавьте 2 города:
--a. Один оператор должен добавить корректную запись
--b. Второй оператор должен содержать не корректные данные
insert into schema1.countries (country_id, country_name) 
values (4, 'France');
insert into schema1.countries (country_id, country_name) 
values (null, 'Spain');

--4 Каков результат? Почему?

--Ответ: каждый оператор - отдельная транзакция, поэтому первая транзакция закончилась успешно и данные были добавлены
--в таблицу, а вторая транзакция закончилась ошибкой и данные не были добавлены

--Режим IMPLICIT TRANZACTION (неявные транзакции)
--1 Изучите материал, предоставленный в статье https://habr.com/ru/companies/postgrespro/articles/446652/
--2 Откройте 2 параллельные сессии к вашей БД

--Первая сессия:
--1) Используя режим IMPLICIT TRANZACTION (Режим транзакций (ручной commit)) в
--первой сессии напишите запрос к таблице Сотрудники. Для контроля выведите значения
--столбцов xmin, xmax
begin;
select *, xmin, xmax
from schema1.employees;

--2) С помощью функций txid_current и txid_status узнайте номер вашей транзакции и ее статус
select txid_current(), txid_status(txid_current());
-- 27857   in progress

--3) Добавьте в таблицу нового сотрудника
insert into schema1.employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, department_id)
values (10, 'Evgenii', 'Safronenko', 'e.s@gmail.com',array['8(800)444-4444']::schema1.phone_domain[], '2023-07-31', 'ML', 6000, 1);

--4) Проверьте, что запись видна и убедитесь, что она добавлена в рамках вашей транзакции
select *, xmin, xmax from schema1.employees 
where employee_id = 10; --запись появилась в таблице, xmin=27857

--5) С помощью функции txid_current_snapshot получите сведения о снимке данных
select txid_current_snapshot(); --27857:27857:

--Вторая сессия:
--1) Сделайте выборку из таблицы Сотрудники. Видна ли добавленная в первой сессии запись? Почему?
--Ответ: не видна, так как ручной коммит еще не сделан в первой сессии
select * from schema1.employees 
where employee_id = 10; 

--2) С помощью функции txid_current_snapshot получите сведения о снимке данных.
select txid_current_snapshot(); --27857:27857:

--3) Выполните сравнение снимков, полученных в ваших сессиях и объясните результат.
--в первой сессии транзакция 27857 была не завершена, поэтому обе сессии показывали снимок 27857:27857:

--Первая сессия:
--Зафиксируйте, сделанные изменения
commit;

--Вторая сессия:
--1) Сделайте выборку из таблицы Сотрудники. Видна ли добавленная в первой сессии запись? Почему?
select * from schema1.employees 
where employee_id = 10; 
--Ответ: теперь запись видна, так как мы зафиксировали изменения в другой сессии 

--2) С помощью функции txid_current_snapshot получите сведения о снимке данных.
select txid_current_snapshot(); --27858:27858:

--3) Выполните сравнение снимков, полученных в ваших сессиях и объясните результат.
--после commit транзакция 27857 завершилась, и во второй сессии сформировался новый снимок 27858:27858:, 
--в котором добавленная запись стала видимой, так как транзакция в первой сессии была завершена.



--Режим EXPLICIT TRANZACTION (явные транзакции)
--Задача 1
--1 Используя явную транзакцию выполните следующую задачу:
--a.Добавьте запись о новой должности в таблицу job
--b.Добавьте сотрудника, который эту должность будет занимать.

begin;

insert into schema1.jobs (job_id, job_title, min_salary, max_salary)
values ('D', 'Data Analyst', 8000, 15000);

insert into schema1.employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, department_id)
values (5, 'Draco', 'Malfoy', 'draco.malfoy@mail.ru', array['8(800)566-3335']::schema1.phone_domain[], '2025-02-22', 'DA', 12000, 1);

commit;

--3
--Протестируйте созданную транзакцию. Убедитесь, что в случае если возникает ошибка
--при добавлении должности или сотрудника, никакие данные в БД не сохраняются
begin;

insert into schema1.jobs (job_id, job_title, min_salary, max_salary)
values ('DA', 'Data st', 8000, 15000);

insert into schema1.employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, department_id)
values (5, 'Draco', 'Malfoy', 'draco.malfoy@mail.ru', array['+7(924)123-4567']::schema1.phone_domain[], '2025-02-22', 'DA', 12000, 2);

rollback;

select * from schema1.jobs;
select * from schema1.employees; --произошла ошибка, так как работа с таким job_id уже существует, из-за этого транзакция не выполнилась и никакие данные не были добавлены ни в какую из таблиц 

--Задача 2
--1 Используя явную транзакцию выполните следующую задачу:
--a.Добавьте сотрудника, который должен занимать новую должность.
--b.Добавьте запись о новой должности
begin;

insert into schema1.employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, department_id)
values (6, 'liliia', 'Baskakova', 'lbaskakova@gmail.com', array['+7(924)123-4567']::schema1.phone_domain[], '2025-02-05', 'DS', 10000, 1);

insert into schema1.jobs (job_id, job_title, min_salary, max_salary)
values ('DS', 'Data Scientist', 9000, 16000);

commit;
--2 Каков результат? Почему?
--Ответ: произошла ошибка, так как такой должности еще не существует в таблице должностей, из-за этого вся транзакция была прервана и никакие даннные не были добавлены

--Задача 3
--1 В таблице Сотрудники измените свойство Deferrable ограничения внешнего ключа, ссылающегося на таблицу job:
--a. Ограничение должно поддерживать гранулярность на уровне транзакции
--b.Приведите код, который вы использовали

alter table schema1.employees 
drop constraint foreign_key_emp;

alter table schema1.employees 
add constraint foreign_key_emp foreign key (job_id)
references schema1.jobs(job_id)
deferrable initially deferred;

--2 Используя явную транзакцию:
--a. Измените время проверки ограничений
begin;

set constraints all deferred;
--b. Добавьте сотрудника, который должен занимать новую должность.
insert into schema1.employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, department_id)
values (6, 'liliia', 'Baskakova', 'lbaskakova@gmail.com', array['8(800)566-3335']::schema1.phone_domain[], '2025-02-05', 'DS', 10000, 1);
--c. Добавьте запись о новой должности
insert into schema1.jobs (job_id, job_title, min_salary, max_salary)
values ('DS', 'Data Scientist', 9000, 16000);
--d. Завершите транзакцию
commit;
--3 Каков результат? Почему?
select * from schema1.employees where employee_id=6;
--Все данные добавились, так как мы отложили проверку ограничений до момента окончания всей транзакции,
--а на момент окончания транзакции новая должность уже существовала в таблице jobs 

--Задача 4
--В рамках явной транзакции выполните следующие действия для добавления нового сотрудника и
--перевода его в новый отдел:
--1) Добавьте нового сотрудника
begin; 
insert into schema1.employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, department_id)
values (7, 'Alexandr', 'Hrabrov', 'aihrabrov@gmail.com', array['8(800)566-3335']::schema1.phone_domain[], '2025-02-05', 'DS', 10000, 1);

--2) Сохраните состояние транзакции
savepoint insert_emp;
--3) «Переведите» сотрудника в другой отдел, без указания фильтра
update schema1.employees 
set department_id = 2; 
--4) Проверьте результат. Что произошло?
select * from schema1.employees; 
--из-за отсутствия фильтра все сотрудники перевелись в другой отдел

--5) Отмените «перевод» и выполните его корректно
rollback to savepoint insert_emp;

update schema1.employees 
set department_id = 2 
where employee_id=7;

--6) Зафиксируйте изменения
commit;

--Задание 3 Режим изоляции READ COMMITTED
--1-я сессия:
--1 Выполните проверку уровня изоляции, используемого в текущей сессии.
show transaction isolation level;
--Ответ: read committed
--2 Откройте явную транзакцию с уровнем изоляции по умолчанию.
begin;
--3 Выполните изменение эл.почты первого сотрудника.
update schema1.employees 
set email = 'lala@mail.ru'
where employee_id = 1;
--4 Транзакцию не закрывайте

--2-я сессия:

--5 Откройте второе соединение с БД.
--6 Выполните проверку уровня изоляции, используемого в текущей сессии.
show transaction isolation level;
--Ответ: read committed

--7 Откройте явную транзакцию с уровнем изоляции по умолчанию.
begin;
--8 Выполните запрос к таблице employees. Убедитесь, что изменения, сделанные в параллельной транзакции не видны
select * from schema1.employees where employee_id=1;
--Ответ: email равен hp@mail.ru, то есть не изменился 
--9 Измените эл.почту первого сотрудника: к содержимому столбца добавьте еще один адрес через запятую (значение должно отличаться от введенного в первой транзакции) .
--НЕ ЗАМЕНА СОДЕРЖИМОГО, а именно ДОБАВЛЕНИЕ!
update schema1.employees 
set email = concat(email, ', dc@mail.ru')
where employee_id = 1;

--на этом моменте у меня эта команда просто зависает, не выполняется и останавливается ,
-- я так понимаю из-за того, что первая транзакция не завершена и не дает изменить эмейл...

--10 Зафиксируйте транзакцию. Каков результат?
commit;

--1-я сессия:
--11 Зафиксируйте транзакцию и проверьте адрес эл.почты у первого сотрудника. Объясните
--результат.
commit;
select * from schema1.employees where employee_id=1;
--Ответ: почта равна тому значению, на которое была изменена в ходе первой транзакции ('lala@mail.ru') 

--12 Откройте новую явную транзакцию с уровнем изоляции по умолчанию.
begin;
--13 Напишите запрос к таблице сотрудники
select * from schema1.employees;
--2-я сессия:
--14 Откройте явную транзакцию с уровнем изоляции по умолчанию.
begin;
--15 Измените второй телефон третьего сотрудника. Используйте для этого соответствующую
--функцию массива
update schema1.employees 
set phone_number[2] = '8(924)337-5555'::schema1.phone_domain
where employee_id = 3;
--16 Зафиксируйте транзакцию.
commit;
--1-я сессия:
--17 Напишите запрос к таблице сотрудники.
select * from schema1.employees;
--18 Как изменился результат выборки и почему?
--у третьего сотрудника изменился второй номер телефона, который мы изменили в рамках второй сессии, так как транзакцию во второй сессии мы завершили
--19 Закройте транзакцию
commit;

--Управление конкурентным доступом (REPEATABLE READ)
--Выполните все описанные в Задании 3 действия для транзакций, работающих с уровнем
--изоляции REPEATABLE READ. Выполните анализ полученных результатов.

--1-я сессия:
--1 Выполните проверку уровня изоляции, используемого в текущей сессии.
show transaction isolation level;
--Ответ: read committed
--2 Откройте явную транзакцию с уровнем изоляции по умолчанию.
begin transaction isolation level repeatable read; 
show transaction isolation level; --repeatable read

--3 Выполните изменение эл.почты первого сотрудника.
update schema1.employees 
set email = 'lolo@mail.ru'
where employee_id = 1;
--4 Транзакцию не закрывайте

--2-я сессия:

--5 Откройте второе соединение с БД.
--6 Выполните проверку уровня изоляции, используемого в текущей сессии.
show transaction isolation level;
--Ответ: read committed

--7 Откройте явную транзакцию с уровнем изоляции по умолчанию.
begin transaction isolation level repeatable read;
--8 Выполните запрос к таблице employees. Убедитесь, что изменения, сделанные в параллельной транзакции не видны
select * from schema1.employees where employee_id=1;
--Ответ: email равен lala@mail.ru, то есть не изменился 
--9 Измените эл.почту первого сотрудника: к содержимому столбца добавьте еще один адрес через запятую (значение должно отличаться от введенного в первой транзакции) .
--НЕ ЗАМЕНА СОДЕРЖИМОГО, а именно ДОБАВЛЕНИЕ!
update schema1.employees 
set email = concat(email, ', li@mail.ru')
where employee_id = 1;

--у меня все так же на этом моменте команда виснет и все(((

--10 Зафиксируйте транзакцию. Каков результат?
commit;

--1-я сессия:
--11 Зафиксируйте транзакцию и проверьте адрес эл.почты у первого сотрудника. Объясните
--результат.
commit;
select * from schema1.employees where employee_id=1; --почта: lolo@mail.ru,


--12 Откройте новую явную транзакцию с уровнем изоляции по умолчанию.
begin transaction isolation level repeatable read;
--13 Напишите запрос к таблице сотрудники
select * from schema1.employees;
--2-я сессия:
--14 Откройте явную транзакцию с уровнем изоляции по умолчанию.
begin transaction isolation level repeatable read;
--15 Измените второй телефон третьего сотрудника. Используйте для этого соответствующую
--функцию массива
update schema1.employees 
set phone_number[2] = '8(924)333-1111'::schema1.phone_domain
where employee_id = 3;
--16 Зафиксируйте транзакцию.
commit;
--1-я сессия:
--17 Напишите запрос к таблице сотрудники.
select * from schema1.employees;
--18 Как изменился результат выборки и почему?
--у третьего сотрудника второй номер телефона, который мы изменили в рамках второй сессии, не поменялся здесь из-за режима транзакции repeatable read 
--19 Закройте транзакцию
commit;

select * from schema1.employees; -- а вот теперь поменялся после завершения транзакции

