


CREATE procedure [dbo].[sp_ssrs_SiteNames] (
	@Database nvarchar(200)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'TwinCities'

exec sp_ssrs_SiteNames @Database
*/

declare
@sql nvarchar(max),
--@sql2 nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select distinct case RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else RatingsSite end as RatingsSite ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputation ' + @CR
set @sql = @sql + 'order by RatingsSite ' + @CR
exec (@sql)

Print @sql





