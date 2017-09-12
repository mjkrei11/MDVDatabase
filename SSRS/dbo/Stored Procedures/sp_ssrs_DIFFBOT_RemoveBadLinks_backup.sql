




CREATE procedure [dbo].[sp_ssrs_DIFFBOT_RemoveBadLinks_backup] (@Database varchar(200), @LinkTarget varchar(4000), @MatchRankOption nvarchar(50))

as

/*
declare

@Database varchar(40) = 'Rothman',
@LinkTarget varchar(4000) = 'https://www.healthgrades.com/physician/dr-joseph-abboud-yt5th/patient-ratings#QualitySurveyResults_anchor',
@MatchRankOption nvarchar(50) = 'all'

exec sp_ssrs_DIFFBOT_RemoveBadLinks_backup @Database, @LinkTarget,  @MatchRankOption
*/

declare
@sql nvarchar(max),
@CR char(1),
@CurrentRowID BIGINT = 1,
@MaxRowID BIGINT

set @CR = char(13)

create table #DiffBotLinks(
	RowID BIGINT identity(1,1) primary key, 
	DiffBotLink varchar(4000)
)

create table #SearchResults(
	NPI varchar(10),
	LastName varchar(80),
	FirstName varchar(120),
	MiddleName varchar(40),
	DatabaseLocated varchar(40),
	SearchEngine varchar(120),
	SearchPattern varchar(400),
	Domain varchar(120),
	LinkTarget varchar(4000),
	LinkType varchar(40),
	ResultNumber int,
	MatchRule int,
	MatchRank int,
	RatingText varchar(4000)
)

set @sql = 'insert #DiffBotLinks(DiffBotLink)' + @CR
set @sql = @sql + 'select distinct OriginalLink' + @CR
set @sql = @sql + 'from RepMgmt.dbo.DIFFBOT_LinkPairs' + @CR
set @sql = @sql + 'where OriginalLink = ''' + @LinkTarget + ''' ' + @CR
set @sql = @sql + 'or SourceLink = ''' + @LinkTarget + ''' ' + @CR
exec(@sql)

set @sql = 'insert #DiffBotLinks(DiffBotLink)' + @CR
set @sql = @sql + 'select distinct SourceLink' + @CR
set @sql = @sql + 'from RepMgmt.dbo.DIFFBOT_LinkPairs' + @CR
set @sql = @sql + 'where OriginalLink = ''' + @LinkTarget + ''' ' + @CR
set @sql = @sql + 'or SourceLink = ''' + @LinkTarget + ''' ' + @CR
exec(@sql)

--select * from #DiffBotLinks

if @MatchRankOption = 'matched'
begin
set @sql = 'insert into #SearchResults (NPI, LastName, FirstName, MiddleName, SearchEngine, SearchPattern, Domain, LinkTarget, LinkType, ResultNumber, MatchRule, MatchRank, RatingText)' + @CR
set @sql = @sql + 'select psm.NPI, psm.LastName, psm.FirstName, psm.MiddleName, psm.SearchEngine, psm.SearchPattern, dbo.fn_GetDomain(sr.LinkTarget) AS Domain, sr.LinkTarget, ' + @CR
set @sql = @sql + 'sr.LinkType, sr.ResultNumber, sr.MatchRule, sr.MatchRank, sr.RatingText ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
set @sql = @sql + 'on psm.SearchID = sr.SearchID' + @CR
set @sql = @sql + 'right outer join #DiffBotLinks dbl' + @CR
set @sql = @sql + 'on sr.LinkTarget = dbl.DiffBotLink' + @CR
set @sql = @sql + 'where sr.MatchRank > 0' + @CR
exec(@sql)

set @sql = 'update #SearchResults set DatabaseLocated = ''' + @Database + ''' ' + @CR
exec(@sql)

set @sql = 'insert into #SearchResults (NPI, LastName, FirstName, MiddleName, DatabaseLocated, SearchEngine, SearchPattern, Domain, LinkTarget, LinkType, ResultNumber, MatchRule, MatchRank, RatingText) ' + @CR
set @sql = @sql + 'select psm.NPI, psm.LastName, psm.FirstName, psm.MiddleName, ''MDVALUATE'' as DatabaseLocated, psm.SearchEngine, psm.SearchPattern,dbo.fn_GetDomain(msr.LinkTarget) AS Domain, msr.LinkTarget, ' + @CR
set @sql = @sql + 'msr.LinkType, msr.ResultNumber, msr.MatchRule, msr.MatchRank, msr.RatingText ' + @CR
set @sql = @sql + 'from MDVALUATE.dbo.MasterPhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'inner join MDVALUATE.dbo.MasterSearchResults msr ' + @CR
set @sql = @sql + 'on msr.SearchID = psm.SearchID' + @CR
set @sql = @sql + 'right outer join #DiffBotLinks dbl' + @CR
set @sql = @sql + 'on msr.LinkTarget = dbl.DiffBotLink' + @CR
set @sql = @sql + 'where msr.MatchRank > 0' + @CR
exec(@sql)
end

if @MatchRankOption = 'un-matched'
begin
set @sql = 'insert into #SearchResults (NPI, LastName, FirstName, MiddleName, SearchEngine, SearchPattern, Domain, LinkTarget, LinkType, ResultNumber, MatchRule, MatchRank, RatingText)' + @CR
set @sql = @sql + 'select psm.NPI, psm.LastName, psm.FirstName, psm.MiddleName, psm.SearchEngine, psm.SearchPattern, dbo.fn_GetDomain(sr.LinkTarget) AS Domain, sr.LinkTarget, ' + @CR
set @sql = @sql + 'sr.LinkType, sr.ResultNumber, sr.MatchRule, sr.MatchRank, sr.RatingText ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
set @sql = @sql + 'on psm.SearchID = sr.SearchID' + @CR
set @sql = @sql + 'right outer join #DiffBotLinks dbl' + @CR
set @sql = @sql + 'on sr.LinkTarget = dbl.DiffBotLink' + @CR
set @sql = @sql + 'where sr.MatchRank = 0' + @CR
exec(@sql)

set @sql = 'update #SearchResults set DatabaseLocated = ''' + @Database + ''' ' + @CR
exec(@sql)

set @sql = 'insert into #SearchResults (NPI, LastName, FirstName, MiddleName, DatabaseLocated, SearchEngine, SearchPattern, Domain, LinkTarget, LinkType, ResultNumber, MatchRule, MatchRank, RatingText) ' + @CR
set @sql = @sql + 'select psm.NPI, psm.LastName, psm.FirstName, psm.MiddleName, ''MDVALUATE'' as DatabaseLocated, psm.SearchEngine, psm.SearchPattern,dbo.fn_GetDomain(msr.LinkTarget) AS Domain, msr.LinkTarget, ' + @CR
set @sql = @sql + 'msr.LinkType, msr.ResultNumber, msr.MatchRule, msr.MatchRank, msr.RatingText ' + @CR
set @sql = @sql + 'from MDVALUATE.dbo.MasterPhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'inner join MDVALUATE.dbo.MasterSearchResults msr ' + @CR
set @sql = @sql + 'on msr.SearchID = psm.SearchID' + @CR
set @sql = @sql + 'right outer join #DiffBotLinks dbl' + @CR
set @sql = @sql + 'on msr.LinkTarget = dbl.DiffBotLink' + @CR
set @sql = @sql + 'where msr.MatchRank = 0' + @CR
exec(@sql)
end

if @MatchRankOption = 'all'
begin
set @sql = 'insert into #SearchResults (NPI, LastName, FirstName, MiddleName, SearchEngine, SearchPattern, Domain, LinkTarget, LinkType, ResultNumber, MatchRule, MatchRank, RatingText)' + @CR
set @sql = @sql + 'select psm.NPI, psm.LastName, psm.FirstName, psm.MiddleName, psm.SearchEngine, psm.SearchPattern, dbo.fn_GetDomain(sr.LinkTarget) AS Domain, sr.LinkTarget, ' + @CR
set @sql = @sql + 'sr.LinkType, sr.ResultNumber, sr.MatchRule, sr.MatchRank, sr.RatingText ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
set @sql = @sql + 'on psm.SearchID = sr.SearchID' + @CR
set @sql = @sql + 'right outer join #DiffBotLinks dbl' + @CR
set @sql = @sql + 'on sr.LinkTarget = dbl.DiffBotLink' + @CR
exec(@sql)

set @sql = 'update #SearchResults set DatabaseLocated = ''' + @Database + ''' ' + @CR
exec(@sql)

set @sql = 'insert into #SearchResults (NPI, LastName, FirstName, MiddleName, DatabaseLocated, SearchEngine, SearchPattern, Domain, LinkTarget, LinkType, ResultNumber, MatchRule, MatchRank, RatingText) ' + @CR
set @sql = @sql + 'select psm.NPI, psm.LastName, psm.FirstName, psm.MiddleName, ''MDVALUATE'' as DatabaseLocated, psm.SearchEngine, psm.SearchPattern,dbo.fn_GetDomain(msr.LinkTarget) AS Domain, msr.LinkTarget, ' + @CR
set @sql = @sql + 'msr.LinkType, msr.ResultNumber, msr.MatchRule, msr.MatchRank, msr.RatingText ' + @CR
set @sql = @sql + 'from MDVALUATE.dbo.MasterPhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'inner join MDVALUATE.dbo.MasterSearchResults msr ' + @CR
set @sql = @sql + 'on msr.SearchID = psm.SearchID' + @CR
set @sql = @sql + 'right outer join #DiffBotLinks dbl' + @CR
set @sql = @sql + 'on msr.LinkTarget = dbl.DiffBotLink' + @CR
exec(@sql)
end

select distinct * 
from #SearchResults
where NPI is not null
order by LastName, DatabaseLocated, SearchEngine, SearchPattern

drop table #DiffBotLinks
drop table #SearchResults
	
