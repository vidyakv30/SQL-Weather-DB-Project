Use Weather;

/**1.	Determine the date range of the records in the Temperature table **/

SELECT cast(min([Date_Local])as date) as 'First date',cast(max ([Date_Local]) as date) as 'Last date' 
FROM [dbo].[Temperature];
GO

/**2.	Find the minimum, maximum and average temperature for each state **/
 Select A.State_Name, min(Average_Temp) as 'Minimum Temperature', max(Average_Temp) as 'Maximum Temperature',
 avg(Average_Temp) as 'Average Temperature' 
 FROM Temperature T,aqs_sites A
 WHERE T.State_Code = A.State_Code 
 GROUP By T.State_Code, A.State_Name
 ORDER BY A.State_Name
GO

/**3.	The results from question #2 show issues with the database.  Obviously, a temperature of -99 degrees Fahrenheit in Arizona is not an accurate reading as most likely is 135.5 degrees.  
        Write the queries to find all suspect temperatures (below -39o and above 105o). Sort your output by State Name and Average Temperature. **/

SELECT A.State_Name,A.State_Code,A.County_Code,A.Site_Number,T. Average_Temp, cast(max ([Date_Local]) as date) as 'Date_Local'
FROM AQS_Sites A, Temperature T
WHERE T.State_Code=A.State_Code AND
T.County_Code=A.County_Code AND
T.Site_Num=A.Site_Number
GROUP BY A.State_Name,A.State_Code,A.County_Code,A.Site_Number, Average_Temp, Date_Local
HAVING (Average_Temp <-39 OR Average_Temp > 105)
ORDER BY State_Name desc , Average_Temp
GO

/**4.	You noticed that the average temperatures become questionable below -39 o and above 125 o and that it is unreasonable to have 
        temperatures over 105 o for state codes 30, 29, 37, 26, 18, 38. Write the queries that remove the questionable entries for these 3 set of circumstances. **/

/*** The records satisfying the conditions mentioned in the Q#4 are considered as questionable entries and hence deleted from the table using the below query **/
DELETE FROM Temperature 
WHERE Average_Temp < -39 OR	Average_Temp > 125
GO

DELETE FROM Temperature WHERE Average_Temp > 105 AND
State_Code IN (30, 29, 37, 26, 18, 38)
GO

/**5.	Using the SQL RANK statement, rank the states by Average Temperature **/
Select A.State_Name,min (T.Average_Temp)as 'Minimum Temperature',
max(T.Average_Temp) as 'Maximum Temperature', avg(T.Average_Temp) as avg_temp,
rank() over (order by avg(T.Average_Temp) desc) as State_Rank
FROM aqs_sites A, Temperature T
WHERE A.State_Code = T.State_Code AND
      A.County_Code = T.County_Code AND
	  A.Site_Number = T.Site_Num
GROUP BY A.State_Name
Go

/**6.	You decide that you are only interested in living in the United States, not Canada or the US territories. 
        You will need to include SQL statements in all the remaining queries to limit the data returned in the remaining queries **/

/*** PS :   The condition State _Code NOT IN ('66','72','78','80','CC')  is included for question 8 and 10. Question# 11-16 focus on  the cities
		    ('Pinellas Park', 'Mission', 'Tucson', 'Ludlow') of the states('Florida', 'Texas', 'Arizona', 'California') respectively and hence the condition
			 for question #6 is not explicitly mentioned in the queries**/

/**7.	At this point, you’ve started to become annoyed at the amount of time each query is taking to run. You’ve heard that creating indexes
        can speed up queries. Create 5 indexes for your database. 2 of the indexes should index the temperature fields in the Temperature 
		table, 1 index for the date in the Temperature table and 2 would index the columns used for joining the 2 tables 
		(state, County and Site codes in the Temperate and aqs_site tables). **/

PRINT 'Before Index Creation: Question 2 Begins at - ' + CONVERT(varchar, format(getdate(), 'HH:mm:ss.fff'), 120)
go

/** Code to execute question #2**/
Select A.State_Name, min(Average_Temp) as 'Minimum Temperature', max(Average_Temp) as 'Maximum Temperature',
 avg(Average_Temp) as 'Average Temperature' 
 FROM Temperature T,aqs_sites A
 WHERE T.State_Code = A.State_Code 
 GROUP By T.State_Code, A.State_Name
 ORDER BY A.State_Name
GO
PRINT 'Before Index Creation: Question 2 ends at - ' + CONVERT(varchar, format(getdate(), 'HH:mm:ss.fff'), 120)
go
--starting of indexing
DROP INDEX IF EXISTS Temperature.IndAvgTemp;
GO
CREATE INDEX IndAvgTemp 
ON Temperature (Average_Temp)
go
DROP INDEX IF EXISTS Temperature.IndDailyHeighTemp;
GO
CREATE INDEX IndDailyHeighTemp 
ON Temperature (Daily_High_Temp)
go
DROP INDEX IF EXISTS Temperature.Inddate;
GO
CREATE INDEX Inddate 
ON Temperature (Date_Local)
go
DROP INDEX IF EXISTS Temperature.IndTempConection;
GO
CREATE INDEX IndTempConection
ON Temperature (State_Code, County_Code, Site_Num)
go
DROP INDEX IF EXISTS aqs_sites.IndAqsConnection;
GO
CREATE INDEX IndAqsConnection
ON aqs_sites (State_Code, County_Code, Site_Number)
go
--end of indexing
/** Run the query for Question#2 to check the difference in execution times after index creation **/
PRINT 'After Index Creation: Question 2 Begins at - ' + CONVERT(varchar, format(getdate(), 'HH:mm:ss.fff'), 120)
go
Select A.State_Name, min(Average_Temp) as 'Minimum Temperature', max(Average_Temp) as 'Maximum Temperature',
 avg(Average_Temp) as 'Average Temperature' 
 FROM Temperature T,aqs_sites A
 WHERE T.State_Code = A.State_Code 
 GROUP By T.State_Code, A.State_Name
 ORDER BY A.State_Name
GO

go
PRINT 'After Index Creation: Question 2 ends at - ' + CONVERT(varchar, format(getdate(), 'HH:mm:ss.fff'), 120)
go
--- to subtract time use this link: http://www.unitarium.com/time-calculator

/** Time difference in initial run , Before index creation  = 19.639 seconds
                                     After index creation   = 10.869 seconds            ***/ 


/**8.	You’ve decided that you want to see the ranking of each high temperatures for each city in each state to see if that helps you decide where to live.
        Write a query that ranks (using the rank function) the states by averages temperature and then ranks the cities in each state. The ranking of the 
		cities should restart at 1 when the query returns a new state. You also want to only show results for the 15 states with the highest average 
		temperatures. **/

With RankTable as(
Select A.State_Code,T.County_Code,A.State_Rank,T.Site_Num, avg(T.Average_Temp) as Avg_T,
rank() over (partition by State_Rank order by avg(Average_Temp) desc) as City_Rank
FROM Temperature T,(Select T.State_Code,avg(T.Average_Temp) as Avg_Temp, rank() over ( order by avg(T.Average_Temp) desc) as State_Rank
FROM Temperature T WHERE State_Code <=56
GROUP BY  T.State_Code) A
WHERE A.State_Code = T.State_Code
GROUP BY A.State_Code,T.County_Code,A.State_Rank,Site_Num)
Select State_Rank,State_Name,City_Rank,City_Name,Avg_T
FROM  RankTable R LEFT JOIN aqs_sites A
on R.State_Code = A.state_code  AND
   R.County_Code= A.County_Code AND
   R.Site_Num  = A.Site_Number 
   WHERE State_Rank < =15 AND
   A.State_Code NOT IN ('66','72','78','80','CC')
   ORDER BY State_Rank,City_Rank
   GO

/**9.	You notice in the results that sites with Not in a City as the City Name are include but do not provide you useful information.
        Exclude these sites from all future answers. **/
		  
		-- city_name not  like '%Not in a city%'

/***PS : The condition City_Name NOT LIKE '%Not in a city%' is applied for the question#10. Question #11-16 exclusively focus on the City_Name (Pinellas Park', 'Mission', 'Tucson')
         and the hence the condition for Q#9 is not included.**/

/**10.	You’ve decided that the results in #8 provided too much information and you only want to 2 cities with the highest temperatures and 
        group the results by state rank then city rank. **/

SELECT StateTable.State_Rank, StateTable.State_Name, City_Rank, CityTable.City_Name, CityTable.[Average Temp]
from 
       (SELECT State_Name, C.[Average Temp],
             rank () over (order by C.[Average Temp] desc) as State_Rank
       from (select State_Name, avg(Average_Temp) as 'Average Temp'
                    from Temperature T, aqs_sites A
                    where A.State_Code = T.State_Code and
                           A.County_Code = T.County_Code and
                           A.Site_Number = T.Site_Num and
                           A.state_code NOT IN ('66','72','78','80','CC')
                    GROUP BY State_Name) C) StateTable ,
       (SELECT State_Name, City_Name, D.[Average Temp],
       rank () over (partition by State_Name order by D.[Average Temp] desc) as City_Rank
       from (select State_Name, City_Name,avg(Average_Temp) as 'Average Temp'
                    from Temperature T, aqs_sites A
                    where A.State_Code = T.State_Code and
                                 A.County_Code = T.County_Code and
                                 A.Site_Number = T.Site_Num and
                                 A.state_code NOT IN ('66','72','78','80','CC') AND
								 A.City_Name NOT LIKE '%Not in a City%'
                    group by State_Name,City_Name) D ) CityTable
Where StateTable.State_Name = CityTable.State_Name  and
      State_Rank <=15 AND
      City_Rank <= 2
Order by State_Rank, City_Rank

/**11.	You decide you like the average temperature to be in the 80's so you decide to research Pinellas Park, Mission, and Tucson in more detail.
        For Ludlow, California, calculate the average temperature by month.You also decide to include a count of the number of records for each of the cities
        to make sure your comparisons are being made with comparable data for each city. **/

Select A.City_Name, DATEPART(MONTH,Date_Local) as 'Month', COUNT(*) as '# of Records', Avg(T.Average_Temp) as Average_Temp
From Temperature T, AQS_Sites A
Where A.State_Code = T.State_Code and 
	A.County_Code = T.County_Code and
	A.Site_Number = T.Site_Num and
	A.City_Name IN ('Pinellas Park', 'Mission', 'Tucson', 'Ludlow') and
	a.State_Name IN ('Florida', 'Texas', 'Arizona', 'California')
Group by a.City_Name, DATEPART(MONTH,Date_Local)
Order by a.City_Name , DATEPART(MONTH,Date_Local)
Go

/**12.	You assume that the temperatures follow a normal distribution and that the majority of the temperatures will fall within the 40% to 60% range of the cumulative distribution.
        Using the CUME_DIST function, show the temperatures for the same 3 cities that fall within the range.**/

Select distinct City_Name,Average_Temp,Temp_cume_Dist 
FROM (Select a.City_Name, t.Average_Temp, 
			CUME_DIST() Over (Partition by a.City_Name Order by t.Average_Temp) as Temp_Cume_Dist
			From Temperature t LEFT JOIN AQS_Sites a ON
							 a.State_Code = t.State_Code and 
							 a.County_Code = t.County_Code and
							 a.Site_Number = t.Site_Num
				WHERE
				a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and	
				a.State_Name IN ('Florida', 'Texas', 'Arizona')) Temp
WHERE Temp.Temp_Cume_Dist between 0.4 and 0.6
GO

/**13.	You decide this is helpful, but too much information.You decide to write a query that shows the first temperature and the last temperature 
        that fall within the 40% and 60% range for the 3 cities your focusing on **/

SELECT DISTINCT City_Name, PERCENTILE_DISC(0.4) WITHIN GROUP (ORDER BY AVERAGE_TEMP) OVER (PARTITION BY CITY_NAME) AS '40 PERCENTILE TEMP',
PERCENTILE_DISC(0.6) WITHIN GROUP (ORDER BY AVERAGE_TEMP) OVER (PARTITION BY CITY_NAME) AS '60 PERCENTILE TEMP'
FROM AQS_Sites A,Temperature T
WHERE City_Name IN ('Pinellas Park', 'Mission', 'Tucson') AND
 A.County_Code=T.County_Code AND
 A.State_Code=T.State_Code AND
 A.Site_Number=T.Site_Num 
 ORDER BY City_Name
 GO

 /**14.	You decide you want more detail regarding the temperature ranges and you think of using the NTILE function to group the temperatures into 10 groups.
        You write a query that shows the minimum and maximum temperature in each of the ntiles by city for the 3 cities you are focusing on. **/

Select m.City_Name, m.Percentile, MIN(m.Average_Temp) as MIN_Temp, MAX(m.Average_Temp) as MAX_Temp
From	(Select a.City_Name, t.Average_Temp,NTILE(10) Over (Partition by a.City_Name Order by t.Average_Temp) as Percentile
From Temperature t, AQS_Sites a
Where  a.State_Code = t.State_Code and 
	 a.County_Code = t.County_Code and
	 a.Site_Number = t.Site_Num and
	 a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and      a.State_Name IN ('Florida', 'Texas', 'Arizona')) m
Group by m.City_Name, m.Percentile
GO

/**15.	You now want to see the percent of the time that will be at a given average temperature. To make the percentages meaningful, you only want to use 
        the whole number portion of the average temperature. You write a query that uses the percent_rank function to create a table of each temperature
		for each of the 3 cities sorted by percent_rank. The percent_rank needs to be formatted as a percentage with 2 decimal places. **/

Select A.City_Name, CAST (round(T.Average_Temp,0) as int) as Avg_Temp, 
format (percent_rank() over (Partition by A.City_Name order by round(T.Average_Temp,0)), 'P') as 'Percent Time'
FROM aqs_sites A, Temperature T
WHERE A.State_Code = T.State_Code AND
      A.County_Code = T.County_Code AND
	  A.Site_Number = T.Site_Num AND
	  A.City_Name IN ( 'MISSION','PINELLAS PARK', 'TUCSON')
	  GROUP BY A.City_Name,round(T.Average_Temp,0)
GO

/***16.	You remember from your statistics classes that to get a smoother distribution of the temperatures and eliminate the small daily changes 
        that you should use a moving average instead of the actual temperatures. Using the windowing within a ranking function to create a 4 day 
		moving average, calculate the moving average for each day of the year. **/


WITH DailyAvgTemp (RCity,julianCalendarDay,Avg_Temp) as
(Select  A.City_Name,datepart(dayofyear,T.Date_Local) as Day_of_Year,avg(T.Average_Temp) as Avg_Temp
                  FROM aqs_sites A, Temperature T
                  WHERE A.State_Code = T.State_Code AND
                        A.County_Code = T.County_Code AND
	                  A.Site_Number = T.Site_Num AND
				  A.City_Name IN ( 'MISSION','PINELLAS PARK', 'TUCSON')
			GROUP BY A.City_Name,datepart(dayofyear,T.Date_Local))
Select RCity as City,D.julianCalendarDay as 'Day of Year' ,
avg(D.Avg_Temp) over (partition by RCity ORDER BY D.julianCalendarDay
ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING) as 'Rolling Average Temperature'
FROM DailyAvgTemp D
GO








