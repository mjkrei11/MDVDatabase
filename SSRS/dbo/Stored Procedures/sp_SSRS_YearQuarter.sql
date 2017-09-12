

CREATE procedure [dbo].[sp_SSRS_YearQuarter] (
	@Database nvarchar(200)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'Panorama'
*/

declare
@sql nvarchar(max),
--@sql2 nvarchar(max),
@CR char(1)

set @CR = char(13)

Set @sql = 'SELECT distinct YearQuarter ' + @CR
Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CR
Set @sql = @sql + 'ORDER BY YearQuarter ' + @CR
exec (@sql)

--Print @sql




