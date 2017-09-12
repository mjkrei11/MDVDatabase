



CREATE procedure [dbo].[sp_SSRS_TrendingDataAcrossQuarters] (
	@Database nvarchar(200),
	@StartingPeriod nvarchar(10),
	@EndingPeriod nvarchar(10)--,
	--@ComboKey nvarchar(50)--,
	--@NPI nvarchar(10)
)

AS

/* Test parameter */
/*
declare
@Database nvarchar(200),
@StartingPeriod nvarchar(10),
@EndingPeriod nvarchar(10),
@ComboKey nvarchar(50),
@NPI nvarchar(10)

Set @Database = 'Rothman'
set @StartingPeriod = '2014_Q4'
set @EndingPeriod = '2015_Q2'
set @ComboKey = '1104822337_1649324195'
--set @NPI = '1912151457'

--exec sp_SSRS_TrendingDataAcrossQuarters 'Rothman', '2014_Q1', '2015_Q2', '1649324195_1649324195', '1912151457'
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

--if @ComboKey is null
--begin
--	Set @sql = 'SELECT media.YearQuarter, media.CollectionID, media.CollectionName, media.SystemID, media.SystemName, media.ComboKey, cast(doc.BinData as varbinary(max)) as ProfilePic, media.NPI, media.FirstName, media.MiddleName, ' + @CR
--	Set @sql = @sql + 'media.LastName, archive.RatingsSite, archive.Percentile, archive.Color, ' + @CR
--	Set @sql = @sql + 'archive.VIMeasure, archive.Rating, archive.NumberOfRatings, archive.RatingsProfile ' + @CR
--	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CR
--	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysMetReputationArchive archive ON archive.XComboKey = media.XComboKey ' + @CR
--	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysicianDoc doc ' + @CR
--	Set @sql = @sql + 'on doc.NPI = media.NPI ' + @CR
--	Set @sql = @sql + 'WHERE media.YearQuarter BETWEEN '''+ @StartingPeriod +''' AND ''' + @EndingPeriod +''' ' + @CR
--	Set @sql = @sql + 'AND archive.RatingsSite = ''Sum All Sites'' ' + @CR
--	--Added the last Set for a quick report, can be removed soon - 03/11/15 CA
--	Set @sql = @sql + 'AND media.NPI = '''+ @NPI +''' '
--	--Print @sql
--	exec(@sql)
--end
--else
--begin
	Set @sql = 'SELECT media.YearQuarter, media.CollectionID, media.CollectionName, media.SystemID, media.SystemName, media.ComboKey, cast(doc.BinData as varbinary(max)) as ProfilePic, media.NPI, media.FirstName, media.MiddleName, ' + @CR
	Set @sql = @sql + 'media.LastName, archive.RatingsSite, archive.Percentile, archive.Color, ' + @CR
	Set @sql = @sql + 'archive.VIMeasure, archive.Rating, archive.NumberOfRatings, archive.RatingsProfile ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysMetReputationArchive archive ON archive.XComboKey = media.XComboKey ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysicianDoc doc ' + @CR
	Set @sql = @sql + 'on doc.NPI = media.NPI ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysicianMedia pm ' + @CR
	Set @sql = @sql + 'on pm.NPI = media.NPI ' + @CR
	Set @sql = @sql + 'WHERE media.YearQuarter BETWEEN '''+ @StartingPeriod +''' AND ''' + @EndingPeriod +''' ' + @CR
	Set @sql = @sql + 'AND archive.RatingsSite = ''Sum All Sites'' ' + @CR
	Set @sql = @sql + 'AND pm.Status = ''Active'' ' + @CR
	--Print @sql
	exec(@sql)
--end


