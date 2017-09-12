create procedure sp_ssrs_DIFFBOT_QA_Checks
(
	@EndBatchID int
,	@result_set int
)

as

/*
declare
@EndBatchID int = null,
@result_set int = 1

exec sp_ssrs_DIFFBOT_QA_Checks @EndBatchID, @result_set
*/

declare
@Database nvarchar(255),
@BatchEndDate datetime,
@StartBatchID int,
@BatchStartDate datetime,
@CustomerID nvarchar(10),@CustomerSource nvarchar(255),@sql nvarchar(max),@parms nvarchar(max),@CR char(1),
@counter int

set @CR = char(13)

if @EndBatchID is null
begin
	select @EndBatchID = max(BatchID) from RepMgmt.dbo.DIFFBOT_ResultLinks
end

select @BatchEndDate = cast(convert(varchar, max(SearchDate), 101) as datetime) + 1 from RepMgmt.dbo.DIFFBOT_ResultLinks where BatchID = @EndBatchID
set @StartBatchID = @EndBatchID - 6
set @BatchStartDate = @BatchEndDate - 7

create table #dates(ID int identity, StartDate datetime, EndDate datetime)
insert #dates(StartDate, EndDate) values(@BatchStartDate, @BatchEndDate)

--select @EndBatchID, @BatchEndDate, @StartBatchID, @BatchStartDate

create table #dbs
(
	ID int identity
,	DbName nvarchar(255)
)

insert #dbs(DbName)
select		SystemDatabase
from		MDVALUATE.dbo.SystemRecordsMedia
where		IsClient = 'Yes'
and			CustomerTerminatedDate is null
and			SystemDatabase is not null
order by	SystemDatabase

create table #date_outside_range
(
	ID int identity
,	DbName nvarchar(255)
,	WorkingKey uniqueidentifier
,	PrimaryCustomerSource nvarchar(510)
,	NPI nvarchar(10)
,	SiteName nvarchar(50)
,	ResultLink nvarchar(4000)
,	ResultRating decimal(2,1)
,	ResultVolume int
,	SearchDate datetime
,	BatchID int
,	RawResultKey uniqueidentifier
)

create table #comments_for_period
(
	ID int identity
,	DbName nvarchar(255)
,	NPI nvarchar(10)
,	FirstName nvarchar(255)
,	LastName nvarchar(255)
,	PrimaryCustomerSource nvarchar(510)
,	SiteName nvarchar(50)
,	CommentDate datetime
,	BatchID int
,	CommentText nvarchar(max)
,	IsNegative bit
,	CommentKey uniqueidentifier
,	ResultLink nvarchar(4000)
)set @counter = 1while @counter <= (select max(ID) from #dbs)begin	select @Database = DbName from #dbs where ID = @counter	set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR	set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'	set @parms = '@TempCustomerSource nvarchar(255) output, @TempCustomerID nvarchar(10) output'	exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output	if @result_set = 1	begin		set @sql = 'insert #date_outside_range(DbName, WorkingKey, PrimaryCustomerSource, NPI, SiteName, ResultLink, ResultRating, ResultVolume, SearchDate, BatchID, RawResultKey)  ' + @CR		set @sql = @sql + 'select ''' + @Database + ''', WorkingKey, ''' + @CustomerSource + ''', NPI, SiteName, ResultLink, ResultRating, ResultVolume, SearchDate, BatchID, RawResultKey ' + @CR		set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR		set @sql = @sql + 'where BatchID between ''' + cast(@StartBatchID as nvarchar(10)) + ''' and ''' + cast(@EndBatchID as nvarchar(10)) + ''' ' + @CR		set @sql = @sql + 'and SearchDate not between (select StartDate from #dates) and (select EndDate from #dates) ' + @CR		exec(@sql)	end	if @result_set = 2	begin		set @sql = 'insert #comments_for_period(DbName, NPI, FirstName, LastName, PrimaryCustomerSource, SiteName, CommentDate, BatchID, COmmentText, IsNegative, CommentKey, ResultLink) ' + @CR		set @sql = @sql + 'select ''' + @Database + ''', a.npi, b.firstname, b.lastname, b.primarycustomersource, a.sitename, a.commentdate, a.batchid, a.CommentText, a.IsNegative, a.CommentKey, c.resultlink ' + @CR		set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_Comments a ' + @CR		set @sql = @sql + 'inner join mdvaluate.dbo.masterphysicianmedia b on a.npi=b.npi ' + @CR		set @sql = @sql + 'inner join ' + @Database + '.dbo.DIFFBOT_ResultLinks c on a.workingkey = c.workingkey ' + @CR		set @sql = @sql + 'where a.batchid between ''' + cast(@StartBatchID as nvarchar(10)) + ''' and ''' + cast(@EndBatchID as nvarchar(10)) + ''' and b.status = ''active'' ' + @CR		set @sql = @sql + 'and a.CommentDate > dateadd (day,-15,(select StartDate from #dates)) ' + @CR		set @sql = @sql + 'and a.searchdate < (select EndDate from #dates) ' + @CR		set @sql = @sql + 'Order by b.primarycustomersource, b.lastname, a.Sitename, a.commenttext, a.commentdate ' + @CR		exec(@sql)	end	set @counter = @counter + 1endif @result_set = 1begin	select * from #date_outside_rangeendif @result_set = 2begin	select * from #comments_for_period
end

drop table #dates
drop table #dbs
drop table #date_outside_range
drop table #comments_for_period