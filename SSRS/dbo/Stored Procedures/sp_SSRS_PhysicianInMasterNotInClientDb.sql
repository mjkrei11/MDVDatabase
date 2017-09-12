


CREATE procedure [dbo].[sp_SSRS_PhysicianInMasterNotInClientDb] (
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

--exec sp_SSRS_PhysicianInMasterNotInClientDb 'Panorama', 'MDVALUATE'

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

/******** WHO IS IN MASTER LIST THAT IS NOT IN CLIENT DB ********/
set @sql = 'SELECT mpm.NPI, mpm.FirstName, mpm.MiddleName, mpm.LastName, mpm.Status, mpm.PrimaryCustomerSource, mpm.PrimaryCustomerID ' + @CR
set @sql = @sql + 'FROM ' + @MasterDB + '.dbo.MasterPhysicianMedia mpm ' + @CR
set @sql = @sql + 'WHERE mpm.NPI not in (select pm.NPI from ' + @ClientDB + '.dbo.PhysicianMedia pm ' + @CR
set @sql = @sql + 'INNER JOIN ' + @ClientDB + '.dbo.PhysCustomerID pci on pci.NPI = pm.NPI and pci.CustomerID = ''' + @CustomerID + ''') ' + @CR
set @sql = @sql + 'AND PrimaryCustomerID = ''' + @CustomerID + ''' '
exec(@sql)
--print (@sql)
