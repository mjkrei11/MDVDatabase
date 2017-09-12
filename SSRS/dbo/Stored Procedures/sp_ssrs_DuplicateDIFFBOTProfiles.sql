create procedure sp_ssrs_DuplicateDIFFBOTProfiles

as

create table #duplicates(
	ID int identity,
	CustomerID nvarchar(10),
	NPI nvarchar(10),
	SiteName nvarchar(50),
	LinkCount int
)
insert		#duplicates(CustomerID, NPI, SiteName, LinkCount)
select		CustomerID, NPI, SiteName, count(distinct SourceLink)
from		RepMgmt.dbo.DIFFBOT_LinkPairs
group by	CustomerID, NPI, SiteName

select		distinct m.PrimaryCustomerID, m.PrimaryCustomerSource, m.NPI, m.FirstName, m.MiddleName, m.LastName,
			d.SiteName, d.LinkCount, l.SourceLink
from		#duplicates d
inner join	MDVALUATE.dbo.MasterPhysicianMedia m
on			m.NPI = d.NPI
inner join	RepMgmt.dbo.DIFFBOT_LinkPairs l
on			l.NPI = d.NPI
and			l.SiteName = d.SiteName
where		LinkCount > 1
order by	LinkCount desc

drop table #duplicates