﻿create procedure sp_ssrs_ArchiveCurrentRepLinksCompare(@Database nvarchar(200))

set @sql = 'insert #current_links ' + @CR

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