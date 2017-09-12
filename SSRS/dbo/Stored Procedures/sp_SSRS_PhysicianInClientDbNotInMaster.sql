



CREATE procedure [dbo].[sp_SSRS_PhysicianInClientDbNotInMaster] (
	@ClientDB nvarchar(200),
	@MasterDB nvarchar(200)
)

AS

/* Test Parameters */
/*
declare
@ClientDB nvarchar(200),
@MasterDB nvarchar(200)

set @ClientDB = 'Rothman'
set @MasterDB = 'MDVALUATE'
*/

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

/******** WHO IS IN CLIENT DB THAT IS NOT IN MASTER LIST ********/

set @sql = 'SELECT pm.NPI, pm.FirstName, pm.MiddleName, pm.LastName, pm.Status, pci.CustomerSource, pci.CustomerID ' + @CR
set @sql = @sql + 'FROM ' + @ClientDB + '.dbo.PhysicianMedia pm ' + @CR
set @sql = @sql + 'INNER JOIN ' + @ClientDB + '.dbo.PhysCustomerID pci ON pm.NPI = pci.NPI ' + @CR
set @sql = @sql + 'WHERE pm.NPI NOT IN (SELECT NPI FROM ' + @MasterDB + '.dbo.MasterPhysicianMedia WHERE PrimaryCustomerID = ''' + @CustomerID + ''') '
--print @sql
exec(@sql)


