






CREATE procedure [dbo].[sp_ssrs_Rothman_RepTrendNetwork_PositiveComments_ByMonth](
	@Database nvarchar(200),
	@StartMonth int,
	@EndMonth int
)

as

/*
declare
@Database nvarchar(200) = 'Rothman',
@StartMonth int = 10,
@EndMonth int = 10

exec sp_ssrs_Rothman_RepTrendNetwork_PositiveComments_ByMonth @Database, @StartMonth, @EndMonth
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

select @StartDate = convert(varchar, dateadd(s, 0, dateadd(mm, datediff(m, 0, @StartDate) + 0, 0)), 101)
select @EndDate = convert(varchar, dateadd(s, -1, dateadd(mm, datediff(m, 0, @EndDate) + 1, 0)), 101)

create table #comment_dates(StartDateStart datetime, StartDateEnd datetime, EndDateStart datetime, EndDateEnd datetime)
insert #comment_dates values(@StartingMonthDate, @StartDate, @EndingMonthDate, @EndDate)

--select * from #comment_dates

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

--select * from #dates

--select @StartDate = StartDate from #dates
--select @EndDate = EndDate from #dates

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
	Volume int,
	--RiskCount int,
	--PercentAboveBench int,
	CommentCount int
)

set @sql = 'insert #start_values ' + @CR
set @sql = @sql + 'select 0, ''' + convert(varchar, @StartDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select StartDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
--set @sql = @sql + 'group by media.NPI, media.FullName ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 1, ''' + convert(varchar, @StartDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select StartDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI <> ''' + @CustomerID + ''' and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
--set @sql = @sql + 'group by media.NPI, media.FullName ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 2, ''' + convert(varchar, @StartDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select StartDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite not in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
--set @sql = @sql + 'group by media.NPI, media.FullName ' + @CR
print @sql
exec(@sql)

create table #end_values
(
	OrderNo int,
	ValuesDate datetime,
	NPI nvarchar(10),
	PhysicianName nvarchar(400),
	RatingSite nvarchar(50),
	Rating decimal(10,2),
	Volume int,
	--RiskCount int,
	--PercentAboveBench int,
	CommentCount int
)

set @sql = 'insert #end_values ' + @CR
set @sql = @sql + 'select 0, ''' + convert(varchar, @EndDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite,  ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select EndDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
--set @sql = @sql + 'group by media.NPI, media.FullName ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 1, ''' + convert(varchar, @EndDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select EndDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI <> ''' + @CustomerID + ''' and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
--set @sql = @sql + 'group by media.NPI, media.FullName ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 2, ''' + convert(varchar, @EndDate, 101) + ''', media.NPI, media.FullName, metric.RepTrendSite, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRating, 0.0) * isnull(metric.RepTrendCount, 0) as Rating, ' + @CR
set @sql = @sql + 'metric.RepTrendCount as Volume, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select EndDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite not in (''HealthGrades'',''RateMDs'',''UCompare'',''Vitals'') ' + @CR
--set @sql = @sql + 'group by media.NPI, media.FullName ' + @CR
--print @sql
exec(@sql)

create table #comment_counts(NPI nvarchar(10), RatingSite nvarchar(50), CommentCount int)

set @sql = 'insert #comment_counts ' + @CR
set @sql = @sql + 'select media.NPI, metric.RepCommentSite, count(*) ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepComment metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepCommentTab = ''Weekly'' ' + @CR
set @sql = @sql + 'and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
set @sql = @sql + 'and datepart(month, cast(metric.RepCommentDate as datetime)) = (select datepart(month, StartDateStart) - 1 from #comment_dates) ' + @CR
set @sql = @sql + 'and datepart(year, cast(metric.RepCommentDate as datetime)) = (select datepart(year, StartDateStart) from #comment_dates) ' + @CR
set @sql = @sql + 'and metric.RepCommentIsNegative is null ' + @CR
set @sql = @sql + 'group by media.NPI, metric.RepCommentSite ' + @CR
print @sql
exec(@sql)

--select * from #comment_counts where NPI = '1932148798'

update		s
set			s.CommentCount = c.CommentCount
from		#start_values s
inner join	#comment_counts c
on			c.NPI = s.NPI
and			c.RatingSite = s.RatingSite

truncate table #comment_counts

set @sql = 'insert #comment_counts ' + @CR
set @sql = @sql + 'select media.NPI, metric.RepCommentSite, count(*) ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepComment metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepCommentTab = ''Weekly'' ' + @CR
set @sql = @sql + 'and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
set @sql = @sql + 'and datepart(month, cast(metric.RepCommentDate as datetime)) = (select datepart(month, EndDateStart) from #comment_dates) ' + @CR
set @sql = @sql + 'and metric.RepCommentIsNegative is null ' + @CR
set @sql = @sql + 'and datepart(year, cast(metric.RepCommentDate as datetime)) = (select datepart(year, EndDateStart) from #comment_dates) ' + @CR 
set @sql = @sql + 'group by media.NPI, metric.RepCommentSite ' + @CR
exec(@sql)

--select * from #comment_counts where NPI = '1932148798'

update		s
set			s.CommentCount = c.CommentCount
from		#end_values s
inner join	#comment_counts c
on			c.NPI = s.NPI
and			c.RatingSite = s.RatingSite

create table #TopComments(TopCommentStartDate date, TopCommentEndDate date, TopCommentPhysicianName nvarchar(400), --RatingSites nvarchar(50),
			TopCommentBeginCount int, TopCommentEndCount int, TopCommentVolumeDiff int, DataType nvarchar(50))
insert #TopComments
select		s.ValuesDate as StartDate, e.ValuesDate as EndDate, s.PhysicianName, --s.RatingSite,
			case when (s.CommentCount IS NULL) then '0' else s.CommentCount end as StartCommentCount, e.CommentCount as EndCommentCount,
			isnull(e.CommentCount, 0) - isnull(s.CommentCount, 0) as CommentDiff, 'Top Comments' as DataType
from		#start_values s
left join	#end_values e
on			e.NPI = s.NPI and e.RatingSite = s.RatingSite
where			e.NPI <> '1649324195' and s.NPI <> '1649324195'
and			isnull(e.CommentCount, 0) - isnull(s.CommentCount, 0) > -1
--and e.NPI = '1811975949' and s.NPI = '1811975949'
order by CommentDiff desc


--create table #TopComments(TopCommentStartDate date, TopCommentEndDate date, TopCommentPhysicianName nvarchar(400), RatingSites nvarchar(50),
--			TopCommentBeginCount int, TopCommentEndCount int, TopCommentVolumeDiff int, DataType nvarchar(50))
--insert #TopComments
--select		top 20 
--			s.ValuesDate as StartDate, e.ValuesDate as EndDate, s.PhysicianName, s.RatingSite,
--			case when (s.CommentCount IS NULL) then '0' else s.CommentCount end as StartCommentCount, e.CommentCount as EndCommentCount,
--			isnull(e.CommentCount, 0) - isnull(s.CommentCount, 0) as CommentDiff, 'Top Comments' as DataType
--from		#start_values s
--left join	#end_values e
--on			e.NPI = s.NPI and e.RatingSite = s.RatingSite
--where			e.NPI <> '1649324195' and s.NPI <> '1649324195'
--and			isnull(e.CommentCount, 0) - isnull(s.CommentCount, 0) > -1
--and e.NPI = '1811975949' and s.NPI = '1811975949'
--order by CommentDiff desc

create table #CommentSum(TopCommentStartDate date, TopCommentEndDate date, TopCommentPhysicianName nvarchar(400),
			TopCommentBeginCount int, TopCommentEndCount int, TopCommentVolumeDiff int, DataType nvarchar(50))
insert #CommentSum
select TopCommentStartDate, TopCommentEndDate, TopCommentPhysicianName, sum(TopCommentBeginCount) as TopCommentBeginCount,
sum(TopCommentEndCount) as TopCommentEndCount, sum(TopCommentEndCount) - sum(TopCommentBeginCount) as TopCommentVolumeDiff, DataType from #TopComments
group by TopCommentStartDate, TopCommentEndDate, TopCommentPhysicianName, DataType
order by TopCommentVolumeDiff desc

select Top 10 * from #CommentSum order by TopCommentEndCount desc

drop table #CommentSum
drop table #param_dates
drop table #dates
drop table #comment_dates
drop table #comment_counts
drop table #start_values
drop table #end_values
drop table #TopComments














