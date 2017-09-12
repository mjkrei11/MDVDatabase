



CREATE procedure [dbo].[sp_SSRS_NPI_For_Charts] (
	@Database nvarchar(200)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'Panorama'

--exec sp_SSRS_NPI_for_Charts 'Panorama'
*/
declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

Set @sql = 'SELECT NPI, LastName + '', '' + substring(FirstName, 1, 1) + ''.'' as NAME ' + @CR
Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianMedia ' + @CR
Set @sql = @sql + 'WHERE Status = ''Active'' ' + @CR
Set @sql = @sql + 'Order By LastName, FirstName '
--Print @sql
exec(@sql)





