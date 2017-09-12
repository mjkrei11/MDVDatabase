

CREATE procedure [dbo].[sp_SSRS_GoodMatchedLinks](@Database nvarchar(200))

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
Set @Database = 'MORUSH'

exec sp_SSRS_GoodMatchedLinks @Database
*/

declare
@MatchRankVerificationLevel int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)
set @MatchRankVerificationLevel = 90

Set @sql = 'SELECT distinct psm.NPI, psm.FirstName, psm.MiddleName, psm.LastName, psm.SearchEngine AS SearchEngine, psm.SearchPattern, ' + @CR
Set @sql = @sql + 'dbo.Fn_GetDomain(sr.LinkTarget) AS Domain, sr.LinkTarget, sr.LinkType, sr.MatchRule, sr.MatchRank, sr.RatingText ' + @CR
Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianSearchMedia AS psm ' + @CR
Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.SearchResults sr ON psm.SearchID = sr.SearchID ' + @CR
Set @sql = @sql + 'WHERE psm.Status = ''Active'' ' + @CR
Set @sql = @sql + 'AND psm.LastRev = 1 ' + @CR
Set @sql = @sql + 'AND sr.MatchRank >= ''' + Cast(@MatchRankVerificationLevel AS nvarchar(5)) + ''' ' + @CR
Set @sql = @sql + 'AND sr.LinkType IS NOT NULL ' + @CR
Set @sql = @sql + 'ORDER BY psm.LastName, psm.FirstName, psm.MiddleName, psm.NPI'
--Print @sql
exec(@sql)

