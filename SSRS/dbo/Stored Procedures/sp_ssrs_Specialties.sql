
CREATE procedure [dbo].[sp_ssrs_Specialties](@Database nvarchar(200))

as

/*
declare @Database nvarchar(200)
set @Database = 'MORUSH'

exec sp_ssrs_Specialties @Database
*/

declare
@CustomerSource nvarchar(400),
@CustomerID nvarchar(20),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)


create table #Specialties(ID int identity, Specialty nvarchar(400))

if @Database is not null
begin
	set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID from ' + @Database + '.dbo.PhysCustomerID'
	set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
	exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

	set @sql = 'insert #Specialties(Specialty) ' + @CR
	set @sql = 'select null as Specialty union ' + @CR
	set @sql = @sql + 'select distinct isnull(PrimaryCustomerSpecialty, PrimarySpecialty) ' + @CR
	set @sql = @sql + 'from MDVALUATE.dbo.MasterPhysicianMedia ' + @CR
	set @sql = @sql + 'where CustomerName = ''' + @CustomerSource + ''' ' + @CR
	--set @sql = @sql + 'or (TreeLevelI = ''Competition'' ' + @CR
	--set @sql = @sql + 'and TreeLevelII = ''' + @CustomerSource + ''') ' + @CR
	exec(@sql)

	select distinct Specialty from #Specialties order by Specialty

end
else
begin
	select null as Specialty
end
/*
set @sql = 'insert #Specialties(Specialty) ' + @CR
set @sql = @sql + 'select distinct Referred_Taxonomy_Desc ' + @CR
set @sql = @sql + 'from CMS_Referrals.dbo.vw_CMSReferralData ' + @CR
exec(@sql)
*/

drop table #Specialties
