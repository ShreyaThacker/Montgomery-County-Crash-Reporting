use newproject


-- COUNT OF CRASHES DUE TO SOME TYPE OF SUBSTANCE ABUSE

SELECT [Driver Substance Abuse], COUNT([Driver Substance Abuse]) AS [# of Accidents]
FROM CrashReportingMontgomery
WHERE [Driver Substance Abuse] NOT IN ('NONE DETECTED', 'UNKNOWN', 'OTHER')
GROUP BY [Driver Substance Abuse]
ORDER BY [# of Accidents] DESC

-- SPEED LIMIT VS INJURY SEVERITY: DO CRASHES ON HIGHER SPEED LIMITS ROADS MEAN MORE SEVERE INJURIES (ASSUMING THE DRIVERS WERE DRIVING AT OR AROUND SPEED LIMIT)

select top 100 *
from CrashReportingMontgomery


SELECT [Speed Limit], [Injury Severity], [Person ID]
FROM CrashReportingMontgomery


SELECT [Speed Limit], [Fatal Injury], [Suspected Serious Injury], [Suspected Minor Injury], [Possible Injury], [No Apparent Injury]
FROM (SELECT [Speed Limit], [Injury Severity], [Person ID] 
	  FROM CrashReportingMontgomery) AS B
PIVOT (COUNT([Person ID])
	   FOR [Injury Severity] IN ([FATAL INJURY], [SUSPECTED SERIOUS INJURY], [SUSPECTED MINOR INJURY], [POSSIBLE INJURY], [NO APPARENT INJURY])) as A


-- HOW IS VISIBILITY AFFECTING DRIVING

SELECT Light, COUNT(light) as Crash_Count
FROM CrashReportingMontgomery
GROUP BY Light
ORDER BY 2 DESC

-- NUMBER OF ACCIDENTS PER YEAR AND MONTH

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

-- in the above result table it is visible that during the pandemic lockdown years the annual accident count dropped by 5-7K in the years 2020-21.
-- the decrease is still visible in the following years of 2022-23, possibly due to wfh culture


-- TYPE OF DISTRACTION CAUSING THE MOST CRASHES
SELECT [Driver Distracted By], COUNT([Driver Distracted By]) AS [Count]
FROM CrashReportingMontgomery
WHERE [Driver Distracted By] != 'NOT DISTRACTED' AND [Driver Distracted By] != 'UNKNOWN'
GROUP BY [Driver Distracted By]
ORDER BY 2 desc


-- TRYING TO SEE IF A CERTAIN TIME OF THE DAY HAS MORE ACCIDENTS FOLLOWED BY HOW WEATHER CONDITIONS IN THAT TIME OF THE DAY AFFECT THE INSTANCES OF CRASHES

DROP TABLE IF EXISTS #TEMP1
WITH CTE AS
		(SELECT CASE WHEN DATEPART(hour, [time]) BETWEEN 4 and 6 THEN 'Early Morning' 
					 WHEN DATEPART(hour, [time]) BETWEEN 7 and 11 THEN 'Morning'
					 WHEN DATEPART(hour, [time]) BETWEEN 12 and 15 THEN 'Afternoon'
					 WHEN DATEPART(hour, [time]) BETWEEN 16 and 19 THEN 'Evening'
					 WHEN DATEPART(hour, [time]) BETWEEN 20 and 23 THEN 'Night'
					 WHEN DATEPART(hour, [time]) BETWEEN 0 and 3 THEN 'Late Night'
					 END AS TimeOfDay,
				Weather,
				COUNT(Unique_ID) As [Accident Count]
		FROM CrashReportingMontgomery
		WHERE Weather NOT IN ('UNKNOWN', 'OTHER', 'N/A')
		GROUP BY CASE WHEN DATEPART(hour, [time]) BETWEEN 4 and 6 THEN 'Early Morning' 
					WHEN DATEPART(hour, [time]) BETWEEN 7 and 11 THEN 'Morning'
					WHEN DATEPART(hour, [time]) BETWEEN 12 and 15 THEN 'Afternoon'
					WHEN DATEPART(hour, [time]) BETWEEN 16 and 19 THEN 'Evening'
					WHEN DATEPART(hour, [time]) BETWEEN 20 and 23 THEN 'Night'
					WHEN DATEPART(hour, [time]) BETWEEN 0 and 3 THEN 'Late Night'
					END,
				 Weather)
		
		--ORDER BY 1, 3 desc

SELECT *,
	   SUM([Accident Count]) OVER (PARTITION BY TimeOfDay) AS [Sum of Accidents]
INTO #Temp1
FROM CTE

SELECT *, FORMAT((CAST([Accident Count] AS float)/CAST([Sum of Accidents] AS float)), 'p2') AS [percentage]
FROM #Temp1
ORDER BY 1, 3 desc

SELECT top 500 * FROM CrashReportingMontgomery

-- ACCIDENTS BY ROUTE TYPE
SELECT [Route Type], COUNT(*) AS [Number of Accidents]
FROM CrashReportingMontgomery
GROUP BY [Route Type]
ORDER BY [Number of Accidents] DESC


-- ACCIDENTS BY VEHICLE MAKE
SELECT [Vehicle Make], COUNT(*) AS [Number of Accidents]
FROM CrashReportingMontgomery
GROUP BY [Vehicle Make]
ORDER BY [Number of Accidents] DESC

