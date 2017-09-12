


CREATE procedure [dbo].[sp_SSRS_PhysicianWithDifferentStatuses] (
	@ClientDB nvarchar(200),
	@MasterDB nvarchar(200)
)

AS

/* Test Parameters */
/*
declare
@ClientDB nvarchar(200),
@MasterDB nvarchar(200)

set @ClientDB = 'Panorama'
set @MasterDB = 'MDVALUATE'
*/

--exec sp_SSRS_PhysicianWithDifferentStatuses 'Panorama', 'MDVALUATE'

declare

@CustomerID nvarchar(200),
@CustomerSource nvarchar(200),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'SELECT Top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID FROM ' + @ClientDB + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

/******** WHO IS IN BOTH DATABASES BUT HAS DIFFERENT STATUSES ********/
set @sql = 'SELECT p.NPI, p.FirstName, p.MiddleName, p.LastName, p.Status as ClientStatus, m.Status AS MasterListStatus, pci.CustomerSource, pci.CustomerID ' + @CR
set @sql = @sql + 'FROM ' + @MasterDB + '.dbo.MasterPhysicianMedia m ' + @CR
set @sql = @sql + 'INNER JOIN ' + @ClientDB + '.dbo.PhysicianMedia p ON p.NPI = m.NPI ' + @CR
set @sql = @sql + 'INNER JOIN ' + @ClientDB + '.dbo.PhysCustomerID pci ON m.NPI = pci.NPI' + @CR
set @sql = @sql + 'WHERE m.Status <> p.Status ' + @CR
set @sql = @sql + 'AND m.PrimaryCustomerID = ''' + @CustomerID + ''' '
exec(@sql)
