﻿CREATE procedure [dbo].[sp_ssrs_RatingsProgressBySite](

create table #raw_data_start(ID int identity, DataDate datetime, NPI nvarchar(10), Diffbot int, RepBrowser int, SiteName nvarchar(50), Volume int, Rating decimal(2,1))
create table #raw_data_end(ID int identity, DataDate datetime, NPI nvarchar(10), Diffbot int, RepBrowser int, SiteName nvarchar(50), Volume int, Rating decimal(2,1))

set @counter = 1
while @counter <= (select max(ID) from #NPI)
begin
	select @NPI = NPI from #npi where ID = @counter

	set @sql = 'select @TempDiffbotStart = count(*) ' + @CR

	if isnull(@diffbot_start_check, 0) = 0
	begin
		set @sql = 'insert #raw_data_start(DataDate, NPI, Diffbot, RepBrowser, SiteName, Volume, Rating) ' + @CR
		set @sql = @sql + 'select top 1 metric.LoadDate, media.NPI, 0, 1, metric.RatingsSite, metric.NumberOfRatings, metric.Rating ' + @CR
		set @sql = @sql + 'from [' + @Database + '].dbo.PhysMetReputationArchiveMedia media ' + @CR
		set @sql = @sql + 'inner join [' + @Database + '].dbo.PhysMetReputationArchive metric ' + @CR
		set @sql = @sql + 'on metric.XComboKey = media.XComboKey ' + @CR
		set @sql = @sql + 'where metric.RatingsSite = ''' + @RepSiteName + ''' ' + @CR
		set @sql = @sql + 'and media.NPI = ''' + @NPI + ''' ' + @CR
		set @sql = @sql + 'and metric.LoadDate >= (select StartDate from #times) ' + @CR--and (select EndDate from #times) ' + @CR
		set @sql = @sql + 'order by metric.LoadDate ' + @CR
		exec(@sql)
	end
	else
	begin
		set @sql = 'insert #raw_data_start(DataDate, NPI, Diffbot, RepBrowser, SiteName, Volume, Rating) ' + @CR
		set @sql = @sql + 'select max(cast(convert(varchar, SearchDate, 101) as datetime)), max(NPI), 1, 0, max(SiteName), max(ResultVolume), max(ResultRating) ' + @CR
		set @sql = @sql + 'from [' + @Database + '].dbo.DIFFBOT_ResultLinks ' + @CR
		set @sql = @sql + 'where SiteName = ''' + @SiteName + ''' ' + @CR
		set @sql = @sql + 'and NPI = ''' + @NPI + ''' ' + @CR
		set @sql = @sql + 'and BatchID = ''' + cast(@start_batchid as nvarchar(10)) + ''' ' + @CR
		exec(@sql)
	end

	set @sql = 'select @TempDiffbotEnd = count(*) ' + @CR

	if isnull(@diffbot_end_check, 0) = 0
	begin
		set @sql = 'insert #raw_data_end(DataDate, NPI, Diffbot, RepBrowser, SiteName, Volume, Rating) ' + @CR
		set @sql = @sql + 'select top 1 metric.LoadDate, media.NPI, 0, 1, metric.RatingsSite, metric.NumberOfRatings, metric.Rating ' + @CR
		set @sql = @sql + 'from [' + @Database + '].dbo.PhysMetReputationArchiveMedia media ' + @CR
		set @sql = @sql + 'inner join [' + @Database + '].dbo.PhysMetReputationArchive metric ' + @CR
		set @sql = @sql + 'on metric.XComboKey = media.XComboKey ' + @CR
		set @sql = @sql + 'where metric.RatingsSite = ''' + @RepSiteName + ''' ' + @CR
		set @sql = @sql + 'and media.NPI = ''' + @NPI + ''' ' + @CR
		set @sql = @sql + 'and metric.LoadDate between (select StartDate from #times) and (select EndDate from #times) ' + @CR
		set @sql = @sql + 'order by metric.LoadDate ' + @CR
		exec(@sql)
	end
	else
	begin
		set @sql = 'insert #raw_data_end(DataDate, NPI, Diffbot, RepBrowser, SiteName, Volume, Rating) ' + @CR
		set @sql = @sql + 'select max(cast(convert(varchar, SearchDate, 101) as datetime)), max(NPI), 1, 0, max(SiteName), max(ResultVolume), max(ResultRating) ' + @CR
		set @sql = @sql + 'from [' + @Database + '].dbo.DIFFBOT_ResultLinks ' + @CR
		set @sql = @sql + 'where SiteName = ''' + @SiteName + ''' ' + @CR
		set @sql = @sql + 'and NPI = ''' + @NPI + ''' ' + @CR
		set @sql = @sql + 'and BatchID <= ''' + cast(@end_batchid as nvarchar(10)) + ''' ' + @CR
		exec(@sql)
	end

	set @counter = @counter + 1
end

create table #mixed_data(NPI nvarchar(10), SiteName nvarchar(50), StartDate datetime, StartingVolume int, StartingRating decimal(2,1),
							EndDate datetime, EndingVolume int, EndingRating decimal(2,1))
insert		#mixed_data(NPI, SiteName, StartDate, StartingVolume, StartingRating, EndDate, EndingVolume, EndingRating)
select		s.NPI, s.SiteName, s.DataDate as StartDate, s.Volume StartingVoume, s.Rating StartingRating,
			e.DataDate as EndDate, e.Volume EndingVolume, e.Rating EndingRating
from		#raw_data_start s
left join	#raw_data_end e
on			e.NPI = s.NPI

update		#mixed_data
set			StartingVolume = null,
			StartingRating = null
where		StartingVolume = 0

update		#mixed_data
set			EndingVolume = null,
			EndingRating = null
where		EndingVolume = 0

set @sql = 'insert #mixed_data(NPI, SiteName, StartDate, StartingVolume, StartingRating, EndDate, EndingVolume, EndingRating) ' + @CR
set @sql = @sql + 'select NPI, null, null, null, null, null, null, null ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysicianMedia ' + @CR
set @sql = @sql + 'where Status = ''Active'' ' + @CR
set @sql = @sql + 'and NPI not in (select NPI from #mixed_data) ' + @CR
exec(@sql)

set @sql = 'select pm.FirstName, pm.LastName, pm.LastName + '', '' + pm.FirstName as FullName, m.*, ' + @CR
set @sql = @sql + 'm.EndingVolume - isnull(m.StartingVolume, 0) as VolumeDiff, m.EndingRating - isnull(m.StartingRating, 0) as RatingDiff ' + @CR
set @sql = @sql + 'from [' + @Database + '].dbo.PhysicianMedia pm ' + @CR
set @sql = @sql + 'inner join #mixed_data m ' + @CR
set @sql = @sql + 'on m.NPI = pm.NPI ' + @CR
set @sql = @sql + 'order by pm.LastName, pm.FirstName ' + @CR
exec(@sql)

drop table #npi
drop table #raw_data_start
drop table #raw_data_end
drop table #times