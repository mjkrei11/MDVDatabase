

CREATE procedure [dbo].[sp_ssrs_LocationLinks]

AS

/*

exec sp_ssrs_LocationLinks
*/

declare
@sql nvarchar(max),
@CR char(1),
@counter int,
@Database nvarchar(200)


set @CR = char(13)

create table #dbs(ID int identity, CustomerID nvarchar(10), DbName nvarchar(200))
insert		#dbs(CustomerID, DbName)
select		distinct SystemID, SystemDatabase
from		MDVALUATE.dbo.SystemRecordsMedia srm
where		srm.IsClient = 'Yes'
and			srm.CustomerTerminatedDate is null
and			srm.SystemDatabase is not null -- added 08/7/17 CA


create table #googlelinks (NPI nvarchar(10), FirstName nvarchar(200), LastName nvarchar(200), SearchEngine nvarchar(50), SearchPattern nvarchar(200), LinkTarget nvarchar(4000), LinkType nvarchar(50), MatchRule nvarchar(50), MatchRank nvarchar(50))

set @counter = 1
while @counter <= (select max(ID) from #dbs)

begin

select @Database = DbName from #dbs where ID = @counter

	set @sql = 'insert #googlelinks' + @CR
	Set @sql = @sql + 'SELECT distinct psm.NPI, psm.FirstName, psm.LastName, psm.SearchEngine AS SearchEngine, psm.SearchPattern, sr.LinkTarget, sr.LinkType, sr.MatchRule, sr.MatchRank ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianSearchMedia AS psm ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.SearchResults sr ON psm.SearchID = sr.SearchID ' + @CR
	Set @sql = @sql + 'WHERE psm.Status = ''Active'' '+ @CR
	Set @sql = @sql + 'AND psm.LastRev = 1 ' + @CR
	Set @sql = @sql + 'AND sr.MatchRank > 0 ' + @CR
	Set @sql = @sql + 'AND sr.LinkType IS NOT NULL ' + @CR
	Set @sql = @sql + 'AND sr.LinkTarget like ''https://www.google.com%'' '+ @CR
	Set @sql = @sql + 'AND psm.NPI = psm.LastName ' + @CR
	Set @sql = @sql + 'AND psm.SearchEngine = ''MasterSearch'' '+ @CR
	Set @sql = @sql + 'ORDER BY psm.FirstName, psm.LastName ' + @CR
	
--Print @sql
exec(@sql)

set @counter = @counter + 1
end



Select NPI, firstname, SearchPattern, LinkTarget
From #googlelinks
Order by firstname


--drop table #dbs
--drop table #googlelinks
--drop table #link


