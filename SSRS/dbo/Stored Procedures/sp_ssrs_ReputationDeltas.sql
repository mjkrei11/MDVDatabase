create procedure sp_ssrs_ReputationDeltas(@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'MORUSH'

exec sp_ssrs_ReputationDeltas @Database
*/

declare
@YearQuarter nvarchar(50),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

set @sql = 'select @TempYearQuarter = max(YearQuarter) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchiveMedia'
set @parms = '@TempYearQuarter varchar(50) output'
exec sp_executesql @sql, @parms, @TempYearQuarter = @YearQuarter output

create table #archive_rep(
	NPI nvarchar(10),
	ComboKey nvarchar(50),
	RatingsSite nvarchar(100),
	VIMeasure float,
	Rating float,
	NumberOfRatings int,
	Percentile float,
	Color nvarchar(20),
	SourceLink nvarchar(4000)
)

set @sql = 'insert #archive_rep ' + @CR
set @sql = @sql + 'select media.NPI, media.ComboKey, metric.RatingsSite, metric.VIMeasure, ' + @CR
set @sql = @sql + 'metric.Rating, metric.NumberOfRatings, metric.Percentile, metric.Color, metric.SourceLink ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationArchive metric ' + @CR
set @sql = @sql + 'on metric.XComboKey = media.XComboKey ' + @CR
set @sql = @sql + 'where media.CollectionID = media.SystemID ' + @CR
set @sql = @sql + 'and media.YearQuarter = ''' + @YearQuarter + ''' '
exec(@sql)

create table #current_rep(
	NPI nvarchar(10),
	ComboKey nvarchar(50),
	FirstName nvarchar(100),
	LastName nvarchar(100),
	RatingsSite nvarchar(100),
	VIMeasure float,
	Rating float,
	NumberOfRatings int,
	Percentile float,
	Color nvarchar(20),
	SourceLink nvarchar(4000)
)

set @sql = 'insert #current_rep ' + @CR
set @sql = @sql + 'select media.NPI, media.ComboKey, media.FirstName, media.LastName, metric.RatingsSite, metric.VIMeasure, ' + @CR
set @sql = @sql + 'metric.Rating, metric.NumberOfRatings, metric.Percentile, metric.Color, metric.SourceLink ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputation metric ' + @CR
set @sql = @sql + 'on metric.ComboKey = media.ComboKey ' + @CR
set @sql = @sql + 'where media.CollectionID = media.SystemID '
exec(@sql)

select		c.NPI, c.FirstName, c.LastName, c.RatingsSite, c.NumberOfRatings as CurrentVolume,
			a.NumberOfRatings as ArchiveVolume, c.Rating as CurrentRating, a.Rating as ArchiveRating,
			c.SourceLink as CurrentSource, a.SourceLink as ArchiveSource
from		#current_rep c
inner join	#archive_rep a
on			a.NPI = c.NPI
and			a.RatingsSite = c.RatingsSite
where		a.NumberOfRatings > c.NumberOfRatings
and			c.RatingsSite <> 'Sum All Sites'

drop table #archive_rep
drop table #current_rep