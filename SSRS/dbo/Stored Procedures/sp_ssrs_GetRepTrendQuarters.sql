create procedure sp_ssrs_GetRepTrendQuarters(@Database nvarchar(200))

as

/*
declare @Database nvarchar(200) = 'TWINCITIES'
exec sp_ssrs_GetRepTrendQuarters @Database
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select distinct RepTrendQtrPeriod, cast(substring(RepTrendQtrPeriod, 2, 1) as int) as Qtr, cast(substring(RepTrendQtrPeriod, 5, 4) as int) as Yr ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.VIRepQuarter ' + @CR
set @sql = @sql + 'order by Yr desc, Qtr desc ' + @CR
exec(@sql)