
CREATE procedure [dbo].[sp_ssrs_RepTrendingMissingSites] (
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

exec sp_ssrs_RepTrendingMissingSites @Database, @Period
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
	and			CustomerTerminatedDate is NULL
	and			SystemDatabase = @Database
end

create table #site_counts(
	DbName nvarchar(200),
	NPITrend nvarchar(50),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	StartDate date,
	EndDate date,
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
	StartDate date,
	EndDate date,
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
select		DbName, StartDate, EndDate, NPITrend, NPI, FirstName, MiddleName, LastName, avg(SiteCount) as AvgSiteCount, max(SiteCount) as MaxSiteCount, min(SiteCount) as MinSiteCount
from		#site_counts
group by	DbName, StartDate, EndDate, NPITrend, NPI, FirstName, MiddleName, LastName

create table #agg(
	DbName nvarchar(200),
	StartDate date,
	EndDate date,
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

create table #NPITrend(ID int identity, DbName nvarchar(200), NPITrend nvarchar(50))
insert		#NPITrend(DbName, NPITrend)
select		DbName, NPITrend
from		#agg

create table #sites(ID int identity, SiteName nvarchar(50))
create table #batches(ID int identity, BatchID int)
create table #results(NPITrend nvarchar(50), BatchID int, SiteName nvarchar(50), RecordExists int)

set @counter = 1
while @counter <= (select max(ID) from #NPITrend)
begin
	truncate table #sites
	truncate table #batches

	select @Database = DbName, @NPITrend = NPITrend from #NPITrend where ID = @counter

	set @sql = 'insert #sites(SiteName) ' + @CR
	set @sql = @sql + 'select distinct v.RepTrendSite ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.VIRepTrend v ' + @CR
	set @sql = @sql + 'inner join #agg a ' + @CR
	set @sql = @sql + 'on a.NPITrend = v.NPITrend ' + @CR
	set @sql = @sql + 'where v.NPITrend = ''' + @NPITrend + ''' ' + @CR
	set @sql = @sql + 'and v.RepTrendTab = ''Weekly'' ' + @CR
	exec(@sql)

	set @sql = 'insert #batches(BatchID) ' + @CR
	set @sql = @sql + 'select distinct v.RepTrendBatchID ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.VIRepTrend v ' + @CR
	set @sql = @sql + 'inner join #agg a ' + @CR
	set @sql = @sql + 'on a.NPITrend = v.NPITrend ' + @CR
	set @sql = @sql + 'where v.NPITrend = ''' + @NPITrend + ''' ' + @CR
	set @sql = @sql + 'and v.RepTrendTab = ''Weekly'' ' + @CR
	exec(@sql)

	set @batch_counter = 1
	while @batch_counter <= (select max(ID) from #batches)
	begin
		select @BatchID = BatchID from #batches where ID = @batch_counter

		set @site_counter = 1
		while @site_counter <= (select max(ID) from #sites)
		begin
			select @Site = SiteName from #sites where ID = @site_counter

			set @sql = 'insert #results(NPITrend, BatchID, SiteName, RecordExists) ' + @CR
			set @sql = @sql + 'select distinct ''' + @NPITrend + ''', ''' + cast(@BatchID as nvarchar(10)) + ''', ''' + @Site + ''', count(*) ' + @CR
			set @sql = @sql + 'from ' + @Database + '.dbo.VIRepTrend ' + @CR
			set @sql = @sql + 'where NPITrend = ''' + @NPITrend + ''' ' + @CR
			set @sql = @sql + 'and RepTrendBatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
			set @sql = @sql + 'and RepTrendSite = ''' + @Site + ''' ' + @CR
			set @sql = @sql + 'and RepTrendTab = ''Weekly'' ' + @CR
			exec(@sql)

			set @site_counter = @site_counter + 1
		end

		set @batch_counter = @batch_counter + 1
	end

	set @counter = @counter + 1
end

create table #report(
	SystemName nvarchar(200),
	Period nvarchar(30),
	BatchRange nvarchar(30),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	NPITrend nvarchar(50),
	BatchID int,
	SiteName nvarchar(50),
	RecordExists int
)

set @counter = 1
while @counter <= (select max(ID) from #dbs)
begin
	select @Database = DbName from #dbs where ID = @counter

	set @sql = 'insert #report ' + @CR
	set @sql = @sql + 'select p.SystemName, p.StartDate + '' - '' + p.EndDate as Period, cast(p.StartBatchID as nvarchar(10)) + '' - '' + cast(p.EndBatchID as nvarchar(10)) as BatchRange, ' + @CR
	set @sql = @sql + 'p.NPI, p.FirstName, p.MiddleName, p.LastName, r.* ' + @CR
	set @sql = @sql + 'from #results r ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysVRepTrendMedia p ' + @CR
	set @sql = @sql + 'on p.NPITrend = r.NPITrend ' + @CR
	set @sql = @sql + 'where r.RecordExists = 0 ' + @CR
	if @Period <> '_ALL_'
	begin
		set @sql = @sql + 'and p.StartDate + '' - '' + p.EndDate = ''' + @Period + ''' ' + @CR
	end
	exec(@sql)

	set @counter = @counter + 1
end

select		*
from		#report
order by	SystemName, NPITrend, BatchID desc, SiteName

drop table #site_counts
drop table #agg_top
drop table #agg
drop table #NPITrend
drop table #sites
drop table #batches
drop table #results
drop table #dbs
drop table #report
