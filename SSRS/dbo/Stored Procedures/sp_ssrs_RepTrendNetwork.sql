
CREATE procedure [dbo].[sp_ssrs_RepTrendNetwork](
	@Database nvarchar(200),
	@SiteName nvarchar(50),
	@TrendDate nvarchar(10)
)

as

/*
declare
@Database nvarchar(200) = 'NANI',
@SiteName nvarchar(50) = 'HealthGrades',
@TrendDate nvarchar(10) = '2016-05-18'

exec sp_ssrs_RepTrendNetwork @Database, @SiteName, @TrendDate
*/

declare
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

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

set @sql = 'select 0 as OrderNo, convert(varchar, cast(StartDate as datetime) - 1, 101) as StartDate, EndDate, media.LastName + '', '' + media.FirstName as PhysicianName, summary.* ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepSummary summary ' + @CR
set @sql = @sql + 'on summary.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where media.TrendDate = ''' + @TrendDate + ''' ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and summary.SummarySite = ''' + @SiteName + ''' ' + @CR
set @sql = @sql + 'and summary.SummaryTab = ''Weekly'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 1, convert(varchar, cast(StartDate as datetime) - 1, 101) as StartDate, EndDate, media.LastName + '', '' + media.FirstName, summary.* ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepSummary summary ' + @CR
set @sql = @sql + 'on summary.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where media.TrendDate = ''' + @TrendDate + ''' ' + @CR
set @sql = @sql + 'and media.NPI <> ''' + @CustomerID + ''' and media.NPI not like ''S%'' and media.NPI not like ''G%'' ' + @CR
set @sql = @sql + 'and summary.SummarySite = ''' + @SiteName + ''' ' + @CR
set @sql = @sql + 'and summary.SummaryTab = ''Weekly'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select 2, convert(varchar, cast(StartDate as datetime) - 1, 101) as StartDate, EndDate, media.LastName + '', '' + media.FirstName, summary.* ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysVRepTrendMedia media ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.VIRepSummary summary ' + @CR
set @sql = @sql + 'on summary.NPITrend = media.NPITrend ' + @CR
set @sql = @sql + 'where media.TrendDate = ''' + @TrendDate + ''' ' + @CR
set @sql = @sql + 'and media.NPI = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and summary.SummarySite <> ''' + @SiteName + ''' ' + @CR
set @sql = @sql + 'and summary.SummaryTab = ''Weekly'' ' + @CR
set @sql = @sql + 'order by OrderNo, PhysicianName'
print @sql
exec(@sql)
