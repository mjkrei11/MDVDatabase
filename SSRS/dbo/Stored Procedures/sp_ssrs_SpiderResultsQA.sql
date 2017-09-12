create procedure sp_ssrs_SpiderResultsQA (@Database nvarchar(200))

as

/*
declare @Database nvarchar(200) = 'CSOG'
exec sp_ssrs_SpiderResultsQA @Database
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

set @sql = 'select ' + @CR
set @sql = @sql + '(select count(*) from [' + @Database + '].dbo.PhysicianMedia where Status = ''Active'') as ActivePhysicians, ' + @CR
set @sql = @sql + '(select count(distinct NPI) from [' + @Database + '].dbo.PhysicianSearchMedia) as NPIsSpidered, ' + @CR
set @sql = @sql + 'NPI, FirstName, LastName, SearchEngine, SearchPattern, SearchText, count(*) as LinkCount ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'inner join [' + @Database + '].dbo.SearchResults sr ' + @CR
set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
set @sql = @sql + 'group by NPI, FirstName, LastName, SearchEngine, SearchPattern, SearchText ' + @CR
set @sql = @sql + 'order by LinkCount, LastName, FirstName, SearchEngine, SearchPattern ' + @CR
exec(@sql)