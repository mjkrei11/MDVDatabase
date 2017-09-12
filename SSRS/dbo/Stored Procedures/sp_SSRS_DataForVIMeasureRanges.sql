


CREATE procedure [dbo].[sp_SSRS_DataForVIMeasureRanges] (
	@Database nvarchar(200),
	@NPI nvarchar(10)
)

AS

/* Test parameter */
/*
declare
@Database nvarchar(200),
@NPI nvarchar(20)

Set @Database = 'Development'
set @NPI = '1164464921'

--exec sp_SSRS_DataForVIMeasureRanges 'MDVALUATE', '1164464921'
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

Set @sql = 'SELECT VIMeasure, Category, VIPriority, UserPriority, HighGreen, LowGreen, HighYellow, ' + @CR
	Set @sql = @sql + 'LowYellow, HighRed, LowRed, VIMeasureWeight, SourceColumn, Benchmark, BenchmarkDesc, SourceTable, ' + @CR
	Set @sql = @sql + 'SourceField, WhereClause, WhereClause2, WhereClause3, HasDataClause ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.VIMeasureRanges ' + @CR
	Set @sql = @sql + 'WHERE NPI = ''' + @NPI +''' ' + @CR
	Set @sql = @sql + 'ORDER By VIPriority '
	--Print @sql
	exec(@sql)




