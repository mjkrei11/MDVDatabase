
CREATE procedure [dbo].[sp_ssrs_BenchmarkLinkVerification](@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)

--exec sp_ssrs_BenchmarkLinkVerification 'Bench_A'
*/

declare
@RunDb nvarchar(200),
@sql nvarchar(max),
@CR char(1)
set @CR = char(13)

set @RunDb = 'MDVALUATE'

create table #RatingsSites(
	ID int identity,
	SiteName nvarchar(200),
	SiteURL nvarchar(max)
)

set @sql = 'insert #RatingsSites(SiteName, SiteURL) ' + @CR
set @sql = @sql + 'select sm.SiteName, sm.SiteURL ' + @CR
set @sql = @sql + 'from ' + @RunDb + '.dbo.SiteDataMedia sdm ' + @CR
set @sql = @sql + 'inner join ' + @RunDb + '.dbo.SiteMappings sm ' + @CR
set @sql = @sql + 'on sm.MappingID = sdm.MappingID ' + @CR
set @sql = @sql + 'where sdm.MappingClassification = ''rating'' ' + @CR
set @sql = @sql + 'and sdm.MappingStatus = ''active'' ' + @CR
set @sql = @sql + 'and sdm.Provider = ''global'' ' + @CR
set @sql = @sql + 'and sm.CalculationFlag = 1 '
exec(@sql)

create table #bench_links(
	Customer nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(100),
	MiddleName nvarchar(50),
	LastName nvarchar(100),
	Domain nvarchar(4000),
	LinkTarget nvarchar(4000),
	RatingText nvarchar(400),
	LinkLabel nvarchar(4000)
)

set @sql = 'insert #bench_links(Customer, NPI, FirstName, MiddleName, LastName, LinkTarget, Domain) ' + @CR
set @sql = @sql + 'select distinct id.CustomerSource, psm.NPI, psm.FirstName, psm.MiddleName, psm.LastName, sr.LinkTarget, ' + @CR
set @sql = @sql + 'dbo.fn_GetDomain(sr.LinkTarget) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysCustomerID id ' + @CR
set @sql = @sql + 'on id.NPI = psm.NPI ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
set @sql = @sql + 'inner join #RatingsSites r ' + @CR
set @sql = @sql + 'on dbo.fn_GetDomain(r.SiteURL) = dbo.fn_GetDomain(sr.LinkTarget) ' + @CR
set @sql = @sql + 'where sr.RatingText is not null ' + @CR
set @sql = @sql + 'and sr.LinkType = ''Rating'' ' + @CR
set @sql = @sql + 'and sr.MatchRank is null '
exec(@sql)

set @sql = 'update b ' + @CR
set @sql = @sql + 'set b.LinkLabel = replace(replace(replace(sr.LinkLabel, char(13), '' ''), ''  '', '' ''), ''  '', '' ''), ' + @CR
set @sql = @sql + 'b.RatingText = sr.RatingText ' + @CR
set @sql = @sql + 'from #bench_links b ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'on psm.NPI = b.NPI ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
set @sql = @sql + 'and sr.LinkTarget = b.LinkTarget ' + @CR
set @sql = @sql + 'where sr.RatingText is not null '
exec(@sql)

select		*
from		#bench_links
order by	Customer, LastName, FirstName, MiddleName, LinkTarget

drop table #RatingsSites
drop table #bench_links
