CREATE procedure [dbo].[sp_ssrs_RatingsProgressBySite](	@Database nvarchar(200),	@SiteName nvarchar(50),	@StartDate datetime,	@EndDate datetime)as/*declare@Database nvarchar(200) = 'Rothman',@SiteName nvarchar(50) = 'HealthGrades',@StartDate datetime = '2015-05-01',@EndDate datetime = '2016-04-29'exec sp_ssrs_RatingsProgressBySite @Database, @SiteName, @StartDate, @EndDate*/declare@CustomerID nvarchar(50),@CustomerSource nvarchar(120),@NPI nvarchar(10),@counter int,@start_batchid int,@end_batchid int,@diffbot_start_check int,@diffbot_end_check int,@rep_start_check int,@rep_end_check int,@RepSiteName nvarchar(50),@sql nvarchar(max),@parms nvarchar(max),@CR char(1)set @CR = char(13)/*set @sql = ' ' + @CRset @sql = @sql + ' ' + @CRexec(@sql)*/select @RepSiteName = case when @SiteName = 'RateMDs' then 'Rate MD Secure' else @SiteName endcreate table #times(ID int identity, StartDate datetime, EndDate datetime)insert		#times(StartDate, EndDate)select		@StartDate, @EndDateset @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CRset @sql = @sql + 'from [' + @Database + '].dbo.PhysCustomerID'set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID outputset @sql = 'select top 1 @TempBatchID = BatchID ' + @CRset @sql = @sql + 'from [' + @Database + '].dbo.DIFFBOT_ResultLinks ' + @CRset @sql = @sql + 'where cast(convert(varchar, SearchDate, 101) as datetime) <= (select StartDate from #times) ' + @CRset @sql = @sql + 'and BatchID > 0 ' + @CRset @sql = @sql + 'order by SearchDate desc ' + @CRset @parms = '@TempBatchID int output'exec sp_executesql @sql, @parms, @TempBatchID = @start_batchid outputset @sql = 'select top 1 @TempBatchID = BatchID ' + @CRset @sql = @sql + 'from [' + @Database + '].dbo.DIFFBOT_ResultLinks ' + @CRset @sql = @sql + 'where cast(convert(varchar, SearchDate, 101) as datetime) <= (select EndDate from #times) ' + @CRset @sql = @sql + 'and BatchID > 0 ' + @CRset @sql = @sql + 'order by SearchDate desc ' + @CRset @parms = '@TempBatchID int output'exec sp_executesql @sql, @parms, @TempBatchID = @end_batchid outputcreate table #npi(ID int identity, NPI nvarchar(10))set @sql = 'insert #npi(NPI) ' + @CRset @sql = @sql + 'select NPI ' + @CRset @sql = @sql + 'from [' + @Database + '].dbo.PhysicianMedia ' + @CRset @sql = @sql + 'where Status = ''Active'' ' + @CRexec(@sql)

create table #raw_data_start(ID int identity, DataDate datetime, NPI nvarchar(10), Diffbot int, RepBrowser int, SiteName nvarchar(50), Volume int, Rating decimal(2,1))
create table #raw_data_end(ID int identity, DataDate datetime, NPI nvarchar(10), Diffbot int, RepBrowser int, SiteName nvarchar(50), Volume int, Rating decimal(2,1))

set @counter = 1
while @counter <= (select max(ID) from #NPI)
begin
	select @NPI = NPI from #npi where ID = @counter

	set @sql = 'select @TempDiffbotStart = count(*) ' + @CR	set @sql = @sql + 'from [' + @Database + '].dbo.DIFFBOT_ResultLinks ' + @CR	set @sql = @sql + 'where NPI = ''' + @NPI + ''' ' + @CR	set @sql = @sql + 'and BatchID = ''' + cast(@start_batchid as nvarchar(10)) + ''' ' + @CR	set @sql = @sql + 'and SiteName = ''' + @SiteName + ''' ' + @CR	set @parms = '@TempDiffbotStart int output'	exec sp_executesql @sql, @parms, @TempDiffbotStart = @diffbot_start_check output

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

	set @sql = 'select @TempDiffbotEnd = count(*) ' + @CR	set @sql = @sql + 'from [' + @Database + '].dbo.DIFFBOT_ResultLinks ' + @CR	set @sql = @sql + 'where NPI = ''' + @NPI + ''' ' + @CR	set @sql = @sql + 'and BatchID = ''' + cast(@end_batchid as nvarchar(10)) + ''' ' + @CR	set @sql = @sql + 'and SiteName = ''' + @SiteName + ''' ' + @CR	set @parms = '@TempDiffbotEnd int output'	exec sp_executesql @sql, @parms, @TempDiffbotEnd = @diffbot_end_check output

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