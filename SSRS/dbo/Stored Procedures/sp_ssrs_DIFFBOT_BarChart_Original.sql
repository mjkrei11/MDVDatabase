







CREATE procedure [dbo].[sp_ssrs_DIFFBOT_BarChart_Original] (
	@Database nvarchar(200)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'twincities'

exec sp_ssrs_DIFFBOT_BarChart_Original @Database
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

declare @BatchID int

set @sql = 'select @TempBatchID = max(BatchID) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks '
set @parms = '@TempBatchID int output'
exec sp_executesql @sql, @parms, @TempBatchID = @BatchID output

create table #baseline_pie_chart(SiteName varchar(50), Rating decimal(2,1), BaselineDate datetime)
create table #updated_pie_chart(SiteName varchar(50), Rating decimal(2,1), UpdatedDate datetime)

declare
@IsBaseline int

set @sql = 'select top 1 @Tempint = IsSummaryBaseline ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.rep_program_baseline ' + @CR
set @sql = @sql + 'where IsBaseLine = 1' + @CR
set @parms = '@Tempint int output'
exec sp_executesql @sql, @parms, @Tempint = @IsBaseline output

if @IsBaseline = 1
begin
	set @sql = 'insert #baseline_pie_chart ' + @CR
	set @sql = @sql + 'select SiteName, avg(Rating), max(udf_1) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.rep_program_baseline ' + @CR
	set @sql = @sql + 'where IsBaseLine = 1 ' + @CR
	set @sql = @sql + 'and SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
	--set @sql = @sql + 'and SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'', ''Yelp'',''Wellness'',''Yahoo'') ' + @CR
	set @sql = @sql + 'group by SiteName ' + @CR
	exec(@sql)
end
else
begin
	set @sql = 'insert #baseline_pie_chart ' + @CR
	set @sql = @sql + 'select SiteName, avg(Rating), max(udf_1) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.rep_core_baseline ' + @CR
	set @sql = @sql + 'where IsBaseLine = 1 ' + @CR
	set @sql = @sql + 'and SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
	--set @sql = @sql + 'and SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'', ''Yelp'',''Wellness'',''Yahoo'') ' + @CR
	set @sql = @sql + 'group by SiteName ' + @CR
	exec(@sql)
end

create table #sites (ID int identity, SiteName nvarchar(50))
set @sql = 'insert #sites(SiteName) ' + @CR
set @sql = @sql + 'select distinct SiteName ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
--set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'', ''Yelp'',''Wellness'',''Yahoo'') ' + @CR
set @sql = @sql + 'and BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
--set @sql = @sql + 'and BatchId between 109 and 139 ' + @CR -- This was to get TCO's December data
exec(@sql)

create table #NPI (ID int identity, NPI nvarchar(10))
set @sql = 'insert #NPI(NPI) ' + @CR
set @sql = @sql + 'select distinct NPI ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
--set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'', ''Yelp'',''Wellness'',''Yahoo'') ' + @CR
set @sql = @sql + 'and BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
--set @sql = @sql + 'and BatchId between 109 and 139 ' + @CR -- This was to get TCO's December data
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
		--set @sql = @sql + 'and BatchId between 109 and 139 ' + @CR -- This was to get TCO's December data
		set @sql = @sql + 'and BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
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

--set @sql = 'insert #updated_pie_chart ' + @CR
--set @sql = @sql + 'select SiteName, avg(ResultRating), max(convert(varchar, SearchDate, 101)) ' + @CR
--set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
--set @sql = @sql + 'where BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
--set @sql = @sql + 'and SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
--set @sql = @sql + 'group by SiteName ' + @CR
--exec(@sql)

select 'Baseline' as RatingType, b.SiteName as RatingSite, b.Rating as NumberOfRatings, b.BaselineDate as ChartDate
from #baseline_pie_chart b
union
select 'Updated' as RatingType, u.SiteName, u.Rating, u.UpdatedDate
from #updated_pie_chart u 

drop table #baseline_pie_chart
drop table #updated_pie_chart
drop table #result_links







