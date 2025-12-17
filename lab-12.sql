--Лабораторная работа 12. Создание процедур и функций на языке plpgsql. Обработка исключений
--
--1.	Создайте функцию, которая будет принимать массив символьных значений и шаблон (например, шаблон телефона).
-- Функция должна возвращать False если хотя бы значение одного элемента массива не соответствует шаблону. 
--Иначе функция должна вернуть – True.Функция должна работать на произвольном количестве элементов массива с произвольным шаблоном.

create function func1(input_array text[], p text)
returns boolean as 
$$
declare
    arr_size int :=array_length(input_array, 1);
begin
	if arr_size=0 or arr_size is null then 
	return true;
	end if;
    for i in 1..arr_size loop    
        if input_array[i] !~ p then
            return false;
        end if;
    end loop;
    return true;
end;
$$ language plpgsql;


select func1(array['8(900)666-3636', '8(924)555-3636'], '^8\(\d{3}\)\d{3}-\d{4}$'); --true
select func1(array[]::text[], 'lalala'); --true
select func1(array['8(900)6663636', '8(924)555-3636'], '^8\(\d{3}\)\d{3}-\d{4}$'); --false
--
--2.	Создайте процедуру. Процедура должна получать идентификатор сотрудника и его телефон. 
--a.	Если номер телефона отличается от существующих номеров сотрудника – необходимо выполнить добавление телефона. И вернуть сообщение о выполненной операции
--b.	Если номер телефона не отличается – выдать соответствующее информационное сообщение
--c.	Если сотрудник с указанным идентификатором отсутствует – процедура должна возвращать сообщение об ошибке

create procedure employee_phone(id_employee numeric, phone text)
as $$
begin
    if not exists (
        select * from schema1.employees
        where employee_id = id_employee) then
        raise exception 'Сотрудник с идентификатором % отсутствует', id_employee;
    end if;

    if exists (
        select * from schema1.employees
        where employee_id = id_employee and phone::schema1.phone_domain = any(phone_number)) then
        raise notice 'Телефон % уже добавлен', phone;
        return;
    end if;

    update schema1.employees 
	set phone_number = array_append(phone_number, phone::schema1.phone_domain)
	where employee_id = id_employee;

    raise notice 'Телефон % добавлен сотруднику %', phone, id_employee;
end;
$$ language plpgsql;

call employee_phone(6, '8(800)566-3335'); --вывод: Телефон 8(800)566-3335 уже добавлен
call employee_phone(6, '8(800)506-3335'); --вывод: Телефон 8(800)506-3335 добавлен сотруднику 6
call employee_phone(76, '8(800)506-3335'); --статистика: SQL Error [P0001]: ERROR: Сотрудник с идентификатором 76 отсутствует



--3.	Создайте процедуру для добавления нового департамента.
--a.	Процедура должна отрабатывать ситуации нарушения ограничений целостности: ошибки ограничений целостности должны перехватываться соответствующими обработчиками. 
--В случае невозможности разрешения конфликта в вызывающую программу должно возвращаться пользовательское сообщение об ошибке. 
--b.	В случае отсутствия обязательных данных, процедура должна возвращать соответствующее пользовательское сообщение.
create procedure add_department(id_department numeric, name_department varchar, id_manager numeric, id_location numeric)
as $$
begin
    if id_department is null or name_department is null or id_manager is null then
        raise exception 'Отсутствуют обязательные данные: department_id, department_name, manager_id не может быть NULL';
    end if;
    insert into schema1.departments values 
 	(id_department, name_department, id_manager, id_location);
exception
    when sqlstate '23505' then 
        raise exception 'Департамент с таким идентификатором или названием уже существует';
    when sqlstate '23503' then
        raise exception 'Ошибка: отсутствует локация с идентификатором %', id_location;
    when others then
        raise exception 'Ошибка при добавлении департамента: %', sqlerrm;
end;
$$ language plpgsql;

call add_department(1, 'ML', 2, 1); --ERROR: Департамент с таким идентификатором или названием уже существует
call add_department(4, 'ML', 2, 1); --добавил
call add_department(1, null, 2, 1); -- ERROR: Ошибка при добавлении департамента: Отсутствуют обязательные данные: department_id, department_name, manager_id не может быть NULL
call add_department(14, 'ML', 55, 77); -- ERROR: Ошибка: отсутствует локация с идентификатором 77





--4.	Создайте процедуру, которая будет получать строку, содержащую адрес, и выполнять разделение этой строки на составляющие и запись в таблицу addresses.
-- Если в таблице уже имеется подобная запись – процедура должна завершаться ошибкой. Если данные адреса добавлены в таблицу процедура должна вернуть информационное сообщение.
create procedure add_location(address text)
as $$
declare
    id numeric;
    str_address varchar;
    p_code varchar;
    city_t varchar;
    country int;
begin
   str_address:=split_part(address, ',', 1);
    p_code:=split_part(address, ',', 2);
    city_t:=split_part(address, ',', 3);
    country:=split_part(address, ',', 4)::int;

    if exists (select * from schema1.locations
        where street_address=str_address 
		and postal_code=p_code and country_id = country and city=city_t) then
        raise exception 'Такой адрес уже существует';
    end if;

	select max(location_id)+1 into id
    from schema1.locations;

    insert into schema1.locations values (id, str_address, p_code, city_t, country);
    raise notice 'Адрес добавлен в таблицу';
end;
$$ language plpgsql;

call add_location('Marata str. 86,62843,Saint P.,1'); -- ERROR: Такой адрес уже существует
call add_location('hse str.,62843,Saint P.,1'); --Вывод: Адрес добавлен в таблицу


--5.	Создайте функцию. Функция должна принимать название города и возвращать список подразделений, расположенных в указанном городе, 
--и количество сотрудников в этих подразделениях в виде json документ следующего вида: 
--{город: название_города, подразделения:[{название:название_подразделения, сотрудники:[список сотрудников]},{}…]}.
--Если в указанном городе нет подразделений функция должна возвращать информационное сообщение


create function get_departmentss(city_t text)
returns json as
$$
declare
    res json;
begin
    if not exists (select * from schema1.departments d
        join schema1.locations l on l.location_id = d.location_id
        where l.city = city_t) then
        raise notice 'В указанном городе нет подразделений';
        return null;
    end if;

    select json_build_object('город', city_t, 'подразделения', 
    json_agg(json_build_object('название', department_name, 'сотрудники', employees)))
    into res
    from (select d.department_name, json_agg(e.employee_id) as employees
    from schema1.departments d
    join schema1.locations l on l.location_id = d.location_id
    join schema1.employees e on e.department_id = d.department_id
    where l.city = city_t
    group by d.department_name) js;
    return res;
end;
$$ language plpgsql;

select get_departmentss('Saint P.'); --{"город" : "Saint P.", "подразделения" : [{"название" : "AI", "сотрудники" : [2, 4, 5, 7, 1, 3, 9, 10, 6]}]}

    

   