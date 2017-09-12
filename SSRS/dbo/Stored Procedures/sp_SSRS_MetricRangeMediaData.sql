

CREATE procedure [dbo].[sp_SSRS_MetricRangeMediaData] (
	@Database nvarchar(200),
	@NPI nvarchar(10)
)

AS

/* Test parameter */
/*
declare
@Database nvarchar(200),
@NPI nvarchar(20)

Set @Database = 'Development'
set @NPI = '1164464921'

--exec sp_SSRS_MetricRangeMediaData 'Development', '1164464921'
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

Set @sql = 'SELECT mrm.NPI, mrm.FacilityID, mrm.FacilityName, mrm.Specialty, mrm.Revision, mrm.SystemID, mrm.SystemName, mrm.OfficeSource, mrm.LastRev, mrm.SourceSystemID, ' + @CR
	Set @sql = @sql + 'cast(mrms.BinData as varbinary(max)) as ProfilePic ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.MetricRangeMedia mrm ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.MetricRangeMediaSection mrms ON mrms.NPI = mrm.NPI ' + @CR
	Set @sql = @sql + 'WHERE mrm.NPI = ' + @NPI +'' + @CR
	--Print @sql
	exec(@sql)



