
CREATE procedure [dbo].[sp_ssrs_DIFFBOTbyPeriod_Periods] (
	@Database nvarchar(200),
	@Start_or_End int
)

as

/*
declare
@Database nvarchar(200),
@Start_or_End int
select
@Database = 'Rothman',
@Start_or_End = 0

exec sp_ssrs_DIFFBOTbyPeriod_Periods @Database, @Start_or_End
*/

declare
@counter int,
@sql nvarchar(max),
@CR char(1)

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
	and			CustomerTerminatedDate is null
end
else
begin
	insert		#dbs(DbName)
	select		distinct SystemDatabase
	from		MDVALUATE.dbo.SystemRecordsMedia
	where		IsClient = 'Yes'
	and			SystemDatabase = @Database
	and			CustomerTerminatedDate is null
end

create table #periods(Period nvarchar(30))

set @counter = 1
while @counter <= (select max(ID) from #dbs)
begin
	select @Database = DbName from #dbs where ID = @counter

	if @Start_or_End = 0
	begin
		set @sql = 'insert #periods ' + @CR
		set @sql = @sql + 'select ''_PREVIOUS_'' as Period ' + @CR
		set @sql = @sql + 'union ' + @CR
		set @sql = @sql + 'select distinct StartDate + '' - '' + EndDate as Period ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia ' + @CR
		exec(@sql)
	end
	else
	begin
		set @sql = 'insert #periods ' + @CR
		set @sql = @sql + 'select ''_CURRENT_'' as Period ' + @CR
		set @sql = @sql + 'union ' + @CR
		set @sql = @sql + 'select distinct StartDate + '' - '' + EndDate as Period ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia ' + @CR
		exec(@sql)
	end

	set @counter = @counter + 1
end

select distinct Period from #periods order by Period

drop table #dbs
drop table #periods
