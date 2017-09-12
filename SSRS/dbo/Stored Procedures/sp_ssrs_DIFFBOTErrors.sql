



CREATE procedure [dbo].[sp_ssrs_DIFFBOTErrors]--(@BatchID int)

as

--exec sp_ssrs_DIFFBOTErrors

declare
@BatchID int,
@previous_BatchID int,
@Database nvarchar(200),
@counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

select @BatchID = max(BatchID) from RepMgmt.dbo.DIFFBOT_WorkingLinks

if (select datepart(w, getdate())) > 2
begin
	select @previous_BatchID = @BatchID - 1
end
if (select datepart(w, getdate())) = 1 -- Sunday
begin
	select @previous_BatchID = @BatchID - 2
end
if (select datepart(w, getdate())) = 2 -- Monday
begin
	select @previous_BatchID = @BatchID - 3
end

create table #customer_ids(ID int identity, CustomerID nvarchar(10))
insert	#customer_ids(CustomerID)
select	distinct CustomerID from RepMgmt.dbo.DIFFBOT_WorkingLinks
where	BatchID = @BatchID

create table #dbs(ID int identity, CustomerID nvarchar(10), DbName nvarchar(200))
insert		#dbs(CustomerID, DbName)
select		distinct SystemID, SystemDatabase
from		MDVALUATE.dbo.SystemRecordsMedia srm
inner join	#customer_ids c
on			c.CustomerID = srm.SystemID
where		srm.IsClient = 'Yes'
and			srm.CustomerTerminatedDate is null

create table #client_info(CustomerID nvarchar(10), CustomerName nvarchar(200), NPI nvarchar(10), FirstName nvarchar(100), LastName nvarchar(100))

set @counter = 1
while @counter <= (select max(ID) from #dbs)
begin
	select @Database = DbName from #dbs where ID = @counter

	set @sql = 'insert #client_info ' + @CR
	set @sql = @sql + 'select id.CustomerID, id.CustomerSource, pm.NPI, pm.Firstname, pm.LastName ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID id ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia pm ' + @CR
	set @sql = @sql + 'on pm.NPI = id.NPI ' + @CR
	set @sql = @sql + 'where pm.Status = ''Active'' ' + @CR
	set @sql = @sql + 'Union' + @CR
	set @sql = @sql + 'select SystemID, SystemName, NPI, PracticeName, '''' ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PracticeRepTrendMedia ' + @CR
	set @sql = @sql + 'where Status = ''Active'' ' + @CR
	print @sql
	exec(@sql)

	set @counter = @counter + 1
end



create table #errors(WorkingKey uniqueidentifier, SourceKey uniqueidentifier, CustomerID nvarchar(10), NPI nvarchar(10), SiteName nvarchar(50),
						ResultLink nvarchar(4000), PreviousResultRating decimal(2,1), PreviousResultVolume int, SearchDate datetime, BatchID int)

insert		#errors(CustomerID, NPI, SiteName, ResultLink, PreviousResultRating, PreviousResultVolume, BatchID)
select		distinct c.CustomerID, c.NPI, r.SiteName, r.ResultLink, r.ResultRating, r.ResultVolume, @BatchID as BatchID
from		RepMgmt.dbo.DIFFBOT_ResultLinks r
inner join	#client_info c
on			c.CustomerID = r.CustomerID
and			c.NPI = r.NPI
left join	RepMgmt.dbo.DIFFBOT_WorkingLinks w
on			w.WorkingLink = r.ResultLink
and			w.BatchID = r.BatchID
and			w.NPI = r.NPI
--inner join RepMgmt.dbo.DIFFBOT_Linkpairs l
--on			l.sourcelink = r.ResultLink
where		r.BatchID = @previous_BatchID
and			replace(r.ResultLink, 'http://', 'https://') not in
(
	select		replace(ResultLink, 'http://', 'https://')
	from		RepMgmt.dbo.DIFFBOT_ResultLinks
	where		BatchID = @BatchID
)
--and			r.ResultLink in (select ResultLink from RepMgmt.dbo.DIFFBOT_Linkpairs l)
--group by	w.SourceKey, r.CustomerID, r.NPI, r.SiteName, r.ResultLink,
--			r.ResultRating, r.ResultVolume, r.SearchDate, r.BatchID
--order by	r.SiteName, r.CustomerID, r.NPI, ResultLink

update		e
set			e.WorkingKey = w.WorkingKey,
			e.SourceKey = w.SourceKey,
			e.SearchDate = w.WorkingDate
from		#errors e
inner join	RepMgmt.dbo.DIFFBOT_WorkingLinks w
on			w.NPI = e.NPI
and			replace(w.WorkingLink, 'http://', 'https://') = e.ResultLink
where		w.BatchID = @BatchID

update		#errors
set			WorkingKey = newid()
where		WorkingKey is null

update		#errors
set			SourceKey = newid()
where		SourceKey is null

update		#errors
set			SearchDate = (select top 1 SearchDate from #errors where SearchDate is not null)
where		SearchDate is null

select		*
from		#errors
order by	SiteName, CustomerID, NPI, ResultLink

drop table #customer_ids
drop table #dbs
drop table #client_info


