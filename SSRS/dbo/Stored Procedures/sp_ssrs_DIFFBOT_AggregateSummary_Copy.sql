















CREATE procedure [dbo].[sp_ssrs_DIFFBOT_AggregateSummary_Copy] (
	@Database nvarchar(200), @Month int
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200), @Month int
set @Database = 'Rothman'
set @Month = 3
exec sp_ssrs_DIFFBOT_AggregateSummary_Copy @Database, @Month
*/

declare
@CustomerID nvarchar(10),
@CustomerSource nvarchar(400),
@CustomerLogo varbinary(max),
@NPI nvarchar(10),
@SiteName nvarchar(50),
@SiteCount int,
@Score float,
@VolumeDenom int,
@BaselineDate datetime,
@SearchDate datetime,
@counter int,
@site_counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

declare 
@StartBatchID int,
@EndBatchID int

set @sql = 'select @TempStartBatchID = min(BatchID), @TempEndBatchID = max(BatchID) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where datepart(month, SearchDate) = ''' + cast(@Month as nvarchar(10)) + ''' and BatchID > 0 ' + @CR
set @parms = '@TempStartBatchID int output, @TempEndBatchID int output'
exec sp_executesql @sql, @parms, @TempStartBatchID = @StartBatchID output, @TempEndBatchID = @EndBatchID output

--select @EndBatchID

create table #physicians(ID int identity, NPI nvarchar(10))

set @sql = 'insert #physicians(NPI) ' + @CR
set @sql = @sql + 'select distinct r.NPI from ' + @Database + '.dbo.DIFFBOT_ResultLinks r ' +@CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia p on p.NPI = r.NPI and p.Status = ''Active'' ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') '
exec(@sql)

create table #baseline_data(
	NPI nvarchar(10),
	SiteName nvarchar(100),
	Score float,
	BaselineDate nvarchar(400),
	SumOfVolume float
)

set @sql = 'insert #baseline_data ' + @CR
set @sql = @sql + 'select substring(XComboKey,1,10) as NPI, case RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else RatingsSite end, ' + @CR
set @sql = @sql + 'sum(Rating) * sum(NumberOfRatings) as Score, ''5/6/2015'' as BaselineDate, sum(NumberOfRatings) as SumOfVolume ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchive ' + @CR
set @sql = @sql + 'where XComboKey like ''%_1649324195_2015_Q2'' ' + @CR
set @sql = @sql + 'and RatingsSite in (''HealthGrades'',''Ucompare'',''Rate MD Secure'',''Vitals'') ' + @CR
set @sql = @sql + 'group by XComboKey, RatingsSite ' + @CR
--print(@sql)
exec(@sql)

--select * from #baseline_data where Score = ''

create table #sites (ID int identity, SiteName nvarchar(50))
set @sql = 'insert #sites(SiteName) ' + @CR
set @sql = @sql + 'select distinct SiteName ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
set @sql = @sql + 'and BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''' ' + @CR
--set @sql = @sql + 'and NPI = ''1659575645'' ' + @CR
--print @sql
exec(@sql)

create table #NPI (ID int identity, NPI nvarchar(10))
set @sql = 'insert #NPI(NPI) ' + @CR
set @sql = @sql + 'select distinct NPI ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
set @sql = @sql + 'and BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''' ' + @CR
--set @sql = @sql + 'and NPI = ''1659575645'' ' + @CR
--print @sql
exec(@sql)

create table #result_links_rating (NPI nvarchar(10), SiteName nvarchar(50), Rating decimal(2,1), Volume int, SearchDate datetime)

set @counter = 1
while @counter <= (select max(ID) from #NPI)
begin
	select @NPI = NPI from #NPI where ID = @counter

	set @site_counter = 1
	while @site_counter <= (select max(ID) from #sites)
	begin
		select @SiteName = SiteName from #sites where ID = @site_counter

		set @sql = 'insert #result_links_rating ' + @CR
		set @sql = @sql + 'select top 1 NPI, SiteName, ResultRating, ResultVolume, SearchDate ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
		set @sql = @sql + 'where SiteName = ''' + @SiteName + ''' ' + @CR
		--set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
		set @sql = @sql + 'and NPI = ''' + @NPI + ''' ' + @CR
		set @sql = @sql + 'and BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''' ' + @CR
		set @sql = @sql + 'order by ResultVolume desc, ResultRating desc ' + @CR
		--print(@sql)
		exec(@sql)

		set @site_counter = @site_counter + 1
	end

	set @counter = @counter + 1
end

--select * from #result_links_rating

create table #updated_data(
	NPI nvarchar(10),
	RatingsSite nvarchar(400),
	Score float,
	SearchDate datetime
)

set @sql = 'insert #updated_data ' + @CR
set @sql = @sql + 'select NPI, SiteName, Rating * Volume, SearchDate ' + @CR
set @sql = @sql + 'from #result_links_rating ' + @CR
--set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
--set @sql = @sql + 'and BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' '
--print(@sql)
exec(@sql)

create table #rep_baseline_data(
	NPI nvarchar(10),
	SiteName nvarchar(50),
	Score float,
	BaselineDate datetime,
	SumOfVolume float

)
set @sql = 'insert #rep_baseline_data ' + @CR
set @sql = @sql + 'select distinct a.NPI, case b.BaselineSite when ''Rate MD Secure'' then ''RateMDs'' else b.BaselineSite end, ' + @CR
set @sql = @sql + 'sum(cast(b.BaselineRating as decimal)) * sum(cast(b.BaselineNumberofRatings as int)) as Score, ''5/6/2015'' as BaselineDate, ' + @CR
set @sql = @sql + 'sum(cast(b.BaselineNumberofRatings as int)) as SumOfVolume ' + @CR
set @sql = @sql + 'from #baseline_data a ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.VIRepBaseline b on substring(b.NPITrend,1,10) = a.NPI ' + @CR
set @sql = @sql + 'left join #physicians c on c.NPI = substring(b.NPITrend,1,10) ' + @CR
set @sql = @sql + 'left join #updated_data d on d.NPI = a.NPI and d.RatingsSite = b.BaselineSite ' + @CR
set @sql = @sql + 'where a.SiteName = NULL ' + @CR
set @sql = @sql + 'and b.BaselineSite in (''HealthGrades'',''Ucompare'',''RateMDs'',''Vitals'') ' + @CR
set @sql = @sql + 'group by a.NPI, b.BaselineSite' + @CR
--print(@sql)
exec(@sql)

delete from #baseline_data
where SiteName is NULL

create table #baseline_volume(NPI nvarchar(10), Volume int, BaselineDate datetime)
create table #updated_volume(NPI nvarchar(10), Volume int)

	set @sql = 'insert #baseline_volume ' + @CR
	set @sql = @sql + 'select distinct NPI, sum(SumOfVolume) As BaselineVolume, BaselineDate' + @CR
	set @sql = @sql + 'from #baseline_data ' + @CR
	set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
	set @sql = @sql + 'group by NPI, BaselineDate ' + @CR
	set @sql = @sql + 'union ' + @CR
	set @sql = @sql + 'select distinct NPI, sum(SumOfVolume) As BaselineVolume, BaselineDate' + @CR
	set @sql = @sql + 'from #rep_baseline_data ' + @CR
	set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
	set @sql = @sql + 'group by NPI, BaselineDate ' + @CR
	exec(@sql)

create table #result_links (NPI nvarchar(10), SiteName nvarchar(50), Volume int)

set @counter = 1
while @counter <= (select max(ID) from #NPI)
begin
	select @NPI = NPI from #NPI where ID = @counter

	set @site_counter = 1
	while @site_counter <= (select max(ID) from #sites)
	begin
		select @SiteName = SiteName from #sites where ID = @site_counter

		set @sql = 'insert #result_links ' + @CR
		set @sql = @sql + 'select top 1 NPI, SiteName, ResultVolume ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
		set @sql = @sql + 'where SiteName = ''' + @SiteName + ''' ' + @CR
		set @sql = @sql + 'and NPI = ''' + @NPI + ''' ' + @CR
		set @sql = @sql + 'and BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''' ' + @CR
		set @sql = @sql + 'order by ResultVolume desc, ResultRating desc ' + @CR
		--print(@sql)
		exec(@sql)

		set @site_counter = @site_counter + 1
	end

	set @counter = @counter + 1
end

drop table #sites
drop table #NPI
drop table #result_links_rating

set @sql = 'insert #updated_volume ' + @CR
set @sql = @sql + 'select distinct NPI, sum(Volume) ' + @CR
set @sql = @sql + 'from #result_links ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
set @sql = @sql + 'group by NPI ' + @CR
--print(@sql)
exec(@sql)

--select * from #updated_volume

drop table #result_links

create table #baseline_final(NPI nvarchar(10), Score float, Volume int, BaselineDate datetime)
create table #updated_final(NPI nvarchar(10), Score float, Volume int, SearchDate datetime)

set @counter = 1
while @counter <= (select max(ID) from #physicians)
begin
	
	set @Score = null
	set @VolumeDenom = null
	set @SearchDate = null

	select @NPI = NPI from #physicians where ID = @counter
	select @Score = round(sum(Score), 1) from #baseline_data where NPI = @NPI
	select @VolumeDenom = Volume from #baseline_volume where NPI = @NPI
	select @BaselineDate = BaselineDate from #baseline_volume where NPI = @NPI

	insert #baseline_final select @NPI, case when isnull(@VolumeDenom, 0) = 0 then 0 else @Score / @VolumeDenom end, @VolumeDenom, @BaselineDate

	set @Score = null
	set @VolumeDenom = null

	select @NPI = NPI from #physicians where ID = @counter
	select @Score = round(sum(Score), 1) from #updated_data where NPI = @NPI
	select @VolumeDenom = Volume from #updated_volume where NPI = @NPI
	select @SearchDate = max(SearchDate) from #updated_data where NPI = @NPI and datepart(month, SearchDate) = @Month

	insert #updated_final select @NPI, case when isnull(@VolumeDenom, 0) = 0 then 0 else @Score / @VolumeDenom end, @VolumeDenom, @SearchDate

	set @counter = @counter + 1
end

set @sql = 'SELECT distinct m.NPI, m.LastName, m.FirstName, isnull(cast(b.Score as decimal(3,2)), 0.0) AS AggregateBaselineRating, ' + @CR
set @sql = @sql + 'isnull(sum(b.Volume), 0) AS AggregateBaselineVolume, convert(varchar, max(b.BaselineDate), 101) as BaselineDate, isnull(cast(u.Score as decimal(3,2)), 0.0) AS AggregateUpdatedRating, ' + @CR
set @sql = @sql + 'isnull(sum(cast(u.Volume as int)), 0) AS AggregateUpdatedVolume, isnull(avg(u.Score) - avg(b.Score), 0.0) AS AggregatedRatingDifference, ' + @CR
set @sql = @sql + 'isnull(sum(cast(u.Volume as int)) - sum(cast(b.Volume as int)), 0) AS AggregateVolumeDifference, convert(varchar, max(u.SearchDate), 101) as UpdatedDate ' + @CR
set @sql = @sql + 'FROM #baseline_final b ' + @CR
set @sql = @sql +  'inner join #updated_final u ' + @CR
set @sql = @sql +  'on u.NPI = b.NPI ' + @CR
set @sql = @sql +  'inner join ' + @Database + '.dbo.PhysicianMedia m ' + @CR
set @sql = @sql +  'on m.NPI = u.NPI ' + @CR
--set @sql = @sql + 'where convert(varchar, u.SearchDate, 101) between cast(convert(varchar, GetDate(), 101) as datetime) - 30 and GetDate() ' + @CR--this is here to test 30 out
--set @sql = @sql + 'and u.SearchDate <> ''03/31/2016'' ' + @CR -- this was added with the 30 day out
set @sql = @sql + 'where datepart(month, u.SearchDate) = ''' + cast(@Month as nvarchar(5)) + ''' ' + @CR
set @sql = @sql + 'Group by m.NPI, m.LastName, m.FirstName, b.Score, u.Score ' + @CR
set @sql = @sql + 'Order By m.LastName ' + @CR
--print(@sql)
exec(@sql)

--select * from #baseline_final
--select * from #updated_final

drop table #baseline_data
drop table #baseline_volume
drop table #baseline_final
drop table #updated_final
drop table #updated_volume
drop table #updated_data
drop table #physicians

















