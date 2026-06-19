/*
Final Project: Fresh Market Database
Student: Megan Patricia Copple
Purpose: Database for a local fruit and vegetable shop that sells products in store and online.
This script creates tables, sample records, constraints, a view, stored procedures, a trigger,
a transaction-based purchase process, and database users for Admin and Staff roles.
*/

-- STEP 0: Create and use the database
IF DB_ID('FreshMarketFinalProject') IS NULL
BEGIN
    CREATE DATABASE FreshMarketFinalProject;
END;
GO

USE FreshMarketFinalProject;
GO

-- Drop objects in safe order for repeat testing
IF OBJECT_ID('dbo.trg_Customers_CapitalizeLastName', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_Customers_CapitalizeLastName;
IF OBJECT_ID('dbo.vw_ReceiptTotals', 'V') IS NOT NULL DROP VIEW dbo.vw_ReceiptTotals;
IF OBJECT_ID('dbo.usp_GetCustomerOrders', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_GetCustomerOrders;
IF OBJECT_ID('dbo.usp_ProcessPurchase', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ProcessPurchase;
IF OBJECT_ID('dbo.Payments', 'U') IS NOT NULL DROP TABLE dbo.Payments;
IF OBJECT_ID('dbo.OrderItems', 'U') IS NOT NULL DROP TABLE dbo.OrderItems;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL DROP TABLE dbo.Categories;
GO

/*
STEP 1: Identify at least five tables.
Tables created: Categories, Customers, Products, Orders, OrderItems, and Payments.
*/
CREATE TABLE dbo.Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL UNIQUE,
    CategoryDescription VARCHAR(150) NULL
);
GO

CREATE TABLE dbo.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(20) NULL,
    PurchaseType VARCHAR(20) NOT NULL
        CONSTRAINT CK_Customers_PurchaseType CHECK (PurchaseType IN ('In Store', 'Online')),
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE dbo.Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT NOT NULL,
    ProductName VARCHAR(75) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL CONSTRAINT CK_Products_UnitPrice CHECK (UnitPrice >= 0),
    QuantityInStock INT NOT NULL CONSTRAINT CK_Products_QuantityInStock CHECK (QuantityInStock >= 0),
    UnitOfMeasure VARCHAR(20) NOT NULL,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES dbo.Categories(CategoryID)
);
GO

CREATE TABLE dbo.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    OrderType VARCHAR(20) NOT NULL CONSTRAINT CK_Orders_OrderType CHECK (OrderType IN ('In Store', 'Online')),
    OrderStatus VARCHAR(20) NOT NULL DEFAULT 'Pending'
        CONSTRAINT CK_Orders_OrderStatus CHECK (OrderStatus IN ('Pending', 'Paid', 'Cancelled')),
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) REFERENCES dbo.Customers(CustomerID)
);
GO

CREATE TABLE dbo.OrderItems (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CONSTRAINT CK_OrderItems_Quantity CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL CONSTRAINT CK_OrderItems_UnitPrice CHECK (UnitPrice >= 0),
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID),
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductID) REFERENCES dbo.Products(ProductID)
);
GO

CREATE TABLE dbo.Payments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL UNIQUE,
    PaymentDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    PaymentMethod VARCHAR(30) NOT NULL
        CONSTRAINT CK_Payments_Method CHECK (PaymentMethod IN ('Cash', 'Credit Card', 'Debit Card', 'Online')),
    AmountPaid DECIMAL(10,2) NOT NULL CONSTRAINT CK_Payments_AmountPaid CHECK (AmountPaid >= 0),
    CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID)
);
GO

/* STEP 7: Trigger to capitalize customers' last names. */
CREATE TRIGGER dbo.trg_Customers_CapitalizeLastName
ON dbo.Customers
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET LastName = UPPER(i.LastName)
    FROM dbo.Customers c
    INNER JOIN inserted i ON c.CustomerID = i.CustomerID;
END;
GO

/* STEP 3: Insert at least 10 entries in each table. */
INSERT INTO dbo.Categories (CategoryName, CategoryDescription) VALUES
('Leafy Greens', 'Fresh green vegetables'),
('Root Vegetables', 'Vegetables that grow underground'),
('Citrus Fruits', 'Fresh citrus fruits'),
('Berries', 'Small fresh fruits'),
('Tropical Fruits', 'Fruits grown in warm climates'),
('Melons', 'Fresh melon varieties'),
('Herbs', 'Fresh cooking herbs'),
('Apples and Pears', 'Common tree fruits'),
('Peppers', 'Sweet and spicy peppers'),
('Tomatoes', 'Fresh tomato varieties');
GO

INSERT INTO dbo.Customers (FirstName, LastName, Email, Phone, PurchaseType) VALUES
('Alyssa', 'reyes', 'alyssa.reyes@email.com', '253-555-0101', 'Online'),
('Jordan', 'miller', 'jordan.miller@email.com', '253-555-0102', 'In Store'),
('Maria', 'santos', 'maria.santos@email.com', '253-555-0103', 'Online'),
('Kevin', 'brown', 'kevin.brown@email.com', '253-555-0104', 'In Store'),
('Nina', 'garcia', 'nina.garcia@email.com', '253-555-0105', 'Online'),
('Sam', 'wilson', 'sam.wilson@email.com', '253-555-0106', 'In Store'),
('Grace', 'lee', 'grace.lee@email.com', '253-555-0107', 'Online'),
('Ethan', 'clark', 'ethan.clark@email.com', '253-555-0108', 'In Store'),
('Lina', 'nguyen', 'lina.nguyen@email.com', '253-555-0109', 'Online'),
('Noah', 'johnson', 'noah.johnson@email.com', '253-555-0110', 'In Store');
GO

INSERT INTO dbo.Products (CategoryID, ProductName, UnitPrice, QuantityInStock, UnitOfMeasure) VALUES
(1, 'Spinach', 2.99, 40, 'bag'),
(2, 'Carrots', 1.49, 75, 'lb'),
(3, 'Oranges', 0.99, 100, 'each'),
(4, 'Strawberries', 4.99, 35, 'box'),
(5, 'Mangoes', 1.99, 50, 'each'),
(6, 'Watermelon', 6.99, 20, 'each'),
(7, 'Basil', 2.49, 25, 'bunch'),
(8, 'Fuji Apples', 1.29, 80, 'each'),
(9, 'Bell Peppers', 1.79, 60, 'each'),
(10, 'Roma Tomatoes', 2.19, 55, 'lb');
GO

INSERT INTO dbo.Orders (CustomerID, OrderDate, OrderType, OrderStatus) VALUES
(1, '2026-06-01T09:15:00', 'Online', 'Paid'),
(2, '2026-06-01T10:20:00', 'In Store', 'Paid'),
(3, '2026-06-02T11:30:00', 'Online', 'Paid'),
(4, '2026-06-02T12:00:00', 'In Store', 'Paid'),
(5, '2026-06-03T13:45:00', 'Online', 'Paid'),
(6, '2026-06-03T15:10:00', 'In Store', 'Paid'),
(7, '2026-06-04T09:50:00', 'Online', 'Paid'),
(8, '2026-06-04T14:30:00', 'In Store', 'Paid'),
(9, '2026-06-05T16:00:00', 'Online', 'Paid'),
(10, '2026-06-05T17:25:00', 'In Store', 'Paid');
GO

INSERT INTO dbo.OrderItems (OrderID, ProductID, Quantity, UnitPrice) VALUES
(1, 1, 2, 2.99),
(2, 2, 5, 1.49),
(3, 3, 8, 0.99),
(4, 4, 2, 4.99),
(5, 5, 6, 1.99),
(6, 6, 1, 6.99),
(7, 7, 3, 2.49),
(8, 8, 10, 1.29),
(9, 9, 4, 1.79),
(10, 10, 5, 2.19);
GO

INSERT INTO dbo.Payments (OrderID, PaymentDate, PaymentMethod, AmountPaid) VALUES
(1, '2026-06-01T09:17:00', 'Online', 5.98),
(2, '2026-06-01T10:22:00', 'Cash', 7.45),
(3, '2026-06-02T11:35:00', 'Online', 7.92),
(4, '2026-06-02T12:02:00', 'Debit Card', 9.98),
(5, '2026-06-03T13:50:00', 'Online', 11.94),
(6, '2026-06-03T15:12:00', 'Credit Card', 6.99),
(7, '2026-06-04T09:55:00', 'Online', 7.47),
(8, '2026-06-04T14:32:00', 'Cash', 12.90),
(9, '2026-06-05T16:05:00', 'Online', 7.16),
(10, '2026-06-05T17:27:00', 'Debit Card', 10.95);
GO

/*
STEP 5: Create a view to generate receipt totals.
This view uses SUM to calculate each order's total cost.
*/
CREATE VIEW dbo.vw_ReceiptTotals AS
SELECT
    o.OrderID,
    c.CustomerID,
    c.FirstName,
    c.LastName,
    o.OrderDate,
    o.OrderType,
    SUM(oi.Quantity * oi.UnitPrice) AS ReceiptTotal
FROM dbo.Orders o
INNER JOIN dbo.Customers c ON o.CustomerID = c.CustomerID
INNER JOIN dbo.OrderItems oi ON o.OrderID = oi.OrderID
GROUP BY o.OrderID, c.CustomerID, c.FirstName, c.LastName, o.OrderDate, o.OrderType;
GO

/*
STEP 6: Create a stored procedure with at least two parameters.
This procedure finds a customer's orders by customer ID and date range.
*/
CREATE PROCEDURE dbo.usp_GetCustomerOrders
    @CustomerID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        OrderID,
        FirstName,
        LastName,
        OrderDate,
        OrderType,
        ReceiptTotal
    FROM dbo.vw_ReceiptTotals
    WHERE CustomerID = @CustomerID
      AND CAST(OrderDate AS DATE) BETWEEN @StartDate AND @EndDate
    ORDER BY OrderDate;
END;
GO

/*
STEP 8: Transaction to ensure item availability before purchase.
This procedure has multiple parameters, checks stock, updates inventory, inserts order details,
and marks the order as paid only when the full transaction succeeds.
*/
CREATE PROCEDURE dbo.usp_ProcessPurchase
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @PaymentMethod VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Quantity <= 0
    BEGIN
        THROW 50001, 'Quantity must be greater than zero.', 1;
    END;

    BEGIN TRANSACTION;

    DECLARE @AvailableQuantity INT;
    DECLARE @UnitPrice DECIMAL(10,2);
    DECLARE @OrderID INT;
    DECLARE @Total DECIMAL(10,2);

    SELECT
        @AvailableQuantity = QuantityInStock,
        @UnitPrice = UnitPrice
    FROM dbo.Products WITH (UPDLOCK, HOLDLOCK)
    WHERE ProductID = @ProductID;

    IF @AvailableQuantity IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50002, 'Product does not exist.', 1;
    END;

    IF @AvailableQuantity < @Quantity
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50003, 'Not enough items are available in the store.', 1;
    END;

    INSERT INTO dbo.Orders (CustomerID, OrderType, OrderStatus)
    VALUES (@CustomerID, 'Online', 'Pending');

    SET @OrderID = SCOPE_IDENTITY();

    INSERT INTO dbo.OrderItems (OrderID, ProductID, Quantity, UnitPrice)
    VALUES (@OrderID, @ProductID, @Quantity, @UnitPrice);

    UPDATE dbo.Products
    SET QuantityInStock = QuantityInStock - @Quantity
    WHERE ProductID = @ProductID;

    SET @Total = @Quantity * @UnitPrice;

    INSERT INTO dbo.Payments (OrderID, PaymentMethod, AmountPaid)
    VALUES (@OrderID, @PaymentMethod, @Total);

    UPDATE dbo.Orders
    SET OrderStatus = 'Paid'
    WHERE OrderID = @OrderID;

    COMMIT TRANSACTION;

    SELECT @OrderID AS NewOrderID, @Total AS ReceiptTotal;
END;
GO

/* STEP 9: Create users and permissions.
Note: LOGIN creation may require server-level permissions. Run this section as an administrator.
*/
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'AdminUser')
    CREATE USER AdminUser WITHOUT LOGIN;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'StaffUser')
    CREATE USER StaffUser WITHOUT LOGIN;
GO

ALTER ROLE db_owner ADD MEMBER AdminUser;
GO

GRANT SELECT, INSERT, UPDATE ON dbo.Customers TO StaffUser;
GRANT SELECT, INSERT, UPDATE ON dbo.Orders TO StaffUser;
GRANT SELECT, INSERT, UPDATE ON dbo.OrderItems TO StaffUser;
GRANT SELECT ON dbo.Products TO StaffUser;
GRANT SELECT ON dbo.vw_ReceiptTotals TO StaffUser;
DENY DELETE ON SCHEMA::dbo TO StaffUser;
GO

/* STEP 10: Export database using SSMS as .sql, .BACPAC, or .BAK. */
/* STEP 11: SQL comments are included throughout this script to document the work. */

-- Test examples:
SELECT * FROM dbo.vw_ReceiptTotals;
EXEC dbo.usp_GetCustomerOrders @CustomerID = 1, @StartDate = '2026-06-01', @EndDate = '2026-06-30';
-- EXEC dbo.usp_ProcessPurchase @CustomerID = 1, @ProductID = 3, @Quantity = 2, @PaymentMethod = 'Online';
