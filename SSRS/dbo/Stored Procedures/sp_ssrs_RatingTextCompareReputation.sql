create procedure [dbo].[sp_ssrs_RatingTextCompareReputation](@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'TWINCITIES'

exec sp_ssrs_RatingTextCompareReputation @Database
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select distinct v.NPI, v.FirstName, v.MiddleName, v.LastName, v.LinkTarget, v.RatingText, v.OriginalRatingText, v.MatchRule, v.MatchRank ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.vw_PhysicianSearch v ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CR
set @sql = @sql + 'on media.NPI = v.NPI ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputation metric ' + @CR
set @sql = @sql + 'on metric.ComboKey = media.ComboKey ' + @CR
set @sql = @sql + 'and metric.SourceLink = v.LinkTarget ' + @CR
set @sql = @sql + 'where v.RatingText is not null ' + @CR
set @sql = @sql + 'and v.OriginalRatingText is not null '
exec(@sql)