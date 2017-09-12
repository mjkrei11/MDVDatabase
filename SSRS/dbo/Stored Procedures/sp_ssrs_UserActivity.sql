CREATE procedure sp_ssrs_UserActivity (
	@Server nvarchar(5),
	@Database nvarchar(200),
	@User nvarchar(50),
	@StartDate nvarchar(10),
	@EndDate nvarchar(10)
)

as

/*
declare
@Server nvarchar(5),
@Database nvarchar(200),
@User nvarchar(50),
@StartDate nvarchar(10),
@EndDate nvarchar(10)

set @Server = 'PROD'
set @Database = 'Rothman2'
set @User = 'jashworth'

exec sp_ssrs_UserActivity @Server, @Database, @User, @StartDate, @EndDate
*/

create table #servers (ID int identity, ServerName nvarchar(5))
create table #dbs (ID int identity, DbName nvarchar(200))
create table #users (ID int identity, Username nvarchar(200))
create table #start_date (ID int identity, EventDate nvarchar(10))
create table #end_date (ID int identity, EventDate nvarchar(10))

if @Server is null
begin
	insert		#servers (ServerName)
	select		distinct [Server]
	from		MDVALUATE.dbo.EventLogArchiveMedia
	order by	[Server]
end
else
begin
	insert		#servers (ServerName)
	select		distinct [Server]
	from		MDVALUATE.dbo.EventLogArchiveMedia
	where		[Server] = @Server
end

if @Database is null
begin
	insert		#dbs (DbName)
	select		distinct Db
	from		MDVALUATE.dbo.EventLogArchiveMedia media
	inner join	#servers s
	on			s.ServerName = media.[Server]
	order by	Db
end
else
begin
	insert		#dbs (DbName)
	select		distinct Db
	from		MDVALUATE.dbo.EventLogArchiveMedia media
	inner join	#servers s
	on			s.ServerName = media.[Server]
	where		Db = @Database
end

if @User is null
begin
	insert		#users (Username)
	select		distinct metric.EventUser
	from		MDVALUATE.dbo.EventLogArchiveMedia media
	inner join	MDVALUATE.dbo.EventLogArchive metric
	on			metric.ELAID = media.ELAID
	inner join	#servers s
	on			s.ServerName = media.[Server]
	inner join	#dbs db
	on			db.DbName = media.Db
	order by	metric.Eventuser
end
else
begin
	insert		#users (Username)
	select		distinct metric.EventUser
	from		MDVALUATE.dbo.EventLogArchiveMedia media
	inner join	MDVALUATE.dbo.EventLogArchive metric
	on			metric.ELAID = media.ELAID
	inner join	#servers s
	on			s.ServerName = media.[Server]
	inner join	#dbs db
	on			db.DbName = media.Db
	where		metric.EventUser = @User
end

if @StartDate is null
begin
	insert		#start_date (EventDate)
	select		distinct convert(varchar, metric.EventDate, 101)
	from		MDVALUATE.dbo.EventLogArchiveMedia media
	inner join	MDVALUATE.dbo.EventLogArchive metric
	on			metric.ELAID = media.ELAID
	inner join	#servers s
	on			s.ServerName = media.[Server]
	inner join	#dbs db
	on			db.DbName = media.Db
	inner join	#users u
	on			u.Username = metric.EventUser
end
else
begin
	insert		#start_date (EventDate)
	select		distinct convert(varchar, metric.EventDate, 101)
	from		MDVALUATE.dbo.EventLogArchiveMedia media
	inner join	MDVALUATE.dbo.EventLogArchive metric
	on			metric.ELAID = media.ELAID
	inner join	#servers s
	on			s.ServerName = media.[Server]
	inner join	#dbs db
	on			db.DbName = media.Db
	inner join	#users u
	on			u.Username = metric.EventUser
	where		convert(varchar, metric.EventDate, 101) = @StartDate
end

if @EndDate is null
begin
	insert		#end_date (EventDate)
	select		distinct convert(varchar, metric.EventDate, 101)
	from		MDVALUATE.dbo.EventLogArchiveMedia media
	inner join	MDVALUATE.dbo.EventLogArchive metric
	on			metric.ELAID = media.ELAID
	inner join	#servers s
	on			s.ServerName = media.[Server]
	inner join	#dbs db
	on			db.DbName = media.Db
	inner join	#users u
	on			u.Username = metric.EventUser
end
else
begin
	insert		#end_date (EventDate)
	select		distinct convert(varchar, metric.EventDate, 101)
	from		MDVALUATE.dbo.EventLogArchiveMedia media
	inner join	MDVALUATE.dbo.EventLogArchive metric
	on			metric.ELAID = media.ELAID
	inner join	#servers s
	on			s.ServerName = media.[Server]
	inner join	#dbs db
	on			db.DbName = media.Db
	inner join	#users u
	on			u.Username = metric.EventUser
	where		convert(varchar, metric.EventDate, 101) = @EndDate
end

create table #routing(
	ELAID nvarchar(100),
	ServerName nvarchar(5),
	DbName nvarchar(200),
	EventSystemName nvarchar(400),
	EventSystem nvarchar(200),
	EventDate datetime,
	EventSource nvarchar(200),
	EventDesc nvarchar(400),
	Username nvarchar(200)	
)

insert		#routing
select		distinct media.ELAID, media.[Server], media.Db, metric.EventSystemName, metric.EventSystem, metric.EventDate, metric.EventSource, metric.EventDesc, metric.EventUser
from		MDVALUATE.dbo.EventLogArchiveMedia media
inner join	MDVALUATE.dbo.EventLogArchive metric
on			metric.ELAID = media.ELAID
inner join	#servers s
on			s.ServerName = media.[Server]
inner join	#users u
on			u.Username = metric.EventUser
inner join	#start_date sd
on			sd.EventDate in (select distinct convert(varchar, metric.EventDate, 101))
inner join	#end_date ed
on			ed.EventDate in (select distinct convert(varchar, metric.EventDate, 101))
where		media.Db = 'MDVRouting2'

insert		#routing
select		distinct media.ELAID, media.[Server], media.Db, metric.EventSystemName,
			metric.EventSystem, metric.EventDate, metric.EventSource, metric.EventDesc,
			metric.EventUser
from		MDVALUATE.dbo.EventLogArchiveMedia media
inner join	MDVALUATE.dbo.EventLogArchive metric
on			metric.ELAID = media.ELAID
inner join	#servers s
on			s.ServerName = media.[Server]
inner join	#dbs d
on			d.DbName = media.Db
inner join	#users u
on			u.Username = metric.Eventuser
where		convert(varchar, metric.EventDate, 101) in (select distinct EventDate from #start_date)
and			convert(varchar, metric.EventDate, 101) in (select distinct EventDate from #end_date)
order by	media.[Server], media.Db, metric.EventUser, metric.EventDate

select		*
from		#routing
order by	ServerName, EventDate, DbName, UserName

drop table #servers
drop table #dbs
drop table #users
drop table #start_date
drop table #end_date