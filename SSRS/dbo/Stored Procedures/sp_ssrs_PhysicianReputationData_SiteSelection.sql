












CREATE procedure [dbo].[sp_ssrs_PhysicianReputationData_SiteSelection] (@Database nvarchar(200),
	@Option int,
	@SiteName nvarchar(max),
	@StartingPeriod nvarchar(10),
	@EndingPeriod nvarchar(10)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200),
	@Option int,
	@SiteName nvarchar(max),
	@StartingPeriod nvarchar(10),
	@EndingPeriod nvarchar(10)--,
	--@CurrentPeriod nvarchar(10)

Set @Database = 'Rothman'
Set @Option = 0
set @SiteName = 'sum all sites'
set @StartingPeriod = '2015_Q4'
set @EndingPeriod = '2016_Q4'
---set @CurrentPeriod = '2015-06-08'

exec sp_ssrs_PhysicianReputationData_SiteSelection @Database, @Option, @SiteName, @StartingPeriod, @EndingPeriod
*/
declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #report_data
(
	NPI nvarchar(10)
,	FirstName nvarchar(200)
,	MiddleName nvarchar(200)
,	LastName nvarchar(200)
,	SystemName nvarchar(400)
,	SystemID nvarchar(10)
,	ComboKey nvarchar(30)
,	RatingsSite nvarchar(50)
,	Specialty nvarchar(200)
,	VIMeasure float
,	Rating float
,	NumberOfRatings int
,	Percentile int
,	Color nvarchar(20)
,	TimeFrame nvarchar(20)
)

--if @Option = 0 /***** Without Competition *****/
--Begin
	set @sql = 'insert #report_data(NPI, FirstName, MiddleName, LastName, SystemName, SystemID, ComboKey, RatingsSite, Specialty, ' + @CR
	set @sql = @sql + 'VIMeasure, Rating, NumberOfRatings, Percentile, Color, TimeFrame) ' + @CR
	set @sql = @sql + 'select media.NPI, media.FirstName, media.MiddleName, media.LastName, media.SystemName,  media.SystemID, media.ComboKey, ' + @CR
	set @sql = @sql + 'case rep.RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else rep.RatingsSite end, ' + @CR
	set @sql = @sql + 'rep.Specialty, rep.VIMeasure, rep.Rating, rep.NumberOfRatings, ' + @CR
	set @sql = @sql + 'rep.Percentile, rep.Color, media.YearQuarter AS TimeFrame ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationArchive rep on media.XComboKey = rep.XComboKey ' + @CR
	if @Option = 0
	begin
		set @sql = @sql + 'where rep.Rating is not null and media.SystemID = media.CollectionID ' + @CR
	end
	if @Option = 1
	begin
		set @sql = @sql + 'where rep.Rating is not null and media.SystemID <> media.CollectionID ' + @CR
	end
	--took this out:  rep.Rating <> 0 AND -- now we will get all info even if there is not a rating
	set @sql = @sql + 'and media.YearQuarter BETWEEN '''+ @StartingPeriod +''' and ''' + @EndingPeriod +''' ' + @CR
	--set @sql = @sql + 'and rep.RatingsSite in (select Value from dbo.fn_SplitValues(''' + @SiteName + ''', '',''))  ' + @CR
	set @sql = @sql + 'order By media.LastName, media.YearQuarter, rep.NumberOfRatings desc '
	exec(@sql)
	print @sql

	select		*
	from		#report_data
	where		RatingsSite in (select [Value] from dbo.fn_SplitValues(@SiteName, ','))
	order by	LastName, FirstName, MiddleName

	drop table #report_data
	--print(@sql)
--End
--if @Option = 1 /***** With Competition *****/
--Begin
--	set @sql = 'select media.NPI, media.FirstName, media.MiddleName, media.LastName, media.SystemName,  media.SystemID, media.ComboKey, ' + @CR
--	set @sql = @sql + 'case rep.RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else rep.RatingsSite end as RatingsSite, ' + @CR
--	set @sql = @sql + 'rep.Specialty, rep.VIMeasure, rep.Rating, rep.NumberOfRatings, ' + @CR
--	set @sql = @sql + 'rep.Percentile, rep.Color, archive.YearQuarter AS TimeFrame ' + @CR
--	set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CR
--	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputation rep on media.ComboKey = rep.ComboKey ' + @CR
--	set @sql = @sql + 'left join ' + @Database + '.dbo.PhysicianSearchMedia sm on sm.NPI = media.NPI and sm.SearchPattern = ''MasterSearch'' ' + @CR
--	set @sql = @sql + 'left join ' + @Database + '.dbo.SearchResults sr on sr.LinkTarget = rep.SourceLink and sr.SearchID = sm.SearchID ' + @CR
--	set @sql = @sql + 'left join ' + @Database + '.dbo.PhysMetReputationArchiveMedia archive on archive.ComboKey = media.ComboKey ' + @CR
--	set @sql = @sql + 'where rep.Rating is not null and media.SystemID <> media.CollectionID ' + @CR
--	--took this out:  rep.Rating <> 0 AND -- now we will get all info even if there is not a rating 
--	set @sql = @sql + 'and archive.YearQuarter BETWEEN '''+ @StartingPeriod +''' and ''' + @EndingPeriod +''' ' + @CR
--	set @sql = @sql + 'and rep.RatingsSite in (select Value from dbo.fn_SplitValues(''' + @SiteName + ''', '',''))  ' + @CR
--	Set @sql = @sql + 'order By media.LastName '
--End

--Print @sql
--exec(@sql)















