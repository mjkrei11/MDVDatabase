

CREATE procedure [dbo].[sp_ssrs_RepTrendingSuspectVolumes](
	@Database nvarchar(200),
	@Period nvarchar(30)
)

as

/*
declare
@Database nvarchar(200),
@Period nvarchar(30)

set @Database = '_ALL_'
set @Period = '_ALL_'

exec sp_ssrs_RepTrendingSuspectVolumes @Database, @Period
*/

declare
@counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #dbs(ID int identity, DbName nvarchar(200))

if @Database = '_ALL_'
begin
	insert		#dbs(DbName)
	select		distinct SystemDatabase
	from		MDVALUATE.dbo.SystemRecordsMedia
	where		IsClient = 'Yes'
	and			CustomerTerminatedDate is NULL

end
else
begin
	insert		#dbs(DbName)
	select		distinct SystemDatabase
	from		MDVALUATE.dbo.SystemRecordsMedia
	where		IsClient = 'Yes'
	and			CustomerTerminatedDate is NULL
	and			SystemDatabase = @Database
end

create table #report(
	SystemName nvarchar(200),
	Period nvarchar(30),
	BatchRange nvarchar(30),
	NPITrend nvarchar(30),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	StartDate nvarchar(10),
	EndDate nvarchar(10),
	StartBatchID int,
	EndBatchID int,
	SummarySite nvarchar(20),
	PreviousNoRatings int,
	PreviousNoComments int,
	PreviousAvgRating decimal(3,2),
	CurrentNoRatings int,
	CurrentNoComments int,
	CurrentAvgRating decimal(3,2),
	DeltaNoRatings int,
	DeltaNoComments int,
	DeltaAvgRating decimal(3,2),
	BatchID int,
	SearchDate nvarchar(10),
	ResultVolume int,
	ResultRating decimal(2,1),
	ResultLink nvarchar(4000)
)

set @counter = 1
while @counter <= (select max(ID) from #dbs)
begin
	select @Database = DbName from #dbs where ID = @counter

	set @sql = 'insert #report ' + @CR
	set @sql = @sql + 'select distinct media.SystemName, media.StartDate + '' - '' + media.EndDate as Period, ' + @CR
	set @sql = @sql + 'cast(media.StartBatchID as nvarchar(10)) + '' - '' + cast(media.EndBatchID as nvarchar(10)) as BatchRange, ' + @CR
	set @sql = @sql + 'media.NPITrend, media.NPI, media.FirstName, media.MiddleName, media.LastName, ' + @CR
	set @sql = @sql + 'media.StartDate, media.EndDate, media.StartBatchID, media.EndBatchID, ' + @CR
	set @sql = @sql + 'summary.SummarySite, summary.PreviousNoRatings, summary.PreviousNoComments, summary.PreviousAvgRating, ' + @CR
	set @sql = @sql + 'summary.CurrentNoRatings, summary.CurrentNoComments, summary.CurrentAvgRating, ' + @CR
	set @sql = @sql + 'summary.DeltaNoRatings, summary.DeltaNoComments, summary.DeltaAvgRating, r.BatchID, convert(varchar, r.SearchDate, 101) as SearchDate, r.ResultVolume, r.ResultRating, r.ResultLink ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia media ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.VIRepSummary summary ' + @CR
	set @sql = @sql + 'on summary.NPITrend = media.NPITrend ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.DIFFBOT_ResultLinks r ' + @CR
	set @sql = @sql + 'on r.NPI = media.NPI ' + @CR
	set @sql = @sql + 'and r.SiteName = summary.SummarySite ' + @CR
	set @sql = @sql + 'where (summary.DeltaNoRatings < 0 ' + @CR
	set @sql = @sql + 'or summary.DeltaNoRatings > 5) ' + @CR
	set @sql = @sql + 'and r.BatchID between (media.StartBatchID - 3) and media.EndBatchID ' + @CR
	set @sql = @sql + 'and summary.SummaryTab = ''Weekly'' ' + @CR
	if @Period <> '_ALL_'
	begin
		set @sql = @sql + 'and media.StartDate + '' - '' + media.EndDate = ''' + @Period + ''' ' + @CR
	end
	set @sql = @sql + 'order by EndBatchID desc, LastName, FirstName, SummarySite ' + @CR
	exec(@sql)

	set @counter = @counter + 1
end

select		*
from		#report
order by	EndBatchID desc, SystemName, LastName, FirstName, SummarySite

drop table #report
drop table #dbs


