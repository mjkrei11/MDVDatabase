








CREATE procedure [dbo].[sp_SSRS_CompetitionValidationData_SystemInfo] (
	@Database nvarchar(200),
	@SystemID nvarchar(10)
)

AS

/* Test parameter */
/*
declare
@Database nvarchar(200),
@SystemID nvarchar(10)

Set @Database = 'CompetitionDemo'
set @SystemID = '1598700478'
*/
----exec sp_SSRS_CompetitionValidationData_SystemInfo 'CompetitionDemo', '1598700478'

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

	Set @sql = 'SELECT pvp.NPI, pvp.Popup2MeasureName, pvp.Popup2Row, pvp.Popup2Value, pvp.Popup2Quarter, pvi.FirstName, pvi.LastName, pvi.SystemID ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysVPopups2 pvp ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysVIndex pvi ON pvi.NPI = pvp.NPI ' + @CR
	Set @sql = @sql + 'WHERE pvp.NPI = ' + @SystemID + ' ' + @CR
	Set @sql = @sql + 'AND pvp.Popup2MeasureName = ''Physician Reputation'' ' + @CR
	Set @sql = @sql + 'AND pvp.Popup2Row IN (''4'',''5'',''6'') ' + @CR
	Set @sql = @sql + 'Order by pvp.Popup2Row, pvp.Popup2Col '
	--Print @sql
	exec(@sql)











