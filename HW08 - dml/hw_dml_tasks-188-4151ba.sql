/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO  Sales.Customers
	(CustomerID, CustomerName, BillToCustomerID,CustomerCategoryID,PrimaryContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,
	AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,WebsiteURL,DeliveryAddressLine1,
	DeliveryPostalCode,PostalAddressLine1,PostalPostalCode,LastEditedBy
	)
VALUES
	(NEXT VALUE FOR Sequences.CustomerID,'Lorin Astrom1', 1,3,3240,3,17054,33475,'2013-01-01',0,0,0,7,'(303) 555-0100','(304) 555-0100','https://ya.ru','Unit 188',90051,'PO Box 7424','90685',1),
	(NEXT VALUE FOR Sequences.CustomerID,'Lorin Astrom2', 1,2,3240,3,12748,26483,'2013-01-01',0,0,0,7,'(313) 555-0100','(304) 555-0100','https://ya.ru','Shop 263',90051,'PO Box 5872','90467',1),
	(NEXT VALUE FOR Sequences.CustomerID,'Lorin Astrom3', 1,3,3240,3,9791,21692,'2013-01-01',0,0,0,7,'(323) 555-0100','(304) 555-0100','https://ya.ru','Unit 72',90051,'PO Box 4080','90298',1),
	(NEXT VALUE FOR Sequences.CustomerID,'Lorin Astrom4', 1,3,3240,3,1604,12748,'2013-01-01',0,0,0,7,'(333) 555-0100','(304) 555-0100','https://ya.ru','Shop 264',90051,'PO Box 1389','90410',1),
	(NEXT VALUE FOR Sequences.CustomerID,'Lorin Astrom5', 1,1,3240,3,25376,17054,'2013-01-01',0,0,0,7,'(343) 555-0100','(304) 555-0100','https://ya.ru','Suite 206',90051,'PO Box 7314','90303',1);

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM cust
	FROM Sales.Customers cust
		WHERE CustomerID = 1092;

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

Update Sales.Customers
SET 
	PhoneNumber = '(777) 666-5555',
	FaxNumber = '(888) 777-6666'
OUTPUT inserted.PhoneNumber as new_phon, inserted.FaxNumber as new_fax, deleted.PhoneNumber as old_phon, deleted.FaxNumber old_fax -- строчка не несет смысловой нагрузки
WHERE CustomerID = 1093;

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

select * into Sales.Customers1 from Sales.Customers where 0 = 1

merge Sales.Customers1 as target
using (select CustomerID,CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,
DeliveryMethodID,DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,
PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,
DeliveryLocation,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,LastEditedBy,ValidFrom,ValidTo  from Sales.Customers with (nolock)
where CustomerID < 15)
AS source
(CustomerID,CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,
DeliveryMethodID,DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,
PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,
DeliveryLocation,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,LastEditedBy,ValidFrom,ValidTo)
on (target.CustomerID = source.CustomerID)

when matched
	then update set CustomerID = source.CustomerID,CustomerName = source.CustomerName,BillToCustomerID = source.BillToCustomerID,CustomerCategoryID = source.CustomerCategoryID,
BuyingGroupID = source.BuyingGroupID,PrimaryContactPersonID = source.PrimaryContactPersonID,AlternateContactPersonID = source.AlternateContactPersonID,
DeliveryMethodID = source.DeliveryMethodID,DeliveryCityID = source.DeliveryCityID,PostalCityID = source.PostalCityID,CreditLimit = source.CreditLimit,
AccountOpenedDate = source.AccountOpenedDate,StandardDiscountPercentage = source.StandardDiscountPercentage,IsStatementSent = source.IsStatementSent,
IsOnCreditHold = source.IsOnCreditHold,PaymentDays = source.PaymentDays,PhoneNumber = source.PhoneNumber,FaxNumber = source.FaxNumber,
DeliveryRun = source.DeliveryRun,RunPosition = source.RunPosition,WebsiteURL = source.WebsiteURL,DeliveryAddressLine1 = source.DeliveryAddressLine1,
DeliveryAddressLine2 = source.DeliveryAddressLine2,DeliveryPostalCode = source.DeliveryPostalCode,DeliveryLocation = source.DeliveryLocation,
PostalAddressLine1 = source.PostalAddressLine1,PostalAddressLine2 = source.PostalAddressLine2,PostalPostalCode = source.PostalPostalCode,
LastEditedBy = source.LastEditedBy,ValidFrom = source.ValidFrom,ValidTo = source.ValidTo

when not matched
	then insert (CustomerID,CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,
DeliveryMethodID,DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,
PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,
DeliveryLocation,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,LastEditedBy,ValidFrom,ValidTo)
	values (source.CustomerID,source.CustomerName,source.BillToCustomerID,source.CustomerCategoryID,source.BuyingGroupID,
source.PrimaryContactPersonID,source.AlternateContactPersonID,source.DeliveryMethodID,source.DeliveryCityID,source.PostalCityID,
source.CreditLimit,source.AccountOpenedDate,source.StandardDiscountPercentage,source.IsStatementSent,source.IsOnCreditHold,
source.PaymentDays,source.PhoneNumber,source.FaxNumber,source.DeliveryRun,source.RunPosition,source.WebsiteURL,
source.DeliveryAddressLine1,source.DeliveryAddressLine2,source.DeliveryPostalCode,source.DeliveryLocation,source.PostalAddressLine1,
source.PostalAddressLine2,source.PostalPostalCode,source.LastEditedBy,source.ValidFrom,source.ValidTo)

OUTPUT deleted.*, $action, inserted.*;

--delete Sales.Customers1;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers" out  "C:\111\111.txt" -T -w -t"fgh%$#" -S DESKTOP-2PMMRFN\CORRTEST'
-----------
select * into Sales.Customers1 from Sales.Customers where 0 = 1
--truncate table Sales.Customers1

	BULK INSERT [WideWorldImporters].[Sales].[Customers1]
				   FROM "C:\111\111.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = 'fgh%$#',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );

select * from Sales.Customers1