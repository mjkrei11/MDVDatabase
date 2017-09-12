

CREATE procedure [dbo].[sp_SSRS_SystemIDMetricRangeMediaData] (
@Database nvarchar(200)
)

AS

/* Test parameter */
/*
declare
@Database nvarchar(200)

Set @Database = 'MDValuate'

--exec sp_SSRS_SystemIDMetricRangeMediaData 'MDValuate'
*/
declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

Set @sql = 'SELECT SystemName + '' - '' + SystemID AS SystemName , SystemID ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.MetricRangeMedia ' + @CR
	Set @sql = @sql + 'ORDER BY SystemName'
	--Print @sql
	exec(@sql)



