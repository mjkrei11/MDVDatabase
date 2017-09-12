CREATE procedure sp_ssrs_ParmTest(@Database nvarchar(200), @Parm nvarchar(4000))

as

/*
declare
@Database nvarchar(200),
@Parm nvarchar(4000)

set @Database = 'NTKDA'
set @Parm = 'a,b,h'

exec sp_ssrs_ParmTest @Database, @Parm
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select * ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia ' + @CR
set @sql = @sql + 'where MiddleName in (select Value from dbo.fn_SplitValues(''' + @Parm + ''', '','')) ' + @CR
exec(@sql)