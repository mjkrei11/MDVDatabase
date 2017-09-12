

CREATE procedure [dbo].[sp_ssrs_CompetitorDetails] (@CustomerID nvarchar(max))

as

/*
declare
@CustomerID nvarchar(max)
set @CustomerID = null
--set @CustomerID = '1164464921'
--set @CustomerID = '1164464921,1407805948,1275653107'

exec sp_ssrs_CompetitorDetails @CustomerID
*/

declare
@RunDb nvarchar(200)
set @RunDb = 'MDVALUATE'

declare
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select distinct cmm.CustomerID, cmm.CustomerName, cmm.CollectionID, cmm.CollectionName, ' + @CR
set @sql = @sql + 'isnull(cmm.HoldingDb, ''MDVALUATE'') as HoldingDatabase, cm.CompetitorID as CompetitorCustomerID, ' + @CR
set @sql = @sql + 'cm.CompetitorName as CompetitorCustomerName, mpm.Status, mpm.NPI as CompetitorNPI, ' + @CR
set @sql = @sql + 'mpm.FirstName as CompetitorFirstName, mpm.LastName as CompetitorLastName, mps.SystemSpecialty as CompetitorSpecialty, ' + @CR
set @sql = @sql + 'mps.SystemGroup as CompetitorGroup, mps.SystemMarket as CompetitorMarket, mpa.OfficeURL ' + @CR
set @sql = @sql + 'from ' + @RunDb + '.dbo.CompetitionMappingMedia cmm ' + @CR
set @sql = @sql + 'inner join ' + @RunDb + '.dbo.CompetitionMapping cm ' + @CR
set @sql = @sql + 'on cm.CollectionID = cmm.CollectionID ' + @CR
set @sql = @sql + 'inner join ' + @RunDb + '.dbo.MasterPhysicianSystems mps ' + @CR
set @sql = @sql + 'on mps.SystemID = cmm.CustomerID ' + @CR
set @sql = @sql + 'inner join ' + @RunDb + '.dbo.MasterPhysicianMedia mpm ' + @CR
set @sql = @sql + 'on mpm.NPI = mps.NPI ' + @CR
set @sql = @sql + 'and mps.SystemSystemID = cm.CompetitorID ' + @CR
set @sql = @sql + 'inner join ' + @RunDb + '.dbo.MasterPhysAddress mpa ' + @CR
set @sql = @sql + 'on mpa.NPI = mpm.NPI ' + @CR
set @sql = @sql + 'where mpm.Status <> ''Inactive'' ' + @CR
set @sql = @sql + 'and mps.IsActive = 1 ' + @CR
set @sql = @sql + 'and mps.IsComp = 1 ' + @CR
set @sql = @sql + 'and cmm.IsActive = 1 ' + @CR
if @CustomerID is not null
begin
	set @sql = @sql + 'and cmm.CustomerID in (select Value from dbo.fn_SplitValues(''' + @CustomerID + ''', '','')) ' + @CR
end
set @sql = @sql + 'order by cmm.CustomerName, cm.CompetitorName, mpm.LastName, mpm.FirstName ' + @CR
exec(@sql)

