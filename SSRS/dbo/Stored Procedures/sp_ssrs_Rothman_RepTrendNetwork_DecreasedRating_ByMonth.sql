











CREATE procedure [dbo].[sp_ssrs_Rothman_RepTrendNetwork_DecreasedRating_ByMonth](
	@Database nvarchar(200),
	@StartMonth int,
	@EndMonth int
)

as

/*
declare
@Database nvarchar(200) = 'Rothman',
@StartMonth int = 8,
@EndMonth int = 8

exec sp_ssrs_Rothman_RepTrendNetwork_DecreasedRating_ByMonth @Database, @StartMonth, @EndMonth
*/


declare
@StartDate datetime,
@EndDate datetime,
@year int,
@CustomerID nvarchar(50),
@CustomerSource nvarchar(120),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

select @year = year(getdate())
select @StartDate = cast(@year as nvarchar(4)) + '-' + cast(@StartMonth as nvarchar(2)) + '-01'
select @EndDate = cast(@year as nvarchar(4)) + '-' + cast(@EndMonth as nvarchar(2)) + '-01'

declare @StartingMonthDate datetime = @StartDate
declare @EndingMonthDate datetime = @EndDate

select @StartDate = convert(varchar, dateadd(s, 0, dateadd(mm, datediff(m, 0, @StartDate) + 0, -1)), 101)
select @EndDate = convert(varchar, dateadd(s, -1, dateadd(mm, datediff(m, 0, @EndDate) + 1, 0)), 101)

create table #comment_dates(StartDateStart datetime, StartDateEnd datetime, EndDateStart datetime, EndDateEnd datetime)
insert #comment_dates values(@StartingMonthDate, @StartDate, @EndingMonthDate, @EndDate)

create table #param_dates(StartDate datetime, EndDate datetime)
insert #param_dates values(@StartDate, @EndDate)

create table #dates(StartDate datetime, EndDate datetime)
set @sql = 'insert #dates ' + @CR
set @sql = @sql + 'select ' + @CR
set @sql = @sql + '(select top 1 RepTrendDate ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.VIRepTrend ' + @CR
set @sql = @sql + 'where RepTrendDate <= (select StartDate from #param_dates) ' + @CR
set @sql = @sql + 'order by RepTrendDate desc), ' + @CR
set @sql = @sql + '(select top 1 RepTrendDate ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.VIRepTrend ' + @CR
set @sql = @sql + 'where RepTrendDate <= (select EndDate from #param_dates) ' + @CR
set @sql = @sql + 'order by RepTrendDate desc) ' + @CR
exec(@sql)

select @StartDate = StartDate from #dates
select @EndDate = EndDate from #dates

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

create table #start_values
(
	OrderNo int,
	ValuesDate datetime,
	NPI nvarchar(10),
	PhysicianName nvarchar(400),
	RatingSite nvarchar(50),
	Rating decimal(10,2),
	Volume int
)

set @sql = 'insert #start_values ' + @CR
set @sql = @sql + 'select 0, ''' + convert(varchar, @StartDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select StartDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 1, ''' + convert(varchar, @StartDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select StartDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI <> ''' + @CustomerID + ''' and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 2, ''' + convert(varchar, @StartDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select StartDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite not in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
--print @sql
exec(@sql)

create table #end_values
(
	OrderNo int,
	ValuesDate datetime,
	NPI nvarchar(10),
	PhysicianName nvarchar(400),
	RatingSite nvarchar(50),
	Rating decimal(10,2),
	Volume int
)

set @sql = 'insert #end_values ' + @CR
set @sql = @sql + 'select 0, ''' + convert(varchar, @EndDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite,  ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select EndDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 1, ''' + convert(varchar, @EndDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select EndDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI <> ''' + @CustomerID + ''' and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 2, ''' + convert(varchar, @EndDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select EndDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite not in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
--print @sql
exec(@sql)

create table #StartVolumeSum(NPI nvarchar(10), PhysicianName nvarchar(400), Rating float, Volume int, ValuesDate datetime)
insert #StartVolumeSum
select	NPI, PhysicianName, sum(Rating)/sum(Volume), sum(Volume), ValuesDate
from	#start_values 
group by NPI, PhysicianName, ValuesDate

create table #EndVolumeSum(NPI nvarchar(10), PhysicianName nvarchar(400), Rating float, Volume int, ValuesDate datetime)
insert #EndVolumeSum
select	NPI, PhysicianName, sum(Rating)/sum(Volume), sum(Volume), ValuesDate
from	#end_values 
group by NPI, PhysicianName, ValuesDate

--select * from #StartVolumeSum where NPI = '1588608731'

--select * from #EndVolumeSum where NPI = '1588608731'

create table #DecreasedRating(StartDate date, EndDate date, PhysicianName nvarchar(400), StartingRating float, StartingVolume int, 
			EndingRating float, EndingVolume int, RatingDiff float, VolumeDiff int, DataType nvarchar(50))
insert #DecreasedRating
select		distinct s.ValuesDate as StartDate, e.ValuesDate as EndDate, s.PhysicianName, 
			round(isnull(s.Rating, 0.00),2) as StartingRating, isnull(s.Volume, 0) as StartingVolume, 
			round(isnull(e.Rating, 0.00),2) as EndingRating, isnull(e.Volume, 0) as EndingVolume, 
			round(isnull(round(e.Rating,2), 0) - isnull(round(s.Rating,2), 0),2) as RatingDiff, isnull(e.Volume, 0) - isnull(s.Volume, 0) as VolumeDiff, 'Decreased Rating' as DataType
from		#StartVolumeSum s
left join	#EndVolumeSum e
on			e.NPI = s.NPI
where			e.NPI <> '1649324195' and s.NPI <> '1649324195'

select * 
from #DecreasedRating
where RatingDiff < 0
order by RatingDiff asc

drop table #param_dates
drop table #dates
drop table #comment_dates
drop table #start_values
drop table #end_values
drop table #StartVolumeSum
drop table #EndVolumeSum
drop table #DecreasedRating









