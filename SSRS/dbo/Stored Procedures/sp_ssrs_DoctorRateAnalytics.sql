




CREATE procedure [dbo].[sp_ssrs_DoctorRateAnalytics] (@StartDate datetime, @EndDate datetime)

as

/*
declare
@StartDate datetime = null,
@EndDate datetime = null

exec sp_ssrs_DoctorRateAnalytics @StartDate, @EndDate
*/

create table #mdv_users(ID int identity, UserName nvarchar(200))
insert		#mdv_users(UserName)
select		distinct UserLogin
from		MDVRouting2.dbo.MDValuateUserSecurity
where		Customer = 'MDVALUATE'

if @StartDate is null
begin
	select @StartDate = convert(varchar, getdate() - 1, 110)
	--select		@StartDate = min(ar.EventDate)
	--from		MDVRate.dbo.AnalyticsResponse ar
	--inner join	MDVRate.dbo.AnalyticsData ad
	--on			ad.AnalyticsResponseKey = ar.AnalyticsResponseKey
	--left join	#mdv_users m
	--on			m.UserName = ad.UserName
	--where		ar.AnalyticsConfigKey = 'C62BF935-9480-4B6D-930E-6C4DA78F7C71'
	--and			m.UserName is null
end
if @EndDate is null
begin
	set @EndDate = convert(varchar, getdate(), 110)
end

select distinct		@StartDate as StartDate, @EndDate as EndDate, s.OrganizationName, s.OrganizationNPI, l.LocationName, l.LocationID, ad.UserID,
			p.RatedEntityNPI, p.RatedEntityFirstName, p.RatedEntityMiddleName, p.RatedEntityLastName, 
			--si.RatingSiteName, si.RatingSiteID, li.LinkUrl, --This was commented out because it was not needed CA 07/25/17
			cast(convert(varchar, ad.CreatedDateTime, 101) as datetime) EventDateTime, count(*) EventValue
from		DoctorRateReporting.dbo.Application_AnalyticsLog ad
inner join	DoctorRate.dbo.Core_Organization s
on			s.OrganizationNPI = ad.OrganizationNPI
inner join	DoctorRate.dbo.Core_Location l
on			l.LocationID = ad.LocationID
inner join	DoctorRate.dbo.Core_RatedEntity p
on			p.RatedEntityID = ad.RatedEntityID
inner join	DoctorRate.dbo.Core_RatedEntityRatingSiteLink li
on			li.RatedEntityID = p.RatedEntityID
inner join	DoctorRate.dbo.Core_RatingSite si
on			si.RatingSiteID = li.RatingSiteID
--left join	#mdv_users m
--on			m.UserName = ad.UserName
where		1 = 1
--and			m.UserName is null
and			ad.UserID not in (select UserID from [MDV-PROD].[MDVRouting2].dbo.MDValuateUserSecurity where Customer = 'MDValuate')
and			p.RatedEntityNPI not like 'D%'
and			ad.NavigationButtonID in (12, 14, 15)
and			ad.CreatedDateTime between @StartDate and @EndDate
group by	s.OrganizationName, s.OrganizationNPI, l.LocationName, l.LocationID, ad.UserID, p.RatedEntityNPI, p.RatedEntityFirstName,
			p.RatedEntityMiddleName, p.RatedEntityLastName, si.RatingSiteName, si.RatingSiteID, li.LinkUrl, convert(varchar, ad.CreatedDateTime, 101)
order by	s.OrganizationName, l.LocationName, EventValue desc, p.RatedEntityLastName, p.RatedEntityFirstName, p.RatedEntityMiddleName

drop table #mdv_users




