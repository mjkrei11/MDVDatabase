create procedure sp_ssrs_GetDBsByServer (@Server nvarchar(200))

as

/*
declare @Server nvarchar(200) = 'DEV'
exec sp_ssrs_GetDBsByServer @Server
*/

select @Server = String from ScriptBox.dbo.Servers where Label = @Server

declare
@sql nvarchar(max)

set @sql = 'select name as DbName from [' + @Server + '].master.dbo.sysdatabases order by name '
exec(@sql)