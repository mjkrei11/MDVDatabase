

CREATE procedure [dbo].[sp_ssrs_SchemaDiscoveryColumns](
	@Server nvarchar(200),
	@Database nvarchar(200),
	@ColumnName nvarchar(200)
)

as

/* Test variables */
/*
declare
@Server nvarchar(200),
@Database nvarchar(200),
@ColumnName nvarchar(200)

select @Server = String from Servers where Label = 'DEV'
set @Database = 'Panorama'
set @ColumnName = 'NPI'
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #tables (id int identity, TableName nvarchar(200))

set @sql = 'insert #tables (TableName) ' + @CR
set @sql = @sql + 'select c.TABLE_NAME ' + @CR
set @sql = @sql + 'from [' + @Server + '].[' + @Database + '].[information_schema].[columns] c ' + @CR
set @sql = @sql + 'where c.COLUMN_NAME = ''' + @ColumnName + ''' ' + @CR
set @sql = @sql + 'order by c.TABLE_NAME'
exec(@sql)

select * from #tables

drop table #tables
