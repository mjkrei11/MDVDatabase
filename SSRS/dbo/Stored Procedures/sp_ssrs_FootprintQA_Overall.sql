
CREATE procedure [dbo].[sp_ssrs_FootprintQA_Overall] (
	@Database nvarchar(200),
	@CompOption int
)

as

/*
declare
@Database nvarchar(200),
@CompOption int

set @Database = 'Panorama'
set @CompOption = 0

exec sp_ssrs_FootprintQA_Overall @Database, @CompOption
*/

declare
@SystemID nvarchar(10),
@ScoreType nvarchar(50),
@PhysicianCount int,
@AvgScore float,
@CountOverBenchmark int,
@NetworkScore float,
@PhysicianCountScore int,
@PhysicianScorePercentage float,
@CustomerID nvarchar(50),
@CustomerSource nvarchar(120),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1),
@counter int,
@score_counter int

set @CR = char(13)

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

create table #footprint (
	GroupName nvarchar(50),
	OrderID int,
	SystemID nvarchar(10),
	SystemName nvarchar(200),
	CollectionID nvarchar(10),
	CollectionName nvarchar(200),
	ComboKey nvarchar(50),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	MetricTitle nvarchar(40),
	VICategory nvarchar(40),
	VIMeasure float,
	MarketName nvarchar(200),
	MarketShortName nvarchar(20),
	Specialty nvarchar(120),
	ScoreType nvarchar(20),
	ScoreNumber nvarchar(20),
	Score float,
	WeightedScore float,
	Percentile float,
	Color nvarchar(20),
	ResultNo int,
	SourceLink nvarchar(4000),
	PhysicianCount int,
	AvgScore decimal(10,0),
	CountOverBenchmark int,
	NetworkScore float
)

set @sql = 'insert #footprint ' + @CR
set @sql = @sql + 'select distinct ''_Footprint'', 0, media.SystemID, media.SystemName, media.CollectionID, media.CollectionName, media.ComboKey, media.NPI, ' + @CR
set @sql = @sql + 'media.FirstName, media.MiddleName, media.LastName, metric.MetricTitle, metric.VICategory, ' + @CR
set @sql = @sql + 'metric.VIMeasure, metric.MarketName, metric.MarketShortName, metric.Specialty, metric.ScoreType, metric.ScoreNumber, ' + @CR
set @sql = @sql + 'metric.Score, metric.WeightedScore, metric.Percentile, metric.Color, metric.ResultNo, metric.SourceLink, null, null, null, null ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetSearchRelevanceMedia media ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetSearchRelevance metric ' + @CR
set @sql = @sql + 'on metric.ComboKey = media.ComboKey ' + @CR
if @CompOption = 0
begin
	set @sql = @sql + 'where media.CollectionID = media.SystemID ' + @CR
end
if @CompOption <> 0
begin
	set @sql = @sql + 'where media.CollectionID <> media.SystemID ' + @CR
end
set @sql = @sql + 'and media.NPI not like ''S%'' and media.NPI not like ''G%'' and media.LastName <> ''System'' '
exec(@sql)

create table #systems(ID int identity, SystemID nvarchar(10))
insert		#systems
select		distinct SystemID
from		#footprint

create table #score_types(ID int identity, ScoreType nvarchar(50))
insert		#score_types
select		distinct ScoreType
from		#footprint

create table #overall(SystemID nvarchar(10), SystemName nvarchar(200), ScoreType nvarchar(50), AvgScore decimal(10,2), PhysicianCount int, PhysCountScore int, PhysScorePercent float)

set @counter = 1
while @counter <= (select max(ID) from #systems)
begin
	select @SystemID = SystemID from #systems where ID = @counter

	select @PhysicianCount = count(distinct NPI) from #footprint where SystemID = @SystemID
	select @AvgScore = avg(Score) from #footprint where ScoreType = 'Overall' and SystemID = @SystemID
	select @CountOverBenchmark = count(distinct NPI) from #footprint where ScoreType = 'Overall' and Score > 500 and SystemID = @SystemID
	select @NetworkScore = cast(@CountOverBenchmark as float) / cast(@PhysicianCount as float)

	update		#footprint
	set			PhysicianCount = @PhysicianCount,
				AvgScore = @AvgScore,
				CountOverBenchmark = @CountOverBenchmark,
				NetworkScore = @NetworkScore
	where		SystemID = @SystemID

	set @score_counter = 1
	while @score_counter <= (select max(ID) from #score_types)
	begin
		select @ScoreType = ScoreType from #score_types where ID = @score_counter

		select		@PhysicianCountScore = count(*)
		from		#footprint
		where		SystemID = @SystemID
		and			ScoreType = @ScoreType
		and			Score > 0

		select		@AvgScore = avg(Score)
		from		#footprint
		where		SystemID = @SystemID
		and			ScoreType = @ScoreType

		select @PhysicianScorePercentage = cast(@PhysicianCountScore as float) / cast(@PhysicianCount as float)

		insert		#overall
		select		distinct SystemID, SystemName, @ScoreType, @AvgScore, @PhysicianCount, @PhysicianCountScore, @PhysicianScorePercentage
		from		#footprint
		where		SystemID = @SystemID

		set @score_counter = @score_counter + 1
	end
	
	set @counter = @counter + 1
end

select * from #overall order by SystemName, PhysCountScore desc, ScoreType


drop table #footprint
drop table #systems
drop table #score_types
drop table #overall
