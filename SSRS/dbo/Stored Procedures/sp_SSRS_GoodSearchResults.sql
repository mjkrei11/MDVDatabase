


CREATE procedure [dbo].[sp_SSRS_GoodSearchResults] (@Database nvarchar(200))

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
Set @Database = 'NTKDA'
*/
declare
@MatchRankVerificationLevel int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1),
@counter int--,
--@Link nvarchar(max),
--@NPI nvarchar(10)

set @CR = char(13)
set @MatchRankVerificationLevel = 90
set @counter = 1

create table #Links(
	ID int identity,
	NPI nvarchar(10),
	FirstName nvarchar(50),
	MiddleName nvarchar(50),
	LastName nvarchar(50),
	SearchPattern nvarchar(200),
	SearchEngine varchar(120),
	LinkTarget nvarchar(max)
)

Set @sql = 'Insert #Links(NPI, FirstName, MiddleName, LastName, SearchPattern, SearchEngine, LinkTarget) ' + @CR
Set @sql = @sql + 'SELECT distinct psm.NPI, psm.FirstName, psm.MiddleName, psm.LastName, ' + @CR
Set @sql = @sql + 'psm.SearchPattern, psm.SearchEngine, sr.LinkTarget ' + @CR
Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianSearchMedia AS psm ' + @CR
Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.SearchResults sr ON psm.SearchID = sr.SearchID ' + @CR
Set @sql = @sql + 'WHERE psm.Status = ''Active'' ' + @CR
Set @sql = @sql + 'AND psm.LastRev = 1 ' + @CR
Set @sql = @sql + 'AND sr.MatchRank >= ''' + Cast(@MatchRankVerificationLevel AS nvarchar(5)) + ''' ' + @CR
Set @sql = @sql + 'AND sr.LinkType IS NOT NULL' + @CR
Set @sql = @sql + 'AND psm.SearchPattern <> ''MasterSearch'''
--Print @sql
exec(@sql)

SELECT *
FROM #Links
Order By LastName, FirstName, MiddleName, NPI

Drop Table #Links


