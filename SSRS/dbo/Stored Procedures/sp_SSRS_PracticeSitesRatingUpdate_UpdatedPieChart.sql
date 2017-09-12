










CREATE procedure [dbo].[sp_SSRS_PracticeSitesRatingUpdate_UpdatedPieChart] (
	@Database nvarchar(200)--,
	--@UpdatedDate nvarchar(50)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'MORUSH'

exec sp_SSRS_PracticeSitesRatingUpdate_UpdatedPieChart @Database
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

set @sql = 'SELECT ''Updated'' as RatingType, ''HealthGrades'' as RatingSite, avg(UpdatedRating) AS AverageRatings, sum(UpdatedVolume) AS NumberOfRatings, ' + @CR
set @sql = @sql + 'sum(RatingDifference) AS RatingDifference, sum(VolumeDifference) AS VolumeDifference ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''HealthGrades'' ' + @CR
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'SELECT ''Updated'' as RatingType, ''Ucompare'' as RatingSite, avg(UpdatedRating) AS AverageRatings, sum(UpdatedVolume) AS NumberOfRatings, ' + @CR
set @sql = @sql + 'sum(RatingDifference) AS RatingDifference, sum(VolumeDifference) AS VolumeDifference ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''Ucompare'' ' + @CR
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'SELECT ''Updated'' as RatingType, ''Vitals'' as RatingSite, avg(UpdatedRating) AS AverageRatings, sum(UpdatedVolume) AS NumberOfRatings, ' + @CR
set @sql = @sql + 'sum(RatingDifference) AS RatingDifference, sum(VolumeDifference) AS VolumeDifference ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''Vitals'' ' + @CR
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'SELECT ''Updated'' as RatingType, ''RateMDs'' as RatingSite, avg(UpdatedRating) AS AverageRatings, sum(UpdatedVolume) AS NumberOfRatings, ' + @CR
set @sql = @sql + 'sum(RatingDifference) AS RatingDifference, sum(VolumeDifference) AS VolumeDifference ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo. PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE RatingsSite = ''RateMDs'' ' + @CR
set @sql = @sql + 'and convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
exec(@sql)
--Print @sql















