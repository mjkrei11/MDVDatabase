


CREATE procedure [dbo].[sp_SSRS_TrendYearQuarter] (
	@Database nvarchar(200)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'stt'

exec sp_SSRS_TrendYearQuarter @Database
*/

declare
@sql nvarchar(max),
--@sql2 nvarchar(max),
@CR char(1)

set @CR = char(13)

Set @sql = 'select distinct RepTrendQtrPeriod ' + @CR
Set @sql = @sql + 'from ' + @Database + '.dbo.VIRepQuarter ' + @CR
Set @sql = @sql + 'order by RepTrendQtrPeriod ' + @CR
exec (@sql)

--print @sql





