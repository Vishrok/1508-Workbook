/* **********************************************
 * Simple Table Creation - Columns and Primary Keys
 *
 * File: DDL-Practice.sql
 * Emergency Service & Product
 * Specification Document 1
 * Version 0.0.7
 *
 * Author: Matt Zielke
 ********************************************** */
-- Select the CREATE DATABASE stement below to create the demo database.
-- CREATE DATABASE [ESP-A01]
USE [ESP-A01] -- this is a statement that tells us to switch to a particular database
-- Notice in the database name above, it is "wrapped" in square brackets because 
-- the name had a hypen in it. 
-- For all our other objects (tables, columns, etc), we won't use hypens or spaces, so
-- the use of square brackets are optional.
GO  -- this statement helps to "separate" various DDL statements in our script
    -- so that they are executed as "blocks" of code.

    -- TIP: to refresh this script's knowlege of DB, Press [ctrl] + [shift] + r

    -- To create a database table, we use the CREATE TABLE statement.
-- Note that the order in which we create/drop tables is important
-- because of how the tables are related via Foreign Keys.
/* DROP TABLE statements (to "clean up" the database for re-creation)  */
/*   You should drop tables in the REVERSE order in which you created them */
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'OrderDetails')
    DROP TABLE OrderDetails
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'InventoryItems')
    DROP TABLE InventoryItems
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Orders')
    DROP TABLE Orders
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Customers')
    DROP TABLE Customers

-- To create a database table, we use the CREATE TABLE statement.
-- Note that the order in which we create/drop tables is important
-- because of how the tables are related via Foreign Keys.

-- Note that square brackets around identifiers is a common standard in writing SQL.
-- Databases in SQL groupe all their content into something called a "schema".  Each Database can have one or more schemas.
-- The default schema name is [dbo].
-- Schema names are applied to top level objects like table names.
CREATE TABLE [dbo].[Customers]
(
    -- The body of a CREATE TABLE will identify a comma-separated list of
    -- Column Declarations and Table Constraints.
    [CustomerNumber]  int-- The following is a PRIMARY KEY constraint that has a specific name
        -- Primary Key constraints ensure a row of data being added to the table
        -- will have to have a unique value for the Primary Key column(s)
        CONSTRAINT PK_Customers_CustomerNumber
            PRIMARY KEY
        -- IDENTITY means the database will generate a unique whole-number
        -- value for this column
        IDENTITY(100, 1) -- The first number is the "seed",
                         -- and the last number is the "increment"
                                          NOT NULL, -- NOT NULL means the data is required
    [FirstName]       varchar(50)         NOT NULL,
    [LastName]        varchar(60)         NOT NULL,
    [Address]         varchar(40)         NOT NULL,
    [City]            varchar(35)         NOT NULL,
    [Province]        char(2)
        CONSTRAINT DF_Customers_Province
            DEFAULT ('AB')
        CONSTRAINT CK_Customers_Province
            CHECK (Province = 'AB' OR
                   Province = 'BC' OR
                   Province = 'SK' OR
                   Province = 'MB' OR
                   Province = 'QC' OR
                   Province = 'ON' OR
                   Province = 'NT' OR
                   Province = 'NS' OR
                   Province = 'NB' OR
                   Province = 'NL' OR
                   Province = 'YK' OR
                   Province = 'NU' OR
                   Province = 'PE')                NOT NULL,
    [PostalCode]      char(6)
        CONSTRAINT CK_PostalCode
            CHECK (PostalCode LIKE '[A-Z][0-9][A-Z][0-9][A-Z][0-9]')             NOT NULL,
    [PhoneNumber]     char(13)
        CONSTRAINT CK_Customers_PhoneNumber
            CHECK (PhoneNumber LIKE '([0-9][0-9][0-9])[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')                NULL  -- NULL means the data is optional
)

CREATE TABLE Orders
(
    OrderNumber     int
            CONSTRAINT PK_Orders_OrderNumber
            PRIMARY KEY
        IDENTITY(200, 1)                NOT NULL,
    CustomerNumber  int CONSTRAINT FK_Orders_CustomerNumber_Customers_CustomerNumber
            FOREIGN KEY REFERENCES
            Customers(CustomerNumber)                   NOT NULL,
    [Date]          datetime            NOT NULL,
    Subtotal        money               
        CONSTRAINT CK_Orders_Subtotal
            CHECK (Subtotal > 0)        NOT NULL,
    GST             money       
        CONSTRAINT CK_Orders_GST
            CHECK (GST >= 0)             NOT NULL,
    Total           AS Subtotal + GST --This is now a Computed Column
)

CREATE TABLE InventoryItems
(
    ItemNumber          varchar(5)
        CONSTRAINT PK_InventoryItems_ItemNumber
            PRIMARY KEY                     NOT NULL,
    ItemDescription     varchar(50)             NULL,
    CurrentSalePrice    money
        CONSTRAINT CK_InventoryItems_CurrentSalePrice
            CHECK (CurrentSalePrice > 0)    NOT NULL,
    InStockCount        int                 NOT NULL,
    ReorderLevel        int                 NOT NULL
)

CREATE TABLE OrderDetails
(
    OrderNumber     int
        CONSTRAINT FK_OrderDetails_OrderNumber_Orders_OrderNumber
            FOREIGN KEY REFERENCES
            Orders(OrderNumber)         NOT NULL,
    ItemNumber      varchar(5)
        CONSTRAINT FK_OrderDetails_ItemNumber_InventoryItems_ItemNumber
            FOREIGN KEY REFERENCES
            InventoryItems(ItemNumber)  NOT NULL,
    Quantity        int
        CONSTRAINT DF_OrderDetails_Quantity
            DEFAULT (1)
        CONSTRAINT CK_OrderDetails_Quantity
            CHECK (Quantity > 0)                 NOT NULL,
    SellingPrice    money
        CONSTRAINT CK_OrderDetails_SellingPrice
            CHECK (SellingPrice >= 0)               NOT NULL,
    Amount                   AS Quantity * SellingPrice ,
    -- The following is a Table Constraint
    -- A composite primary key MUST be done as a Table Constraint
    -- because it involves two or more columns
    CONSTRAINT PK_OrderDetails_OrderNumber_ItemNumber
        PRIMARY KEY (OrderNumber, ItemNumber)  -- Specify all the columns in the PK           
)


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'PaymentLogDetails')
    DROP TABLE PaymentLogDetails
-- IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Orders')
--   DROP TABLE Orders
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Payments')
    DROP TABLE Payments

CREATE TABLE Payments
(
    PaymentID     int    
        CONSTRAINT PK_Payments_PaymentID
            PRIMARY KEY                 NOT NULL,
    [Date]        datetime              NOT NULL,
    PaymentAmount   money
        CONSTRAINT CK_Payments_PaymentAmount
            CHECK (PaymentAmount > 0)               NOT NULL,
    PaymentType     varchar(7)
        CONSTRAINT CK_Payments_PaymentType
            CHECK (PaymentType = 'Cash' OR
                   PaymentType =  'Cheque' OR
                   PaymentType =  'Credit')          NOT NULL
)


CREATE TABLE PaymentLogDetails
(
    OrderNumber                int               NOT NULL,
    PaymentID                  int               NOT NULL,
    PaymentNumber           smallint             NOT NULL,
    BalanceOwing              money
        CONSTRAINT CK_PaymentLogDetails_BalanceOwing
            CHECK (BalanceOwing > 0)             NOT NULL,
    DepositBatchNumber         int               NOT NULL
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'PurchaseOrders')
    DROP TABLE PurchaseOrders
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'PurchaseOrderItems')
    DROP TABLE PurchaseOrderItems
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Suppliers')
    DROP TABLE Suppliers

CREATE TABLE Suppliers
(
    SupplierNumber          int
    CONSTRAINT PK_Suppliers_SupplierNumber
                    PRIMARY KEY             NOT NULL,
    SupplierName            varchar(65)     NOT NULL,
    [Address]               varchar(40)     NOT NULL,
    City                    varchar(35)     NOT NULL,
    Province                char(2)         NOT NULL,
    PostalCode              char(6)         NOT NULL,
    Phone                   char(13)        NOT NULL
)

CREATE TABLE PurchaseOrders
(
    PurchaseOrderNumber     int 
        CONSTRAINT PK_PurchaseOrders_PurchaseOrderNumber
                     PRIMARY KEY            NOT NULL,
    SupplierNumber          int
        CONSTRAINT FK_PurchaseOrders_PurchaseOrderNumber_Suppliers_SupplierNumber
            FOREIGN KEY REFERENCES Suppliers (SupplierNumber)          NOT NULL,
    [Date]                  datetime        NOT NULL,
    Subtotal                money           NOT NULL,
    GST                     money           NOT NULL,
    Total                   money           NOT NULL
)

CREATE TABLE PurchaseOrderItems
(
    PurchaseOrderNumber     int
    CONSTRAINT FK_PurchaseOrderItems_PurchaseOrderNumber_PurchaseOrders_PurchaseOrderNumber
            FOREIGN KEY REFERENCES PurchaseOrders (PurchaseOrderNumber)             NOT NULL,
    ItemNumber              varchar(5)
         CONSTRAINT FK_PurchaseOrderItems_ItemNumber_InventoryItems_ItemNumber
            FOREIGN KEY REFERENCES InventoryItems (ItemNumber)    NOT NULL,
    SupplierItemNumber      varchar(25)     NOT NULL,
    SupplierDescription     varchar(25)     NOT NULL,
    Quantity                smallint        NOT NULL,
    Cost                    money           NOT NULL,
    Amount                  money           NOT NULL

    CONSTRAINT PK_PurchaseOrderItems_PurchaseOrderNumber_InventoryItems_ItemNumber
        PRIMARY KEY (PurchaseOrderNumber, ItemNumber)
)



--Let's insert a few rows of data for the tables (DML Statments)
PRINT 'Inserting customer data'
INSERT INTO Customers(FirstName, LastName, [Address], City, PostalCode)
    VALUES ('Clark','Kent','344 Clinton Street', 'Metropolis', 'S0S0N0')
INSERT INTO Customers(FirstName, LastName, [Address], City, PostalCode)
    VALUES ('Jimmy', 'Olsen', '242 River Close', 'Bakerline', 'B4K3R1')
PRINT '-- end of customer data--'
PRINT''

-- Let's write an SQL Query statment to veiw the data in the database
-- Select the customer information
SELECT CustomerNumber, FirstName, LastName,
        [Address] + '' + City + ',' + Province AS 'Customer Address',
        PhoneNumber
FROM Customers

PRINT 'Inserting inventory items'
INSERT INTO InventoryItems(ItemNumber,ItemDescription, CurrentSalePrice, InStockCount, ReorderLevel)
    VALUES ('H8726', 'Cleaning Fan belt', 29.95, 3, 5),
           ('H8621', 'Engine Fan belt', 17.45, 10, 5)

SELECT * FROM InventoryItems

PRINT 'Inserting an order'
INSERT INTO Orders(CustomerNumber, [Date], Subtotal, GST)
    VALUES(100, GETDATE(), 17.45, 0.87)
INSERT INTO OrderDetails(OrderNumber, ItemNumber, Quantity, SellingPrice)
    VALUES (200, 'H8726', 1, 17.45)
PRINT '--end of order data--'
PRINT ''
GO


--A) Allow Address, City, Province, and PostalCode to be NULL

ALTER TABLE Customers
    ALTER COLUMN [Address] varchar (40) NULL
GO

ALTER TABLE Customers
    ALTER COLUMN City varchar(35) NULL
GO

ALTER TABLE Customers
    ALTER COLUMN Province char(2) NULL
GO

ALTER TABLE Customers
    ALTER COLUMN PostalCode char(6) NULL
GO

--B) Add a check constraint on the first and Last name to require at least 2 letters

-- % is a wildcard for zero or more characters (letter, digit, or other character)
-- _ is a wildcard for a single character
-- [] are used to represent a range or set of characters that are allowed

ALTER TABLE Customers
    ADD CONSTRAINT CK_Customers_FirstName
        CHECK (FirstName LIKE '[A-Z][A-Z]%')
ALTER TABLE Customers
    ADD CONSTRAINT CK_Customers_LastName
        CHECK (LastName LIKE '[A-Z][A-Z]%')

INSERT INTO Customers(FirstName, LastName)
    VALUES('Fred', 'Flintstone')
INSERT INTO Customers(FirstName, LastName)
    VALUES('Barney', 'Rubble')
INSERT INTO Customers(FirstName, LastName, PhoneNumber)
    VALUES('Wilma', 'Slaghoople', '(403)555-1212')
INSERT INTO Customers(FirstName, LastName, [Address], [City])
    VALUES('Betty', 'Mcbricker', '103 Granite Road', 'Bedrock')

SELECT CustomerNumber, FirstName, LastName,
       [Address] + ' ' + City + ', ' + Province AS 'Customer Address',
       PhoneNumber
FROM Customers
GO

--C) Add an extra bit of information to Customer table. The client wants to start tracking customer emails, so they can send out statments for outstanding payments that are due at the end of the month.

ALTER TABLE Customers
  ADD Email varchar(30) NULL
GO  

--D) Add indexes to the Customer's First and Last Name columns

CREATE NONCLUSTERED INDEX IX_Customers_FirstName
    ON Customers (FirstName)
CREATE NONCLUSTERED INDEX IX_Customers_LasttName
    ON Customers (LastName)
GO
--E Add a default constraint on the Orders.Date column to use the current date.

ALTER TABLE Orders
    ADD CONSTRAINT DF_Orders_Date
       Default GETDATE

GO

INSERT INTO Orders (CustomerNumber, SubTotal, GST)
    VALUES (101, 150.00, 7.50)

    SELECT OrderNumber, CustomerNumber, Total, [Date]
FROM Orders
GO

--F) Change the InventoryItems.ItemDescription column to be NOT NULL

--G) Add an index on the Item's Description column, to improve search.

--H) Data change requests: All inventory items that are less than $5.00 have to have their prices increased by 10%.

    /* =================Practice SQL Below=============================================*/



