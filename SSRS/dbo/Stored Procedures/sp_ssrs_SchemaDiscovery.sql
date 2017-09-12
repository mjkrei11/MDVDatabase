

CREATE procedure [dbo].[sp_ssrs_SchemaDiscovery](@Server nvarchar(200))

as

--exec sp_ssrs_SchemaDiscovery 'DEV'

declare
@ServerName nvarchar(10),
--@Server nvarchar(200),
@Database nvarchar(200),
@sql nvarchar(max),
@CR char(1),
@counter int

create table #servers(
	id int identity,
	ServerString nvarchar(200)
)
create table #dbs(
	id int identity,
	ServerString nvarchar(200),
	DatabaseName nvarchar(200)
)
create table #schema(
	id int identity,
	ServerName nvarchar(200),
	DatabaseName nvarchar(200),
	TableName nvarchar(200),
	ColumnName nvarchar(200),
	DataType nvarchar(50),
	MaxSize nvarchar(20)
)

insert		#servers(ServerString)
select		String
from		ScriptBox.dbo.Servers
where		Label = @Server

set @CR = char(13)
set @counter = 1

while @counter <= (select max(id) from #servers)
begin
	select @Server = ServerString from #servers where id = @counter
	set @sql = 'insert #dbs(ServerString, DatabaseName) ' + @CR
	set @sql = @sql + 'select ''' + @Server + ''', name ' + @CR
	set @sql = @sql + 'from [' + @Server + '].master.dbo.sysdatabases ' + @CR
	set @sql = @sql + 'where name not in (''master'',''model'',''msdb'',''tempdb'') ' + @CR -- exclude these databases
	set @sql = @sql + 'and name not like ''ReportServer%'''
	exec(@sql)

	set @counter = @counter + 1
end

set @counter = 1

while @counter <= (select max(id) from #dbs)
begin
	select @Server = ServerString, @Database = DatabaseName from #dbs where id = @counter

	set @sql = 'insert #schema (ServerName, DatabaseName, TableName, ColumnName, DataType, MaxSize) ' + @CR
	set @sql = @sql + 'select ''' + @Server + ''',''' + @Database + ''', c.TABLE_NAME, c.COLUMN_NAME, ' + @CR
	set @sql = @sql + 'c.DATA_TYPE, case when c.CHARACTER_MAXIMUM_LENGTH = -1 THEN ''max'' else cast(c.CHARACTER_MAXIMUM_LENGTH as nvarchar(20)) end ' + @CR
	set @sql = @sql + 'from [' + @Server + '].[' + @Database + '].[information_schema].[columns] c ' + @CR
	set @sql = @sql + 'order by c.TABLE_NAME, c.ORDINAL_POSITION'
	exec(@sql)

	set @counter = @counter + 1
end

select		*
from		#schema
order by	id

drop table #servers
drop table #dbs
drop table #schema

