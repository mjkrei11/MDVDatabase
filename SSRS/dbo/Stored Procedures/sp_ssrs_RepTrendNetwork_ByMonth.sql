

CREATE procedure [dbo].[sp_ssrs_RepTrendNetwork_ByMonth](
	@Database nvarchar(200),
	@SiteName nvarchar(50),
	@StartMonth int,
	@StartYear int,
	@EndMonth int,
	@EndYear int
)

as

/*
declare
@Database nvarchar(200) = 'NANI',
@SiteName nvarchar(50) = 'HealthGrades',
@StartMonth int = 12,
@StartYear int = '2016',
@EndMonth int = 1,
@EndYear int = '2016'

exec sp_ssrs_RepTrendNetwork_ByMonth @Database, @SiteName, @StartMonth, @StartYear, @EndMonth, @EndYear
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
--set @StartYear = '2016'

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

select @year = year(getdate()) 
select @StartDate = cast(@Startyear as nvarchar(4)) + '-' + cast(@StartMonth as nvarchar(2)) + '-01' --'2016-11-01' --
--select @EndDate = cast(@year as nvarchar(4)) + '-' + cast(@EndMonth as nvarchar(2)) + '-01'
select @EndDate = cast(@EndYear as nvarchar(4)) + '-' + cast(@EndMonth as nvarchar(2)) + '-01'

declare @StartingMonthDate datetime = @StartDate
declare @EndingMonthDate datetime = @EndDate

--select @StartDate

select @StartDate = convert(varchar, dateadd(s, -1, dateadd(mm, datediff(m, 0, @StartDate) + 1, 0)), 101)
select @EndDate = convert(varchar, dateadd(s, -1, dateadd(mm, datediff(m, 0, @EndDate) + 1, 0)), 101)

create table #comment_dates(StartDateStart datetime, StartDateEnd datetime, EndDateStart datetime, EndDateEnd datetime)
insert #comment_dates values(@StartingMonthDate, @StartDate, @EndingMonthDate, @EndDate)
--select * into savecommentdates from #comment_dates

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
	Rating decimal(3,2),
	Volume int,
	RiskCount int,
	PercentAboveBench int,
	CommentCount int
)

set @sql = 'insert #start_values ' + @CR
set @sql = @sql + 'select 0, ''' + convert(varchar, @StartDate, 101) + ''', media.NPI, media.FullName,  ' + @CR
set @sql = @sql + 'metric.RepTrendSite, isnull(metric.RepTrendRating, 0.0) as RepTrendRating, isnull(metric.RepTrendCount, 0) as RepTrendCount, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRiskCount, 0) as RepTrendRiskCount, isnull(metric.RepTrendPercentAboveBench, 0) as RepTrendPercentAboveBench, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select StartDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite = ''' + @SiteName + ''' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 1, ''' + convert(varchar, @StartDate, 101) + ''', media.NPI, media.FullName,  ' + @CR
set @sql = @sql + 'metric.RepTrendSite, isnull(metric.RepTrendRating, 0.0) as RepTrendRating, isnull(metric.RepTrendCount, 0) as RepTrendCount, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRiskCount, 0) as RepTrendRiskCount, isnull(metric.RepTrendPercentAboveBench, 0) as RepTrendPercentAboveBench, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select StartDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI <> ''' + @CustomerID + ''' and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite = ''' + @SiteName + ''' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 2, ''' + convert(varchar, @StartDate, 101) + ''', media.NPI, media.FullName,  ' + @CR
set @sql = @sql + 'metric.RepTrendSite, isnull(metric.RepTrendRating, 0.0) as RepTrendRating, isnull(metric.RepTrendCount, 0) as RepTrendCount, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRiskCount, 0) as RepTrendRiskCount, isnull(metric.RepTrendPercentAboveBench, 0) as RepTrendPercentAboveBench, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select StartDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite <> ''' + @SiteName + ''' '
exec(@sql)

create table #end_values
(
	OrderNo int,
	ValuesDate datetime,
	NPI nvarchar(10),
	PhysicianName nvarchar(400),
	RatingSite nvarchar(50),
	Rating decimal(3,2),

	Volume int,
	RiskCount int,
	PercentAboveBench int,
	CommentCount int
)

set @sql = 'insert #end_values ' + @CR
set @sql = @sql + 'select 0, ''' + convert(varchar, @EndDate, 101) + ''', media.NPI, media.FullName,  ' + @CR
set @sql = @sql + 'metric.RepTrendSite, isnull(metric.RepTrendRating, 0.0) as RepTrendRating, isnull(metric.RepTrendCount, 0) as RepTrendCount, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRiskCount, 0) as RepTrendRiskCount, isnull(metric.RepTrendPercentAboveBench, 0) as RepTrendPercentAboveBench, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select EndDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite = ''' + @SiteName + ''' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 1, ''' + convert(varchar, @EndDate, 101) + ''', media.NPI, media.FullName,  ' + @CR
set @sql = @sql + 'metric.RepTrendSite, isnull(metric.RepTrendRating, 0.0) as RepTrendRating, isnull(metric.RepTrendCount, 0) as RepTrendCount, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRiskCount, 0) as RepTrendRiskCount, isnull(metric.RepTrendPercentAboveBench, 0) as RepTrendPercentAboveBench, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select EndDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI <> ''' + @CustomerID + ''' and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite = ''' + @SiteName + ''' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 2, ''' + convert(varchar, @EndDate, 101) + ''', media.NPI, media.FullName,  ' + @CR
set @sql = @sql + 'metric.RepTrendSite, isnull(metric.RepTrendRating, 0.0) as RepTrendRating, isnull(metric.RepTrendCount, 0) as RepTrendCount, ' + @CR
set @sql = @sql + 'isnull(metric.RepTrendRiskCount, 0) as RepTrendRiskCount, isnull(metric.RepTrendPercentAboveBench, 0) as RepTrendPercentAboveBench, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepTrend metric ' + @CR
set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where metric.RepTrendDate = (select EndDate from #dates) ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and metric.RepTrendSite <> ''' + @SiteName + ''' '
exec(@sql)

create table #comment_counts(NPI nvarchar(10), RatingSite nvarchar(50), CommentCount int)

--set @sql = 'insert #comment_counts ' + @CR
--set @sql = @sql + 'select media.NPI, metric.RepCommentSite, count(*) ' + @CR
--set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
--set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepComment metric ' + @CR
--set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
--set @sql = @sql + 'where metric.RepCommentTab = ''Weekly'' ' + @CR
--set @sql = @sql + 'and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
--set @sql = @sql + 'and datepart(month, cast(media.TrendDate as datetime)) = (select datepart(month, StartDateStart) from #comment_dates) ' + @CR
--set @sql = @sql + 'group by media.NPI, metric.RepCommentSite ' + @CR
--print @sql
--exec(@sql)

set @sql = 'insert #comment_counts ' + @CR
set @sql = @sql + 'select substring(NPITrend, 1, 10), RepCommentSite, count(*) ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.VIRepComment metric ' + @CR
set @sql = @sql + 'where RepCommentTab = ''Weekly'' ' + @CR
set @sql = @sql + 'and NPITrend not like ''S%'' and NPITrend not like ''G%'' and NPITrend not like ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and datepart(month, RepCommentDate) = (select datepart(month, StartDateStart) from #comment_dates) ' + @CR
set @sql = @sql + 'and datepart(year, RepCommentDate) = (select datepart(year, StartDateStart) from #comment_dates) ' + @CR
set @sql = @sql + 'group by substring(NPITrend, 1, 10), RepCommentSite ' + @CR
print @sql
exec(@sql)

update		s
set			s.CommentCount = c.CommentCount
from		#start_values s
inner join	#comment_counts c
on			c.NPI = s.NPI
and			c.RatingSite = s.RatingSite

truncate table #comment_counts

--set @sql = 'insert #comment_counts ' + @CR
--set @sql = @sql + 'select media.NPI, metric.RepCommentSite, count(*) ' + @CR
--set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
--set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepComment metric ' + @CR
--set @sql = @sql + 'on metric.NPITrend = media.NPITrend ' + @CR
--set @sql = @sql + 'where metric.RepCommentTab = ''Weekly'' ' + @CR
--set @sql = @sql + 'and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
--set @sql = @sql + 'and datepart(month, cast(media.TrendDate as datetime)) = (select datepart(month, EndDateStart) from #comment_dates) ' + @CR
--set @sql = @sql + 'group by media.NPI, metric.RepCommentSite ' + @CR

set @sql = 'insert #comment_counts ' + @CR
set @sql = @sql + 'select substring(NPITrend, 1, 10), RepCommentSite, count(*) ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.VIRepComment metric ' + @CR
set @sql = @sql + 'where RepCommentTab = ''Weekly'' ' + @CR
set @sql = @sql + 'and NPITrend not like ''S%'' and NPITrend not like ''G%'' and NPITrend not like ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and datepart(month, RepCommentDate) = (select datepart(month, EndDateStart) from #comment_dates) ' + @CR
set @sql = @sql + 'and datepart(year, RepCommentDate) = (select datepart(year, EndDateStart) from #comment_dates) ' + @CR
set @sql = @sql + 'group by substring(NPITrend, 1, 10), RepCommentSite ' + @CR
print @sql
exec(@sql)

update		s
set			s.CommentCount = c.CommentCount
from		#end_values s
inner join	#comment_counts c
on			c.NPI = s.NPI
and			c.RatingSite = s.RatingSite

select		distinct s.OrderNo, s.ValuesDate as StartDate, e.ValuesDate as EndDate, s.PhysicianName, s.RatingSite,
			isnull(s.Rating, 0.00) as StartingRating, isnull(s.Volume, 0) as StartingVolume, isnull(s.RiskCount, 0) as StartingRiskCount,
			isnull(s.PercentAboveBench, 0) as StartingPercentAboveBench, isnull(s.CommentCount, 0) as StartingCommentCount,
			isnull(e.Rating, 0.00) as EndingRating, isnull(e.Volume, 0) as EndingVolume, isnull(e.RiskCount, 0) as EndingRiskCount,
			isnull(e.PercentAboveBench, 0) as EndingPercentAboveBench, isnull(e.CommentCount, 0) as EndingCommentCount,
			isnull(e.Rating, 0) - isnull(s.Rating, 0) as RatingDiff, isnull(e.Volume, 0) - isnull(s.Volume, 0) as VolumeDiff,
			isnull(e.RiskCount, 0) - isnull(s.RiskCount, 0) as RiskCountDiff, isnull(e.PercentAboveBench, 0) - isnull(s.PercentAboveBench, 0) as PercentDiff
from		#start_values s
left join	#end_values e
on			e.NPI = s.NPI
and			e.RatingSite = s.RatingSite
and			e.OrderNo = s.OrderNo
order by	s.OrderNo, s.PhysicianName

drop table #param_dates
drop table #dates
drop table #comment_dates
drop table #comment_counts
drop table #start_values
drop table #end_values





