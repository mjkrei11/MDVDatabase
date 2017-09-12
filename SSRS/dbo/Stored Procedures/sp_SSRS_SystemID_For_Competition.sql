

CREATE procedure [dbo].[sp_SSRS_SystemID_For_Competition] (
	@Database nvarchar(200)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'Panorama'

--exec sp_SSRS_SystemID_For_Competition 'CompetitionDemo'
*/
declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

Set @sql = 'SELECT SystemID, SystemName ' + @CR
Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysVIndex ' + @CR
Set @sql = @sql + 'Group By SystemID, SystemName ' + @CR
Set @sql = @sql + 'Order By SystemName '
--Print @sql
exec(@sql)





