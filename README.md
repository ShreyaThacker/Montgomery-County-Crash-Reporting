# Montgomery County, Crash Reporting

## [Tableau Dashboard](https://public.tableau.com/app/profile/shreya.thacker6577/viz/MontgomeryCountyMarylandCrashReporting/Dashboard3)

### Project Overview
Montgomery County Crash Reporting is a simple exploratory data analysis project on the public dataset obtained via [data.gov](https://catalog.data.gov/dataset/crash-reporting-drivers-data).
The project intends to showcase a basic understanding of the process of data cleaning and standardization, data querying, and data visualization.

### Tools and Environments
- Microsoft SQL Server Management Studio v18
- Tableau Public v2024

### Data Analysis Process
  #### Data Cleaning and Standardization
  The data cleaning and standardization were done entirely in Microsoft SQL server. It involved:
  - Adding a 'unique identifier' field to the dataset 
  - Identifying and deleting duplicate records
  - Looking for and handling missing values
  - Fixing several typographical errors and inconsistent formatting
  - Recognizing and grouping similar values
  - Identifying outliers

A few code snippets from data cleaning:
- Looking for and managing duplicate records:
``` SQL
SELECT ROW_NUMBER () OVER(PARTITION BY [Report Number], [Vehicle ID], [Person ID] ORDER BY [Report Number]) AS Ranking,
	     *
FROM #New_CrashReporting;

WITH CTE AS 
(SELECT *,
        ROW_NUMBER () OVER(PARTITION BY [Report Number], [Vehicle ID], [Person ID] ORDER BY [Report Number]) AS Ranking
FROM #New_CrashReporting)

SELECT *
FROM CTE
WHERE Ranking != 1

-- duplicate records were deleted using an UPDATE statement
```
- Identifying Drivers' Licenses that aren't from USA/Canada (2 lookup tables were created for USA-states and Canada-states in a different query sheet)
```SQL
DROP TABLE IF EXISTS #USA_Canada_Abbreviation
SELECT [Drivers License State], s.US_Abbrev, C.Canada_Abbrev
INTO #USA_Canada_Abbreviation
FROM #New_CrashReporting A 
LEFT JOIN USAStateLookup S
	on A.[Drivers License State] = s.US_Abbrev
LEFT JOIN CanadaStateLookup C
	on A.[Drivers License State] = c.Canada_Abbrev

SELECT *
FROM #USA_Canada_Abbreviation
WHERE US_Abbrev IS NULL AND Canada_Abbrev IS NULL AND [Drivers License State] IS NOT NULL
ORDER BY 1

UPDATE #New_CrashReporting
SET [Drivers License State] = 'Other'
WHERE (SELECT * 
       FROM #USA_Canada_Abbreviation
       WHERE US_Abbrev IS NULL AND Canada_Abbrev IS NULL)
```


  #### Data Querying
  The following questions were queried against the dataset:
  - What type of substances (intoxication) were detected on the drivers and which of the substances were the most prevalent causes of accidents?
  - What were the most common reasons for driver distractions leading to crashes?
  - What was the distribution of vehicle make (eg: Toyota/Honda/Hyundai etc.) in the total number of accidents?
  - Which road or route in Montgomery County saw the highest number of crashes?
  - How does the time of the day affect the incidents of accidents?
  - How do the weather and visibility affect the incidents of accidents?
  - How many accidents occurred at different speed limits? Did the speed limit of the road have a bearing on the drivers' severity of injury?
  - What was the total count of monthly and yearly accidents?

A few code snippets from data querying:
- Speed limit vs injury severity: do crashes on higher speed limits roads mean more severe injuries (assuming the drivers were driving at or around speed limit)
```SQL
SELECT [Speed Limit], [Injury Severity], [Person ID]
FROM CrashReportingMontgomery

SELECT [Speed Limit], [Fatal Injury], [Suspected Serious Injury], [Suspected Minor Injury], [Possible Injury], [No Apparent Injury]
FROM (SELECT [Speed Limit], [Injury Severity], [Person ID] 
      FROM CrashReportingMontgomery) AS B
PIVOT (COUNT([Person ID])
       FOR [Injury Severity] IN ([FATAL INJURY], [SUSPECTED SERIOUS INJURY], [SUSPECTED MINOR INJURY], [POSSIBLE INJURY], [NO APPARENT INJURY])) as A
```
- Number of accidents per month and year
```SQL
SELECT YEAR([Date]) AS [Year], MONTH ([Date]) AS [Month], DATENAME(MONTH, [Date]) AS [Month Name], COUNT([Report Number]) AS NumberOfAccidents
FROM CrashReportingMontgomery
GROUP BY YEAR([Date]), MONTH ([Date]), DATENAME(MONTH, [Date])
ORDER BY 1, 2

-- using the above result to show a running total 

WITH CTE AS (SELECT YEAR([Date]) AS [YEAR], MONTH ([Date]) AS [MONTH], DATENAME(MONTH, [Date]) AS [Month Name], COUNT([Report Number]) AS NumberOfAccidents
			       FROM CrashReportingMontgomery
             GROUP BY YEAR([Date]), MONTH ([Date]), DATENAME(MONTH, [Date]))

SELECT *,
       SUM(NumberOfAccidents) OVER(PARTITION BY [Year] ORDER BY [Year], [Month]) AS [Running Total of Accidents per Year]
     FROM CTE
```

#### Data Visualization
Please visit the [Tableau Dashboard](https://public.tableau.com/app/profile/shreya.thacker6577/viz/MontgomeryCountyMarylandCrashReporting/Dashboard3)

A few images of charts:

<p align="center">
  <img width="700" height="250" src="https://github.com/ShreyaThacker/Montgomery-County-Crash-Reporting/blob/main/donut.png">
</p>

<p align="center">
  <img width="1000" height="525" src="https://github.com/ShreyaThacker/Montgomery-County-Crash-Reporting/blob/main/speed%20limit.png">
</p>

<p align="center">
  <img width="1000" height="525" src="https://github.com/ShreyaThacker/Montgomery-County-Crash-Reporting/blob/main/time%20of%20day%20and%20weather.png">
</p>
