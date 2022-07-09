/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

select * from Sales.Customers
select * from Sales.Invoices
select * from Sales.InvoiceLines


/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

USE WideWorldImporters;
GO
CREATE PROCEDURE CB_MaxPrice AS
BEGIN
    select SUM(ExtendedPrice) as suminv, cus.CustomerName from Sales.InvoiceLines invl with (nolock)
		inner join Sales.Invoices inv on inv.InvoiceID = invl.InvoiceID
		inner join Sales.Customers cus on cus.CustomerID = inv.CustomerID
		group by invl.InvoiceID,cus.CustomerName
		having SUM(ExtendedPrice) >= ALL (
			select SUM(ExtendedPrice) from Sales.InvoiceLines invl
			group by invl.InvoiceID
			)
END;

exec CB_MaxPrice


/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

USE WideWorldImporters;
GO
CREATE PROCEDURE CB_PriceForCustomer
(@CastCustomerID int)
AS
begin
select SUM(ExtendedPrice) as suminv, cus.CustomerName from Sales.InvoiceLines invl with (nolock)
		inner join Sales.Invoices inv on inv.InvoiceID = invl.InvoiceID
		inner join Sales.Customers cus on cus.CustomerID = inv.CustomerID
		where inv.CustomerID = @CastCustomerID
		group by invl.InvoiceID,cus.CustomerName
END;

exec CB_PriceForCustomer @CastCustomerID = 1

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

--SET STATISTICS IO ON
--SET STATISTICS TIME ON

--IF OBJECT_ID (N'func_rich_cust', N'IF') IS NOT NULL  
--    DROP FUNCTION func_rich_cust;  
--GO 

--USE WideWorldImporters;
--GO
--Create PROCEDURE CB_Pepople_Item (@StokID int)
--AS
--BEGIN 
--select pep.PersonID, pep.FullName, pep.PhoneNumber from Sales.Orders ord with (nolock)
--inner join Sales.Customers cus on ord.CustomerID = cus.CustomerID
--inner join Sales.OrderLines ordl on ordl.OrderID = ord.OrderID
--inner join Application.People pep on pep.PersonID = cus.PrimaryContactPersonID
--where StockItemID = @StokID

--end;


--USE WideWorldImporters;
--GO
--CREATE FUNCTION CB_Pepople_Item_F(@StokID int)
--RETURNS TABLE
--AS
-- RETURN 
-- (
--  select pep.PersonID, pep.FullName, pep.PhoneNumber from Sales.Orders ord with (nolock)
--		inner join Sales.Customers cus on ord.CustomerID = cus.CustomerID
--		inner join Sales.OrderLines ordl on ordl.OrderID = ord.OrderID
--		inner join Application.People pep on pep.PersonID = cus.PrimaryContactPersonID
--		where StockItemID = @StokID
-- )

--select * from CB_Pepople_Item_F('10') 

--exec CB_Pepople_Item @StokID = 10

USE WideWorldImporters;
GO
CREATE FUNCTION F_PriceForCustomer(@CastCustomerID int)
RETURNS TABLE
AS
 RETURN 
 (
select SUM(ExtendedPrice) as suminv, cus.CustomerName from Sales.InvoiceLines invl with (nolock)
		inner join Sales.Invoices inv on inv.InvoiceID = invl.InvoiceID
		inner join Sales.Customers cus on cus.CustomerID = inv.CustomerID
		where inv.CustomerID = @CastCustomerID
		group by invl.InvoiceID,cus.CustomerName
 )

SET STATISTICS IO ON
SET STATISTICS TIME ON

select * from F_PriceForCustomer ('1')

exec CB_PriceForCustomer @CastCustomerID = 1

-- Для агрегирующих выражений лучше использовать функцию, помоему быстрее работает.

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

CREATE PROCEDURE testcursor 
	@TestCursor CURSOR VARYING OUTPUT
AS
	SET NOCOUNT ON;
	SET @TestCursor = CURSOR
	FORWARD_ONLY STATIC FOR
		select top 10 StockItemName, StockItemID from Warehouse.StockItems 
	OPEN @TestCursor;
GO

DECLARE @MyCursor CURSOR;
EXEC testcursor @TestCursor = @MyCursor OUTPUT;
WHILE (@@FETCH_STATUS = 0)
BEGIN;
	FETCH NEXT FROM @MyCursor;
END;
CLOSE @MyCursor;
DEALLOCATE @MyCursor;
GO

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/


