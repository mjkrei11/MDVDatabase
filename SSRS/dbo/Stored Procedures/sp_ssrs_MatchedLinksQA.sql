


CREATE procedure [dbo].[sp_ssrs_MatchedLinksQA](@Database nvarchar(200), @MatchRankOption nvarchar(50))

AS

/* Test parameter */
/*
declare
@Database nvarchar(200),
@MatchRankOption nvarchar(50)

set @Database = 'DallasNA'
set @MatchRankOption = 'all'

exec sp_ssrs_MatchedLinksQA @Database, @MatchRankOption
*/

declare
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

if @MatchRankOption = 'matched'
begin
	Set @sql = 'SELECT distinct psm.NPI, psm.FirstName, psm.MiddleName, psm.LastName, psm.SearchEngine AS SearchEngine, psm.SearchPattern, ' + @CR
	Set @sql = @sql + 'dbo.Fn_GetDomain(sr.LinkTarget) AS Domain, sr.LinkTarget, sr.LinkType, sr.MatchRule, sr.MatchRank, sr.RatingText, sr.ResultNumber ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianSearchMedia AS psm ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.SearchResults sr ON psm.SearchID = sr.SearchID ' + @CR
	Set @sql = @sql + 'WHERE psm.Status = ''Active'' ' + @CR
	Set @sql = @sql + 'AND psm.LastRev = 1 ' + @CR
	--Set @sql = @sql + 'AND sr.MatchRank >= 0 ' + @CR --Commented out and changed to the code below it -  5/12/17 CA
	Set @sql = @sql + 'AND sr.MatchRank > 0 ' + @CR
	Set @sql = @sql + 'AND sr.LinkType IS NOT NULL ' + @CR
	Set @sql = @sql + 'ORDER BY psm.LastName, psm.FirstName, psm.MiddleName, psm.NPI'
	--Print @sql
	exec(@sql)
end
if @MatchRankOption = 'un-matched'
begin
	Set @sql = 'SELECT distinct psm.NPI, psm.FirstName, psm.MiddleName, psm.LastName, psm.SearchEngine AS SearchEngine, psm.SearchPattern, ' + @CR
	Set @sql = @sql + 'dbo.Fn_GetDomain(sr.LinkTarget) AS Domain, sr.LinkTarget, sr.LinkType, sr.MatchRule, sr.MatchRank, sr.RatingText, sr.ResultNumber ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianSearchMedia AS psm ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.SearchResults sr ON psm.SearchID = sr.SearchID ' + @CR
	Set @sql = @sql + 'WHERE psm.Status = ''Active'' ' + @CR
	Set @sql = @sql + 'AND psm.LastRev = 1 ' + @CR
	Set @sql = @sql + 'AND sr.MatchRank = 0 ' + @CR
	Set @sql = @sql + 'AND sr.LinkType IS NOT NULL ' + @CR
	Set @sql = @sql + 'ORDER BY psm.LastName, psm.FirstName, psm.MiddleName, psm.NPI'
	--Print @sql
	exec(@sql)
end
if @MatchRankOption = 'all'
begin
	Set @sql = 'SELECT distinct psm.NPI, psm.FirstName, psm.MiddleName, psm.LastName, psm.SearchEngine AS SearchEngine, psm.SearchPattern, ' + @CR
	Set @sql = @sql + 'dbo.Fn_GetDomain(sr.LinkTarget) AS Domain, sr.LinkTarget, sr.LinkType, sr.MatchRule, sr.MatchRank, sr.RatingText, sr.ResultNumber ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianSearchMedia AS psm ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.SearchResults sr ON psm.SearchID = sr.SearchID ' + @CR
	Set @sql = @sql + 'WHERE psm.Status = ''Active'' ' + @CR
	Set @sql = @sql + 'AND psm.LastRev = 1 ' + @CR
	Set @sql = @sql + 'AND sr.MatchRank is not null ' + @CR
	Set @sql = @sql + 'AND sr.LinkType IS NOT NULL ' + @CR
	Set @sql = @sql + 'ORDER BY psm.LastName, psm.FirstName, psm.MiddleName, psm.NPI'
	--Print @sql
	exec(@sql)
end
