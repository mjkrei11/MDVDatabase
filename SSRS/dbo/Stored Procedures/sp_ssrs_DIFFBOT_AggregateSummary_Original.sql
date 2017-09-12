







CREATE procedure [dbo].[sp_ssrs_DIFFBOT_AggregateSummary_Original] (
	@Database nvarchar(200)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'Rothman'
exec sp_ssrs_DIFFBOT_AggregateSummary_Original @Database
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
@udf_2 nvarchar(400),
@udf_3 nvarchar(400),
@counter int,
@site_counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

declare
@BatchID int

set @sql = 'select @Tempint = max(BatchID) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks '
set @parms = '@Tempint int output'
exec sp_executesql @sql, @parms, @Tempint = @BatchID output

create table #physicians(ID int identity, NPI nvarchar(10))

set @sql = 'insert #physicians(NPI) ' + @CR
set @sql = @sql + 'select distinct r.NPI from ' + @Database + '.dbo.DIFFBOT_ResultLinks r ' +@CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia p on p.NPI = r.NPI and p.Status = ''Active'' ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') '
exec(@sql)

declare
@IsBaseline int

set @sql = 'select top 1 @Tempint = IsSummaryBaseline ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.rep_program_baseline ' + @CR
set @sql = @sql + 'where IsBaseLine = 1' + @CR
set @parms = '@Tempint int output'
exec sp_executesql @sql, @parms, @Tempint = @IsBaseline output

create table #baseline_data(
	NPI nvarchar(10),
	SiteName nvarchar(100),
	Score float,
	udf_2 nvarchar(400),
	udf_3 nvarchar(400)
)

if @IsBaseline = 1
begin
	set @sql = 'insert #baseline_data ' + @CR
	set @sql = @sql + 'select NPI, SiteName, Rating * Volume, udf_2, udf_3 ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.rep_program_baseline ' + @CR
	set @sql = @sql + 'where IsBaseline = 1 ' + @CR
	set @sql = @sql + 'and SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') '
	exec(@sql)
end
else
begin
	set @sql = 'insert #baseline_data ' + @CR
	set @sql = @sql + 'select NPI, SiteName, Rating * Volume, udf_2, udf_3 ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.rep_core_baseline ' + @CR
	set @sql = @sql + 'where IsBaseline = 1 ' + @CR
	set @sql = @sql + 'and SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') '
	exec(@sql)
end

create table #sites (ID int identity, SiteName nvarchar(50))
set @sql = 'insert #sites(SiteName) ' + @CR
set @sql = @sql + 'select distinct SiteName ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
set @sql = @sql + 'and BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
exec(@sql)

create table #NPI (ID int identity, NPI nvarchar(10))
set @sql = 'insert #NPI(NPI) ' + @CR
set @sql = @sql + 'select distinct NPI ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
set @sql = @sql + 'and BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
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
		set @sql = @sql + 'and BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
		set @sql = @sql + 'order by ResultVolume desc, ResultRating desc ' + @CR
		--print(@sql)
		exec(@sql)

		set @site_counter = @site_counter + 1
	end

	set @counter = @counter + 1
end

create table #updated_data(
	NPI nvarchar(10),
	RatingsSite nvarchar(400),
	Score float,
	SearchDate datetime
)

--set @sql = 'insert #updated_data ' + @CR
--set @sql = @sql + 'select NPI, SiteName, ResultRating * ResultVolume, SearchDate ' + @CR
--set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
--set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
--set @sql = @sql + 'and BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' '
----print(@sql)
--exec(@sql)

set @sql = 'insert #updated_data ' + @CR
set @sql = @sql + 'select NPI, SiteName, Rating * Volume, SearchDate ' + @CR
set @sql = @sql + 'from #result_links_rating ' + @CR
--set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
--set @sql = @sql + 'and BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' '
--print(@sql)
exec(@sql)

create table #baseline_volume(NPI nvarchar(10), Volume int, BaselineDate datetime)
create table #updated_volume(NPI nvarchar(10), Volume int)

if @IsBaseline = 1
begin
	set @sql = 'insert #baseline_volume ' + @CR
	set @sql = @sql + 'select distinct NPI, sum(Volume) As BaselineVolume, max(ProgramDate) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.rep_program_baseline ' + @CR
	set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
	set @sql = @sql + 'group by NPI ' + @CR
	exec(@sql)
end
else
begin
	set @sql = 'insert #baseline_volume ' + @CR
	set @sql = @sql + 'select distinct NPI, sum(Volume) As BaselineVolume, max(BaselineDate) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.rep_core_baseline ' + @CR
	set @sql = @sql + 'where SiteName in (''HealthGrades'',''Vitals'',''RateMDs'',''UCompare'') ' + @CR
	set @sql = @sql + 'group by NPI ' + @CR
	exec(@sql)
end

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

create table #baseline_final(NPI nvarchar(10), Score float, Volume int, BaselineDate datetime, udf_2 nvarchar(400), udf_3 nvarchar(400))
create table #updated_final(NPI nvarchar(10), Score float, Volume int, SearchDate datetime)

set @counter = 1
while @counter <= (select max(ID) from #physicians)
begin
	
	set @Score = null
	set @VolumeDenom = null
	set @SearchDate = null
	set @udf_2 = null
	set @udf_3 = null

	select @NPI = NPI from #physicians where ID = @counter
	select @Score = round(sum(Score), 1) from #baseline_data where NPI = @NPI
	select @VolumeDenom = Volume from #baseline_volume where NPI = @NPI
	select @BaselineDate = BaselineDate from #baseline_volume where NPI = @NPI
	select @udf_2 = udf_2 from #baseline_data where NPI = @NPI
	select @udf_3 = udf_3 from #baseline_data where NPI = @NPI

	insert #baseline_final select @NPI, case when isnull(@VolumeDenom, 0) = 0 then 0 else @Score / @VolumeDenom end, @VolumeDenom, @BaselineDate, @udf_2, @udf_3

	set @Score = null
	set @VolumeDenom = null

	select @NPI = NPI from #physicians where ID = @counter
	select @Score = round(sum(Score), 1) from #updated_data where NPI = @NPI
	select @VolumeDenom = Volume from #updated_volume where NPI = @NPI
	select @SearchDate = max(SearchDate) from #updated_data where NPI = @NPI

	insert #updated_final select @NPI, case when isnull(@VolumeDenom, 0) = 0 then 0 else @Score / @VolumeDenom end, @VolumeDenom, @SearchDate

	set @counter = @counter + 1
end

set @sql = 'SELECT distinct m.NPI, m.LastName, m.FirstName, isnull(b.Score, 0.0) AS AggregateBaselineRating, ' + @CR
set @sql = @sql + 'isnull(sum(b.Volume), 0) AS AggregateBaselineVolume, convert(varchar, max(b.BaselineDate), 101) as BaselineDate, isnull(u.Score, 0.0) AS AggregateUpdatedRating, ' + @CR
set @sql = @sql + 'isnull(sum(cast(u.Volume as int)), 0) AS AggregateUpdatedVolume, isnull(avg(u.Score) - avg(b.Score), 0.0) AS AggregatedRatingDifference, ' + @CR
set @sql = @sql + 'isnull(sum(cast(u.Volume as int)) - sum(cast(b.Volume as int)), 0) AS AggregateVolumeDifference, convert(varchar, max(u.SearchDate), 101) as UpdatedDate, ' + @CR
set @sql = @sql + 'b.udf_2, b.udf_3 ' + @CR
set @sql = @sql + 'FROM #baseline_final b ' + @CR
set @sql = @sql +  'inner join #updated_final u ' + @CR
set @sql = @sql +  'on u.NPI = b.NPI ' + @CR
set @sql = @sql +  'inner join ' + @Database + '.dbo.PhysicianMedia m ' + @CR
set @sql = @sql +  'on m.NPI = u.NPI ' + @CR
set @sql = @sql + 'where convert(varchar, u.SearchDate, 101) between cast(convert(varchar, GetDate(), 101) as datetime) - 30 and GetDate() ' + @CR--this is here to test 30 out
set @sql = @sql + 'and u.SearchDate <> ''03/31/2016'' ' + @CR -- this was added with the 30 day out
set @sql = @sql + 'Group by m.NPI, m.LastName, m.FirstName, b.Score, u.Score, b.udf_2, b.udf_3 ' + @CR
set @sql = @sql + 'Order By m.LastName ' + @CR
exec(@sql)

drop table #baseline_data
drop table #updated_data









