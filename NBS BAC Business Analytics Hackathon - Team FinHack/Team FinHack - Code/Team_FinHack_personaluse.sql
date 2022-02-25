-- Credit Card Expense on leave


SELECT t.Employee_Number, Vendor_Name, Comment, Expense_Date, Net_Amount, `From`, `To` FROM transactions t, `leaves` l
WHERE t.Employee_Number=l.Employee_Number
AND t.Expense_Date <= l.`To`
AND  t.Expense_Date >= l.`From`;



-- Employee Paid After Contract End
SELECT m.Employee_Master, Contractual, Contract_End, Date AS PayDate, `Description`, Amount FROM `master` m, payslips p
WHERE m.Employee_Master = p.Employee_ID
AND DATE_ADD(m.Contract_End, Interval 30 Day) < p.Date
AND m.contractual = "Yes";

-- Number of Employee Paid After
SELECT Employee_Master, SUM(Amount) FROM  (SELECT m.Employee_Master, Contractual, Contract_End, Date AS PayDate, `Description`, Amount FROM `master` m, payslips p
WHERE m.Employee_Master = p.Employee_ID
AND DATE_ADD(m.Contract_End, Interval 30 Day) <= p.Date
AND m.contractual = "Yes") T1
GROUP BY Employee_Master;

SELECT Employee_Master, SUM(Amount) FROM  (SELECT m.Employee_Master, Contractual, Contract_End, Date AS PayDate, `Description`, Amount FROM `master` m, payslips p
WHERE m.Employee_Master = p.Employee_ID
AND DATE_ADD(m.Contract_End, Interval 30 Day) <= p.Date
AND m.contractual = "Yes") T1
GROUP BY Employee_Master;
