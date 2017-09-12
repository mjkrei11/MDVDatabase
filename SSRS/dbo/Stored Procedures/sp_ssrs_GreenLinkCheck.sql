
CREATE procedure [dbo].[sp_ssrs_GreenLinkCheck] (@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'Competition'

--exec sp_ssrs_GreenLinkCheck 'Competition'
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #results(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	SearchEngine nvarchar(200),
	SearchPattern nvarchar(200),
	SearchID nvarchar(50),
	SearchDate datetime,
	LinkTarget nvarchar(4000),
	GreenLink nvarchar(4000),
	ResultNumber int
)
set @sql = 'insert #results(NPI, FirstName, LastName, SearchEngine, SearchPattern, SearchID, SearchDate, LinkTarget, GreenLink, ResultNumber) ' + @CR
set @sql = @sql + 'select psm.NPI, psm.FirstName, psm.LastName, psm.SearchEngine, psm.SearchPattern, psm.SearchID, psm.SearchDate, ' + @CR
set @sql = @sql + 'sr.LinkTarget, sr.GreenLink, cast(sr.ResultNumber as int) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
set @sql = @sql + 'and sr.GreenLink not like ''%'' + dbo.fn_GetDomain(sr.LinkTarget) + ''%'' ' + @CR
set @sql = @sql + 'and sr.LinkTarget like ''http%'' '
exec(@sql)

create table #counts(
	SearchID nvarchar(50),
	LinkCount int
)

insert		#counts
select		SearchID, count(SearchID)
from		#results
group by	SearchID

select		r.*
from		#results r
inner join	#counts c
on			c.SearchID = r.SearchID
where		c.LinkCount > 5
order by	LastName, FirstName, SearchEngine, SearchPattern, ResultNumber, LinkTarget, GreenLink

drop table #results
drop table #counts
