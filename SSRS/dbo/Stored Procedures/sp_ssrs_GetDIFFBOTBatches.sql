CREATE procedure sp_ssrs_GetDIFFBOTBatches(@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'Rothman'

exec sp_ssrs_GetDIFFBOTBatches @Database
*/

declare
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select distinct BatchID, cast(BatchID as nvarchar(5)) + '' - '' + convert(varchar, SearchDate, 101) as BatchDate ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'order by BatchID desc ' + @CR
exec(@sql)