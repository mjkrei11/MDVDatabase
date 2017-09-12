



CREATE procedure [dbo].[sp_ssrs_ReferralData_2014_60Day](
	@Database nvarchar(200),
	@CompetitionOption int,
	@NPIList nvarchar(max),
	@SpecialtyWhere nvarchar(1000),
	@CityWhere nvarchar(200),
	@StateWhere nvarchar(200),
	@ReferralCountWhere nvarchar(200),
	@UniqueBeneficiariesWhere nvarchar(200),
	@SameDayReferralsWhere nvarchar(200),
	@ReferringNPIList nvarchar(max)
)

as

/*
declare
@Database nvarchar(200),
@CompetitionOption int,
@NPIList nvarchar(max),
@SpecialtyWhere nvarchar(1000),
@CityWhere nvarchar(200),
@StateWhere nvarchar(200),
@ReferralCountWhere nvarchar(200),
@UniqueBeneficiariesWhere nvarchar(200),
@SameDayReferralsWhere nvarchar(200),
@ReferringNPIList nvarchar(max)

set @Database = 'Panorama'
--set @Database = null
set @CompetitionOption = 0
--set @NPIList = '1013996701,1043299795,1245219963,1255310157'
set @NPIList = null
set @SpecialtyWhere = null
set @CityWhere = null
set @StateWhere = null
set @ReferralCountWhere = null
set @UniqueBeneficiariesWhere = null
set @SameDayReferralsWhere = null
set @ReferringNPIList = null
--set @ReferringNPIList = '1013996701,1043299795,1245219963,1255310157'

exec sp_ssrs_ReferralData_2014_60Day @Database, @CompetitionOption, @NPIList, @SpecialtyWhere, @CityWhere, @StateWhere, @ReferralCountWhere, @UniqueBeneficiariesWhere, @SameDayReferralsWhere, @ReferringNPIList
*/

set @NPIList = isnull(@NPIList, '')
if @NPIList <> ''
begin
	set @NPIList = replace(@NPIList, ',', ''',''')
	set @NPIList = 'and v.Referred_NPI in (''' + replace(@NPIList, '', '''') + ''') '
end
set @ReferringNPIList = isnull(@ReferringNPIList, '')
if @ReferringNPIList <> ''
begin
	set @ReferringNPIList = replace(@ReferringNPIList, ',', ''',''')
	set @ReferringNPIList = 'and v.Referring_NPI in (''' + replace(@ReferringNPIList, '', '''') + ''') '
end
set @SpecialtyWhere = isnull(@SpecialtyWhere, '')
if @SpecialtyWhere <> ''
begin
	set @SpecialtyWhere = replace(@SpecialtyWhere, ',', ''',''')
	if @Database is not null
	begin
		set @SpecialtyWhere = 'and isnull(n.Specialty, v.Referred_Taxonomy_Desc) in (''' +  replace(@SpecialtyWhere, '', '''') + ''') '
	end
	else
	begin
		set @SpecialtyWhere = 'and v.Referred_Taxonomy_Desc) in (''' +  replace(@SpecialtyWhere, '', '''') + ''') '
	end
end
set @CityWhere = isnull(@CityWhere, '')
if @CityWhere <> ''
begin
	set @CityWhere = replace(@CityWhere, ',', ''',''')
	set @CityWhere = 'and v.Referred_City in (''' + replace(@CityWhere, '', '''') + ''') '
end
set @StateWhere = isnull(@StateWhere, '')
if @StateWhere <> ''
begin
	set @StateWhere = replace(@StateWhere, ',', ''',''')
	set @StateWhere = 'and v.Referred_State in (''' + replace(@StateWhere, '', '''') + ''') '
end
set @ReferralCountWhere = isnull(@ReferralCountWhere, '')
if @ReferralCountWhere <> ''
begin
	set @ReferralCountWhere = 'and v.Referral_Count >= ''' + cast(cast(@ReferralCountWhere as int) as nvarchar(20)) + ''''
end
set @UniqueBeneficiariesWhere = isnull(@UniqueBeneficiariesWhere, '')
if @UniqueBeneficiariesWhere <> ''
begin
	set @UniqueBeneficiariesWhere = 'and v.Unique_Beneficiaries >= ''' + cast(cast(@UniqueBeneficiariesWhere as int) as nvarchar(20)) + ''''
end
set @SameDayReferralsWhere = isnull(@SameDayReferralsWhere, '')
if @SameDayReferralsWhere <> ''
begin
	set @SameDayReferralsWhere = 'and v.Same_Day_Referrals >= ''' + cast(cast(@SameDayReferralsWhere as int) as nvarchar(20)) + ''''
end

declare
@CustomerSource nvarchar(200),
@CustomerID nvarchar(20),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

if @Database is not null
begin
	set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID from ' + @Database + '.dbo.PhysCustomerID'
	set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
	exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

	create table #NPI(ID int identity, NPI nvarchar(10), Specialty nvarchar(400), Customer nvarchar(400))
	create table #Address(ID int identity, NPI nvarchar(10), PrimaryAddress nvarchar(200), PrimaryAddress2 nvarchar(200), PrimaryCity nvarchar(200), PrimaryState nvarchar(50), PrimaryZipcode nvarchar(20))

	if @CompetitionOption = 0
	begin
		set @sql = 'insert #NPI(NPI, Specialty, Customer) ' + @CR
		set @sql = @sql + 'select distinct NPI, isnull(PrimaryCustomerSpecialty, PrimarySpecialty), CustomerName ' + @CR
		set @sql = @sql + 'from MDVALUATE.dbo.MasterPhysicianMedia ' + @CR
		set @sql = @sql + 'where Status = ''Active'' ' + @CR
		set @sql = @sql + 'and PrimaryCustomerID = ''' + @CustomerID + ''''
		exec(@sql)

		--set @sql = 'insert #Address(NPI, PrimaryAddress, PrimaryAddress2, PrimaryCity, PrimaryState, PrimaryZipcode) ' + @CR
		--set @sql = @sql + 'select distinct NPI, PrimaryAddress, PrimaryAddress2, PrimaryCity, PrimaryState, PrimaryZipcode ' + @CR
		--set @sql = @sql + 'from MDVALUATE.dbo.MasterPhysicianMedia ' + @CR
		--set @sql = @sql + 'where Status = ''Active'' ' + @CR
		--set @sql = @sql + 'and PrimaryCustomerID = ''' + @CustomerID + ''''
		--exec(@sql)
	end
	if @CompetitionOption = 1
	begin
		set @sql = 'insert #NPI(NPI, Specialty, Customer) ' + @CR
		set @sql = @sql + 'select distinct NPI, isnull(PrimaryCustomerSpecialty, PrimarySpecialty), CustomerName ' + @CR
		set @sql = @sql + 'from MDVALUATE.dbo.MasterPhysicianMedia ' + @CR
		set @sql = @sql + 'where Status = ''Active'' ' + @CR
		set @sql = @sql + 'and PrimaryCustomerID = ''' + @CustomerID + ''''
		exec(@sql)
		
		set @sql = 'insert #NPI(NPI, Specialty, Customer) ' + @CR
		set @sql = @sql + 'select mps.NPI, mps.SystemSpecialty, mps.SystemSystem ' + @CR
		set @sql = @sql + 'from MDVALUATE.dbo.CompetitionMappingMedia cmm ' + @CR
		set @sql = @sql + 'inner join MDVALUATE.dbo.CompetitionMapping cm ' + @CR
		set @sql = @sql + 'on cm.CollectionID = cmm.CollectionID ' + @CR
		set @sql = @sql + 'inner join MDVALUATE.dbo.MasterPhysicianSystems mps ' + @CR
		set @sql = @sql + 'on mps.SystemID = cmm.CustomerID ' + @CR
		set @sql = @sql + 'inner join MDVALUATE.dbo.MasterPhysicianMedia mpm ' + @CR
		set @sql = @sql + 'on mpm.NPI = mps.NPI ' + @CR
		set @sql = @sql + 'and	mpm.PrimaryCustomerID = cm.CompetitorID ' + @CR
		set @sql = @sql + 'where mpm.Status = ''Active'' ' + @CR
		set @sql = @sql + 'and mps.IsActive = 1 ' + @CR
		set @sql = @sql + 'and mps.IsComp = 1 ' + @CR
		set @sql = @sql + 'and cmm.IsActive = 1 ' + @CR
		set @sql = @sql + 'and mps.SystemID = ''' + @CustomerID + ''' ' + @CR
		exec(@sql)

		--set @sql = 'insert #Address(NPI, PrimaryAddress, PrimaryAddress2, PrimaryCity, PrimaryState, PrimaryZipcode) ' + @CR
		--set @sql = @sql + 'select distinct NPI, PrimaryAddress, PrimaryAddress2, PrimaryCity, PrimaryState, PrimaryZipcode ' + @CR
		--set @sql = @sql + 'from MDVALUATE.dbo.MasterPhysicianMedia ' + @CR
		--set @sql = @sql + 'where Status = ''Active'' ' + @CR
		--set @sql = @sql + 'and PrimaryCustomerID = ''' + @CustomerID + ''''
		--exec(@sql)

		--set @sql = 'insert #Address(NPI, PrimaryAddress, PrimaryAddress2, PrimaryCity, PrimaryState, PrimaryZipcode) ' + @CR
		--set @sql = @sql + 'select distinct NPI, PrimaryAddress, PrimaryAddress2, PrimaryCity, PrimaryState, PrimaryZipcode ' + @CR
		--set @sql = @sql + 'from MDVALUATE.dbo.MasterPhysicianMedia ' + @CR
		--set @sql = @sql + 'where Status = ''Active'' ' + @CR
		--set @sql = @sql + 'and TreeLevelII = ''' + @CustomerSource + ''' ' + @CR
		--set @sql = @sql + 'and TreeLevelI = ''Competition'''
		--exec(@sql)
	end

	set @sql = 'select v.*, ' + @CR
	set @sql = @sql + 'substring(v.Referring_ZipCode, 1, 5) as SubString_Referring_ZipCode, substring(v.Referred_ZipCode, 1, 5) as SubString_Referred_ZipCode, ' + @CR
	set @sql = @sql + 'isnull(n.Specialty, v.Referred_Taxonomy_Desc) as PrimaryCustomerSpecialty, n.Customer as CustomerName, ' + @CR
	set @sql = @sql + 'v.Referring_Last_Name + '', '' + v.Referring_First_Name as Referring_Physician, ' + @CR
	set @sql = @sql + 'v.Referred_Last_Name + '', '' + v.Referred_First_Name as Referred_Physician, ' + @CR
	set @sql = @sql + 'replace(v.Referring_Address1 + '' '' + isnull(v.Referring_Address2, '''') + '' '' + v.Referring_City + '' '' + ' + @CR
	set @sql = @sql + 'v.Referring_State + '' '' + substring(v.Referring_ZipCode, 1, 5), ''  '', '' '') as Referring_Full_Address, ' + @CR
	set @sql = @sql + 'replace(v.Referring_Taxonomy_Desc, ''Allopathic & Osteopathic Physicians/'', '''') as Referring_Specialty, ' + @CR
	set @sql = @sql + 'replace(v.Referred_Address1 + '' '' + isnull(v.Referred_Address2, '''') + '' '' + v.Referred_City + '' '' + ' + @CR
	set @sql = @sql + 'v.Referred_State + '' '' + substring(v.Referred_ZipCode, 1, 5), ''  '', '' '') as Referred_Full_Address ' + @CR
	set @sql = @sql + 'from [192.168.30.27].[CMS_Referrals].dbo.vw_CMSReferralData_2014_60Day v ' + @CR
	set @sql = @sql + 'inner join #NPI n ' + @CR
	set @sql = @sql + 'on n.NPI = v.Referred_NPI ' + @CR
	set @sql = @sql + 'where 1 = 1 ' + @CR
	set @sql = @sql + ' ' + @NPIList + ' ' + @CR
	set @sql = @sql + ' ' + @ReferringNPIList + ' ' + @CR
	set @sql = @sql + ' ' + @SpecialtyWhere + ' ' + @CR
	set @sql = @sql + ' ' + @CityWhere + ' ' + @CR
	set @sql = @sql + ' ' + @StateWhere + ' ' + @CR
	set @sql = @sql + ' ' + @ReferralCountWhere + ' ' + @CR
	set @sql = @sql + ' ' + @UniqueBeneficiariesWhere + ' ' + @CR
	set @sql = @sql + ' ' + @SameDayReferralsWhere + ' ' + @CR
	exec(@sql)

	drop table #NPI
	drop table #Address
end
else
begin
	set @sql = 'select v.*, ' + @CR
	set @sql = @sql + 'substring(v.Referring_ZipCode, 1, 5) as SubString_Referring_ZipCode, substring(v.Referred_ZipCode, 1, 5) as SubString_Referred_ZipCode, ' + @CR
	set @sql = @sql + 'v.Referred_Taxonomy_Desc as PrimaryCustomerSpecialty, null as CustomerName, ' + @CR
	set @sql = @sql + 'v.Referring_Last_Name + '', '' + v.Referring_First_Name as Referring_Physician, ' + @CR
	set @sql = @sql + 'v.Referred_Last_Name + '', '' + v.Referred_First_Name as Referred_Physician, ' + @CR
	set @sql = @sql + 'replace(v.Referring_Address1 + '' '' + isnull(v.Referring_Address2, '''') + '' '' + v.Referring_City + '' '' + ' + @CR
	set @sql = @sql + 'v.Referring_State + '' '' + substring(v.Referring_ZipCode, 1, 5), ''  '', '' '') as Referring_Full_Address, ' + @CR
	set @sql = @sql + 'replace(v.Referring_Taxonomy_Desc, ''Allopathic & Osteopathic Physicians/'', '''') as Referring_Specialty, ' + @CR
	set @sql = @sql + 'replace(v.Referred_Address1 + '' '' + isnull(v.Referred_Address2, '''') + '' '' + v.Referred_City + '' '' + ' + @CR
	set @sql = @sql + 'v.Referred_State + '' '' + substring(v.Referred_ZipCode, 1, 5), ''  '', '' '') as Referred_Full_Address ' + @CR
	set @sql = @sql + 'from [192.168.30.27].[CMS_Referrals].dbo.vw_CMSReferralData_2014_60Day v ' + @CR
	set @sql = @sql + 'where 1 = 1 ' + @CR
	set @sql = @sql + ' ' + @NPIList + ' ' + @CR
	set @sql = @sql + ' ' + @ReferringNPIList + ' ' + @CR
	set @sql = @sql + ' ' + @SpecialtyWhere + ' ' + @CR
	set @sql = @sql + ' ' + @CityWhere + ' ' + @CR
	set @sql = @sql + ' ' + @StateWhere + ' ' + @CR
	set @sql = @sql + ' ' + @ReferralCountWhere + ' ' + @CR
	set @sql = @sql + ' ' + @UniqueBeneficiariesWhere + ' ' + @CR
	set @sql = @sql + ' ' + @SameDayReferralsWhere + ' ' + @CR
	exec(@sql)
end



