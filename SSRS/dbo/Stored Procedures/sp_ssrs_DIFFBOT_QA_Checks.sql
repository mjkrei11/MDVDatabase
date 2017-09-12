﻿create procedure sp_ssrs_DIFFBOT_QA_Checks
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
@CustomerID nvarchar(10),
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
)
end

drop table #dates
drop table #dbs
drop table #date_outside_range
drop table #comments_for_period