/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

select * from (
select SUBSTRING(CustomerName,CHARINDEX('(',CustomerName)+1,((CHARINDEX(')',CustomerName)-(CHARINDEX('(',CustomerName)+1)))) as cusn, 1 as con2 ,CONVERT(nvarchar,CAST(DATEADD(mm,DATEDIFF(mm,0,ord.OrderDate),0) as date),104) as InvoiceMonth
from Sales.Orders ord 
inner join Sales.Customers cus on cus.CustomerID = ord.CustomerID
where ord.CustomerID between 2 and 6
) as asdf
PIVOT
(
sum(con2)
FOR cusn IN ("Gasport, NY","Jessie, ND","Medicine Lodge, KS","Peeples Valley, AZ","Sylvanite, MT")
)
as PVT_my;

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select cus1.CustomerName, cus2.*
from Sales.Customers cus1
CROSS APPLY (
select PostalAddressLine1 from Sales.Customers cus2
where cus2.CustomerID = cus1.CustomerID and CustomerName like ('%Tailspin Toys%')
union
select PostalAddressLine2 from Sales.Customers cus2
where cus2.CustomerID = cus1.CustomerID and CustomerName like ('%Tailspin Toys%')
union
select DeliveryAddressLine1 from Sales.Customers cus2
where cus2.CustomerID = cus1.CustomerID and CustomerName like ('%Tailspin Toys%')
union
select DeliveryAddressLine2 from Sales.Customers cus2
where cus2.CustomerID = cus1.CustomerID and CustomerName like ('%Tailspin Toys%')
) as cus2
order by cus1.CustomerID

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select CountryID,coun2.* from Application.Countries coun1
cross apply (
select CountryName, IsoAlpha3Code from Application.Countries coun2
where coun2.CountryID = coun1.CountryID
union
select CountryName, cast(IsoNumericCode as nvarchar(20)) from Application.Countries coun2
where coun2.CountryID = coun1.CountryID
) as coun2
order by coun1.CountryID

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

with cte as (select ROW_NUMBER() over(PARTITION BY ord.CustomerID ORDER BY stc.UnitPrice DESC,ord.OrderDate) as rn, 
ord.CustomerID, stc.StockItemID, stc.UnitPrice, ord.OrderDate from Sales.Orders ord
inner join Sales.OrderLines	ordl on ordl.OrderID = ord.OrderID
inner join Warehouse.StockItems stc on ordl.StockItemID = stc.StockItemID 
)
select cte.CustomerID,cus.CustomerName,cte.StockItemID,cte.UnitPrice,cte.OrderDate from Sales.Customers cus
cross apply (
select * from cte
where rn <=2
and cte.CustomerID = cus.CustomerID
) as cte
order by cte.CustomerID,cte.UnitPrice desc