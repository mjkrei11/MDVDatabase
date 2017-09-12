





CREATE procedure [dbo].[sp_ssrs_DIFFBOTDiffReport_byPeriod](
	@Database nvarchar(200),
	@StartingPeriod nvarchar(30),
	@EndingPeriod nvarchar(30)
)

as

/*
declare
@Database nvarchar(200),
@StartingPeriod nvarchar(30),
@EndingPeriod nvarchar(30)
select
@Database = 'twincities',
@StartingPeriod = '_PREVIOUS_',
@EndingPeriod = '_CURRENT_'

exec sp_ssrs_DIFFBOTDiffReport_byPeriod @Database, @StartingPeriod, @EndingPeriod
*/

declare
@CurrentDate datetime,
@LastDate datetime,
@MinDate nvarchar(10),
@MaxDate nvarchar(10),
@StartBatchID int,
@EndBatchID int,
@MaxBatchID int,
@counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #starting_batches (ID int identity, BatchID int, BatchDate nvarchar(10))
create table #ending_batches (ID int identity, BatchID int, BatchDate nvarchar(10))

create table #last_rep(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	RatingsSite nvarchar(200),
	Rating float,
	Volume int,
	SearchDate datetime,
	ResultLink nvarchar(4000),
	BatchID int,
	TotalComments int,
	NegativeComments int
)

create table #current_rep(
	CustomerID nvarchar(10),
	Customer nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	RatingsSite nvarchar(200),
	Rating float,
	Volume int,
	SearchDate datetime,
	ResultLink nvarchar(4000),
	BatchID int,
	TotalComments int,
	NegativeComments int
)

create table #customer_ids(ID int identity, CustomerID nvarchar(10))
insert	#customer_ids(CustomerID)
select	distinct CustomerID from RepMgmt.dbo.DIFFBOT_WorkingLinks

create table #dbs(ID int identity, CustomerID nvarchar(10), DbName nvarchar(200))

if @Database = '_ALL_'
begin
	insert		#dbs(CustomerID, DbName)
	select		distinct SystemID, SystemDatabase
	from		MDVALUATE.dbo.SystemRecordsMedia srm
	inner join	#customer_ids c
	on			c.CustomerID = srm.SystemID
	where		srm.IsClient = 'Yes'
	and			srm.SystemDatabase is not null
	and			srm.CustomerTerminatedDate is null
end
else
begin
	insert		#dbs(CustomerID, DbName)
	select		distinct SystemID, SystemDatabase
	from		MDVALUATE.dbo.SystemRecordsMedia srm
	inner join	#customer_ids c
	on			c.CustomerID = srm.SystemID
	where		SystemDatabase = @Database
	and			srm.IsClient = 'Yes'
	and			srm.SystemDatabase is not null
	and			srm.CustomerTerminatedDate is null
end

set @counter = 1
while @counter <= (select max(ID) from #dbs)
begin
	select @Database = DbName from #dbs where ID = @counter

	if @EndingPeriod = '_CURRENT_'
	begin
		set @sql = 'select top 1 @TempMaxDate = max(EndDate) ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia ' + @CR
		set @parms = '@TempMaxDate nvarchar(30) output'
		exec sp_executesql @sql, @parms, @TempMaxDate = @MaxDate output

		if @MaxDate = convert(varchar, getdate() - 1, 101)
		begin
			set @sql = 'select top 1 @TempEndingPeriod = StartDate + '' - '' + EndDate ' + @CR
			set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia ' + @CR
			set @sql = @sql + 'order by EndBatchID desc ' + @CR
			set @parms = '@TempEndingPeriod nvarchar(30) output'
			exec sp_executesql @sql, @parms, @TempEndingPeriod = @EndingPeriod output

			set @sql = 'insert #ending_batches(BatchID, BatchDate) ' + @CR
			set @sql = @sql + 'select distinct metric.RepTrendBatchID, convert(varchar, metric.RepTrendDate, 101) ' + @CR
			set @sql = @sql + 'from ' + @Database + '.dbo.VIRepTrend metric ' + @CR
			set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysVRepTrendMedia media ' + @CR
			set @sql = @sql + 'on media.NPITrend = metric.NPITrend ' + @CR
			set @sql = @sql + 'where media.StartDate + '' - '' + media.EndDate = ''' + @EndingPeriod + ''' ' + @CR
			set @sql = @sql + 'and metric.RepTrendTab = ''Weekly'' ' + @CR
			exec(@sql)
		end
		else
		begin
			set @sql = 'select top 1 @TempEndBatchID = max(EndBatchID) ' + @CR
			set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia ' + @CR
			set @parms = '@TempEndBatchID int output'
			exec sp_executesql @sql, @parms, @TempEndBatchID = @MaxBatchID output

			set @sql = 'insert #ending_batches(BatchID, BatchDate) ' + @CR
			set @sql = @sql + 'select distinct BatchID, convert(varchar, SearchDate, 101) ' + @CR
			set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
			set @sql = @sql + 'where BatchID > ''' + cast(@MaxBatchID as nvarchar(10)) + ''' ' + @CR
			exec(@sql)
		end
	end
	else
	begin
		set @sql = 'insert #ending_batches(BatchID, BatchDate) ' + @CR
		set @sql = @sql + 'select distinct metric.RepTrendBatchID, convert(varchar, metric.RepTrendDate, 101) ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.VIRepTrend metric ' + @CR
		set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysVRepTrendMedia media ' + @CR
		set @sql = @sql + 'on media.NPITrend = metric.NPITrend ' + @CR
		set @sql = @sql + 'where media.StartDate + '' - '' + media.EndDate = ''' + @EndingPeriod + ''' ' + @CR
		set @sql = @sql + 'and metric.RepTrendTab = ''Weekly'' ' + @CR
		exec(@sql)
	end

	if @StartingPeriod = '_PREVIOUS_'
	begin
		if @EndingPeriod = '_CURRENT_'
		begin
			set @sql = 'select top 1 @TempStartingPeriod = StartDate + '' - '' + EndDate ' + @CR
			set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia ' + @CR
			set @sql = @sql + 'order by EndBatchID desc ' + @CR
			set @parms = '@TempStartingPeriod nvarchar(30) output'
			exec sp_executesql @sql, @parms, @TempStartingPeriod = @StartingPeriod output
		end
		else
		begin
			set @sql = 'select top 1 @TempStartingPeriod = StartDate + '' - '' + EndDate ' + @CR
			set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia ' + @CR
			set @sql = @sql + 'where StartDate + '' - '' + EndDate < ''' + @EndingPeriod + ''' ' + @CR
			set @sql = @sql + 'order by StartDate desc ' + @CR
			set @parms = '@TempStartingPeriod nvarchar(30) output'
			exec sp_executesql @sql, @parms, @TempStartingPeriod = @StartingPeriod output
		end
	end

	set @sql = 'select top 1 @TempStartBatchID = StartBatchID ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia ' + @CR
	set @sql = @sql + 'where StartDate + '' - '' + EndDate = ''' + @StartingPeriod + ''' ' + @CR
	set @parms = '@TempStartBatchID int output'
	exec sp_executesql @sql, @parms, @TempStartBatchID = @StartBatchID output

	set @sql = 'insert #starting_batches(BatchID, BatchDate) ' + @CR
	set @sql = @sql + 'select distinct metric.RepTrendBatchID, convert(varchar, metric.RepTrendDate, 101) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.VIRepTrend metric ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysVRepTrendMedia media ' + @CR
	set @sql = @sql + 'on media.NPITrend = metric.NPITrend ' + @CR
	set @sql = @sql + 'where media.StartDate + '' - '' + media.EndDate = ''' + @StartingPeriod + ''' ' + @CR
	set @sql = @sql + 'and metric.RepTrendTab = ''Weekly'' ' + @CR
	exec(@sql)

	select @StartBatchID = max(BatchID) from #starting_batches
	select @EndBatchID = max(BatchID) from #ending_batches

	set @sql = 'insert #last_rep ' + @CR
	set @sql = @sql + 'select distinct media.NPI, media.FirstName, media.LastName, r.SiteName, ' + @CR
	set @sql = @sql + 'r.ResultRating, r.ResultVolume, r.SearchDate, r.ResultLink, r.BatchID, ' + @CR
	set @sql = @sql + '(select count(distinct c.CommentText) from ' + @Database + '.dbo.DIFFBOT_Comments c where convert(varchar, c.CommentDate, 101) in (select BatchDate from #starting_batches)  ' + @CR
	set @sql = @sql + 'and c.CommentText is not null and c.CommentText <> ''show details'' and len(c.CommentText) > 3 and c.WorkingKey = r.WorkingKey), ' + @CR
	set @sql = @sql + '(select count(distinct c.CommentText) from ' + @Database + '.dbo.DIFFBOT_Comments c where convert(varchar, c.CommentDate, 101) in (select BatchDate from #starting_batches) ' + @CR
	set @sql = @sql + 'and c.CommentText is not null and c.CommentText <> ''show details'' and len(c.CommentText) > 3 ' + @CR
	set @sql = @sql + 'and c.IsNegative = 1 and c.WorkingKey = r.WorkingKey) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia media ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.DIFFBOT_ResultLinks r ' + @CR
	set @sql = @sql + 'on r.NPI = media.NPI ' + @CR
	set @sql = @sql + 'where r.BatchID = ''' + cast(@StartBatchID as nvarchar(10)) + ''' '
	exec(@sql)

	set @sql = 'insert #current_rep ' + @CR
	set @sql = @sql + 'select distinct id.CustomerID, id.CustomerSource, media.NPI, media.FirstName, ' + @CR
	set @sql = @sql + 'media.LastName, r.SiteName, r.ResultRating, r.ResultVolume, r.SearchDate, r.ResultLink, r.BatchID, ' + @CR
	set @sql = @sql + '(select count(distinct c.CommentText) from ' + @Database + '.dbo.DIFFBOT_Comments c where convert(varchar, c.CommentDate, 101) in (select BatchDate from #ending_batches) ' + @CR
	set @sql = @sql + 'and c.CommentText is not null and c.CommentText <> ''show details'' and len(c.CommentText) > 3 and c.WorkingKey = r.WorkingKey), ' + @CR
	set @sql = @sql + '(select count(distinct c.CommentText) from ' + @Database + '.dbo.DIFFBOT_Comments c where convert(varchar, c.CommentDate, 101) in (select BatchDate from #ending_batches) ' + @CR
	set @sql = @sql + 'and c.CommentText is not null and c.CommentText <> ''show details'' and len(c.CommentText) > 3 ' + @CR
	set @sql = @sql + 'and c.IsNegative = 1 and c.WorkingKey = r.WorkingKey) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia media ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysCustomerID id ' + @CR
	set @sql = @sql + 'on id.NPI = media.NPI ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.DIFFBOT_ResultLinks r ' + @CR
	set @sql = @sql + 'on r.NPI = media.NPI ' + @CR
	set @sql = @sql + 'where r.BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''' '
	set @sql = @sql + 'and media.Status = ''Active'' '
	exec(@sql)

	set @counter = @counter + 1
end

select		distinct d.CustomerID, d.Customer, r.NPI, r.FirstName, r.LastName, r.RatingsSite, r.Rating as PreviousRating,
			r.Volume as PreviousVolume, r.TotalComments as PreviousTotalComments, r.NegativeComments as PreviousNegativeComments,
			d.TotalComments as CurrentTotalComments, d.NegativeComments as CurrentNegativeComments, d.Rating as CurrentRating, d.Volume as CurrentVolume,
			convert(varchar, r.SearchDate, 101) as PreviousSearchDate, convert(varchar, d.SearchDate, 101) as CurrentSearchDate, d.ResultLink
--from		#last_rep r
--left join	#current_rep d
from		#current_rep d
left join	#last_rep r
on			d.NPI = r.NPI
and			d.RatingsSite = r.RatingsSite
and			d.ResultLink = r.ResultLink
--where		(d.Rating <> r.Rating
--or			d.Volume <> r.Volume)
order by	Customer, LastName, FirstName, RatingsSite

drop table #last_rep
drop table #current_rep
drop table #starting_batches
drop table #ending_batches
drop table #customer_ids
drop table #dbs




