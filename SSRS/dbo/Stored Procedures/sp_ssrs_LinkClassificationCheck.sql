CREATE procedure [dbo].[sp_ssrs_LinkClassificationCheck] (@Database nvarchar(200))

as

/*
declare @Database nvarchar(200)
set @Database = 'Competition'

--exec sp_ssrs_LinkClassificationCheck 'Competition'
*/

declare
@sql nvarchar(max),
@CR char(1)
set @CR = char(13)

set @sql = 'select distinct sr.LinkTarget, sr.LinkType ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.SearchResults sr ' + @CR
set @sql = @sql + 'where sr.LinkType in (''Hospital'', ''Practice'') ' + @CR
set @sql = @sql + 'and sr.LinkTarget not like ''%.pdf'' ' + @CR
set @sql = @sql + 'and sr.LinkTarget not like ''%.doc'' ' + @CR
set @sql = @sql + 'order by sr.LinkType, sr.LinkTarget'
exec(@sql)