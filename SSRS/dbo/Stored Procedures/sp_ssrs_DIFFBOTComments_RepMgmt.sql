



CREATE procedure [dbo].[sp_ssrs_DIFFBOTComments_RepMgmt](
	@BatchID int
)

as

/*
declare
@BatchID int
set @BatchID = null

exec sp_ssrs_DIFFBOTComments_RepMgmt @BatchID
*/

declare
@Database nvarchar(200),
@LastBatchID int,
@CurrentDate datetime,
@LastDate datetime,
@counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

if @BatchID is null
begin
	select @BatchID = max(BatchID) from RepMgmt.dbo.DIFFBOT_Comments
end

create table #prev_comments(
	CustomerID nvarchar(10),
	NPI nvarchar(10),
	SiteName nvarchar(50),
	CommentText nvarchar(max)
)

insert	#prev_comments(CustomerID, NPI, SiteName, CommentText)
select	distinct CustomerID, NPI, SiteName, CommentText
from	RepMgmt.dbo.DIFFBOT_Comments
where	BatchID < @BatchID

create table #comments(
	DbName nvarchar(200),
	CustomerID nvarchar(10),
	Customer nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(100),
	MiddleName nvarchar(100),
	LastName nvarchar(100),
	SiteName nvarchar(50),
	CommentDate datetime,
	CommentRating nvarchar(max),
	CommentText nvarchar(max),
	CommentKey uniqueidentifier,
	SearchDate datetime,
	ResultLink nvarchar(max)
)

insert		#comments
select		distinct s.SystemDatabase, s.SystemID, s.SystemName, m.NPI, m.FirstName, m.MiddleName, m.LastName,
			c.SiteName, min(cast(convert(varchar, c.CommentDate, 101) as datetime)), min(c.CommentRating), c.CommentText, null, min(c.SearchDate), min(r.ResultLink)
from		MDVALUATE.dbo.SystemRecordsMedia s
inner join	MDVALUATE.dbo.MasterPhysicianMedia m
on			m.PrimaryCustomerID = s.SystemID
inner join	RepMgmt.dbo.DIFFBOT_Comments c
on			c.NPI = m.NPI
and			c.CustomerID = s.SystemID
inner join	RepMgmt.dbo.DIFFBOT_ResultLinks r
on			r.SourceKey = c.SourceKey
where		m.Status = 'Active'
and			s.IsClient = 'Yes'
and			s.CustomerTerminatedDate is null
and			c.BatchID = @BatchID
and			cast(convert(varchar, CommentDate, 101) as datetime) >= cast(convert(varchar, getdate() - 30, 101) as datetime)
and			cast(convert(varchar, CommentDate, 101) as datetime) <= cast(convert(varchar, getdate(), 101) as datetime)
and			cast(convert(varchar, c.SearchDate, 101) as datetime) = cast(convert(varchar, getdate() - 1, 101) as datetime)
group by	s.SystemDatabase, s.SystemID, s.SystemName, m.NPI, m.FirstName, m.MiddleName, m.LastName, c.SiteName, c.CommentText

delete		c
from		#comments c
inner join	#prev_comments p
on			p.CustomerID = c.CustomerID
and			p.NPI = c.NPI
and			p.CommentText = c.CommentText

update		c
set			c.CommentKey = d.CommentKey
from		#comments c
inner join	RepMgmt.dbo.DIFFBOT_Comments d
on			d.CommentText = c.CommentText
and			d.NPI = c.NPI
and			d.SiteName = c.SiteName
where		d.BatchID = @BatchID

select distinct * from #comments

drop table #comments
drop table #prev_comments