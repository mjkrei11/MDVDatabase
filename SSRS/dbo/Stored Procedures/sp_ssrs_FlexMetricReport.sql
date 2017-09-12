create procedure sp_ssrs_FlexMetricReport(
	@Database nvarchar(200),
	@FormID nvarchar(50)
)

as

/*
declare
@Database nvarchar(200),
@FormID nvarchar(50)

set @Database = 'Rothman'
set @FormID = 'SACT'

exec sp_ssrs_FlexMetricReport @Database, @FormID
*/

declare
@MediaTable nvarchar(200),
@MetricTable nvarchar(200),
@CrossTableType nvarchar(50),
@MetricType nvarchar(50),
@VICategory nvarchar(200),
@TimeFrame nvarchar(100),
@Category nvarchar(200),
@RecordCheck int,
@counter int,
@sqlCheck nvarchar(max),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

create table #form_tables(
	ID int identity,
	IsMedia int,
	TableName nvarchar(200), 
	VICategory nvarchar(200),
	Category nvarchar(200),
	TimeFrame nvarchar(200)
)

set @sql = 'insert #form_tables(IsMedia, TableName) ' + @CR
set @sql = @sql + 'select distinct 1, MediaTable ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.FormInfo ' + @CR
set @sql = @sql + 'where FormID = ''' + @FormID + ''' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select distinct 0, SourceTable ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.FormTable ' + @CR
set @sql = @sql + 'where FormID = ''' + @FormID + ''' ' + @CR
set @sql = @sql + 'and len(ltrim(rtrim(SourceTable))) > 0 ' + @CR
exec(@sql)

update		#form_tables
set			VICategory =	case
								when TableName like '%mean' then 'VICategory'
								when TableName like '%median' then 'VICategoryMedian'
								when TableName like '%benchmark' then 'VICategoryBenchmark'
							end,
			Category =		case
								when TableName like '%mean' then 'Category'
								when TableName like '%median' then 'CategoryMedian'
								when TableName like '%benchmark' then 'CategoryBenchmark'
							end,
			TimeFrame =		case
								when TableName like '%mean' then 'TimeFrame'
								when TableName like '%median' then 'TimeFrameMedian'
								when TableName like '%benchmark' then 'TimeFrameBenchmark'
							end

select @MediaTable = TableName from #form_tables where IsMedia = 1

set @sql = 'select distinct media.NPI, media.FirstName, media.MiddleName, media.LastName ' + @CR

set @counter = 1
while @counter <= (select max(ID) from #form_tables)
begin
	select @MetricTable = TableName from #form_tables where IsMedia = 0 and ID = @counter
	if @MetricTable like '%mean'
	begin
		set @CrossTableType = ''
		set @MetricType = 'Mean'
	end
	if @MetricTable like '%median'
	begin
		set @CrossTableType = 'Median'
		set @MetricType = ''
	end
	if @MetricTable like '%benchmark'
	begin
		set @CrossTableType = 'Benchmark'
		set @MetricType = ''
	end

	if @MetricTable is not null
	begin
		set @sqlCheck = 'select top 1 @TempRecordCheck = count(*) ' + @CR
		set @sqlCheck = @sqlCheck + 'from ' + @Database + '.dbo.' + @MetricTable + ' '
		set @parms = '@TempRecordCheck int output'
		exec sp_executesql @sqlCheck, @parms, @TempRecordCheck = @RecordCheck output

		if isnull(@RecordCheck, 0) > 0
		begin		
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.PrimaryCustomerSpecialty' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.PrimaryGroup' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.VIMeasure' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.VICategory' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.TimeFrame' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.Category' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.Observed' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.System' + @MetricType + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.Specialty' + @MetricType + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.Group' + @MetricType + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.VarianceFromSystem' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.VarianceFromSpecialty' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.VarianceFromGroup' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.SystemPercentile' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.SpecialtyPercentile' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.GroupPercentile' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.SystemColor' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.SpecialtyColor' + @CrossTableType + ' ' + @CR
			set @sql = @sql + ',metric' + cast(@counter as nvarchar(5)) + '.GroupColor' + @CrossTableType + ' ' + @CR
		end
	end

	set @counter = @counter + 1
end

set @sql = @sql + 'from ' + @Database + '.dbo.' + @MediaTable + ' media ' + @CR

set @counter = 1
while @counter <= (select max(ID) from #form_tables)
begin
	select @MetricTable = TableName, @VICategory = VICategory, @Category = Category, @TimeFrame = TimeFrame from #form_tables where IsMedia = 0 and ID = @counter
	if @MetricTable like '%mean'
	begin
		set @CrossTableType = ''
		set @MetricType = 'Mean'
		set @TimeFrame = 'TimeFrame'
	end
	if @MetricTable like '%median'
	begin
		set @CrossTableType = 'Median'
		set @MetricType = ''
		set @TimeFrame = 'TimeFrameMedian'
	end
	if @MetricTable like '%benchmark'
	begin
		set @CrossTableType = 'Benchmark'
		set @MetricType = ''
		set @TimeFrame = 'TimeFrameBenchmark'
	end

	if @MetricTable is not null
	begin
		set @sqlCheck = 'select top 1 @TempRecordCheck = count(*) ' + @CR
		set @sqlCheck = @sqlCheck + 'from ' + @Database + '.dbo.' + @MetricTable + ' '
		set @parms = '@TempRecordCheck int output'
		exec sp_executesql @sqlCheck, @parms, @TempRecordCheck = @RecordCheck output

		if isnull(@RecordCheck, 0) > 0
		begin	
			set @sql = @sql + 'inner join ' + @Database + '.dbo.' + @MetricTable + ' metric' + cast(@counter as nvarchar(5)) + ' ' + @CR
			set @sql = @sql + 'on metric' + cast(@counter as nvarchar(5)) + '.NPI = media.NPI ' + @CR
			if @counter > 2
			begin
				select @VICategory = VICategory, @Category = Category, @TimeFrame = TimeFrame from #form_tables where IsMedia = 0 and ID = @counter - 1
				set @sql = @sql + 'and metric' + cast(@counter as nvarchar(5)) + '.VICategory' + @CrossTableType + ' = metric' + cast(@counter - 1 as nvarchar(5)) + '.' + @VICategory + ' ' + @CR
				set @sql = @sql + 'and metric' + cast(@counter as nvarchar(5)) + '.Category' + @CrossTableType + ' = metric' + cast(@counter - 1 as nvarchar(5)) + '.' + @Category + ' ' + @CR
				set @sql = @sql + 'and metric' + cast(@counter as nvarchar(5)) + '.TimeFrame' + @CrossTableType + ' = metric' + cast(@counter - 1 as nvarchar(5)) + '.' + @TimeFrame + ' ' + @CR
			end
		end
	end

	set @counter = @counter + 1
end

exec(@sql)

drop table #form_tables