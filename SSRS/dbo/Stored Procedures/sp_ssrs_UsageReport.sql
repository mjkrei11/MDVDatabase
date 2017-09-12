
CREATE procedure [dbo].[sp_ssrs_UsageReport] (
	@Server nvarchar(5),
	@Database nvarchar(max),
	@StartDate datetime,
	@EndDate datetime
)

as

/*
declare
@Server nvarchar(5),
@Database nvarchar(200),
@StartDate datetime,
@EndDate datetime

select
@Server = 'PROD',
@Database = 'TWINCITIES2',
@StartDate = '01/01/2016',
@EndDate = '01/27/2016'

exec sp_ssrs_UsageReport @Server, @Database, @StartDate, @EndDate
*/

create table #routing(
	ELAID nvarchar(100),
	[Server] nvarchar(5),
	Db nvarchar(200),
	EventSystemName nvarchar(400),
	EventSystem nvarchar(200),
	EventDate datetime,
	EventSource nvarchar(200),
	EventDesc nvarchar(400),
	EventUser nvarchar(200)
)

declare
@ServerString nvarchar(200),
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

select @ServerString = String from ScriptBox.dbo.Servers where Label = @Server

create table #dbs(ID int identity, DbName nvarchar(200))
set @sql = 'insert #dbs(DbName) ' + @CR
set @sql = @sql + 'select distinct Db ' + @CR
set @sql = @sql + 'from MDVALUATE.dbo.EventLogArchiveMedia ' + @CR
set @sql = @sql + 'where Db in (select Value from dbo.fn_SplitValues(''' + @Database + ''', '',''))  ' + @CR
exec(@sql)

create table #system_ids(ID int identity, SystemID nvarchar(10), CollectionID nvarchar(10), SystemName nvarchar(400))
insert		#system_ids(SystemID, CollectionID, SystemName)
select		distinct case when len(ltrim(rtrim(metric.EventSystem))) > 10 then
				substring(metric.EventSystem, 1, charindex('_', metric.EventSystem) - 1) else
				ltrim(rtrim(metric.EventSystem)) end,
			case when len(ltrim(rtrim(metric.EventSystem))) > 10 then
				substring(metric.EventSystem, charindex('_', metric.EventSystem) + 1, 10) else
				ltrim(rtrim(metric.EventSystem)) end,
			metric.EventSystemName
from		MDVALUATE.dbo.EventLogArchiveMedia media
inner join	MDVALUATE.dbo.EventLogArchive metric
on			metric.ELAID = media.ELAID
inner join	#dbs d
on			d.DbName = media.Db

create table #users(
	ID int identity,
	UserID nvarchar(20),
	UserLogin nvarchar(200),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	Customer nvarchar(200)
)
set @sql = 'insert #users(UserID, UserLogin, FirstName, LastName, Customer) ' + @CR
set @sql = @sql + 'select distinct m.UserID, m.UserLogin, m.FirstName, m.LastName, m.Customer ' + @CR
set @sql = @sql + 'from [' + @ServerString + '].[MDVRouting2].dbo.MDValuateUserSecurity m ' + @CR
set @sql = @sql + 'inner join [' + @ServerString + '].[MDVRouting2].dbo.MDValuateSecurityDetail d ' + @CR
set @sql = @sql + 'on d.UserID = m.UserID ' + @CR
set @sql = @sql + 'inner join #system_ids s ' + @CR
set @sql = @sql + 'on s.SystemID = d.SystemID ' + @CR
set @sql = @sql + 'and s.CollectionID = d.CollectionID ' + @CR
exec(@sql)

--insert		#routing
--select		distinct ltrim(rtrim(media.ELAID)) ELAID, ltrim(rtrim(media.[Server])) [Server], ltrim(rtrim(media.Db)) Db,
--			ltrim(rtrim(metric.EventSystemName)) EventSystemName, ltrim(rtrim(metric.EventSystem)) EventSystem,
--			cast(ltrim(rtrim(metric.EventDate)) as datetime) EventDate, ltrim(rtrim(metric.EventSource)) EventSource,
--			ltrim(rtrim(metric.EventDesc)) EventDesc, ltrim(rtrim(metric.EventUser)) EventUser
--from		MDVALUATE.dbo.EventLogArchiveMedia media
--inner join	MDVALUATE.dbo.EventLogArchive metric
--on			metric.ELAID = media.ELAID
--inner join	#users u
--on			u.UserLogin = metric.EventUser
----inner join	#dbs d
----on			d.DbName = media.Db
--where		media.Db = 'MDVRouting2'
--and			media.[Server] = @Server
--and			metric.EventDate between @StartDate and @EndDate + 1

insert		#routing
select		distinct ltrim(rtrim(media.ELAID)) ELAID, ltrim(rtrim(media.[Server])) [Server], ltrim(rtrim(media.Db)) Db,
			ltrim(rtrim(metric.EventSystemName)) EventSystemName, ltrim(rtrim(metric.EventSystem)) EventSystem,
			cast(ltrim(rtrim(metric.EventDate)) as datetime) EventDate, ltrim(rtrim(metric.EventSource)) EventSource,
			ltrim(rtrim(metric.EventDesc)) EventDesc, ltrim(rtrim(metric.EventUser)) EventUser
from		MDVALUATE.dbo.EventLogArchiveMedia media
inner join	MDVALUATE.dbo.EventLogArchive metric
on			metric.ELAID = media.ELAID
inner join	#users u
on			u.UserLogin = metric.EventUser
inner join	#dbs d
on			d.DbName = media.Db
where		media.[Server] = @Server
and			metric.EventDate between @StartDate and @EndDate + 1

select		*
from		#routing r
inner join	#users u
on			u.UserLogin = r.EventUser
order by	EventUser, EventDate

drop table #routing
drop table #users
drop table #dbs
drop table #system_ids
