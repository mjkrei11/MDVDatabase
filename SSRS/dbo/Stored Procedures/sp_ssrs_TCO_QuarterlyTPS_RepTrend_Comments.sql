



















CREATE procedure [dbo].[sp_ssrs_TCO_QuarterlyTPS_RepTrend_Comments] (
	@Database nvarchar(200)--, @Quarter nvarchar(20)

)

as
/*This reporst was created for TCO. It excludes UCompare ratings.*/
/*
declare
@Database nvarchar(200)--,
--@Quarter nvarchar(20)


set @Database = 'TwinCities'
--set @Quarter = 'Q3, 2016'


exec sp_ssrs_TCO_QuarterlyTPS_RepTrend_Comments @Database--, @Quarter
*/

declare
@SystemID nvarchar(10),
@CustomerID nvarchar(50),
@CustomerSource nvarchar(120),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1),
@counter int

set @CR = char(13)

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

--declare
--@MonthNumber int

--set @sql = 'select top 1 @TempMonthNumber = max(datepart(m, RepTrendQtrDate)) ' + @CR
--set @sql = @sql + 'from ' + @Database + '.dbo.VIRepQuarter '
--set @sql = @sql + 'where RepTrendQtrPeriod = ''' + @Quarter + ''' and RepTrendQtrSite <> ''Summary'' and RepTrendQtrSite in (''HealthGrades'',''Vitals'',''RateMDs'') ' + @CR
--set @parms = '@TempMonthNumber int output'
--exec sp_executesql @sql, @parms, @TempMonthNumber = @MonthNumber output

create table #phys_sites (NPI nvarchar(10), NPITrend nvarchar(50), LastName nvarchar(50), FirstName nvarchar(50), MiddleName nvarchar(50), RepCommentSite nvarchar(20), RepCommentDateAndSite nvarchar(100), RepCommentIsNegative int, RepCommentText nvarchar(max), RepCommentDate datetime) 
set @sql = 'insert #phys_sites ' + @CR
set @sql = @sql + 'select c.NPI, b.NPITrend, c.LastName, c.FirstName, c.MiddleName, b.RepCommentSite, convert(varchar,b.RepCommentDate, 101) + '' '' + b.RepCommentSite, b.RepCommentIsNegative, b.RepCommentText, b.RepCommentDate ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.VIRepComment b ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysVRepTrendMedia c on c.NPITrend = b.NPITrend ' + @CR
--set @sql = @sql + 'where a.RepTrendQtrSite in (''HealthGrades'',''Vitals'',''RateMDs'') and a.RepTrendQtrPeriod = ''' + @Quarter + ''' ' + @CR
set @sql = @sql + 'where b.RepCommentSite in (''HealthGrades'',''Vitals'',''RateMDs'') ' + @CR
set @sql = @sql + 'and b.RepCommentDate >= ''2016-10-01 00:00:00.000'' ' + @CR
--set @sql = @sql + 'and datepart(m, a.RepTrendQtrDate) = ''' + cast(@MonthNumber as nvarchar(5)) + ''' ' + @CR
--set @sql = @sql + 'and datepart(m, b.RepCommentDate) = ''' + cast(@MonthNumber as nvarchar(5)) + ''' ' + @CR
set @sql = @sql + 'and b.NPITrend not like ''S%'' and b.NPITrend not like ''G%'' ' + @CR
set @sql = @sql + 'and c.LastName not like ''System'' ' + @CR
set @sql = @sql + 'group by c.NPI, b.NPITrend, b.RepCommentSite, b.RepCommentDate, b.RepCommentIsNegative, b.RepCommentText, c.LastName, c.FirstName, c.MiddleName ' + @CR
print @sql
exec(@sql)

select * from #phys_sites
order by LastName, RepCommentDate desc

drop table #phys_sites
--drop table #phys_avg_rating
--drop table #AWR












