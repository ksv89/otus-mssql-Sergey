.o./*
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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
	CASE grouping(DATEPART(yy, inv.InvoiceDate)) 
    WHEN 1 THEN CAST('TotalAll' as NCHAR(20))
    ELSE CAST(DATEPART(yy, inv.InvoiceDate) as NCHAR(20))
	END as YearInv,

	CASE grouping(DATEPART(m, inv.InvoiceDate)) 
    WHEN 1 THEN CAST('Total' as NCHAR(20))
    ELSE CAST(DATEPART(m, inv.InvoiceDate) as NCHAR(20))
	END as MonthInv,

AVG(ordl.UnitPrice) as AVGPrice, 
SUM(ordl.UnitPrice) as SUMPrice
from Sales.Invoices inv with (nolock)
inner join Sales.OrderLines ordl on ordl.OrderID = inv.OrderID
group by ROLLUP( DATEPART(yy, inv.InvoiceDate), DATEPART(m, inv.InvoiceDate))
order by DATEPART(yy, inv.InvoiceDate),DATEPART(m, inv.InvoiceDate)

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
	CASE grouping(DATEPART(yy, inv.InvoiceDate)) 
    WHEN 1 THEN CAST('TotalAll' as NCHAR(20))
    ELSE CAST(DATEPART(yy, inv.InvoiceDate) as NCHAR(20))
	END as YearInv,

	CASE grouping(DATEPART(m, inv.InvoiceDate)) 
    WHEN 1 THEN CAST('Total' as NCHAR(20))
    ELSE CAST(DATEPART(m, inv.InvoiceDate) as NCHAR(20))
	END as MonthInv,

SUM(ordl.UnitPrice) as SUMPrice
from Sales.Invoices inv with (nolock)
inner join Sales.OrderLines ordl on ordl.OrderID = inv.OrderID
group by DATEPART(yy, inv.InvoiceDate), DATEPART(m, inv.InvoiceDate), PackageTypeID
having 
SUM(ordl.UnitPrice) > 10000 and 
PackageTypeID = 9
order by DATEPART(yy, inv.InvoiceDate),DATEPART(m, inv.InvoiceDate)

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select DATEPART(yy, inv.InvoiceDate) as saleyear, DATEPART(m, inv.InvoiceDate) as salemonth, wst.StockItemName, SUM(ordl.UnitPrice) as SUMPrice, MIN(inv.InvoiceDate) as mindate, COUNT (ordl.StockItemID) as quantity
from Sales.Invoices inv with (nolock)
inner join Sales.OrderLines ordl on ordl.OrderID = inv.OrderID
inner join Warehouse.StockItems wst on wst.StockItemID = ordl.StockItemID
group by DATEPART(yy, inv.InvoiceDate), DATEPART(m, inv.InvoiceDate), wst.StockItemName
having COUNT (ordl.StockItemID) < 51
order by DATEPART(yy, inv.InvoiceDate) , DATEPART(m, inv.InvoiceDate) , COUNT (ordl.StockItemID)

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
