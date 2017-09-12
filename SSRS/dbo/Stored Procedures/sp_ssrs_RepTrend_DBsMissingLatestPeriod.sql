
CREATE procedure [dbo].[sp_ssrs_RepTrend_DBsMissingLatestPeriod]

as

--exec sp_ssrs_RepTrend_DBsMissingLatestPeriod

declare
@Server nvarchar(200),
@ServerName nvarchar(10),
@Database nvarchar(200),
@CustomerID nvarchar(50),
@CustomerSource nvarchar(120),
@MaxEndDate nvarchar(10),
@StartDate nvarchar(10),
@Period nvarchar(50),
@counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

select @Server = 'DEV'
select @ServerName = @Server

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

create table #dbs (ID int identity, DbName nvarchar(200), CustomerID nvarchar(10))
insert		#dbs(DbName, CustomerID)
select		distinct SystemDatabase, SystemID
from		MDVALUATE.dbo.SystemRecordsMedia
where		IsClient = 'Yes'
and			SystemDatabase is not null
and			CustomerTerminatedDate is null

if @ServerName in ('QA', 'PROD')
begin
	update		#dbs
	set			DbName = DbName + '2'
end

select @Server = String from ScriptBox.dbo.Servers where Label = @Server

create table #periods (
	ID int identity,
	ServerName nvarchar(200),
	DbName nvarchar(200),
	CustomerID nvarchar(10),
	Period nvarchar(50),
	StartDate nvarchar(10),
	EndDate nvarchar(10)
)

set @counter = 1
while @counter <= (select max(ID) from #dbs)
begin
	select @Database = DbName from #dbs where ID = @counter

	set @sql = 'insert #periods(ServerName, DbName, CustomerID, Period, StartDate, EndDate) ' + @CR
	set @sql = @sql + 'select distinct ''' + @ServerName + ''', ''' + @Database + ''', SystemID, StartDate + '' - '' + EndDate, StartDate, EndDate ' + @CR
	set @sql = @sql + 'from [' + @Server + '].[' + @Database + '].dbo.PhysVRepTrendMedia ' + @CR
	exec(@sql)

	set @counter = @counter + 1
end

select @MaxEndDate = max(EndDate) from #periods

create table #dbs_with_max_end_date (ID int identity, DbName nvarchar(200), CustomerID nvarchar(10), Period nvarchar(50))

insert		#dbs_with_max_end_date(DbName, CustomerID, Period)
select		distinct DbName, CustomerID, Period
from		#periods
where		EndDate = @MaxEndDate

select @StartDate = StartDate from #periods where EndDate = @MaxEndDate
select @Period = Period from #periods where EndDate = @MaxEndDate

create table #dbs_missing (ID int identity, DbName nvarchar(200), CustomerID nvarchar(10), Period nvarchar(50), StartDate datetime, MaxEndDate datetime)
insert		#dbs_missing(DbName, CustomerID, Period, StartDate, MaxEndDate)
select		d.DbName, d.CustomerID, (select top 1 Period from #dbs_with_max_end_date), @StartDate, @MaxEndDate
from		#dbs d
left join	#dbs_with_max_end_date dd
on			dd.DbName = d.DbName
where		dd.DbName is null

create table #db_diffbot (
	ID int identity,
	ServerName nvarchar(10),
	DbName nvarchar(200),
	Period nvarchar(50),
	SearchDate datetime,
	BatchID int
)

set @counter = 1
while @counter <= (select max(ID) from #dbs_missing)
begin
	select @Database = DbName from #dbs_missing where ID = @counter

	set @sql = 'insert #db_diffbot(ServerName, DbName, Period, SearchDate, BatchID) ' + @CR
	set @sql = @sql + 'select distinct ''' + @ServerName + ''', db.DbName, db.Period, convert(varchar, d.SearchDate, 101), d.BatchID ' + @CR
	set @sql = @sql + 'from #dbs_missing db ' + @CR
	set @sql = @sql + 'left join ' + @Database + '.dbo.DIFFBOT_ResultLinks d ' + @CR
	set @sql = @sql + 'on d.CustomerID = db.CustomerID ' + @CR
	set @sql = @sql + 'and convert(varchar, d.SearchDate, 101) <= convert(varchar, db.MaxEndDate, 101) ' + @CR
	set @sql = @sql + 'and d.BatchID > 0 '
	exec(@sql)

	set @counter = @counter + 1
end

select		@Period as LatestPeriod, isnull(DbName, 'None Missing Latest Period') as DbName,
			isnull(convert(varchar, SearchDate, 101), 'No Results this Period') as SearchDate, BatchID
from		#db_diffbot
order by	BatchID

drop table #dbs
drop table #periods
drop table #dbs_with_max_end_date
drop table #db_diffbot
drop table #dbs_missing
