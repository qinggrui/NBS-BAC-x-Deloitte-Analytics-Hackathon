CREATE DATABASE  IF NOT EXISTS `fraud` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */;
USE `fraud`;


-- import csv using data import wizard.

-- Change date formats
SET SQL_SAFE_UPDATES = 0;

UPDATE master
SET Contract_End = if(Contract_End = '', null, DATE_FORMAT(STR_TO_DATE(Contract_End,'%Y-%m-%dT%H:%i:%sZ'),'%Y-%m-%d %H:%i:%s'));

UPDATE payslips
SET Date = DATE_FORMAT(STR_TO_DATE(Date,'%Y-%m-%dT%H:%i:%sZ'),'%Y-%m-%d %H:%i:%s');

UPDATE `transaction`
SET Expense_Date = DATE_FORMAT(STR_TO_DATE(Expense_Date,'%Y-%m-%dT%H:%i:%sZ'),'%Y-%m-%d %H:%i:%s');

UPDATE `leaves`
SET `To` = DATE_FORMAT(STR_TO_DATE(`To`,'%Y-%m-%dT%H:%i:%sZ'),'%Y-%m-%d %H:%i:%s'),
`From` = DATE_FORMAT(STR_TO_DATE(`From`,'%Y-%m-%dT%H:%i:%sZ'),'%Y-%m-%d %H:%i:%s');

SET SQL_SAFE_UPDATES = 1;


-- Credit Card Spending on Leave Days
CREATE VIEW spend AS SELECT t.Employee_Number, Vendor_Name, Comment, Expense_Date, Net_Amount, `From`, `To` FROM transaction t, `leaves` l
WHERE t.Employee_Number=l.Employee_Number
AND t.Expense_Date <= l.`To`
AND  t.Expense_Date >= l.`From`;


SELECT * FROM spend;

-- Number of Employees

SELECT COUNT(DISTINCT(Employee_Number)) FROM spend;


-- Total Spending on Leave days
SELECT sum(Net_Amount) as TotalCost FROM spend;



-- Employee Paid After Contract End
SELECT m.Employee_Master, Contractual, Contract_End, Date AS PayDate, `Description`, Amount FROM `master` m, payslips p
WHERE m.Employee_Master = p.Employee_ID
AND DATE_ADD(m.Contract_End, Interval 38 Day) < p.Date
AND m.contractual = "Yes";



SELECT Employee_ID, LatestPayDate, totalpaid, MaxPayDay FROM 
(SELECT Employee_ID, MAX(Date) as LatestPayDate, SUM(Amount) as totalpaid FROM payslips
Group By Employee_ID) T1,
(SELECT Employee_Master, Contractual, Contract_End, DATE_ADD(Contract_End, Interval 38 Day) as MaxPayDay FROM master
WHERE Contractual = "Yes") T2
WHERE T1.Employee_ID = T2.Employee_Master
AND LatestPayDate > MaxPayDay;



-- Number of Employee Paid After
SELECT Employee_Master, SUM(Amount) AS total  FROM  (SELECT m.Employee_Master, Contractual, Contract_End, Date AS PayDate, `Description`, Amount FROM `master` m, payslips p
WHERE m.Employee_Master = p.Employee_ID
AND DATE_ADD(m.Contract_End, Interval 38 Day) < p.Date
AND m.contractual = "Yes") T1
GROUP BY Employee_Master;


CREATE View output AS SELECT Employee_Master, SUM(Amount) AS total FROM  (SELECT m.Employee_Master, Contractual, Contract_End, Date AS PayDate, `Description`, Amount FROM `master` m, payslips p
WHERE m.Employee_Master = p.Employee_ID
AND DATE_ADD(m.Contract_End, Interval 38 Day) <= p.Date
AND m.contractual = "Yes"
AND `Description` != "P Fund and Tax") T155
GROUP BY Employee_Master;


SELECT * FROM output;

SELECT sum(total) FROM output;

