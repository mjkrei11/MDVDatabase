










CREATE procedure [dbo].[sp_SSRS_PracticeSitesRatingUpdate_BaselineTable] (
	@Database nvarchar(200)--,
	--@UpdatedDate nvarchar(50)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'MORUSH'

exec sp_SSRS_PracticeSitesRatingUpdate_BaselineTable @Database
*/

declare
@CustomerID nvarchar(10),
@CustomerSource nvarchar(400),
@CustomerLogo varbinary(max),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

declare @date datetime

set @sql = 'select @Tempdate = max(UpdatedDate) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianRatingUpdate'
set @parms = '@Tempdate datetime output'
exec sp_executesql @sql, @parms, @Tempdate = @date output

/* HealthGrades */
set @sql = 'SELECT (SELECT avg(UpdatedRating) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''HealthGrades'' '+ @CR
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') AS HealthGradesAverageRatings, ' + @CR
set @sql = @sql + '(SELECT sum(UpdatedVolume) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''HealthGrades'' ' + @CR
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') as HealthGradesNumberOfRatings, ' + @CR
set @sql = @sql + '(SELECT sum(RatingDifference) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''HealthGrades'' ' + @CR
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql +') as HealthGradesRatingDifference, ' + @CR
set @sql = @sql + '(SELECT sum(VolumeDifference) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''HealthGrades'' ' + @CR
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') AS HealthGradesVolumeDifference, ' + @CR
/* Vitals */
set @sql = @sql + '(SELECT avg(UpdatedRating) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''Vitals'' ' + @CR
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') AS VitalsAverageRatings, ' + @CR
set @sql = @sql + '(SELECT sum(UpdatedVolume) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''Vitals'' ' + @CR 
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') as VitalsNumberOfRatings, ' + @CR
set @sql = @sql + '(SELECT sum(RatingDifference) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''Vitals'' ' + @CR 
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') as VitalsRatingDifference, ' + @CR
set @sql = @sql + '(SELECT sum(VolumeDifference) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''Vitals'' ' + @CR 
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') AS VitalsVolumeDifference, ' + @CR
/* UCompare */
set @sql = @sql + '(SELECT avg(UpdatedRating) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''UCompare'' ' + @CR
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') AS UCompareAverageRatings, ' + @CR
set @sql = @sql + '(SELECT sum(UpdatedVolume) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''UCompare'' ' + @CR 
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') as UCompareNumberOfRatings, ' + @CR
set @sql = @sql + '(SELECT sum(RatingDifference) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''UCompare'' ' + @CR 
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') as UCompareRatingDifference, ' + @CR
set @sql = @sql + '(SELECT sum(VolumeDifference) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''UCompare'' ' + @CR 
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') AS UCompareVolumeDifference, ' + @CR
/* RateMDs */
set @sql = @sql + '(SELECT avg(UpdatedRating) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''RateMDs'' ' + @CR 
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') AS RateMDsAverageRatings, ' + @CR
set @sql = @sql + '(SELECT sum(UpdatedVolume) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''RateMDs'' ' + @CR 
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') as RateMDsNumberOfRatings, ' + @CR
set @sql = @sql + '(SELECT sum(RatingDifference) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''RateMDs'' ' + @CR 
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') as RateMDsRatingDifference, ' + @CR
set @sql = @sql + '(SELECT sum(VolumeDifference) ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''RateMDs'' ' + @CR 
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + ') AS RateMDsVolumeDifference ' + @CR
exec(@sql)
--Print @sql

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(400) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

select top 1 @CustomerLogo = BinData from MDVALUATE.dbo.MetricRangeMediaSection where NPI = @CustomerID















