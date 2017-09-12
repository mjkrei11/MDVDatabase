












CREATE procedure [dbo].[sp_ssrs_DIFFBOT_PieCharts_Copy] (
	@Database nvarchar(200), @Month int
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200), @Month int
set @Database = 'Rothman'
set @Month = 3

exec sp_ssrs_DIFFBOT_PieCharts_Copy @Database, @Month
*/

declare
@CustomerID nvarchar(10),
@CustomerSource nvarchar(400),
@CustomerLogo varbinary(max),
@SiteName nvarchar(50),
@NPI nvarchar(10),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1),
@counter int,
@site_counter int

set @CR = char(13)

declare --@BatchID int
@StartBatchID int,
@EndBatchID int

set @sql = 'select @TempStartBatchID = min(BatchID), @TempEndBatchID = max(BatchID) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where datepart(month, SearchDate) = ''' + cast(@Month as nvarchar(10)) + ''' and BatchID > 0 ' + @CR
set @parms = '@TempStartBatchID int output, @TempEndBatchID int output'
exec sp_executesql @sql, @parms, @TempStartBatchID = @StartBatchID output, @TempEndBatchID = @EndBatchID output

create table #baseline_pie_chart(SiteName varchar(50), Volume int, BaselineDate datetime, OrderID int)
create table #updated_pie_chart(SiteName varchar(50), Volume int, UpdatedDate datetime, OrderID int)

	set @sql = 'insert #baseline_pie_chart(SiteName, Volume, BaselineDate) ' + @CR
	set @sql = @sql + 'select case RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else RatingsSite end, ' + @CR
	set @sql = @sql + 'sum(NumberOfRatings) as Volume, ''5/6/2015'' as BaselineDate ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchive ' + @CR
	set @sql = @sql + 'where XComboKey like ''%_1649324195_2015_Q2'' ' + @CR
	set @sql = @sql + 'and RatingsSite in (''HealthGrades'',''Ucompare'',''Rate MD Secure'',''Vitals'') ' + @CR
	set @sql = @sql + 'group by RatingsSite ' + @CR
	--print(@sql)
	exec(@sql)

create table #rep_baseline_pie_chart(SiteName varchar(50), Volume int, BaselineDate datetime, OrderID int)

	set @sql = 'insert #rep_baseline_pie_chart(SiteName, Volume, BaselineDate) ' + @CR
	set @sql = @sql + 'select case b.BaselineSite when ''Rate MD Secure'' then ''RateMDs'' else b.BaselineSite end, ' + @CR
	set @sql = @sql + 'sum(cast(b.BaselineNumberofRatings as int)) as Volume, ''5/6/2015'' as BaselineDate ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.VIRepBaseline b ' + @CR
	set @sql = @sql + 'where b.BaselineIdentifier <> ''2015-10-14'' ' + @CR
	set @sql = @sql + 'and b.BaselineSite in (''HealthGrades'',''Ucompare'',''RateMDs'',''Vitals'') ' + @CR
	set @sql = @sql + 'group by b.BaselineSite ' + @CR
	--print(@sql)
	exec(@sql)

create table #sites (ID int identity, SiteName nvarchar(50))
set @sql = 'insert #sites(SiteName) ' + @CR
set @sql = @sql + 'select distinct SiteName ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
set @sql = @sql + 'and BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''' ' + @CR
exec(@sql)

create table #NPI (ID int identity, NPI nvarchar(10))
set @sql = 'insert #NPI(NPI) ' + @CR
set @sql = @sql + 'select distinct NPI ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
set @sql = @sql + 'and BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''' ' + @CR
exec(@sql)

create table #result_links (NPI nvarchar(10), SiteName nvarchar(50), Volume int, UpdatedDate datetime)

set @counter = 1
while @counter <= (select max(ID) from #NPI)
begin
	select @NPI = NPI from #NPI where ID = @counter

	set @site_counter = 1
	while @site_counter <= (select max(ID) from #sites)
	begin
		select @SiteName = SiteName from #sites where ID = @site_counter

		set @sql = 'insert #result_links ' + @CR
		set @sql = @sql + 'select top 1 NPI, SiteName, ResultVolume, SearchDate ' + @CR
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

insert #updated_pie_chart(SiteName, Volume, UpdatedDate) 
select SiteName, sum(Volume), max(convert(varchar, UpdatedDate, 101)) from #result_links
group by SiteName


update		#baseline_pie_chart
set			OrderID = 1
where		SiteName = 'HealthGrades'

update		#baseline_pie_chart
set			OrderID = 2
where		SiteName = 'RateMDs'

update		#baseline_pie_chart
set			OrderID = 3
where		SiteName = 'Vitals'

update		#baseline_pie_chart
set			OrderID = 4
where		SiteName = 'UCompare'

update		#rep_baseline_pie_chart
set			OrderID = 1
where		SiteName = 'HealthGrades'

update		#rep_baseline_pie_chart
set			OrderID = 2
where		SiteName = 'RateMDs'

update		#rep_baseline_pie_chart
set			OrderID = 3
where		SiteName = 'Vitals'

update		#rep_baseline_pie_chart
set			OrderID = 4
where		SiteName = 'UCompare'
/*
update		#baseline_pie_chart
set			OrderID = 5
where		SiteName = 'Yelp'

update		#baseline_pie_chart
set			OrderID = 6
where		SiteName = 'Wellness'

update		#baseline_pie_chart
set			OrderID = 7
where		SiteName = 'Yahoo'
*/
update		#updated_pie_chart
set			OrderID = 1
where		SiteName = 'HealthGrades'

update		#updated_pie_chart
set			OrderID = 2
where		SiteName = 'RateMDs'

update		#updated_pie_chart
set			OrderID = 3
where		SiteName = 'Vitals'

update		#updated_pie_chart
set			OrderID = 4
where		SiteName = 'UCompare'

/*
update		#updated_pie_chart
set			OrderID = 5
where		SiteName = 'Yelp'

update		#updated_pie_chart
set			OrderID = 6
where		SiteName = 'Wellness'

update		#updated_pie_chart
set			OrderID = 7
where		SiteName = 'Yahoo'
*/

create table #piecharts(
	RatingType nvarchar(20),
	RatingSite nvarchar(100),
	NumberOfRatings int,
	ChartDate datetime,
	OrderID int
)

insert #piecharts
select 'Baseline' as RatingType, b.SiteName as RatingSite, sum(b.Volume) + sum(r.Volume) as NumberOfRatings, b.BaselineDate as ChartDate, b.OrderID
from #baseline_pie_chart b
	inner join #rep_baseline_pie_chart r on r.SiteName = b.SiteName
		and r.OrderID = b.OrderID
		and r.BaselineDate = b.BaselineDate
		group by b.SiteName, b.BaselineDate, b.OrderID

insert #piecharts
select 'Updated' as RatingType, u.SiteName, u.Volume, u.UpdatedDate, u.OrderID
from #updated_pie_chart u 

select * from #piecharts

drop table #baseline_pie_chart
drop table #updated_pie_chart
drop table #result_links
drop table #piecharts












