



CREATE procedure [dbo].[sp_ssrs_PhysicianUpdatedReviews](
	@Database nvarchar(200)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'MoRush'
exec sp_ssrs_PhysicianUpdatedReviews 'MORUSH'
*/
declare
@sql nvarchar(max),
--@sql2 nvarchar(max),
@CR char(1)

set @CR = char(13)


Set @sql = 'select distinct c.NPI, c.SiteName, convert(varchar, c.CommentDate, 101) as CommentDate, c.CommentText ' + @CR
Set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_Comments c ' + @CR
Set @sql = @sql + 'where c.CommentDate >=  ''2015-08-01'' and c.CommentDate < ''2015-09-01'' ' + @CR
Set @sql = @sql + 'and isnull(ltrim(rtrim(c.CommentText)), '''') <> ''''  ' + @CR
Set @sql = @sql + 'and c.SiteName in (''UCompare'', ''RateMDs'', ''Vitals'') and c.CommentText like ''%[a-z]%'' ' + @CR
Set @sql = @sql + 'order by NPI ' + @CR
exec (@sql)
Print @sql

--select        distinct c.NPI, pm.FirstName, pm.MiddleName, pm.LastName, c.SiteName, convert(varchar, c.CommentDate, 101) as CommentDate, c.CommentText
--from        DIFFBOT_Comments c
--inner join    PhysicianMedia pm
--on            pm.NPI = c.NPI
--where        c.CommentDate >=  '2015-08-01'
--and            c.CommentDate < '2015-09-01'
--and            isnull(ltrim(rtrim(c.CommentText)), '') <> ''
--and            c.SiteName in ('UCompare', 'RateMDs', 'Vitals')
--and            c.CommentText like '%[a-z]%'
--order by    CommentDate, SiteName, LastName, FirstName






