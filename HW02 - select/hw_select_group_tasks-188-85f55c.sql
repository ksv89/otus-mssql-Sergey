/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select sti.StockItemID, sti.StockItemName from Warehouse.StockItems sti with (nolock)
where sti.StockItemName like ('%urgent%') 
or sti.StockItemName like ('Animal%')

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select spl.SupplierID, spl.SupplierName from Purchasing.Suppliers spl with (nolock)
left join Purchasing.PurchaseOrders psh on psh.SupplierID = spl.SupplierID
where psh.PurchaseOrderID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select 
ordl.OrderID, 
convert(varchar, ord.OrderDate, 104), 
DATENAME(m, ord.OrderDate) as MonthOrder,
DATEPART(q, ord.OrderDate) as QuarterOrder,
((DATEPART(m, ord.OrderDate)-1)/4)+1 as ThirdYear,
cus.CustomerName 

from Sales.Orders ord with (nolock)
inner join Sales.OrderLines ordl on ordl.OrderID = ord.OrderID
inner join Sales.Customers cus on cus.CustomerID = ord.CustomerID

order by QuarterOrder, ThirdYear, ordl.OrderID
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 годаээ
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select 
del.DeliveryMethodName, ord.ExpectedDeliveryDate, sup.SupplierName,pep.FullName
from Purchasing.Suppliers sup with (nolock)
inner join Purchasing.PurchaseOrders ord on sup.SupplierID = ord.SupplierID
inner join Application.DeliveryMethods del on del.DeliveryMethodID = sup.DeliveryMethodID
inner join Application.People pep on pep.PersonID = sup.PrimaryContactPersonID
where ord.IsOrderFinalized = 1
and (del.DeliveryMethodID = 8 or del.DeliveryMethodID = 10)
and ExpectedDeliveryDate BETWEEN '20130101' and '20130131'

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10 ord.OrderID,ord.OrderDate,cus.CustomerName,pep.FullName from Sales.Orders ord with (nolock)
inner join Sales.Customers cus on cus.CustomerID = ord.CustomerID
inner join Application.People pep on ord.SalespersonPersonID = pep.PersonID
order by ord.OrderDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select pep.PersonID, pep.FullName, pep.PhoneNumber from Sales.Orders ord with (nolock)
inner join Sales.Customers cus on ord.CustomerID = cus.CustomerID
inner join Sales.OrderLines ordl on ordl.OrderID = ord.OrderID
inner join Application.People pep on pep.PersonID = cus.PrimaryContactPersonID
where StockItemID = 224
