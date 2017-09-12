create procedure sp_SSRS_PhysicianRatingUpdateTable(@Database nvarchar(200))

as

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'SELECT * ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianRatingUpdate ' + @CR
exec(@sql)