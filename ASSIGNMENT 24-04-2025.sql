/*1. Write a SQL query to locate those salespeople who do not live in the same city 
   where their customers live and have received a commission of more than 12%. 
   Return Customer Name, Customer City, Salesman Name, Salesman City, and Commission.*/


SELECT DISTINCT
    p1.FirstName + ' ' + p1.LastName AS CustomerFullName,        -- Full name of the customer
    cust_address.City AS CustomerCity,                           -- City where the customer lives
    p.FirstName + ' ' + p.LastName AS SalespersonFullName,       -- Full name of the salesperson
    sp_address.City AS SalespersonCity,                          -- City where the salesperson lives
    sp.CommissionPct * 1000 AS SalesCommission                   -- Salesperson's commission percentage (scaled)
FROM Sales.SalesOrderHeader AS soh
-- Join to get customer details
JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID        -- Get customer info for the order
-- Join to get salesperson details
JOIN Sales.SalesPerson AS sp ON soh.SalesPersonID = sp.BusinessEntityID  -- Get salesperson info for the order
JOIN Person.Person AS p ON sp.BusinessEntityID = p.BusinessEntityID      -- Get salesperson's personal info
JOIN Person.Person AS p1 ON c.PersonID = p1.BusinessEntityID             -- Get customer's personal info

-- Get Customer Address
JOIN Person.BusinessEntityAddress AS cust_bea ON c.StoreID = cust_bea.BusinessEntityID    -- Get address mapping for store customers
JOIN Person.Address AS cust_address ON cust_bea.AddressID = cust_address.AddressID         -- Get customer city from address

-- Get Salesperson Address
JOIN Person.BusinessEntityAddress AS sp_bea ON sp.BusinessEntityID = sp_bea.BusinessEntityID -- Address mapping for salesperson
JOIN Person.Address AS sp_address ON sp_bea.AddressID = sp_address.AddressID                -- Get salesperson city from address

-- Conditions:
WHERE 
    cust_address.City <> sp_address.City        -- Only include rows where customer and salesperson are in different cities
    AND sp.CommissionPct > 0.012;               -- Only include salespeople with commission more than 12%


SELECT * FROM Sales.SalesOrderHeader
SELECT * FROM Sales.Customer
SELECT * FROM Sales.SalesPerson
SELECT * FROM Person.Person
SELECT * FROM Person.BusinessEntityAddress
SELECT * FROM Person.Address
SELECT * FROM Person.Person


/*2. To list every salesperson, along with the customer's name, city, grade, order number, date, and amount, create a SQL query.
   Requirement for choosing the salesmen's list:
   1. Salespeople who work for one or more clients, or  Salespeople who haven't joined any clients yet.
   2. Requirements for choosing a customer list:
		1. placed one or more orders with their salesman, or  didn't place any orders.*/


SELECT DISTINCT
    sp.BusinessEntityID AS SalespersonID,  -- Salesperson ID
    pp.FirstName + ' ' + pp.LastName AS SalespersonFullName,  -- Salesperson Full Name
    c.CustomerID,  -- Customer ID
    ISNULL(ppc.FirstName + ' ' + ppc.LastName, s.Name) AS CustomerFullName,  -- Customer Full Name (if Person exists, else Store Name)
    ISNULL(store_address.City, person_address.City) AS CustomerCity,  -- Customer City (address for store or person)
    soh.SalesOrderID AS OrderNumber,  -- Order Number
    soh.OrderDate AS OrderDate,  -- Order Date
    soh.TotalDue AS OrderAmount  -- Order Amount
FROM 
    Sales.SalesPerson AS sp
LEFT JOIN 
    Person.Person AS pp ON sp.BusinessEntityID = pp.BusinessEntityID  -- Join to get Salesperson details
LEFT JOIN 	
    Sales.SalesOrderHeader AS soh ON sp.BusinessEntityID = soh.SalesPersonID  -- Ensure we get orders for each salesperson, including those with no orders
LEFT JOIN 
    Sales.Customer AS c ON soh.CustomerID = c.CustomerID  -- Join to get customer data
LEFT JOIN 
    Person.Person AS ppc ON c.PersonID = ppc.BusinessEntityID  -- Customer Person details
LEFT JOIN 
    Sales.Store AS s ON c.StoreID = s.BusinessEntityID  -- Store details for customers who are stores

-- Address for store customers
LEFT JOIN Person.BusinessEntityAddress AS store_bea ON c.StoreID = store_bea.BusinessEntityID  -- Store address details
LEFT JOIN Person.Address AS store_address ON store_bea.AddressID = store_address.AddressID  -- Store's address

-- Address for individual customers
LEFT JOIN Person.BusinessEntityAddress AS person_bea ON c.PersonID = person_bea.BusinessEntityID  -- Person address details
LEFT JOIN Person.Address AS person_address ON person_bea.AddressID = person_address.AddressID  -- Person's address

ORDER BY 
    SalespersonFullName, CustomerFullName, soh.OrderDate;



/*
3. Write a SQL query to calculate the difference between the maximum salary and the salary of all the employees who work in the department of ID 80.
Return job title, employee name and salary difference.
*/
SELECT 
    e.JobTitle AS JobTitle,  -- Job title of the employee
    p.FirstName + ' ' + p.LastName AS EmployeeFullName,  -- Full name of the employee
    ( 
        (SELECT MAX(ep.Rate)  -- Subquery to get the maximum salary for the department
         FROM HumanResources.EmployeePayHistory ep
         JOIN HumanResources.EmployeeDepartmentHistory ed
           ON ep.BusinessEntityID = ed.BusinessEntityID
         WHERE ed.DepartmentID = 8)  -- The department ID is filtered as 8
        - eph.Rate  -- Subtracting the employee's salary from the maximum salary to get the difference
    ) AS SalaryDifference  -- The difference between the max salary and the employee's salary
FROM 
    HumanResources.Employee e
JOIN 
    HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID  -- Employee to department history join
JOIN 
    HumanResources.Department d ON edh.DepartmentID = d.DepartmentID  -- Employee to department join
JOIN 
    HumanResources.EmployeePayHistory eph ON e.BusinessEntityID = eph.BusinessEntityID  -- Employee pay history join
JOIN 
    Person.Person p ON e.BusinessEntityID = p.BusinessEntityID  -- Employee's personal details join
WHERE 
    d.DepartmentID = 8  -- Filter for employees working in department 8
ORDER BY 
    EmployeeFullName;  -- Ordering by employee's full name




/* 4. Create a SQL query to compare employees' year-to-date sales. 
Return TerritoryName, SalesYTD, BusinessEntityID, and Sales from the prior year (PrevRepSales). 
The results are sorted by territorial name in ascending order. */

SELECT 
    t.Name AS TerritoryName,  -- Name of the territory
    sp.SalesYTD AS SalesYTD,  -- Current year-to-date sales for the salesperson
    sp.BusinessEntityID AS SalespersonID,  -- Unique ID of the salesperson
    ISNULL(SUM(soh.SubTotal), 0) AS PrevRepSales  -- Sum of last year's sales; if none, return 0
FROM 
    Sales.SalesPerson AS sp  -- Salesperson table
INNER JOIN 
    Sales.SalesTerritory AS t ON sp.TerritoryID = t.TerritoryID  -- Join to get territory name
LEFT JOIN 
    Sales.SalesOrderHeader AS soh 
    ON sp.BusinessEntityID = soh.SalesPersonID 
    AND YEAR(soh.OrderDate) = YEAR(GETDATE()) - 1  -- Only include orders from the previous year
GROUP BY 
    t.Name, sp.SalesYTD, sp.BusinessEntityID  -- Group by required columns
ORDER BY 
    t.Name ASC;  -- Sort result by territory name in ascending order


/*
5. Write a SQL query to find those orders 
where the order amount exists between 500 and 2000. 
Return ord_no, purch_amt, cust_name, city.*/
SELECT DISTINCT
    soh.SalesOrderID AS OrderNumber,  -- Unique ID of the sales order
    soh.TotalDue AS PurchaseAmount,  -- Total amount due for the order
    p.FirstName + ' ' + p.LastName AS CustomerFullName,  -- Full name of the customer
    a.City AS CustomerCity  -- City from the billing address of the customer
FROM 
    Sales.SalesOrderHeader AS soh  -- Main sales order table
JOIN 
    Sales.Customer AS c ON soh.CustomerID = c.CustomerID  -- Join to get customer info
JOIN 
    Person.Person AS p ON c.PersonID = p.BusinessEntityID  -- Join to get person's name
JOIN 
    Sales.SalesOrderHeaderSalesReason AS sohsr ON soh.SalesOrderID = sohsr.SalesOrderID  -- Join for sales reasons (relationship table)
JOIN 
    Person.Address AS a ON soh.BillToAddressID = a.AddressID  -- Join to get the billing address city
WHERE 
    soh.TotalDue BETWEEN 500 AND 2000;  -- Filter for orders with TotalDue between 500 and 2000


/* 
6. To find out if any of the current customers have placed an order or not, 
create a report using the following SQL statement: customer name, city, 
order number, order date, and order amount in ascending order based on the order date.
*/

SELECT
    p.FirstName + ' ' + p.LastName AS CustomerFullName,  -- Full name of the customer
    addr.City AS CustomerCity,  -- City from the customer's billing address
    soh.SalesOrderID AS OrderNumber,  -- Sales order number
    soh.OrderDate AS OrderDate,  -- Date when the order was placed
    soh.TotalDue AS OrderAmount  -- Total amount due for the order
FROM 
    Sales.Customer AS c  -- Table containing customer data
JOIN 
    Person.Person AS p ON c.PersonID = p.BusinessEntityID  -- Join to get customer name from Person table
JOIN 
    Sales.SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID  -- Join to get orders placed by the customer
JOIN 
    Person.Address AS addr ON soh.BillToAddressID = addr.AddressID  -- Join to get the billing address city
ORDER BY 
    soh.OrderDate ASC;  -- Sorting the results by order date in ascending order



/* 7. Create a SQL query that will return all employees with "Sales" at the start of their job titles. 
Return the columns for job title, last name, middle name, and first name.*/

SELECT 
    e.JobTitle AS JobTitle,  -- Retrieves the employee's job title
    p.LastName AS LastName,  -- Retrieves the employee's last name
    p.MiddleName AS MiddleName,  -- Retrieves the employee's middle name
    p.FirstName AS FirstName  -- Retrieves the employee's first name
FROM 
    HumanResources.Employee AS e  -- Main employee table
JOIN 
    Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID  -- Join with person table to get name details
WHERE 
    e.JobTitle LIKE 'Sales%';  -- Filters job titles that start with 'Sales'

	

