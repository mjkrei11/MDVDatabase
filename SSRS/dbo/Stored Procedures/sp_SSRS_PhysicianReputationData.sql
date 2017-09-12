









CREATE procedure [dbo].[sp_SSRS_PhysicianReputationData] (@Database nvarchar(200),
	@Option int,
	@StartingPeriod nvarchar(10),
	@EndingPeriod nvarchar(10)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200),
	@Option int,
	@StartingPeriod nvarchar(10),
	@EndingPeriod nvarchar(10)--,
	--@CurrentPeriod nvarchar(10)

Set @Database = 'TwinCities'
Set @Option = 0
set @StartingPeriod = '2015_Q4'
set @EndingPeriod = '2015_Q4'
---set @CurrentPeriod = '2015-06-08'

exec sp_SSRS_PhysicianReputationData @Database, @Option, @StartingPeriod, @EndingPeriod
*/
declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

if @Option = 0 /***** Without Competition *****/
Begin
	Set @sql = 'SELECT media.NPI, media.FirstName, media.MiddleName, media.LastName, media.SystemName,  media.SystemID, media.ComboKey, ' + @CR
	Set @sql = @sql + 'rep.RatingsSite, rep.Specialty, rep.VIMeasure, rep.Rating, rep.NumberOfRatings, sr.SpiderDate, ' + @CR
	Set @sql = @sql + 'rep.Percentile, rep.Color, rep.RatingsProfile, rep.SourceLink, substring(sr.MasterSearchPattern, 1, charindex(''|'', sr.MasterSearchPattern) - 1) as SearchEngine, archive.YearQuarter AS TimeFrame ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysMetReputation rep ON media.ComboKey = rep.ComboKey ' + @CR
	Set @sql = @sql + 'LEFT JOIN ' + @Database + '.dbo.PhysicianSearchMedia sm on sm.NPI = media.NPI and sm.SearchPattern = ''MasterSearch'' ' + @CR
	Set @sql = @sql + 'LEFT JOIN ' + @Database + '.dbo.SearchResults sr on sr.LinkTarget = rep.SourceLink and sr.SearchID = sm.SearchID ' + @CR
	Set @sql = @sql + 'LEFT JOIN ' + @Database + '.dbo.PhysMetReputationArchiveMedia archive ON archive.ComboKey = media.ComboKey ' + @CR
	Set @sql = @sql + 'WHERE rep.Rating is not null and media.SystemID = media.CollectionID ' + @CR
	--took this out:  rep.Rating <> 0 AND -- now we will get all info even if there is not a rating
	Set @sql = @sql + 'AND archive.YearQuarter BETWEEN '''+ @StartingPeriod +''' AND ''' + @EndingPeriod +''' ' + @CR
	Set @sql = @sql + 'Order By media.LastName '
	--print(@sql)
End
if @Option = 1 /***** With Competition *****/
Begin
	Set @sql = 'SELECT media.NPI, media.FirstName, media.MiddleName, media.LastName, media.SystemName,  media.SystemID, media.ComboKey, ' + @CR
	Set @sql = @sql + 'rep.RatingsSite, rep.Specialty, rep.VIMeasure, rep.Rating, rep.NumberOfRatings, sr.SpiderDate, ' + @CR
	Set @sql = @sql + 'rep.Percentile, rep.Color, rep.RatingsProfile, rep.SourceLink, substring(sr.MasterSearchPattern, 1, charindex(''|'', sr.MasterSearchPattern) - 1) as SearchEngine, archive.YearQuarter AS TimeFrame ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysMetReputation rep ON media.ComboKey = rep.ComboKey ' + @CR
	Set @sql = @sql + 'LEFT JOIN ' + @Database + '.dbo.PhysicianSearchMedia sm on sm.NPI = media.NPI and sm.SearchPattern = ''MasterSearch'' ' + @CR
	Set @sql = @sql + 'LEFT JOIN ' + @Database + '.dbo.SearchResults sr on sr.LinkTarget = rep.SourceLink and sr.SearchID = sm.SearchID ' + @CR
	Set @sql = @sql + 'LEFT JOIN ' + @Database + '.dbo.PhysMetReputationArchiveMedia archive ON archive.ComboKey = media.ComboKey ' + @CR
	Set @sql = @sql + 'WHERE rep.Rating is not null and media.SystemID <> media.CollectionID ' + @CR
	--took this out:  rep.Rating <> 0 AND -- now we will get all info even if there is not a rating 
	Set @sql = @sql + 'AND archive.YearQuarter BETWEEN '''+ @StartingPeriod +''' AND ''' + @EndingPeriod +''' ' + @CR
	Set @sql = @sql + 'Order By media.LastName '
End

--Print @sql
exec(@sql)












