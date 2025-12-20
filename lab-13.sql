--Лабораторная 13. Создание триггеров
--
--1.	Реализуйте следующее решение:
--a.	Создайте триггерную функцию check_salary, которая вызывает исключение, если новая зарплата сотрудника больше старой на 100%.
create function check_salary()
returns trigger as
$$
begin
    if new.salary >= old.salary * 2 then
        raise exception 'Новая зарплата % больше старой зарплаты %', 
                        new.salary, old.salary;
    end if;
    return new;
end;
$$ language plpgsql;
--b.	Создайте триггер BEFORE UPDATE - before_update_salary, который вызывает функцию check_salary перед обновлением значения в столбце salary для каждой записи.
create trigger before_update_salary
before update of salary on schema1.employees
for each row
execute function check_salary();
--c.	Обновите зарплату сотрудника с идентификатором 1 и убедитесь, что триггер сработал и вернул соответствующее сообщение

update schema1.employees 
set salary = salary * 2 
where employee_id = 1; -- ERROR: Новая зарплата 96000.00 больше старой зарплаты 48000.00

--d.	Переименуйте before_update_salary триггер в salary_before_update
alter trigger before_update_salary on schema1.employees 
rename to salary_before_update;

--e.	Отключите триггер salary_before_update.  Обновите зарплату сотрудника с идентификатором 2 и убедитесь, что триггер не сработал. 
alter table schema1.employees disable trigger salary_before_update;

update schema1.employees 
set salary = salary * 2 
where employee_id = 2; --все хорошо, зп изменилась

--f.	Измените имя функции check_salary на validate_salary.
alter function check_salary() rename to validate_salary;
--g.	Измените «привязку» триггера к триггерной функции validate_salary
drop trigger salary_before_update on schema1.employees;

create trigger salary_before_update
before update of salary on schema1.employees
for each row
execute function validate_salary();

alter table schema1.employees enable trigger salary_before_update;
--h.	Выполните проверку

update schema1.employees 
set salary = salary * 2
where employee_id = 3;  -- ERROR: Новая зарплата 10000.00 больше старой зарплаты 5000.00


--2.	Добавьте в таблицу employees 2 новых столбца:
--a.	login – для сохранения учетной записи сотрудника
--b.	password– для сохранения пароля сотрудника
alter table schema1.employees
add column login text, 
add column password text;

--3.	Создайте триггер, который будет срабатывать при добавлении или изменении записей о сотрудниках:
--a.	Login и password не должны быть одинаковыми, при этом их длина должна быть больше или равна 8 символов. Поля не должны содержать NULL значения.
--b.	В случае нарушения данных условий должно генерироваться пользовательское исключение, предоставляющее информацию о нарушении
create function check_emp()
returns trigger as
$$
begin
    if new.login is null or new.password is null then
        raise exception 'login и password не должны содержать null значения';
    end if;

    if char_length(new.login)<8 or char_length(new.password)<8 then
        raise exception 'login и password должны содержать не менее 8 символов.';
    end if;
    if new.login = new.password then
        raise exception 'login и password не должны совпадать';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger check_trig
before insert or update on schema1.employees
for each row
execute function check_emp();


--c.	Протестируйте ваш триггер
insert into schema1.employees values
(11, 'ivan', 'ivanov', 'sss', array['8(800)555-3535'::schema1.phone_domain], '1896-02-02', 'ML', 5000, 1, 'aaaaaaaa', 'aaaaaaaa'); -- ERROR: login и password не должны совпадать

insert into schema1.employees values
(12, 'sergey', 'ivanov', 'sss', array['8(800)555-3535'::schema1.phone_domain], '1896-02-02', 'ML', 5000, 1, 'aaaaa', 'aaaaaaaa'); -- ERROR: login и password должны содержать не менее 8 символов.

insert into schema1.employees values
(13, 'andrey', 'ivanov', 'sss', array['8(800)555-3535'::schema1.phone_domain], '1896-02-02', 'ML', 5000, 1, null, 'aaaaaaaa'); -- ERROR: login и password не должны содержать null значения

insert into schema1.employees values
(11, 'ivan', 'ivanov', 'sss', array['8(800)555-3535'::schema1.phone_domain], '1896-02-02', 'ML', 5000, 1, 'aaaaanaa', 'aaaaaaaa'); -- данные добавлены



--d.	Удалите созданный триггер
drop trigger check_trig on schema1.employees;
drop function check_emp();

--4.	Необходимо реализовать процедурную поддержку процесса карьерных перемещений сотрудников - таблица job_history в схеме schema1
--a.	Таблица employees должна содержать только актуальную информацию о активных сотрудниках
--b.	Таблица job_history должна содержать информацию о всех «изменениях» сотрудника: прием, увольнение, изменение должности, изменение отдела, изменение заработной платы.
--c.	Тип изменения должен сохранятся в столбце type_operation в таблице job_history
alter table schema1.job_history
add column type_operation varchar(50) not null;

create function history_job()
returns trigger
as $$
begin
    if tg_op = 'INSERT' then
        insert into schema1.job_history values
		(new.employee_id, new.hire_date, '2100-01-01', new.job_id, new.department_id, new.salary, 'прием');
        return new;
    end if;

    if tg_op = 'UPDATE' then
        if new.job_id <> old.job_id then
            update schema1.job_history
            set end_date = current_date
            where employee_id = old.employee_id and job_id=old.job_id and end_date = '2100-01-01';

            insert into schema1.job_history values (new.employee_id, current_date, '2100-01-01', new.job_id, new.department_id, new.salary, 'изменение должности');
        
		elsif new.department_id <> old.department_id then
            update schema1.job_history
            set end_date = current_date
            where employee_id = old.employee_id and department_id=old.department_id and end_date = '2100-01-01';

            insert into schema1.job_history values (new.employee_id, current_date, '2100-01-01', new.job_id, new.department_id, new.salary, 'изменение отдела');
        
		elsif new.salary <> old.salary then
            update schema1.job_history
            set end_date = current_date
            where employee_id = old.employee_id and salary=old.salary and end_date = '2100-01-01';

            insert into schema1.job_history values (new.employee_id, current_date, '2100-01-01', new.job_id, new.department_id, new.salary, 'изменение заработной платы');
        end if;
        return new;
    end if;

    if tg_op = 'DELETE' then
		insert into schema1.job_history values (old.employee_id, old.hire_date, current_date, old.job_id, old.department_id, old.salary, 'увольнение');
        return old;
    end if;

    return null;
end;
$$ language plpgsql;


create trigger job_insert
after insert on schema1.employees
for each row
execute function history_job();

create trigger job_update
after update on schema1.employees
for each row
execute function history_job();

create trigger job_delete
before delete on schema1.employees
for each row
execute function history_job();


insert into schema1.employees values (100, 'Matanaliz', 'Matanalizov', 'matan@mail.ru', array['8(900)666-3636'::schema1.phone_domain], '2024-09-01', 'ML', 6000, 2);

update schema1.employees 
set salary = 10000 where employee_id = 100;

select * from schema1.job_history where employee_id = 100; --записи появились 
--100  2024-09-01   2100-01-01  ML   2   6000   прием
--100  2025-12-21   2100-01-01  ML   2   10000  изменение заработной платы


--5.	Необходимо реализовать процедурную поддержку для проверки номеров телефона сотрудников на соответствие заданному шаблону. 
--Проверка должна осуществляться как при вставке новых записей о сотрудниках, так и при изменении существующих.

create function check_phones()
returns trigger
as $$
declare
    phone text;
begin
    foreach phone in array new.phone_number
    loop
        if phone is not null and phone !~ '^8\(\d{3}\)\d{3}-\d{4}$' then
        raise exception
        'Неверный формат телефона';
        end if;
    end loop;
    return new;
end;
$$ language plpgsql;

create trigger phone_update
before update on schema1.employees
for each row
execute function check_phones();

create trigger phone_insert
before insert on schema1.employees
for each row
execute function check_phones();

insert into schema1.employees values (10000, 'Matanaliz', 'Matanalizov', 'matan@mail.ru', array['8(900)666-3636'], '2024-09-01', 'ML', 6000, 2); --успешно

insert into schema1.employees values (101, 'Matanaliz', 'Matanalizov', 'matan@mail.ru', array['89006663636'], '2024-09-01', 'ML', 6000, 2); --ошибка