CREATE procedure [dbo].[sp_ssrs_DIFFBOTMissingRatings](
	@Database nvarchar(200),
	@BatchID nvarchar(20)
)

as

/*
declare
@Database nvarchar(200),
@BatchID nvarchar(20)
set @Database = '_ALL_'
set @BatchID = '9999999999_ALL_'

exec sp_ssrs_DIFFBOTMissingRatings @Database, @BatchID
*/

declare
@PreviousBatch int,
@SearchDate nvarchar(20)

if @BatchID = '9999999999_ALL_'
begin
	select @BatchID = max(BatchID) from RepMgmt.dbo.DIFFBOT_WorkingLinks
end

select @PreviousBatch = @BatchID - 1
select @SearchDate = convert(varchar, min(WorkingDate), 101) from RepMgmt.dbo.DIFFBOT_WorkingLinks where BatchID = @BatchID

create table #client_dbs(
	ID int identity,
	CustomerID nvarchar(10),
	DbName nvarchar(200)
)

if @Database is not null
begin
	insert		#client_dbs(CustomerID, DbName)
	select		SystemID, SystemDatabase
	from		MDVALUATE.dbo.SystemRecordsMedia
	where		SystemDatabase is not null
	and			SystemDatabase = @Database
end
if @Database = '_ALL_'
begin
	insert		#client_dbs(CustomerID, DbName)
	select		SystemID, SystemDatabase
	from		MDVALUATE.dbo.SystemRecordsMedia
	where		SystemDatabase is not null
end

declare
@CustomerID nvarchar(10),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #current_results (
	CustomerID nvarchar(10),
	NPI nvarchar(10),
	SiteName nvarchar(20),
	SiteURL nvarchar(4000),
	Rating decimal(2,1),
	Volume int,
	BatchID int
)
insert		#current_results
select		CustomerID, NPI, SiteName, ResultLink, ResultRating, ResultVolume, BatchID
from		RepMgmt.dbo.DIFFBOT_ResultLinks
where		BatchID = @BatchID

create table #previous_results (
	CustomerID nvarchar(10),
	NPI nvarchar(10),
	SiteName nvarchar(20),
	SiteURL nvarchar(4000),
	Rating decimal(2,1),
	Volume int,
	BatchID int
)
insert		#previous_results
select		CustomerID, NPI, SiteName, ResultLink, ResultRating, ResultVolume, BatchID
from		RepMgmt.dbo.DIFFBOT_ResultLinks
where		BatchID = @PreviousBatch

select		media.PrimaryCustomerSource, media.PrimaryCustomerID, media.NPI, media.FirstName, media.MiddleName, media.LastName,
			w.SourceKey, w.WorkingKey, newid() as ResultKey, p.SiteName, p.SiteURL as ResultLink,
			null as ResultRating, null as ResultVolume, @SearchDate as SearchDate, @BatchID as BatchID
from		MDVALUATE.dbo.MasterPhysicianMedia media
inner join	#client_dbs c
on			c.CustomerID = media.PrimaryCustomerID
inner join	#previous_results p
on			p.NPI = media.NPI
and			p.CustomerID = media.PrimaryCustomerID
inner join	RepMgmt.dbo.DIFFBOT_WorkingLinks w
on			w.CustomerID = p.CustomerID
and			w.NPI = p.NPI
and			w.SiteName = p.SiteName
and			w.BatchID = @BatchID
left join	#current_results cr
on			cr.CustomerID = p.CustomerID
and			cr.NPI = p.NPI
and			cr.SiteName = p.SiteName
where		cr.NPI is null
and			p.Rating is not null
and			media.Status = 'Active'
order by	media.LastName, media.FirstName, media.MiddleName, p.SiteName

drop table #current_results
drop table #previous_results
drop table #client_dbs