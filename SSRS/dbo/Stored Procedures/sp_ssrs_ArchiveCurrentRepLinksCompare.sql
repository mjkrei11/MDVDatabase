create procedure sp_ssrs_ArchiveCurrentRepLinksCompare(@Database nvarchar(200))as/*declare@Database nvarchar(200)set @Database = 'Rothman'exec sp_ssrs_ArchiveCurrentRepLinksCompare @Database*/declare@sql nvarchar(max),@parms nvarchar(max),@CR char(1)set @CR = char(13) create table #archive_links(	NPI nvarchar(10),	FirstName nvarchar(200),	MiddleName nvarchar(200),	LastName nvarchar(200),	SiteName nvarchar(200),	SourceLink nvarchar(4000),	Rating float,	Volume int,	YearQuarter nvarchar(20))create table #current_links(	NPI nvarchar(10),	FirstName nvarchar(200),	MiddleName nvarchar(200),	LastName nvarchar(200),	SiteName nvarchar(200),	SourceLink nvarchar(4000),	Rating float,	Volume int)set @sql = 'insert #archive_links ' + @CRset @sql = @sql + 'select distinct media.NPI, media.FirstName, media.MiddleName, media.LastName, ' + @CRset @sql = @sql + 'metric.RatingsSite, metric.SourceLink, metric.Rating, metric.NumberOfRatings, media.YearQuarter ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia pm ' + @CRset @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CRset @sql = @sql + 'on media.NPI = pm.NPI ' + @CRset @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationArchive metric ' + @CRset @sql = @sql + 'on metric.XComboKey = media.XComboKey ' + @CRset @sql = @sql + 'where pm.Status = ''Active'' ' + @CRexec(@sql)

set @sql = 'insert #current_links ' + @CRset @sql = @sql + 'select distinct media.NPI, media.FirstName, media.MiddleName, media.LastName, ' + @CRset @sql = @sql + 'metric.RatingsSite, metric.SourceLink, metric.Rating, metric.NumberOfRatings ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia pm ' + @CRset @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CRset @sql = @sql + 'on media.NPI = pm.NPI ' + @CRset @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputation metric ' + @CRset @sql = @sql + 'on metric.ComboKey = media.ComboKey ' + @CRset @sql = @sql + 'where pm.Status = ''Active'' ' + @CRexec(@sql)

select		c.NPI, c.FirstName, c.MiddleName, c.LastName, c.SiteName, 'Current' as CurrentTimePeriod, c.SourceLink as CurrentLink,
			c.Rating as CurrentRating, c.Volume as CurrentVolume, a.YearQuarter as ArchiveTimePeriod, a.SourceLink as ArchiveLink,
			a.Rating as ArchiveRating, a.Volume as ArchiveVolume
from		#archive_links a
inner join	#current_links c
on			c.NPI = a.NPI
and			c.SiteName = a.SiteName
where		a.SourceLink is not null
and			c.SourceLink is null
order by	c.LastName, c.FirstName, ArchiveTimePeriod, c.SiteName

drop table #archive_links
drop table #current_links