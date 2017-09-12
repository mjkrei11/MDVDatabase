
CREATE procedure [dbo].[sp_ssrs_MDVRateAnalytics] (@StartDate datetime, @EndDate datetime)

as

/*
declare
@StartDate datetime = null,
@EndDate datetime = null

exec sp_ssrs_MDVRateAnalytics @StartDate, @EndDate
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

select		@StartDate as StartDate, @EndDate as EndDate, s.SystemName, s.SystemID, l.LocationName, l.LocationKey, ad.UserName,
			p.NPI, p.FirstName, p.MiddleName, p.LastName, si.SiteName, si.SiteKey,
			li.LinkTarget, cast(convert(varchar, ad.EventDateTime, 101) as datetime) EventDateTime, count(*) EventValue
from		DoctorRateReporting.dbo.Analytics_Activity ad
inner join	MDVRate.dbo.Systems s
on			s.SystemID = ad.SystemID
inner join	MDVRate.dbo.Locations l
on			l.LocationKey = ad.LocationKey
inner join	MDVRate.dbo.SystemLocations sl
on			sl.LocationKey = l.LocationKey
inner join	MDVRate.dbo.Physicians p
on			p.NPI = ad.NPI
inner join	MDVRate.dbo.Links li
on			li.NPI = p.NPI
and			li.LinkKey = p.LinkKey
inner join	MDVRate.dbo.Sites si
on			si.SiteKey = li.SiteKey
--left join	#mdv_users m
--on			m.UserName = ad.UserName
where		1 = 1
--and			m.UserName is null
and			ad.UserName not in (select UserLogin from [MDV-PROD].[MDVRouting2].dbo.MDValuateUserSecurity where Customer = 'MDValuate')
and			p.NPI not like 'D%'
and			ad.NavigationButtonKey = '6DFBC682-814B-48F7-9678-02CBEDF0C3B2'
and			ad.EventDateTime between @StartDate and @EndDate
group by	s.SystemName, s.SystemID, l.LocationName, l.LocationKey, ad.UserName, p.NPI, p.FirstName,
			p.MiddleName, p.LastName, si.SiteName, si.SiteKey, li.LinkTarget, convert(varchar, ad.EventDateTime, 101)
order by	s.SystemName, l.LocationName, EventValue desc, p.LastName, p.FirstName, p.MiddleName

drop table #mdv_users
