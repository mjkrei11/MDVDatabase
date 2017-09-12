
CREATE procedure [dbo].[sp_ssrs_DIFFBOTMissingRatings_old](
	@Database nvarchar(200),
	@BatchID nvarchar(20)
)

as

/*
declare
@Database nvarchar(200),
@BatchID nvarchar(20)
set @Database = 'Competition'
set @BatchID = '-8'

exec sp_ssrs_DIFFBOTMissingRatings @Database, @BatchID
*/

if @BatchID = '9999999999_ALL_'
begin
	select @BatchID = max(BatchID) from RepMgmt.dbo.DIFFBOT_WorkingLinks
end

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

create table #potential_missing_ratings(
	PrimaryCustomerSource nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(100),
	MiddleName nvarchar(100),
	Lastname nvarchar(100),
	ResultKey uniqueidentifier,
	SiteName nvarchar(50),
	ResultLink nvarchar(4000),
	ResultRating decimal(10,2),
	ResultVolume int,
	SearchDate datetime,
	BatchID int
)

set @sql = 'insert #potential_missing_ratings ' + @CR
set @sql = @sql +'select media.PrimaryCustomerSource, media.NPI, media.FirstName, media.MiddleName, media.LastName, ' + @CR
set @sql = @sql + 'd.ResultKey, d.SiteName, d.ResultLink, d.ResultRating, d.ResultVolume, d.SearchDate, d.BatchID ' + @CR
set @sql = @sql + 'from MDVALUATE.dbo.MasterPhysicianMedia media ' + @CR
set @sql = @sql + 'inner join #client_dbs c ' + @CR
set @sql = @sql + 'on c.CustomerID = media.PrimaryCustomerID ' + @CR
set @sql = @sql + 'inner join RepMgmt.dbo.DIFFBOT_ResultLinks d ' + @CR
set @sql = @sql + 'on d.NPI = media.NPI ' + @CR
set @sql = @sql + 'where d.ResultRating is null and d.ResultVolume is not null ' + @CR
set @sql = @sql + 'and d.BatchID = ''' + cast(@BatchID as nvarchar(5)) + ''' ' + @CR
set @sql = @sql + 'order by LastName, FirstName, MiddleName, SiteName ' + @CR
exec(@sql)

--select * from #potential_missing_ratings order by BatchID desc

create table #previous_ratings(
	NPI nvarchar(10),
	SiteName nvarchar(50),
	ResultLink nvarchar(4000),
	BatchID int,
	ResultRating decimal(10,2),
	PreviousVolume int,
	CurrentVolume int
)

insert		#previous_ratings
select		d.NPI, d.SiteName, d.ResultLink, d.BatchID, d.ResultRating, d.ResultVolume, p.ResultVolume
from		RepMgmt.dbo.DIFFBOT_ResultLinks d
inner join	#potential_missing_ratings p
on			p.NPI = d.NPI
and			p.SiteName = d.SiteName
--where		d.ResultRating is not null

--select * from #previous_ratings

select		distinct p.*
from		#potential_missing_ratings p
left join	#previous_ratings pr
on			pr.NPI = p.NPI
and			pr.SiteName = p.SiteName
where		(pr.PreviousVolume < pr.CurrentVolume or (pr.ResultRating is null and pr.CurrentVolume is not null))

drop table #potential_missing_ratings
drop table #previous_ratings
drop table #client_dbs
