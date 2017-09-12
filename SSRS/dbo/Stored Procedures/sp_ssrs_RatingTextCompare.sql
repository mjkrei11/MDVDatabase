CREATE procedure [dbo].[sp_ssrs_RatingTextCompare](@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'TWINCITIES'

exec sp_ssrs_RatingTextCompare @Database
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select distinct v.NPI, v.FirstName, v.MiddleName, v.LastName, v.LinkTarget, v.RatingText, v.OriginalRatingText, v.MatchRule, v.MatchRank ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.vw_PhysicianSearch v ' + @CR
set @sql = @sql + 'where v.RatingText is not null ' + @CR
set @sql = @sql + 'and v.OriginalRatingText is not null ' + @CR
set @sql = @sql + 'and v.LinkType = ''Rating'' ' + @CR
set @sql = @sql + 'and v.RatingText <> v.OriginalRatingText ' + @CR
set @sql = @sql + 'order by v.LastName, v.FirstName, v.MiddleName, v.LinkTarget '
exec(@sql)