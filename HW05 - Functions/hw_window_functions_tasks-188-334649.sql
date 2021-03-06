/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

select inv.InvoiceID, cus.CustomerName, inv.InvoiceDate, cust.AmountExcludingTax,hhh.sumAmountExcludingTax
from Sales.Invoices inv with (nolock)
inner join Sales.Customers cus on cus.CustomerID = inv.CustomerID
inner join Sales.CustomerTransactions cust on cust.InvoiceID = inv.InvoiceID
inner join (
select ct1.InvoiceID as InvoiceID, ct1.AmountExcludingTax as AmountExcludingTax, SUM(ct2.AmountExcludingTax) as sumAmountExcludingTax
from Sales.CustomerTransactions ct1
inner join Sales.CustomerTransactions ct2 on ct1.InvoiceID >=ct2.InvoiceID and ct1.InvoiceID > '39071' and ct2.InvoiceID > '39071'
where 1=1
--and YEAR(ct1.TransactionDate) = YEAR(ct1.TransactionDate) and MONTH(ct1.TransactionDate) = MONTH(ct2.TransactionDate)
and ct1.InvoiceID > '39071'
group by ct1.InvoiceID, ct1.AmountExcludingTax
) as hhh on hhh.InvoiceID = inv.InvoiceID
where inv.InvoiceDate > '20141231'
group by inv.InvoiceID, cus.CustomerName, inv.InvoiceDate, cust.AmountExcludingTax,hhh.sumAmountExcludingTax
order by inv.InvoiceID

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select inv.InvoiceID, cus.CustomerName, inv.InvoiceDate, cust.AmountExcludingTax
,SUM (cust.AmountExcludingTax) OVER ( order by YEAR(InvoiceDate),MONTH(InvoiceDate)) as CumulativeTotalMonth
from Sales.Invoices inv with (nolock)
inner join Sales.Customers cus on cus.CustomerID = inv.CustomerID
inner join Sales.CustomerTransactions cust on cust.InvoiceID = inv.InvoiceID
where inv.InvoiceDate > '20141231'
group by inv.InvoiceID, cus.CustomerName, inv.InvoiceDate, cust.AmountExcludingTax
order by inv.InvoiceID

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select * from (
select stc.StockItemName, MONTH(OrderDate) as mon, YEAR(OrderDate) as yearc, COUNT(ordl.StockItemID) as stccnt, ROW_NUMBER() OVER (PARTITION BY YEAR(OrderDate),MONTH(OrderDate) order by COUNT(ordl.StockItemID) DESC) as rn
from Sales.Orders ord
inner join Sales.OrderLines ordl on ordl.OrderID = ord.OrderID
inner join Warehouse.StockItems stc on stc.StockItemID = ordl.StockItemID
where OrderDate between '20150101' and '20161231'
group by YEAR(OrderDate),MONTH(OrderDate),ordl.StockItemID,stc.StockItemName
) as tbl1
where tbl1.rn <=2
order by yearc,mon,rn

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select 
StockItemID, StockItemName
,ROW_NUMBER () over (PARTITION BY SUBSTRING(StockItemName, 1, 1) order by StockItemName) as rn_namesort
,COUNT(StockItemID) over () as countall
,COUNT (StockItemID) over (PARTITION BY SUBSTRING(StockItemName, 1, 1) ) as xxx
,LEAD (StockItemID,1) over (order by StockItemName) as nextIDforname
,LAG (StockItemID,1) over (order by StockItemName) as prevIDforname
,CAST (LAG (StockItemName,2,'NO items') over (order by StockItemName) as nvarchar(50)) as next2
,NTILE (30) over (order by TypicalWeightPerUnit) as gr
from Warehouse.StockItems
group by StockItemID,StockItemName,TypicalWeightPerUnit
order by StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

with cte as (
select SalespersonPersonID, CustomerID,InvoiceDate,InvoiceID, ROW_NUMBER() over (PARTITION BY SalespersonPersonID order by InvoiceDate desc, InvoiceID) as rn from Sales.Invoices)
select cte.SalespersonPersonID, pep.FullName, cte.CustomerID, cus.CustomerName, cte.InvoiceDate, cust.AmountExcludingTax 
from cte
inner join Application.People pep on cte.SalespersonPersonID = pep.PersonID
inner join Sales.Customers cus on cus.CustomerID = cte.CustomerID
inner join Sales.CustomerTransactions cust on cust.InvoiceID = cte.InvoiceID
where rn =1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

with cte as (
select inv.CustomerID, cus.CustomerName, stc.StockItemID, stc.UnitPrice, inv.InvoiceDate, ROW_NUMBER() over (PARTITION BY inv.CustomerID order by stc.UnitPrice desc,invl.InvoiceID desc) as rn from Sales.InvoiceLines invl
inner join Sales.Invoices inv on inv.InvoiceID = invl.InvoiceID
inner join Warehouse.StockItems stc on stc.StockItemID = invl.StockItemID
inner join Sales.Customers cus on cus.CustomerID = inv.CustomerID
)
select * from cte
where rn <=2
order by CustomerID

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 