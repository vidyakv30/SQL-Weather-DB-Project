Use [Weather];

/*Adding new column Geolocation with datatype geography. If exists,drop and create the column*/
IF COL_LENGTH('dbo.aqs_sites', 'GeoLocation') IS NOT NULL
BEGIN
ALTER TABLE aqs_sites
DROP COLUMN GeoLocation
END
Go

ALTER TABLE [dbo].[AQS_Sites]
add  [GeoLocation] geography
GO

/*Inserting values into Geolocation column*/
UPDATE [dbo].[AQS_Sites]
SET [GeoLocation] = geography::Point([Latitude], [Longitude], 4326)
GO

/*Check if procedure Spring2018_Calc_GEO_Distance already exists. Drop and create new if procedure already exists  **/

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'[dbo].[Spring2018_Calc_GEO_Distance]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
DROP PROCEDURE dbo.Spring2018_Calc_GEO_Distance
END
go
Create Procedure Spring2018_Calc_GEO_Distance(
@longitude varchar(255),
@latitude varchar(255),
@State varchar(255),
@rownum int OUTPUT
)
As
Begin
  Declare @h as GEOGRAPHY;
  set @h = (geography::Point(@latitude, @longitude, 4326))
 
  select Site_Number,
     case when (Local_Site_Name='' or Local_Site_Name=NULL) 
	 then Site_Number+City_Name 
	 else Local_Site_Name  end as Local_Site_Name,
  Address,City_Name,State_Name,Zip_Code,GeoLocation.STDistance(@h) as Distance_In_Meters,Latitude,Longitude,GeoLocation.STDistance(@h)/80000 as Hours_of_Travel  from AQS_Sites
  Where State_Name=@State and City_Name<>'Not in a city'
 set @rownum=@@ROWCOUNT
End
/* to execute the stored procedure*/
go

declare @rownum as int;
EXEC Spring2018_Calc_GEO_Distance @Longitude= '-74.192892', @Latitude= '40.720989', @State = 'Alabama',@rownum = @rownum OUTPUT;
SELECT	@rownum as N'@rownum'

go

declare @rownum as int;
EXEC Spring2018_Calc_GEO_Distance @Longitude= '-74.1807', @Latitude= '40.742879', @State = 'Arizona',@rownum = @rownum OUTPUT;
SELECT	@rownum as N'@rownum'
GO



