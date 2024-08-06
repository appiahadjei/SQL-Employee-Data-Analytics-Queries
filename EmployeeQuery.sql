CREATE DATABASE EmployeeDB
;
USE EmployeeDB;
GO
;


------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 1----------------------------------------------
--What is the total amount spent on employee training and development by Training Type?

----------------------------------------------SOLUTION------------------------------------------------
--The total amount spent on training by Training Type
SELECT t.TrainingType AS TrainingType,
       ROUND(Sum(t.TrainingCost), 0) AS TotalTrainingCost
FROM [dbo].[TrainingAndDevelopment] t
GROUP BY t.TrainingType 
ORDER BY t.TrainingType DESC
;


------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 2----------------------------------------------
--List the top 100 employees based on their tenure with the company.

----------------------------------------------SOLUTION------------------------------------------------
--The top 100 employees based on their tenure with the company
WITH EmployeeDuration AS (
    SELECT 
        EmployeeID,
        FirstName,
        LastName,
        StartDate,
        ISNULL(ExitDate, GETDATE()) AS EndDate,
        DATEDIFF(YEAR, StartDate, ISNULL(ExitDate, GETDATE())) AS YearsWithCompany,
        DATEDIFF(MONTH, StartDate, ISNULL(ExitDate, GETDATE())) % 12 AS MonthsWithCompany
    FROM EmployeeINFO
)
SELECT TOP 100
    EmployeeID,
    FirstName + ' ' + LastName AS EmployeeName,
    CAST(YearsWithCompany AS VARCHAR) + ' years, ' + CAST(MonthsWithCompany AS VARCHAR) + ' months' AS Duration
FROM EmployeeDuration
ORDER BY YearsWithCompany DESC, MonthsWithCompany DESC, EmployeeName ASC
;


------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 3----------------------------------------------
--What is the percentage of active employees by race?

----------------------------------------------SOLUTION------------------------------------------------
--The percentage of active employees by race
WITH TotalActiveEmployees AS (
    SELECT COUNT(*) AS TotalCount
    FROM EmployeeINFO
    WHERE EmployeeStatus = 'Active'
),
RaceCounts AS (
    SELECT RaceDesc,
           COUNT(*) AS Count,
           ROUND((COUNT(*) * 100.0 / (SELECT TotalCount FROM TotalActiveEmployees)), 2) AS Percentage
    FROM EmployeeINFO
    WHERE EmployeeStatus = 'Active'
    GROUP BY RaceDesc
),
AdjustedRaceCounts AS (
    SELECT RaceDesc,
           Count,
           Percentage,
           ROW_NUMBER() OVER (ORDER BY Percentage DESC, RaceDesc) AS RowNum
    FROM RaceCounts
)
SELECT RaceDesc,
       Count,
       CAST(
           CASE 
               WHEN RowNum = (SELECT MAX(RowNum) FROM AdjustedRaceCounts) THEN
                   ROUND(100.0 - SUM(Percentage) OVER (), 2) + Percentage
               ELSE Percentage
           END AS DECIMAL(5, 2)
       ) AS Percentage
FROM AdjustedRaceCounts
ORDER BY Percentage DESC
;


------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 4----------------------------------------------
--How many active employees are males compared to females, expressed as percentages?

----------------------------------------------SOLUTION------------------------------------------------
--Percentage active employees by gender
SELECT Gender,
       COUNT(*) AS Count, 
       CAST(ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM EmployeeINFO WHERE EmployeeStatus = 'Active')), 2) AS DECIMAL(5, 2)) AS Percentage
FROM EmployeeINFO
WHERE EmployeeStatus = 'Active'
GROUP BY Gender
ORDER BY Percentage DESC
;


------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 5----------------------------------------------
--What is the average employee engagement score, satisfaction score, and work-life balance score by State?

----------------------------------------------SOLUTION------------------------------------------------
--The average employee engagement score, satisfaction score, and work-life balance score by State
SELECT ei.StateCode, 
       CAST(AVG(es.EngagementScore) AS DECIMAL(5, 2)) AS AvgEngagementScore,
       CAST(AVG(es.SatisfactionScore) AS DECIMAL(5, 2)) AS AvgSatisfactionScore,
       CAST(AVG(es.WorkLifeBalanceScore) AS DECIMAL(5, 2)) AS AvgWorkLifeBalanceScore,
       CAST(ROUND((AVG(es.EngagementScore) + AVG(es.SatisfactionScore) + AVG(es.WorkLifeBalanceScore)) / 3.0, 2) AS DECIMAL(5, 2)) AS AvgScore
FROM EmployeeINFO ei
JOIN EmployeeESD es
ON ei.EmployeeID = es.EmployeeID
GROUP BY ei.StateCode
ORDER BY AvgScore DESC
;



------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 6----------------------------------------------
--Which employees have completed the trainig program?

----------------------------------------------SOLUTION------------------------------------------------
--Employees who have completed training programs, with total training durations, ordered by highest duration to lowest
SELECT ei.EmployeeID, 
       ei.FirstName, 
       ei.LastName, 
       SUM(td.TrainingDurationDays) AS TotalTrainingDuration
FROM employeeINFO ei
JOIN TrainingAndDevelopment td
ON ei.EmployeeID = td.EmployeeID
WHERE td.TrainingOutcome = 'Completed'
GROUP BY ei.EmployeeID, ei.FirstName, ei.LastName
ORDER BY TotalTrainingDuration DESC
;


------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 7----------------------------------------------
--What are the average performance scores of employees by department?

----------------------------------------------SOLUTION------------------------------------------------
--The average performance scores of employees by department
SELECT DepartmentType,
       AVG(CurrentEmployeeRating) AS AvgPerformanceScore
FROM EmployeeINFO
GROUP BY DepartmentType
ORDER BY AvgPerformanceScore DESC
;


------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 8----------------------------------------------
--How many employees have been terminated, and what are the reasons for their termination?

----------------------------------------------SOLUTION------------------------------------------------
--The total number of terminations with reasons for their termination
SELECT TerminationType,
       Count
FROM (
    SELECT TerminationType,
           COUNT(*) AS Count
    FROM EmployeeINFO
    WHERE EmployeeStatus IN ('Terminated for Cause', 'Voluntarily Terminated')
    GROUP BY TerminationType

    UNION ALL

    SELECT 'Total' AS TerminationType,
           COUNT(*) AS Count
    FROM EmployeeINFO
    WHERE EmployeeStatus IN ('Terminated for Cause', 'Voluntarily Terminated')
) AS CombinedResults
ORDER BY 
    CASE WHEN TerminationType = 'Total' THEN 1 ELSE 0 END, -- Ensures 'Total' row is last
    Count DESC -- Orders other rows by count in descending order
;


------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 9----------------------------------------------
--What is the average employee satisfaction scores across different job functions?

----------------------------------------------SOLUTION------------------------------------------------
--The average satisfaction score by job function function
SELECT ei.JobFunctionDescription,
       AVG(es.SatisfactionScore) AS AvgSatisfactionScore
FROM EmployeeINFO ei
INNER JOIN EmployeeESD es
ON ei.EmployeeID = es.EmployeeID
GROUP BY ei.JobFunctionDescription
ORDER BY AvgSatisfactionScore DESC
;


------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 10----------------------------------------------
--List the supervisors and the number of direct reports

----------------------------------------------SOLUTION------------------------------------------------
--The supervisors and the number of direct reports
SELECT Supervisor,
       COUNT(*) AS DirectReports
FROM EmployeeINFO
GROUP BY Supervisor
ORDER BY DirectReports DESC
;


------------------------------------------------------------------------------------------------------
----------------------------------------------QUESTION 11----------------------------------------------
--What is the total number of employees by state?

----------------------------------------------SOLUTION------------------------------------------------
--Total number of employees
WITH TotalEmployees AS (
    SELECT COUNT(*) AS TotalCount
    FROM EmployeeINFO
)

-- Employee count and percentage by state
SELECT 
    ei.StateCode, 
    COUNT(*) AS EmployeeCount,
    CAST(ROUND((COUNT(*) * 100.0 / te.TotalCount), 2) AS DECIMAL(5, 2)) AS Percentage
FROM EmployeeINFO ei
CROSS JOIN TotalEmployees te
GROUP BY ei.StateCode, te.TotalCount
ORDER BY EmployeeCount DESC
;