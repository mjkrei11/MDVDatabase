
CREATE procedure [dbo].[sp_ssrs_RepTrendingSiteCount] (
	@Database nvarchar(200),
	@Period nvarchar(30)
)

as

/*
declare
@Database nvarchar(200),
@Period nvarchar(30)

set @Database = '_ALL_'
set @Period = '_ALL_'

exec sp_ssrs_RepTrendingSiteCount @Database, @Period
*/

declare
@sql nvarchar(max),
@CR char(1),
@counter int,
@site_counter int,
@batch_counter int,
@NPITrend nvarchar(50),
@Site nvarchar(50),
@BatchID int

set @CR = char(13)

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

create table #dbs(ID int identity, DbName nvarchar(200))

if @Database = '_ALL_'
begin
	insert		#dbs(DbName)
	select		distinct SystemDatabase
	from		MDVALUATE.dbo.SystemRecordsMedia
	where		IsClient = 'Yes'
	and			CustomerTerminatedDate is NULL
end
else
begin
	insert		#dbs(DbName)
	select		distinct SystemDatabase
	from		MDVALUATE.dbo.SystemRecordsMedia
	where		IsClient = 'Yes'
	and			SystemDatabase = @Database
	and			CustomerTerminatedDate is NULL
end

create table #site_counts(
	DbName nvarchar(200),
	NPITrend nvarchar(50),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	StartDate nvarchar(10),
	EndDate nvarchar(10),
	StartBatchID int,
	EndBatchID int,
	BatchID int,
	SiteCount int
)

set @counter = 1
while @counter <= (select max(ID) from #dbs)
begin
	select @Database = DbName from #dbs where ID = @counter

	set @sql = 'insert #site_counts ' + @CR
	set @sql = @sql + 'select ''' + @Database + ''', media.NPITrend, media.NPI, media.FirstName, media.MiddleName, media.LastName, ' + @CR
	set @sql = @sql + 'media.StartDate, media.EndDate, media.StartBatchID, media.EndBatchID, ' + @CR
	set @sql = @sql + 'trend.RepTrendBatchID ,count(distinct trend.RepTrendSite) as SiteCount ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia media ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.VIRepTrend trend ' + @CR
	set @sql = @sql + 'on trend.NPITrend = media.NPITrend ' + @CR
	set @sql = @sql + 'where trend.RepTrendTab = ''Weekly'' ' + @CR
	set @sql = @sql + 'group by media.NPITrend, media.NPI, media.FirstName, media.MiddleName, media.LastName, ' + @CR
	set @sql = @sql + 'media.StartDate, media.EndDate, media.StartBatchID, media.EndBatchID, trend.RepTrendBatchID ' + @CR
	set @sql = @sql + 'order by media.LastName, media.FirstName, media.EndBatchID desc, trend.RepTrendBatchID desc ' + @CR
	exec(@sql)

	set @counter = @counter + 1
end

create table #agg_top(
	DbName nvarchar(200),
	StartDate nvarchar(10),
	EndDate nvarchar(10),
	StartBatch int,
	EndBatch int,
	NPITrend nvarchar(50),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	AvgSiteCount float,
	MaxSiteCount int,
	MinSiteCount int
)
insert		#agg_top
select		DbName, StartDate, EndDate, StartBatchID, EndBatchID, NPITrend, NPI, FirstName, MiddleName, LastName, avg(SiteCount) as AvgSiteCount, max(SiteCount) as MaxSiteCount, min(SiteCount) as MinSiteCount
from		#site_counts
group by	DbName, StartDate, EndDate, StartBatchID, EndBatchID, NPITrend, NPI, FirstName, MiddleName, LastName

create table #agg(
	DbName nvarchar(200),
	StartDate nvarchar(10),
	EndDate nvarchar(10),
	StartBatch int,
	EndBatch int,
	NPITrend nvarchar(50),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	AvgSiteCount float,
	MaxSiteCount int,
	MinSiteCount int
)
insert		#agg
select		*
from		#agg_top
where		AvgSiteCount <> MaxSiteCount

if @Period = '_ALL_'
begin
	select		DbName as SystemName, StartDate + ' - ' + EndDate as Period, cast(StartBatch as nvarchar(10)) + ' - ' + cast(EndBatch as nvarchar(10)) as BatchRange, *
	from		#agg
end
else
begin
	select		DbName as SystemName, StartDate + ' - ' + EndDate as Period, cast(StartBatch as nvarchar(10)) + ' - ' + cast(EndBatch as nvarchar(10)) as BatchRange, *
	from		#agg
	where		StartDate + ' - ' + EndDate = @Period
end

drop table #site_counts
drop table #agg_top
drop table #agg
drop table #dbs
