CREATE DATABASE  IF NOT EXISTS `fraud` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */;
USE `fraud`;
-- MySQL dump 10.13  Distrib 8.0.12, for Win64 (x86_64)
--
-- Host: localhost    Database: hospital
-- ------------------------------------------------------
-- Server version	8.0.12

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
 SET NAMES utf8 ;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- import csv using data import wizard.



-- Credit Card Spending on Leave Days
CREATE VIEW spend AS SELECT t.Employee_Number, Vendor_Name, Comment, Expense_Date, Net_Amount, `From`, `To` FROM transactions t, `leaves` l
WHERE t.Employee_Number=l.Employee_Number
AND t.Expense_Date <= l.`To`
AND  t.Expense_Date >= l.`From`;

select * from transactions;

SELECT * FROM spend;

-- Number of Employees

SELECT COUNT(DISTINCT(Employee_Number)) FROM spend;


-- Total Spending on Leave days
SELECT sum(Net_Amount) as TotalCost FROM spend;



-- Employee Paid After Contract End
SELECT m.Employee_Master, Contractual, Contract_End, Date AS PayDate, `Description`, Amount FROM `master` m, payslips p
WHERE m.Employee_Master = p.Employee_ID
AND DATE_ADD(m.Contract_End, Interval 30 Day) < p.Date
AND m.contractual = "Yes";

-- Number of Employee Paid After
SELECT Employee_Master, SUM(Amount) AS total  FROM  (SELECT m.Employee_Master, Contractual, Contract_End, Date AS PayDate, `Description`, Amount FROM `master` m, payslips p
WHERE m.Employee_Master = p.Employee_ID
AND DATE_ADD(m.Contract_End, Interval 30 Day) <= p.Date
AND m.contractual = "Yes") T1
GROUP BY Employee_Master;

CREATE View output AS SELECT Employee_Master, SUM(Amount) AS total FROM  (SELECT m.Employee_Master, Contractual, Contract_End, Date AS PayDate, `Description`, Amount FROM `master` m, payslips p
WHERE m.Employee_Master = p.Employee_ID
AND DATE_ADD(m.Contract_End, Interval 30 Day) <= p.Date
AND m.contractual = "Yes") T155
GROUP BY Employee_Master;

SELECT * FROM output;

SELECT sum(total) FROM output;

