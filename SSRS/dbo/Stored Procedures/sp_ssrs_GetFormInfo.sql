create procedure sp_ssrs_GetFormInfo(@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'Rothman'

exec sp_ssrs_GetFormInfo @Database
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

set @sql = 'select distinct FormName as Browser, FormID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.FormInfo ' + @CR
set @sql = @sql + 'order by Browser ' + @CR
exec(@sql)