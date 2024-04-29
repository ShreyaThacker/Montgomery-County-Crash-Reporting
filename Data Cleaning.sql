use NewProject

DROP TABLE IF EXISTS #Final_CrashReporting
SELECT ROW_NUMBER() OVER(ORDER BY [Report Number]) as Unique_ID,
	   ROW_NUMBER () OVER(PARTITION BY [Report Number], [Vehicle ID], [Person ID] ORDER BY [Report Number]) AS Ranking,
	   [Report Number],
	   [Local Case Number],
	   [Crash Date/Time],
	   [Collision Type],
	   [Vehicle Make],
	   [Vehicle Model],
	   [Vehicle Year],
	   [Vehicle Damage Extent],
	   [Vehicle ID],
	   [Vehicle Body Type],
	   [Vehicle Movement],
	   [Speed Limit],
	   Weather,
	   Light,
	   [Surface Condition],
	   [Traffic Control],
	   [Person ID],
	   [Driver At Fault],
	   [Driver Substance Abuse],
	   [Driver Distracted By],
	   [Injury Severity],
	   [Drivers License State],
	   [Road Name],
	   [Route Type],
	   Municipality,
	   [Cross-Street Name],
	   [Agency Name]
INTO #Final_CrashReporting
FROM ['Crash_Reporting']
ORDER BY Unique_ID

SELECT *
FROM #Final_CrashReporting
WHERE Ranking != 1
ORDER BY [Report Number]


-- now creating a CTE to see which records are more than one (ranking/row numbers show more than one records for the unique combination of [Report Number], [Vehicle ID], [Person ID])

DELETE FROM #Final_CrashReporting
WHERE Ranking != 1

-- 412 rows deleted 172,105 remain

--Adding two new [Date] and [Time] columns to the table
ALTER TABLE #Final_CrashReporting
ADD [Date] Date,
    [Time] Time(0);

-- converting [crash Date/Time] to two separate rows

UPDATE #Final_CrashReporting
SET [Date] = CONVERT(date, [crash Date/Time])

UPDATE #Final_CrashReporting
SET [Time] = CONVERT(TIME(0), [crash Date/Time])

-- standardizing data in certain columns
-- Ran DISNTICT on each columns to know what values need cleaning/adjusting

SELECT DISTINCT ([Drivers License State]) 
FROM #Final_CrashReporting

UPDATE #Final_CrashReporting
SET [Surface Condition] = CASE WHEN [Surface Condition] ='N/A' THEN 'OTHER'
							   WHEN [Surface Condition] IS NULL THEN 'UNKOWN'
							   ELSE [Surface Condition]
							   END


UPDATE #Final_CrashReporting
SET [Traffic Control] = CASE WHEN [Traffic Control] ='N/A' THEN 'OTHER'
						     ELSE [Traffic Control]
						     END 


UPDATE #Final_CrashReporting
SET [Driver Substance Abuse] = CASE WHEN [Driver Substance Abuse] = 'COMBINATION CONTRIBUTED' THEN 'COMBINED SUBSTANCE PRESENT'
									WHEN [Driver Substance Abuse] = 'ALCOHOL CONTRIBUTED' THEN 'ALCOHOL PRESENT'
									WHEN [Driver Substance Abuse] = 'ILLEGAL DRUG CONTRIBUTED' THEN 'ILLEGAL DRUG PRESENT'
									WHEN [Driver Substance Abuse] = 'MEDICATION CONTRIBUTED' THEN 'MEDICATION PRESENT'
									WHEN [Driver Substance Abuse] = 'N/A' THEN 'OTHER'
									ELSE [Driver Substance Abuse]
									END

UPDATE #Final_CrashReporting
SET [Driver Distracted by] =  CASE WHEN [Driver Distracted by] IN ('TALKING OR LISTENING TO CELLULAR PHONE', 'DIALING CELLULAR PHONE', 'OTHER CELLULAR PHONE RELATED', 'TEXTING FROM A CELLULAR PHONE')
										THEN 'CELLULAR PHONE RELATED'
								   WHEN [Driver Distracted by] IN ('USING OTHER DEVICE CONTROLS INTEGRAL TO VEHICLE', 'ADJUSTING AUDIO AND OR CLIMATE CONTROLS') THEN 'USING DEVICE CONTROLS INTEGRAL TO VEHICLE'
								   WHEN [Driver Distracted by]IN ('USING DEVICE OBJECT BROUGHT INTO VEHICLE', 'OTHER ELECTRONIC DEVICE (NAVIGATIONAL PALM PILOT)') THEN 'DISTRACTED BY ELECTRONICS BROUGHT INTO VEHICLE'
								   ELSE [Driver Distracted by]
								   END

UPDATE #Final_CrashReporting
SET [Drivers License State] = CASE WHEN [Drivers License State] IS NULL THEN 'UNKNOWN'
								   WHEN [Drivers License State] = 'XX' THEN 'UNKNOWN'
								   ELSE [Drivers License State]
								   END

-- [Drivers License State] has 74 states listed
-- I am going to make USA and CANADA state abbreviation lookup tables

-- USA
CREATE TABLE USAStateLookup
(
StateName     VARCHAR (32),
US_Abbrev   CHAR (2),
)

INSERT INTO USAStateLookup
VALUES ('Alabama', 'AL'),
       ('Alaska', 'AK'),
       ('Arizona', 'AZ'),
       ('Arkansas', 'AR'),
       ('California', 'CA'),
       ('Colorado', 'CO'),
       ('Connecticut', 'CT'),
       ('Delaware', 'DE'),
       ('District of Columbia', 'DC'),
       ('Florida', 'FL'),
       ('Georgia', 'GA'),
       ('Hawaii', 'HI'),
       ('Idaho', 'ID'),
       ('Illinois', 'IL'),
       ('Indiana', 'IN'),
       ('Iowa', 'IA'),
       ('Kansas', 'KS'),
       ('Kentucky', 'KY'),
       ('Louisiana', 'LA'),
       ('Maine', 'ME'),
       ('Maryland', 'MD'),
       ('Massachusetts', 'MA'),
       ('Michigan', 'MI'),
       ('Minnesota', 'MN'),
       ('Mississippi', 'MS'),
       ('Missouri', 'MO'),
       ('Montana', 'MT'),
       ('Nebraska', 'NE'),
       ('Nevada', 'NV'),
       ('New Hampshire', 'NH'),
       ('New Jersey', 'NJ'),
       ('New Mexico', 'NM'),
       ('New York', 'NY'),
       ('North Carolina', 'NC'),
       ('North Dakota', 'ND'),
       ('Ohio', 'OH'),
       ('Oklahoma', 'OK'),
       ('Oregon', 'OR'),
       ('Pennsylvania', 'PA'),
       ('Rhode Island', 'RI'),
       ('South Carolina', 'SC'),
       ('South Dakota', 'SD'),
       ('Tennessee', 'TN'),
       ('Texas', 'TX'),
       ('Utah', 'UT'),
       ('Vermont', 'VT'),
       ('Virginia', 'VA'),
       ('Washington', 'WA'),
       ('West Virginia', 'WV'),
       ('Wisconsin', 'WI'),
       ('Wyoming', 'WY')


-- CANADA
CREATE TABLE CanadaStateLookup
(
StateName     VARCHAR (32),
Canada_Abbrev   CHAR (2),
)

INSERT INTO CanadaStateLookup
VALUES            ('Alberta', 'AB'),
         ('British Columbia', 'BC'),
                 ('Manitoba', 'MB'),
            ('New Brunswick', 'NB'),
('Newfoundland and Labrador', 'NL'),
              ('Nova Scotia', 'NS'),
    ('Northwest Territories', 'NT'),
				  ('Nunavut', 'NU'),
				  ('Ontario', 'ON'),
     ('Prince Edward Island', 'PE'),
				   ('Quebec', 'QC'),
			('Saskatachewan', 'SK'),
					('Yukon', 'YT')

					SELECT * FROM USAStateLookup
					SELECT * FROM CanadaStateLookup

-- using these two tables to standardize the data in [Drivers License State] column

-- Creating a #TempTable to compare and generate NULL where the license-states in original table don't match either USA's or Canada's state list
DROP TABLE IF EXISTS #USA_Canada_Abbreviation
SELECT Unique_ID,
	   [Report Number],
	   [Drivers License State], 
	   s.US_Abbrev, 
	   C.Canada_Abbrev
INTO #USA_Canada_Abbreviation
FROM #Final_CrashReporting A 
LEFT JOIN USAStateLookup S
	on A.[Drivers License State] = s.US_Abbrev
LEFT JOIN CanadaStateLookup C
	on A.[Drivers License State] = c.Canada_Abbrev

SELECT Unique_ID, [Report Number], [Drivers License State], COUNT([Drivers License State]) 
FROM #USA_Canada_Abbreviation
WHERE US_Abbrev IS NULL and Canada_Abbrev IS NULL AND [Drivers License State] != 'UNKNOWN'
GROUP BY [Drivers License State], Unique_ID, [Report Number]
ORDER BY [Drivers License State]

-- updating the records with license-states that don't belong in USA-Canada territory to 'OTHER' in #USA_Canada_Abbreviation

UPDATE #USA_Canada_Abbreviation
SET [Drivers License State] = CASE WHEN US_Abbrev IS NULL and Canada_Abbrev IS NULL AND [Drivers License State] != 'UNKNOWN' THEN 'OTHER'
								   ELSE [Drivers License State]
								   END

-- updating #Final_CrashReporting with the above set of records								  
UPDATE #Final_CrashReporting
SET [Drivers License State] = a.[Drivers License State] FROM (SELECT * FROM #USA_Canada_Abbreviation 
															  WHERE US_Abbrev IS NULL and Canada_Abbrev IS NULL AND [Drivers License State] != 'UNKNOWN') a
							  WHERE #Final_CrashReporting.Unique_ID = a.Unique_ID

SELECT DISTINCT ([Vehicle Movement]) 
FROM #Final_CrashReporting

UPDATE #Final_CrashReporting
SET [Vehicle Movement] = CASE WHEN [Vehicle Movement] = 'N/A' THEN 'OTHER'
					    	  ELSE [Vehicle Movement]
							  END

UPDATE #Final_CrashReporting
SET [Vehicle Damage Extent] = CASE WHEN [Vehicle Damage Extent] = 'N/A' THEN 'OTHER'
								   ELSE [Vehicle Damage Extent]
								   END

UPDATE #Final_CrashReporting
SET [Vehicle Body Type] = CASE WHEN [Vehicle Body Type] IN ('AMBULANCE/EMERGENCY', 'AMBULANCE/NON EMERGENCY') THEN 'AMBULANCE'
							   WHEN [Vehicle Body Type] IN ('FIRE VEHICLE/EMERGENCY', 'FIRE VEHICLE/NON EMERGENCY') THEN 'FIRE VEHICLE'
							   WHEN [Vehicle Body Type] IN ('POLICE VEHICLE/EMERGENCY', 'POLICE VEHICLE/NON EMERGENCY') THEN 'POLICE VEHICLE'
							   WHEN [Vehicle Body Type] IN ('CARGO VAN/LIGHT TRUCK 2 AXLES (OVER 10,000LBS (4,536 KG))', 'MEDIUM/HEAVY TRUCKS 3 AXLES (OVER 10,000LBS (4,536KG))', 
							   							 'OTHER LIGHT TRUCKS (10,000LBS (4,536KG) OR LESS)', 'TRUCK TRACTOR', 'PICKUP TRUCK') THEN 'TRUCK'
							   WHEN [Vehicle Body Type] IN ('CROSS COUNTRY BUS', 'OTHER BUS', 'TRANSIT BUS') THEN 'BUS'
							   WHEN [Vehicle Body Type] IN ('N/A', 'OTHER') THEN 'UNKNOWN'
							   ELSE [Vehicle Body Type]
							   END

UPDATE #Final_CrashReporting
SET [Route Type] = CASE WHEN [Route Type] IS NULL THEN 'UNKNOWN'
					    ELSE [Route Type]
						END

UPDATE #Final_CrashReporting
SET [Vehicle Body Type] = CASE WHEN [Vehicle Body Type] IS NULL THEN 'UNKNOWN'
					    ELSE [Vehicle Body Type]
						END

UPDATE #Final_CrashReporting
SET [Agency Name] = CASE WHEN [Agency Name] IN ('GAITHERSBURG', 'Gaithersburg Police Depar') THEN 'Gaithersburg Police Department'
					     WHEN [Agency Name] = 'MONTGOMERY' THEN 'Montgomery County Police'
						 WHEN [Agency Name] IN ('ROCKVILLE', 'Rockville Police Departme') THEN 'Rockville Police Department'
						 WHEN [Agency Name] IN ('TAKOMA', 'Takoma Park Police Depart') THEN 'Takoma Park Police Department'
						 ELSE [Agency Name]
						 END

ALTER TABLE #Final_CrashReporting
ADD [Vehicles Year] varchar(max)

UPDATE #Final_CrashReporting
SET [Vehicles Year] = [Vehicle Year]

DELETE FROM #Final_CrashReporting
WHERE [Vehicles Year] NOT BETWEEN 1983 AND 2024 AND [Vehicles Year] != 0


UPDATE #Final_CrashReporting
SET [Vehicles Year] = CASE WHEN [Vehicles Year] = '0' THEN 'UNKNOWN'
						  ELSE [Vehicles Year]
						  END

select * from #Final_CrashReporting where [Vehicles Year] = '0'


--SELECT [Vehicles Year], COUNT ([Vehicles Year]) 
--FROM #Final_CrashReporting
--GROUP BY [Vehicles Year]
--ORDER BY [Vehicles Year]

select * from #Final_CrashReporting
WHERE [Vehicles Year] NOT BETWEEN 1983 AND 2024 AND [Vehicle Year] != 0

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- VEHICLE MAKE

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [VEHICLE MAKE] LIKE ('MER%[CSZ]') THEN 'Mercedes-Benz' 
						  WHEN [VEHICLE MAKE] LIKE ('MER%[XDNE]') THEN 'Mercedes-Benz' 
						  WHEN [VEHICLE MAKE] LIKE ('M__C') THEN 'Mercedes-Benz'
						  WHEN [VEHICLE MAKE] = 'BENZ' THEN 'Mercedes-Benz'
						  ELSE [Vehicle Make]
						  END


SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Mercedes-Benz'
		
-- 3901 rows


UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('ME%Y') THEN 'Mercury'
						  WHEN [Vehicle Make] LIKE 'MERCARY' THEN 'Mercury'
						  WHEN [Vehicle Make] LIKE 'MER' THEN 'Mercury'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Mercury'
		
-- 286 records

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('POR%') THEN 'Porsche'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Porsche' 

-- 256 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('HY%I') THEN 'Hyundai'
						  WHEN [Vehicle Make] LIKE ('HU%I') THEN 'Hyundai'
						  WHEN [Vehicle Make] LIKE ('HY%A') THEN 'Hyundai'
						  WHEN [Vehicle Make] LIKE ('H%I') THEN 'Hyundai'
						  WHEN [Vehicle Make] = 'HYUN' THEN 'Hyundai'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Hyundai'

-- 6310 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('NIS%') THEN 'Nissan'
						  WHEN [Vehicle Make] LIKE ('NII%') THEN 'Nissan'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Nissan'

--11,377 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('TO%[TAYO]') THEN 'Toyota'
						  WHEN [Vehicle Make] LIKE ('TOY%') THEN 'Toyota'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Toyota'

-- 32,771 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] =CASE WHEN [Vehicle Make] LIKE ('TOW%') THEN 'Tow Truck'
						 ELSE [Vehicle Make]
						 END

						 
SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Tow Truck'

-- 2 rows
UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('HON%') THEN 'Honda'
						  WHEN [Vehicle Make] = 'HODNA' THEN 'Honda'
						  WHEN [Vehicle Make] = 'HODA' THEN 'Honda'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Honda'

--24,660 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('CHEV%') THEN 'Chevrolet'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Chevrolet'

-- 10,895 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('CHR%') THEN 'Chrysler '
						  WHEN [Vehicle Make] LIKE ('CHY%') THEN 'Chrysler '			
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Chrysler'

--1,666 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('SUB%') THEN 'Subaru'
						  ELSE [Vehicle Make]
						  END


SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Subaru'

--3,313 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('FO%') THEN 'Ford'
						  ELSE [Vehicle Make]
						  END


SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Ford'

-- 17,149 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('DO%') THEN 'Dodge'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Dodge'

-- 5,376 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('BM%') THEN 'BMW'
						  WHEN [Vehicle Make] LIKE ('B%W%') THEN 'BMW'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'BMW'

-- 3324 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('BU[^S]%') THEN 'Buick'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Buick'

--875 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('MI[^NCFXY]%') THEN 'Mitsubishi'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Mitsubishi'

--1066 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('GENE[^S]%') THEN 'General Motors'
						  WHEN [Vehicle Make] LIKE ('GM%') THEN 'General Motors'
						  ELSE [Vehicle Make]
						  END


SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'General Motors'

-- 1943 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('VOL[KST]%') THEN 'Volkswagen'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Volkswagen'

--3018 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('LE[SXZ]%') THEN 'Lexus'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Lexus'

--3803 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('IN[FI]%') THEN 'Infinity'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Infinity'

-- 1277 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('T[ES]%') THEN 'Tesla'
						  WHEN [Vehicle Make] = 'TSMR' THEN 'Tesla'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Tesla'

--440 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('MIN%') THEN 'Mini Cooper'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Mini Cooper'

--365 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('A%[DI]') THEN 'Audi'
						  ELSE [Vehicle Make]
						  END



SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Audi'

-- 1359 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE ('AC%[^DT]') THEN 'Acura'
						  WHEN [Vehicle Make] LIKE ('AR%[^DT]') THEN 'Acura'
						  WHEN [Vehicle Make] LIKE ('AUC%[^DT]') THEN 'Acura'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Acura'

-- 3824 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'JA[GJU]%' THEN 'Jaguar'
						  ELSE [Vehicle Make]
						  END


SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Jaguar'

-- 205 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'JE[^T]%' THEN 'JEEP'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'JEEP'

--3771 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'EM%' THEN 'EMERGENCY'
						   ELSE [Vehicle Make]
						   END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'EMERGENCY'

-- 21 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'VO[LV]%' AND [Vehicle Make] NOT LIKE ('VOL[KST]%') THEN 'VOLVO'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'VOLVO'

-- 1258 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'SU[SZU]%' THEN 'Suzuki'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Suzuki'

-- 330 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'FR[AEI]%' THEN 'Freightliner'
						  WHEN [Vehicle Make] LIKE 'FR[GHT]%' THEN 'Freightliner'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Freightliner'

-- 1396

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'US%' AND [Vehicle Make] != 'US' THEN 'US POSTAL Vehicle'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'US POSTAL Vehicle'

-- 33 rows
UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'ROLL%' THEN 'ROLLS ROYCE'
						  ELSE [Vehicle Make]
						  END
SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'ROLLS ROYCE'

-- 2 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'RAN%' THEN 'Range Rover'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Range Rover'

-- 77 rows
UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'ROY%' THEN 'Royal Enfield'
						  ELSE [Vehicle Make]
						  END


SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Royal Enfield'

--6 rows
UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'X%' THEN 'UNKNOWN'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'UNKNOWN'

-- 3741 rows
UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'M[OA]%Z%' AND [Vehicle Make] != 'MAZZERATI' THEN 'Mazda'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Mazda'

--2925 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'YA%A' THEN 'Yamaha'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Yamaha'

--149 rows
UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'HA%' THEN 'Harley-Davidson'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Harley-Davidson'

--191 rows
UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE '%BUS' THEN 'BUS'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'BUS'

--110 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'KI%' THEN 'KIA'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'KIA'

-- 2702 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'THOM%' THEN 'Thomas'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Thomas'

-- 2321 rows
UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'CAD%' THEN 'Cadillac'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Cadillac'

-- 952 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'GIL%' THEN 'GILLIG'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'GILLIG'

-- 2100 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'PO[NM]%' THEN 'Pontiac'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'Pontiac'

-- 447 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'NEW%' THEN 'New Flyer'
						  ELSE [Vehicle Make]
						  END

SELECT ([Vehicle Make])
FROM #Final_CrashReporting
WHERE [Vehicle Make] = 'New Flyer'

-- 817 rows

UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'RAM' THEN 'RAM Truck'
						  ELSE [Vehicle Make]
						  END
----
UPDATE #Final_CrashReporting
SET [Vehicle Make] = CASE WHEN [Vehicle Make] LIKE 'LAND%' THEN 'Land Rover'
						  ELSE [Vehicle Make]
						  END

SELECT *
FROM #Final_CrashReporting
WHERE [Vehicle Make] IN ('Toyota', 'Nissan', 'Hyundai', 'Mercedes-Benz', 'Porsche', 'Tow Truck', 'Chevrolet', 'Honda', 'Chrysler', 'Subaru', 'Ford', 'Dodge', 'BMW', 'Buick',
						     'Mitsubishi', 'General Motors', 'Volkswagen', 'Lexus', 'Infinity', 'Tesla', 'Mini Cooper', 'Audi', 'Acura', 'Jaguar', 'JEEP', 'EMERGENCY', 'VOLVO', 
							 'Suzuki', 'Freightliner', 'US POSTAL Vehicle', 'ROLLS ROYCE', 'Range Rover', 'Royal Enfield', 'UNKNOWN', 'Mazda', 'Yamaha', 'Harley-Davidson', 'BUS', 'BENZ',
							 'KIA', 'Thomas', 'Cadillac', 'GILLIG', 'Pontiac', 'New Flyer', 'MACK', 'LINCOLN', 'RAM truck', 'Mercury', 'SATURN', 'Land Rover', 'FIAT')
--GROUP BY [Vehicle Make]
ORDER BY Unique_ID

DELETE FROM #Final_CrashReporting
WHERE [Vehicle Make] NOT IN ('Toyota', 'Nissan', 'Hyundai', 'Mercedes-Benz', 'Porsche', 'Tow Truck', 'Chevrolet', 'Honda', 'Chrysler', 'Subaru', 'Ford', 'Dodge', 'BMW', 'Buick',
						     'Mitsubishi', 'General Motors', 'Volkswagen', 'Lexus', 'Infinity', 'Tesla', 'Mini Cooper', 'Audi', 'Acura', 'Jaguar', 'JEEP', 'EMERGENCY', 'VOLVO', 
							 'Suzuki', 'Freightliner', 'US POSTAL Vehicle', 'ROLLS ROYCE', 'Range Rover', 'Royal Enfield', 'UNKNOWN', 'Mazda', 'Yamaha', 'Harley-Davidson', 'BUS', 'BENZ',
							 'KIA', 'Thomas', 'Cadillac', 'GILLIG', 'Pontiac', 'New Flyer', 'MACK', 'LINCOLN', 'RAM truck', 'Mercury', 'SATURN', 'Land Rover', 'FIAT') 

SELECT top 100 * FROM #Final_CrashReporting
ORDER BY Unique_ID

ALTER TABLE #Final_CrashReporting
DROP COLUMN [Vehicle Year]
 

 SELECT * -- , COUNT([Local Case Number])
 FROM #Final_CrashReporting
 where [Vehicle Make] is null
 group by [Local Case Number]
 order by [Local Case Number]


 SELECT Unique_ID,
	   [Report Number],
	   [Local Case Number],
	   [Date],
	   [Time],
	   [Collision Type],
	   [Vehicle Make],
	   [Vehicles Year],
	   [Vehicle Damage Extent],
	   [Vehicle ID],
	   [Vehicle Body Type],
	   [Vehicle Movement],
	   [Speed Limit],
	   Weather,
	   Light,
	   [Surface Condition],
	   [Traffic Control],
	   [Person ID],
	   [Driver At Fault],
	   [Driver Substance Abuse],
	   [Driver Distracted By],
	   [Injury Severity],
	   [Drivers License State],
	   [Route Type],
	   [Agency Name]
INTO NewProject.dbo.CrashReportingMontgomery
FROM #Final_CrashReporting
ORDER BY Unique_ID

DROP TABLE CrashReportingMontgomery

select * from CrashReportingMontgomery
ORDER BY Unique_ID