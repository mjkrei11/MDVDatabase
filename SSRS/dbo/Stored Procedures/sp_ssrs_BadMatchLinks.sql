
CREATE procedure [dbo].[sp_ssrs_BadMatchLinks] (@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'Bench_A'

--exec sp_ssrs_BadMatchLinks 'Bench_A'
*/

declare
@sql nvarchar(max),
@CR char(1)
set @CR = char(13)

create table #matched_links(
	NPI nvarchar(10),
	LinkTarget nvarchar(4000),
	MatchRule int,
	MatchRank int,
	LinkType nvarchar(20)
)

set @sql = 'insert #matched_links(NPI, LinkTarget, MatchRule, MatchRank, LinkType) ' + @CR
set @sql = @sql + 'select distinct psm.NPI, sr.LinkTarget, sr.MatchRule, sr.MatchRank, sr.LinkType ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
set @sql = @sql + 'where sr.MatchRank >= 90 ' + @CR
set @sql = @sql + 'and sr.LinkType in (''Rating'', ''Practice - Profile'', ''Hospital - Profile'') ' + @CR
set @sql = @sql + 'and psm.SearchPattern = ''MasterSearch'' ' + @CR
set @sql = @sql + 'order by sr.LinkTarget, psm.NPI ' + @CR
exec(@sql)

create table #results(
	LinkType nvarchar(20),
	LinkTarget nvarchar(4000),
	LinkCount int
)
insert		#results
select		LinkType, LinkTarget, count(NPI)
from		#matched_links
group by	LinkType, LinkTarget

set @sql = 'select distinct psm.NPI, psm.FirstName, psm.MiddleName, psm.LastName, psm.SearchEngine, ' + @CR
set @sql = @sql + 'psm.SearchPattern, r.LinkType, r.LinkTarget, r.LinkCount ' + @CR
set @sql = @sql + 'from #results r ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
set @sql = @sql + 'on sr.LinkTarget = r.LinkTarget ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'on psm.SearchID = sr.SearchID ' + @CR
set @sql = @sql + 'where r.LinkCount > 1 ' + @CR
set @sql = @sql + 'order by r.LinkType, r.LinkTarget, psm.LastName, psm.FirstName, psm.MiddleName '
exec(@sql)

drop table #matched_links
drop table #results
