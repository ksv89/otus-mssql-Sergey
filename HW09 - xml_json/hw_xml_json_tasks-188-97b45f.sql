/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

--select * into Warehouse.StockItems1 from Warehouse.StockItems where 0 = 1

--------------- OPENXML ------------

DROP TABLE IF EXISTS #tempxml

CREATE TABLE #tempxml
(
StockItemName nvarchar(100),
SupplierID int,
UnitPackageID int,
OuterPackageID int,
QuantityPerOuter int,
TypicalWeightPerUnit float,
LeadTimeDays int,
IsChillerStock int,
TaxRate decimal,
UnitPrice decimal
)

DECLARE @xmlDocument  xml

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'C:\111\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
as data 

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

--select NEXT VALUE FOR Sequences.StockItemID

insert into #tempxml  
SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] nvarchar(100) '@Name' 
	,[SupplierID] int 'SupplierID'
	,[UnitPackageID] int 'Package/UnitPackageID'
	,[OuterPackageID] int 'Package/OuterPackageID'
	,[QuantityPerOuter] int 'Package/QuantityPerOuter'
	,[TypicalWeightPerUnit] nvarchar(100) 'Package/TypicalWeightPerUnit'
	,[LeadTimeDays] int 'LeadTimeDays'
	,[IsChillerStock] int 'IsChillerStock'
	,[TaxRate] decimal 'TaxRate'
	,[UnitPrice] decimal 'UnitPrice'
	)


merge Warehouse.StockItems as target
using (
select StockItemName,SupplierID,UnitPackageID,OuterPackageID,QuantityPerOuter,TypicalWeightPerUnit,
LeadTimeDays,IsChillerStock,TaxRate,UnitPrice from #tempxml
) AS source
(StockItemName,SupplierID,UnitPackageID,OuterPackageID,QuantityPerOuter,TypicalWeightPerUnit,
LeadTimeDays,IsChillerStock,TaxRate,UnitPrice)
on target.StockItemName = source.StockItemName COLLATE database_default

when matched
	then update set StockItemName = source.StockItemName,
					SupplierID = source.SupplierID,
					UnitPackageID = source.UnitPackageID,
					OuterPackageID = source.OuterPackageID,
					QuantityPerOuter = source.QuantityPerOuter,
					TypicalWeightPerUnit = source.TypicalWeightPerUnit,
					LeadTimeDays = source.LeadTimeDays,
					IsChillerStock = source.IsChillerStock,
					TaxRate = source.TaxRate,
					UnitPrice = source.UnitPrice

when not matched
	then 
	insert (StockItemName,SupplierID,UnitPackageID,OuterPackageID,QuantityPerOuter,TypicalWeightPerUnit,
LeadTimeDays,IsChillerStock,TaxRate,UnitPrice,LastEditedBy)
	values (
		source.StockItemName,
		source.SupplierID,
		source.UnitPackageID,
		source.OuterPackageID,
		source.QuantityPerOuter,
		source.TypicalWeightPerUnit,
		source.LeadTimeDays,
		source.IsChillerStock,
		source.TaxRate,
		source.UnitPrice,
		'1'
	)

	OUTPUT deleted.*, $action, inserted.*;

	drop table #tempxml

------------------------ XQuery ---------------------------------

DROP TABLE IF EXISTS #tempxml
CREATE TABLE #tempxml
(
StockItemName nvarchar(100),
SupplierID int,
UnitPackageID int,
OuterPackageID int,
QuantityPerOuter int,
TypicalWeightPerUnit float,
LeadTimeDays int,
IsChillerStock int,
TaxRate decimal,
UnitPrice decimal
)

DECLARE @x XML,
		@countitem int
SET @x = ( 
  SELECT * FROM OPENROWSET
  (BULK 'C:\111\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB) as d)

insert into #tempxml  
SELECT 
	t.Supplier.value('(@Name)[1]', 'varchar(100)') as Name,
	t.Supplier.value('(SupplierID)[1]', 'int') as SupplierID,
	t.Supplier.value('(Package/UnitPackageID)[1]', 'int') as UnitPackageID,
	t.Supplier.value('(Package/OuterPackageID)[1]', 'int') as OuterPackageID,
	t.Supplier.value('(Package/QuantityPerOuter)[1]', 'int') as QuantityPerOuter,
	t.Supplier.value('(Package/TypicalWeightPerUnit)[1]', 'varchar(100)') as TypicalWeightPerUnit,
	t.Supplier.value('(LeadTimeDays)[1]', 'int') as LeadTimeDays,
	t.Supplier.value('(IsChillerStock)[1]', 'int') as IsChillerStock,
	t.Supplier.value('(TaxRate)[1]', 'decimal') as TaxRate,
	t.Supplier.value('(UnitPrice)[1]', 'decimal') as UnitPrice
	FROM @x.nodes('/StockItems/Item') as t(Supplier)

merge Warehouse.StockItems as target
using (
select StockItemName,SupplierID,UnitPackageID,OuterPackageID,QuantityPerOuter,TypicalWeightPerUnit,
LeadTimeDays,IsChillerStock,TaxRate,UnitPrice from #tempxml
) AS source
(StockItemName,SupplierID,UnitPackageID,OuterPackageID,QuantityPerOuter,TypicalWeightPerUnit,
LeadTimeDays,IsChillerStock,TaxRate,UnitPrice)
on target.StockItemName = source.StockItemName COLLATE database_default

when matched
	then update set StockItemName = source.StockItemName,
					SupplierID = source.SupplierID,
					UnitPackageID = source.UnitPackageID,
					OuterPackageID = source.OuterPackageID,
					QuantityPerOuter = source.QuantityPerOuter,
					TypicalWeightPerUnit = source.TypicalWeightPerUnit,
					LeadTimeDays = source.LeadTimeDays,
					IsChillerStock = source.IsChillerStock,
					TaxRate = source.TaxRate,
					UnitPrice = source.UnitPrice

when not matched
	then 
	insert (StockItemName,SupplierID,UnitPackageID,OuterPackageID,QuantityPerOuter,TypicalWeightPerUnit,
LeadTimeDays,IsChillerStock,TaxRate,UnitPrice,LastEditedBy)
	values (
		source.StockItemName,
		source.SupplierID,
		source.UnitPackageID,
		source.OuterPackageID,
		source.QuantityPerOuter,
		source.TypicalWeightPerUnit,
		source.LeadTimeDays,
		source.IsChillerStock,
		source.TaxRate,
		source.UnitPrice,
		'1'
	)

	OUTPUT deleted.*, $action, inserted.*;

	drop table #tempxml;

-------------------------------------------------------------------

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

DECLARE @xmlDocument  xml

select @xmlDocument =
(select 
StockItemName as '@Name',
SupplierID,
(select UnitPackageID,
OuterPackageID,
QuantityPerOuter,
TypicalWeightPerUnit from
Warehouse.StockItems st
where st.StockItemID = st1.StockItemID
FOR XML PATH (''), TYPE, ROOT ('Package')
),
LeadTimeDays,
IsChillerStock,
TaxRate,
UnitPrice from Warehouse.StockItems st1
FOR XML PATH ('Item'), TYPE, ROOT ('StockItems'))

select @xmlDocument as xmldoc

---- по идее выгружать надо таким образом, но у меня на виртуалке слишком мало прав

DECLARE @fileName VARCHAR(50)
 
DECLARE @sqlStr VARCHAR(1000)
DECLARE @sqlCmd VARCHAR(1000)
 
SET @fileName = 'C:\Users\vez\Desktop\test.xml'
SET @sqlStr = 'select @xmlDocument'
 
SET @sqlCmd = 'bcp "' + @sqlStr + '" queryout ' + @fileName + ' -w -T'
 
EXEC xp_cmdshell @sqlCmd


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select StockItemID,StockItemName,JSON_VALUE(CustomFields, '$.CountryOfManufacture') as valueCF,JSON_VALUE(CustomFields, '$.Tags[0]') as firsttag from Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


drop table if exists #tempxml

CREATE TABLE #tempxml
(
StockItemID int,
tagval nvarchar(100),
)

insert into #tempxml
select StockItemID, cus.value from Warehouse.StockItems
CROSS APPLY OPENJSON(CustomFields,'$.Tags') cus

select stc.StockItemID, stc.StockItemName, JSON_QUERY(CustomFields, '$.Tags') as qur,(select tmp1.tagval +',' as 'data()'  from #tempxml tmp1 where tmp1.StockItemID = stc.StockItemID for xml path('')) as tagfull from #tempxml tmp1
inner join Warehouse.StockItems stc on tmp1.StockItemID = stc.StockItemID 
where tagval = 'Vintage'
