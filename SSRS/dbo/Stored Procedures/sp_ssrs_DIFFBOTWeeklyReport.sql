
CREATE procedure [dbo].[sp_ssrs_DIFFBOTWeeklyReport] (
	@Database nvarchar(200),
	@BenchmarkDate datetime,
	@RatingsSite nvarchar(200)
)

as

/*
declare
@Database nvarchar(200) = 'Rothman',
@BenchmarkDate datetime = '2015-06-06',
@RatingsSite nvarchar(200) = 'HealthGrades'

exec sp_ssrs_DIFFBOTWeeklyReport @Database, @BenchmarkDate, @RatingsSite
*/

declare
@CustomerID nvarchar(50),
@CustomerSource nvarchar(120),
@LoadDate datetime,
@BatchID int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

set @sql = 'select top 1 @TempLoadDate = metric.LoadDate ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationArchive metric ' + @CR
set @sql = @sql + 'on metric.XComboKey = media.XComboKey ' + @CR
set @sql = @sql + 'where media.SystemID = media.CollectionID ' + @CR
set @sql = @sql + 'and metric.LoadDate <= ''' + cast(@BenchmarkDate as nvarchar(20)) + ''' ' + @CR
set @sql = @sql + 'and metric.RatingsSite = ''' + @RatingsSite + ''' ' + @CR
set @sql = @sql + 'order by metric.LoadDate desc ' + @CR
set @parms = '@TempLoadDate datetime output'
exec sp_executesql @sql, @parms, @TempLoadDate = @LoadDate output

set @sql = 'select @TempBatchID = max(BatchID) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks'
set @parms = '@TempBatchID int output'
exec sp_executesql @sql, @parms, @TempBatchID = @BatchID output

create table #npi (ID int identity, NPI nvarchar(10))
create table #archive_data (NPI nvarchar(10), LastName nvarchar(200), FirstName nvarchar(200), RatingsSite nvarchar(50), Rating decimal(2,1), Volume int, BaselineDate datetime)
create table #remaining_npi (ID int identity, NPI nvarchar(10))
create table #remaining_npi_batch (ID int identity, NPI nvarchar(10), BatchID int)
create table #remaining_data (NPI nvarchar(10), LastName nvarchar(200), FirstName nvarchar(200), RatingsSite nvarchar(50), Rating decimal(2,1), Volume int, BaselineDate datetime)
create table #master_initial_data (NPI nvarchar(10), LastName nvarchar(200), FirstName nvarchar(200), RatingsSite nvarchar(50), Rating decimal(2,1), Volume int, BaselineDate datetime)
create table #diffbot (NPI nvarchar(10), Rating decimal(2,1), Volume int, SearchDate datetime)
create table #master_final_data (
	NPI nvarchar(10),
	LastName nvarchar(200),
	FirstName nvarchar(200),
	SiteName nvarchar(50),
	BaselineDate datetime,
	BaselineRating decimal(2,1),
	CurrentRating decimal(2,1),
	RatingDifference decimal(2,1),
	BaselineVolume int,
	CurrentVolume int,
	VolumeImprovement int
)

set @sql = 'insert #npi(NPI) ' + @CR
set @sql = @sql + 'select distinct NPI ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia ' + @CR
set @sql = @sql + 'where Status = ''Active'' ' + @CR
exec(@sql)

set @sql = 'insert #archive_data ' + @CR
set @sql = @sql + 'select media.NPI, media.LastName, media.FirstName, metric.RatingsSite, ' + @CR
set @sql = @sql + 'case when cast(metric.Rating as decimal(2,1)) = 0.0 then null else cast(metric.Rating as decimal(2,1)) end , metric.NumberOfRatings, ''' + cast(@BenchmarkDate as nvarchar(20)) + ''' ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationArchive metric ' + @CR
set @sql = @sql + 'on metric.XComboKey = media.XComboKey ' + @CR
set @sql = @sql + 'inner join #npi n ' + @CR
set @sql = @sql + 'on n.NPI = media.NPI ' + @CR
set @sql = @sql + 'where media.SystemID = media.CollectionID ' + @CR
set @sql = @sql + 'and metric.LoadDate = ''' + cast(@LoadDate as nvarchar(20)) + ''' ' + @CR
set @sql = @sql + 'and metric.RatingsSite = ''' + @RatingsSite + ''' ' + @CR
exec(@sql)

insert #remaining_npi select distinct NPI from #npi where NPI not in (select NPI from #archive_data)

set @sql = 'insert #remaining_npi_batch(NPI, BatchID) ' + @CR
set @sql = @sql + 'select r.NPI, min(d.BatchID) ' + @CR
set @sql = @sql + 'from #remaining_npi r ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.DIFFBOT_ResultLinks d ' + @CR
set @sql = @sql + 'on d.NPI = r.NPI ' + @CR
set @sql = @sql + 'where d.SiteName = ''' + @RatingsSite + ''' ' + @CR
set @sql = @sql + 'and d.BatchID > 0 ' + @CR
set @sql = @sql + 'group by r.NPI ' + @CR
exec(@sql)

set @sql = 'insert #remaining_data ' + @CR
set @sql = @sql + 'select distinct pm.NPI, pm.LastName, pm.FirstName, d.SiteName, ' + @CR
set @sql = @sql + 'cast(d.ResultRating as decimal(2,1)), d.ResultVolume, convert(varchar, d.SearchDate, 101) ' + @CR
set @sql = @sql + 'from #remaining_npi n ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia pm ' + @CR
set @sql = @sql + 'on pm.NPI = n.NPI ' + @CR
set @sql = @sql + 'left join #remaining_npi_batch r ' + @CR
set @sql = @sql + 'on r.NPI = n.NPI ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.DIFFBOT_ResultLinks d ' + @CR
set @sql = @sql + 'on d.NPI = r.NPI ' + @CR
set @sql = @sql + 'and d.BatchID = r.BatchID ' + @CR
set @sql = @sql + 'and d.SiteName = ''' + @RatingsSite + ''' ' + @CR
exec(@sql)

insert	#master_initial_data
select	*
from	#archive_data
union
select	*
from	#remaining_data

set @sql = 'insert #diffbot ' + @CR
set @sql = @sql + 'select distinct m.NPI, d.ResultRating, d.ResultVolume, d.SearchDate ' + @CR
set @sql = @sql + 'from #master_initial_data m ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.DIFFBOT_ResultLinks d ' + @CR
set @sql = @sql + 'on m.NPI = d.NPI ' + @CR
set @sql = @sql + 'where d.BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
set @sql = @sql + 'and d.SiteName = ''' + @RatingsSite + ''' ' + @CR
exec(@sql)

insert		#master_final_data
select		distinct m.NPI, m.LastName, m.FirstName, m.RatingsSite, m.BaselineDate,
			--isnull(m.Rating, 0.0), isnull(d.Rating, 0.0), isnull(d.Rating - m.Rating, 0.0), isnull(m.Volume, 0), isnull(d.Volume, 0), isnull(d.Volume - m.Volume, 0)
			m.Rating, d.Rating, d.Rating - isnull(m.Rating, 0.0), m.Volume, d.Volume, d.Volume - isnull(m.Volume, 0)
from		#master_initial_data m
left join	#diffbot d
on			d.NPI = m.NPI

select		*
from		#master_final_data
order by	LastName, FirstName

drop table #npi
drop table #archive_data
drop table #remaining_npi
drop table #remaining_npi_batch
drop table #remaining_data
drop table #master_initial_data
drop table #diffbot
drop table #master_final_data
