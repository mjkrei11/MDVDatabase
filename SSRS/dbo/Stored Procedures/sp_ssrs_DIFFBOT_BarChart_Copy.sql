












CREATE procedure [dbo].[sp_ssrs_DIFFBOT_BarChart_Copy] (
	@Database nvarchar(200), @Month int
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200), @Month int
set @Database = 'Rothman'
set @Month = 3

exec sp_ssrs_DIFFBOT_BarChart_Copy @Database, @Month
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

declare 
@StartBatchID int,
@EndBatchID int

set @sql = 'select @TempStartBatchID = min(BatchID), @TempEndBatchID = max(BatchID) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where datepart(month, SearchDate) = ''' + cast(@Month as nvarchar(10)) + ''' and BatchID > 0 ' + @CR
set @parms = '@TempStartBatchID int output, @TempEndBatchID int output'
exec sp_executesql @sql, @parms, @TempStartBatchID = @StartBatchID output, @TempEndBatchID = @EndBatchID output

create table #baseline_pie_chart(SiteName varchar(50), Rating decimal(2,1), BaselineDate datetime)
create table #updated_pie_chart(SiteName varchar(50), Rating decimal(2,1), UpdatedDate datetime)

	--set @sql = 'insert #baseline_pie_chart ' + @CR
	--set @sql = @sql + 'select SiteName, avg(Rating), max(udf_1) ' + @CR
	--set @sql = @sql + 'from ' + @Database + '.dbo.rep_program_baseline ' + @CR
	--set @sql = @sql + 'where IsBaseLine = 1 ' + @CR
	--set @sql = @sql + 'and SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
	----set @sql = @sql + 'and SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'', ''Yelp'',''Wellness'',''Yahoo'') ' + @CR
	--set @sql = @sql + 'group by SiteName ' + @CR
	--exec(@sql)


	set @sql = 'insert #baseline_pie_chart ' + @CR
	set @sql = @sql + 'select case RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else RatingsSite end, ' + @CR
	set @sql = @sql + 'Rating, ''5/6/2015'' as BaselineDate ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchive ' + @CR
	set @sql = @sql + 'where XComboKey like ''%_1649324195_2015_Q2'' ' + @CR
	set @sql = @sql + 'and RatingsSite in (''HealthGrades'',''Ucompare'',''Rate MD Secure'',''Vitals'') ' + @CR
	set @sql = @sql + 'and Rating <> 0 ' + @CR
	--print(@sql)
	exec(@sql)

create table #rep_baseline_pie_chart(SiteName varchar(50), Rating decimal(2,1), BaselineDate datetime)

	set @sql = 'insert #rep_baseline_pie_chart ' + @CR
	set @sql = @sql + 'select case b.BaselineSite when ''Rate MD Secure'' then ''RateMDs'' else b.BaselineSite end, ' + @CR
	set @sql = @sql + 'BaselineRating as Rating, ''5/6/2015'' as BaselineDate ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.VIRepBaseline b ' + @CR
	set @sql = @sql + 'where b.BaselineIdentifier <> ''2015-10-14'' ' + @CR
	set @sql = @sql + 'and b.BaselineSite in (''HealthGrades'',''Ucompare'',''RateMDs'',''Vitals'') ' + @CR
	print(@sql)
	exec(@sql)

create table #Ratings(SiteName varchar(50), Rating decimal(2,1), BaselineDate datetime)

	set @sql = 'insert #Ratings ' + @CR
	set @sql = @sql + 'select SiteName, Rating, BaselineDate ' + @CR
	set @sql = @sql + 'from #baseline_pie_chart ' + @CR
	set @sql = @sql + 'union' + @CR
	set @sql = @sql + 'select SiteName, Rating, BaselineDate ' + @CR
	set @sql = @sql + 'from #rep_baseline_pie_chart ' + @CR
	--print(@sql)
	exec(@sql)

create table #AvgRatings(SiteName varchar(50), Rating decimal(2,1), BaselineDate datetime)

	set @sql = 'insert #AvgRatings ' + @CR
	set @sql = @sql + 'select SiteName, avg(Rating) as Rating, BaselineDate ' + @CR
	set @sql = @sql + 'from #Ratings ' + @CR
	set @sql = @sql + 'group by SiteName, BaselineDate ' + @CR
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

create table #result_links (NPI nvarchar(10), SiteName nvarchar(50), Rating decimal(3,2), UpdatedDate datetime)

set @counter = 1
while @counter <= (select max(ID) from #NPI)
begin
	select @NPI = NPI from #NPI where ID = @counter

	set @site_counter = 1
	while @site_counter <= (select max(ID) from #sites)
	begin
		select @SiteName = SiteName from #sites where ID = @site_counter

		set @sql = 'insert #result_links ' + @CR
		set @sql = @sql + 'select top 1 NPI, SiteName, ResultRating, SearchDate ' + @CR
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

insert #updated_pie_chart(SiteName, Rating, UpdatedDate) 
select SiteName, avg(Rating), max(convert(varchar, UpdatedDate, 101)) from #result_links
group by SiteName

select 'Baseline' as RatingType, b.SiteName as RatingSite, b.Rating as NumberOfRatings, b.BaselineDate as ChartDate
from #AvgRatings b
union
select 'Updated' as RatingType, u.SiteName, u.Rating, u.UpdatedDate
from #updated_pie_chart u 

drop table #baseline_pie_chart
drop table #updated_pie_chart
drop table #result_links












