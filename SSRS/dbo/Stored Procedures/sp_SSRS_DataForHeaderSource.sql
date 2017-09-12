
CREATE procedure [dbo].[sp_SSRS_DataForHeaderSource] (
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

--exec sp_SSRS_DataForHeaderSource 'Development', '1164464921'
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

Set @sql = 'SELECT HeaderPage, HeaderName, HeaderLabel, HeaderIcon, HeaderActive ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.HeaderSource ' + @CR
	Set @sql = @sql + 'WHERE NPI = ''' + @NPI +''' ' + @CR
	--Print @sql
	exec(@sql)


