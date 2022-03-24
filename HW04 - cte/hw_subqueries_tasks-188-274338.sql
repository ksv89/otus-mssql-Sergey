/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

select pep.PersonID,pep.FullName from Application.People pep with (nolock)
where pep.IsSalesperson = '1'
and	pep.PersonID not in (select DISTINCT SalespersonPersonID from Sales.Invoices with (nolock) where InvoiceDate = '20150704')

;with testcte (SalespersonPersonID) as
(
	select DISTINCT SalespersonPersonID from Sales.Invoices with (nolock) where InvoiceDate = '20150704'
)
select pep.PersonID,pep.FullName from Application.People pep with (nolock)
left join testcte tcte on tcte.SalespersonPersonID = pep.PersonID
where pep.IsSalesperson = '1' and tcte.SalespersonPersonID is NULL

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

select StockItemID, StockItemName, UnitPrice from Warehouse.StockItems with (nolock)
where UnitPrice in (select MIN(UnitPrice) from Warehouse.StockItems)

SELECT StockItemID, StockItemName, UnitPrice 
FROM Warehouse.StockItems where UnitPrice <= ALL (select UnitPrice from Warehouse.StockItems)

;with testcte2 (UnitPrice) as 
(
select MIN(UnitPrice) from Warehouse.StockItems
)
select stc.StockItemID, stc.StockItemName, stc.UnitPrice from Warehouse.StockItems stc with (nolock)
inner join testcte2 tste2 on tste2.UnitPrice = stc.UnitPrice

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

select * from Sales.Customers with (nolock)
where CustomerID in (
select top 5 CustomerID from Sales.CustomerTransactions with (nolock)
group by CustomerID
order by max(TransactionAmount) desc
)

;with testcte3 (CustomerID) as
(
select top 5 CustomerID from Sales.CustomerTransactions with (nolock)
group by CustomerID
order by max(TransactionAmount) desc
)
select * from Sales.Customers cus with (nolock)
inner join testcte3 tcte3 on cus.CustomerID = tcte3.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

select cit.CityID, cit.CityName, pep.FullName from Sales.Orders ord
inner join Sales.Customers cus on cus.CustomerID = ord.CustomerID
inner join Application.Cities cit on cit.CityID = cus.DeliveryCityID
inner join Sales.Invoices inv on inv.OrderID = ord.OrderID
inner join Application.People pep on pep.PersonID = inv.PackedByPersonID
where ord.OrderID in 
(
select OrderID ordl from Sales.OrderLines ordl
where StockItemID in (select top 3 StockItemID from Warehouse.StockItems with (nolock) 
group by StockItemID
order by MAX(UnitPrice) desc)
)
order by CityID

;with testcte4 (OrderID) as
(
select OrderID ordl from Sales.OrderLines ordl
where StockItemID in (select top 3 StockItemID from Warehouse.StockItems with (nolock) 
group by StockItemID
order by MAX(UnitPrice) desc)
)
select cit.CityID, cit.CityName, pep.FullName from Sales.Orders ord
inner join Sales.Customers cus on cus.CustomerID = ord.CustomerID
inner join Application.Cities cit on cit.CityID = cus.DeliveryCityID
inner join Sales.Invoices inv on inv.OrderID = ord.OrderID
inner join Application.People pep on pep.PersonID = inv.PackedByPersonID
inner join testcte4 tcte4 on tcte4.OrderID = ord.OrderID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
