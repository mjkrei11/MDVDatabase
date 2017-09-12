
CREATE procedure [dbo].[sp_ssrs_FootprintQA_Archive] (
	@Database nvarchar(200),
	@CompOption int,
	@YearQuarter nvarchar(20)
)

as

/*
declare
@Database nvarchar(200),
@CompOption int

set @Database = 'Panorama'
set @CompOption = 0

exec sp_ssrs_FootprintQA @Database, @CompOption
*/

declare
@SystemID nvarchar(10),
@PhysicianCount int,
@AvgScore float,
@CountOverBenchmark int,
@NetworkScore float,
@CustomerID nvarchar(50),
@CustomerSource nvarchar(120),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1),
@counter int

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
	Score decimal(10,0),
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
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetSearchRelevanceArchiveMedia media ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetSearchRelevanceArchive metric ' + @CR
set @sql = @sql + 'on metric.XComboKey = media.XComboKey ' + @CR
set @sql = @sql + 'and media.YearQuarter = ''' + @YearQuarter + ''' ' + @CR
if @CompOption = 0
begin
	set @sql = @sql + 'and media.CollectionID = media.SystemID ' + @CR
end
if @CompOption <> 0
begin
	set @sql = @sql + 'and media.CollectionID <> media.SystemID ' + @CR
end
set @sql = @sql + 'and media.NPI not like ''S%'' and media.NPI not like ''G%'' and media.LastName <> ''System'' '
exec(@sql)

create table #systems(ID int identity, SystemID nvarchar(10))
insert		#systems
select		distinct SystemID
from		#footprint

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
	
	set @counter = @counter + 1
end

/***** POSITION *****/
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Position', 1, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1,
			(select f.ResultNo from #footprint f where f.NPI = #footprint.NPI and f.ScoreType = 'Practice - Profile'),
			Score,
			(select f.SourceLink from #footprint f where f.NPI = #footprint.NPI and f.ScoreType = 'Practice - Profile')
from		#footprint
where		ScoreType = 'Position'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'No Position', 2, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Position'
and			Score = 0

/***** PRACTICE *****/
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Pracitce - Profile', 3, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Practice - Profile'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'No Pracitce - Profile', 4, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Practice - Profile'
and			Score = 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Pracitce - Directory', 5, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Practice - Directory'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'No Pracitce - Directory', 6, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Practice - Directory'
and			Score = 0

/***** HOSPITAL *****/
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Hospital - Profile', 7, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Hospital - Profile'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'No Hospital - Profile', 8, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Hospital - Profile'
and			Score = 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Hospital - Directory', 9, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Hospital - Directory'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'No Hospital - Directory', 10, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Hospital - Directory'
and			Score = 0

/***** PERSONAL *****/
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'EC - Personal', 11, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'EC - Personal'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'No EC - Personal', 12, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'EC - Personal'
and			Score = 0

/***** BLOG *****/
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'EC - Blog', 13, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'EC - Blog'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'No EC - Blog', 14, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'EC - Blog'
and			Score = 0

/***** SOCIAL *****/
/* FACEBOOK */
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Social - Facebook', 15, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Social - Facebook'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Social - Facebook', 16, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Social - Facebook'
and			Score = 0
/* TWITTER */
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Social - Twitter', 17, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Social - Twitter'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Social - Twitter', 18, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Social - Twitter'
and			Score = 0
/* LINKEDIN */
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Social - LinkedIn', 19, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Social - LinkedIn'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Social - LinkedIn', 20, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Social - LinkedIn'
and			Score = 0
/* YOUTUBE */
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Social - YouTube', 21, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Social - YouTube'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Social - YouTube', 22, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Social - YouTube'
and			Score = 0
/* GOOGLEPLUS */
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Social - Google Plus', 23, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Social - Google Plus'
and			Score > 0
insert		#footprint(GroupName, OrderID, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, PhysicianCount, ResultNo, Score, SourceLink)
select		'Social - Google Plus', 24, SystemID, SystemName, NPI, FirstName, MiddleName, LastName, 1, ResultNo, Score, SourceLink
from		#footprint
where		ScoreType = 'Social - Google Plus'
and			Score = 0

select		*
from		#footprint
order by	OrderID, AvgScore desc, SystemName, LastName, FirstName, MiddleName

drop table #footprint
drop table #systems
