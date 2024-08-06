# SQL Employee Data Analytics Queries

## Overview

This repository contains a series of SQL Server queries designed to analyze and extract insights from employee data. The queries are based on datasets from [Employee Dataset(All in One)](https://www.kaggle.com/datasets/ravindrasinghrana/employeedataset/data). The dataset includes four components, of which three of the components were used:

1. **Employee Data**: A simulated dataset reflecting employee details and organizational structure, designed for HR and data analysis tasks.
2. **Training/Development Data**: Information about employee participation in training and development programs, capturing various metrics related to training activities.
3. **Employee Engagement Survey Data**: Survey results providing insights into employee engagement, satisfaction, and work-life balance.

## Datasets

**Employee Data**: 
- **Employee ID**: Unique identifier for each employee.
- **First Name**: Employee’s first name.
- **Last Name**: Employee’s last name.
- **Start Date**: Date the employee started.
- **Exit Date**: Date the employee exited (if applicable).
- **Title**: Job title.
- **Supervisor**: Supervisor’s full name.
- **Email**: Employee’s email address.
- **Business Unit**: Department or business unit.
- **Employee Status**: Current status (e.g., Active, On Leave).
- **Employee Type**: Type of employment (e.g., Full-time).
- **Pay Zone**: Salary band.
- **Employee Classification Type**: Employment classification.
- **Termination Type**: Type of termination.
- **Termination Description**: Additional termination details.
- **Department Type**: Department category.
- **Division Description**: Organizational division.
- **State**: State or region code.
- **Job Function**: Description of primary job role.
- **Gender**: Gender code.
- **Location**: Office location code.
- **Race**: Racial or ethnic background.
- **Marital Status**: Marital status.
- **Performance Score**: Performance level score.
- **Current Employee Rating**: Overall performance rating (1 to 5).

**Training/Development Data**:
- **Employee ID**: Unique identifier for training participants.
- **Training Date**: Date of the training session.
- **Training Program Name**: Title of the training program.
- **Training Type**: Type of training (e.g., Technical).
- **Training Outcome**: Outcome of the training.
- **Location**: Location of the training session.
- **Trainer**: Name of the trainer.
- **Training Duration (Days)**: Duration of the training program in days.
- **Training Cost**: Cost associated with the training program.

**Employee Engagement Survey Data**:
- **Employee ID**: Unique identifier for survey participants.
- **Survey Date**: Date of the survey.
- **Engagement Score**: Numerical score representing employee engagement.
- **Satisfaction Score**: Numerical score indicating job satisfaction.
- **Work-Life Balance Score**: Numerical score reflecting work-life balance perceptions.

## Data Transformation

The datasets were transformed using Power Query in [MSExcel](https://www.microsoft.com/en-us/microsoft-365/business/compare-all-microsoft-365-business-products-b?ef_id=_k_328579c5fd991c308c901f77d27db64f_k_&OCID=AIDcmm474qp8el_SEM__k_328579c5fd991c308c901f77d27db64f_k_&msclkid=328579c5fd991c308c901f77d27db64f) to:
- Change date formats to SQL-compatible formats.
- Rename columns to remove spaces and ensure compatibility with SQL.

The transformed data was imported into a SQL Server database with the following tables:
- **EmployeeData**
- **TrainingAndDevelopment**
- **EmployeeEngagementSurvey**

## SQL Queries

Below are the SQL queries used for various analytical needs:

1. **Total Amount Spent on Training by Type**
   ```sql
   SELECT t.TrainingType AS TrainingType,
       ROUND(Sum(t.TrainingCost), 0) AS TotalTrainingCost
   FROM [dbo].[TrainingAndDevelopment] t
   GROUP BY t.TrainingType 
   ORDER BY t.TrainingType DESC
   ;

2. **Top 100 Employees by Tenure**
   ```sql
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
    CAST(YearsWithCompany AS VARCHAR) + ' years, ' + CAST(MonthsWithCompany AS VARCHAR) + 
   ' months' AS Duration
   FROM EmployeeDuration
   ORDER BY YearsWithCompany DESC, MonthsWithCompany DESC, EmployeeName ASC
   ;
3. **Percentage of Active Employees by Race**
    ```sql
    WITH TotalActiveEmployees AS (
      SELECT COUNT(*) AS TotalCount
      FROM EmployeeINFO
      WHERE EmployeeStatus = 'Active'
    ),
    RaceCounts AS (
      SELECT RaceDesc,
             COUNT(*) AS Count,
             ROUND((COUNT(*) * 100.0 / (SELECT TotalCount FROM TotalActiveEmployees)), 2)       AS Percentage
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

4. **Percentage of Active Employees by Gender**
   ```sql
   SELECT Gender,
       COUNT(*) AS Count, 
       CAST(ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM EmployeeINFO WHERE      
          EmployeeStatus = 'Active')), 2) AS DECIMAL(5, 2)) AS Percentage
    FROM EmployeeINFO
    WHERE EmployeeStatus = 'Active'
    GROUP BY Gender
    ORDER BY Percentage DESC
    ;
5. **Average Employee Scores by State**
   ```sql
     SELECT ei.StateCode, 
         CAST(AVG(es.EngagementScore) AS DECIMAL(5, 2)) AS AvgEngagementScore,
         CAST(AVG(es.SatisfactionScore) AS DECIMAL(5, 2)) AS AvgSatisfactionScore,
         CAST(AVG(es.WorkLifeBalanceScore) AS DECIMAL(5, 2)) AS AvgWorkLifeBalanceScore,
         CAST(ROUND((AVG(es.EngagementScore) + AVG(es.SatisfactionScore) +  
           AVG(es.WorkLifeBalanceScore)) / 3.0, 2) AS DECIMAL(5, 2)) AS AvgScore
    FROM EmployeeINFO ei
    JOIN EmployeeESD es
    ON ei.EmployeeID = es.EmployeeID
    GROUP BY ei.StateCode
    ORDER BY AvgScore DESC
    ;

6. **Employees Who Completed Training**
   ```sql
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
   
7. **Average Performance Scores by Department**
   ```sql
   SELECT DepartmentType,
       AVG(CurrentEmployeeRating) AS AvgPerformanceScore
   FROM EmployeeINFO
   GROUP BY DepartmentType
   ORDER BY AvgPerformanceScore DESC
   ;

8. **Termination Counts and Reasons**
   ```sql
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
        CASE WHEN TerminationType = 'Total' THEN 1 ELSE 0 END, -- Ensures 'Total' row is          last
    Count DESC -- Orders other rows by count in descending order
    ;
   
9. **Average Satisfaction Scores by Job Function**
    ```sql
    SELECT ei.JobFunctionDescription,
       AVG(es.SatisfactionScore) AS AvgSatisfactionScore
    FROM EmployeeINFO ei
    INNER JOIN EmployeeESD es
    ON ei.EmployeeID = es.EmployeeID
    GROUP BY ei.JobFunctionDescription
    ORDER BY AvgSatisfactionScore DESC
    ;

10. **Supervisors and Direct Reports**
    ```sql
    SELECT Supervisor,
       COUNT(*) AS DirectReports
    FROM EmployeeINFO
    GROUP BY Supervisor
    ORDER BY DirectReports DESC
    ;

11. **Total Number of Employees by State**
    ```sql
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

## License
This repository is licensed under the [MIT License](https://mit-license.org/), allowing users to freely use, modify, and distribute the content while providing attribution to the original creator.
