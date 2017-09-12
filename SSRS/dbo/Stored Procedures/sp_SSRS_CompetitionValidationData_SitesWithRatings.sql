











CREATE procedure [dbo].[sp_SSRS_CompetitionValidationData_SitesWithRatings] (
	@Database nvarchar(200),
	@SystemID nvarchar(10)
)

AS

/* Test parameter */
/*
declare
@Database nvarchar(200),
@SystemID nvarchar(10)

Set @Database = 'CompetitionDemo'
set @SystemID = '1598700478'

--exec sp_SSRS_CompetitionValidationData_SitesWithRatings 'CompetitionDemo', '1295063857'
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #PhysAvgSitesWithRatings(
	PhysicianAvgSitesWithRatings int,
	RatingsSite varchar(120)
)

	Set @sql = 'INSERT #PhysAvgSitesWithRatings(PhysicianAvgSitesWithRatings, pa.RatingsSite) ' + @CR
	Set @sql = @sql + 'SELECT count(distinct pa.RatingsSite), pa.RatingsSite FROM ' + @Database + '.dbo.PhysMetReputation pa ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysMetReputationMedia media ON media.ComboKey = pa.ComboKey ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysVIndex pvi ON media.NPI = pvi.NPI ' + @CR
	Set @sql = @sql + 'WHERE pa.Rating <> 0 AND pa.RatingsSite <> ''Sum All Sites'' ' + @CR
	Set @sql = @sql + 'AND pvi.SystemID = ' + @SystemID + ' ' + @CR
	Set @sql = @sql + 'Group By pa.RatingsSite'
	--print(@sql)
	exec(@sql)

	SELECT PhysicianAvgSitesWithRatings, RatingsSite
	FROM #PhysAvgSitesWithRatings 
	
	drop table #PhysAvgSitesWithRatings
	








