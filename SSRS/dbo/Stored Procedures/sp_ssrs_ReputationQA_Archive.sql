
CREATE procedure [dbo].[sp_ssrs_ReputationQA_Archive](
	@Database nvarchar(200),
	@CompOption int,
	@RatingsSite nvarchar(50),
	@YearQuarter nvarchar(20),
	@option int	
)

as

/*
declare
@Database nvarchar(200),
@CompOption int,
@RatingsSite nvarchar(50),
@YearQuarter nvarchar(20),
@option int

set @Database = 'Rothman'
set @CompOption = 0
set @RatingsSite = null
set @YearQuarter = '2015_Q2'
set @option = 4

exec sp_ssrs_ReputationQA_Archive @Database, @CompOption, @RatingsSite, @YearQuarter, @option
*/

declare
@CustomerID nvarchar(10),
@CustomerSource nvarchar(200)

declare
@TotalPhysicianCount int,
@AvgOverallRating float,
@TotalVolume int,
@CountOverBenchmark int,
@NetworkScore float,
@SpiderDate datetime

declare
@PhysicianCountWithScore int,
@PhysicianCountWithSource int,
@PhysicianCountWithoutScore int,
@PhysicianCountWIthoutSource int

declare
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13) 

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

set @sql = 'select @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID where isnull(CustomerSource, '''') != '''' '
set @parms = '@TempCustomerSource nvarchar(200) output, @TempCustomerID nvarchar(20) output'
exec sp_executesql	@sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

create table #phys_rep(
	CollectionID nvarchar(10),
	CollectionName nvarchar(200),
	SystemID nvarchar(10),
	SystemName nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(50),
	MiddleName nvarchar(50),
	LastName nvarchar(50),
	RatingsSite nvarchar(50),
	Rating float,
	Volume int,
	Percentile int,
	Color nvarchar(20),
	SourceLink nvarchar(4000),
	SpiderDate datetime
)

set @sql = 'insert #phys_rep ' + @CR
set @sql = @sql + 'select distinct media.CollectionID, media.CollectionName, media.SystemID, media.SystemName, media.NPI, media.FirstName, media.MiddleName, media.LastName, ' + @CR
set @sql = @sql + 'metric.RatingsSite, metric.Rating, metric.NumberOfRatings, metric.Percentile, metric.Color, metric.SourceLink, v.SpiderDate ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationArchive metric ' + @CR
set @sql = @sql + 'on metric.XComboKey = media.XComboKey ' + @CR
set @sql = @sql + 'left join MDVALUATE.dbo.vw_MasterPhysicianSearch v ' + @CRset @sql = @sql + 'on v.NPI = media.NPI ' + @CRset @sql = @sql + 'and v.SearchPattern = media.YearQuarter ' + @CRset @sql = @sql + 'and v.LinkTarget = metric.SourceLink ' + @CR
set @sql = @sql + 'where media.YearQuarter = ''' + @YearQuarter + ''' '
if @CompOption = 0
begin
	set @sql = @sql + 'and media.SystemID = media.CollectionID '
end
if @CompOption = 1
begin
	set @sql = @sql + 'and media.SystemID <> media.CollectionID '
end
set @sql = @sql + 'and media.NPI not like ''S%'' and media.NPI not like ''G%'' and media.LastName <> ''System'' '
exec(@sql)

/***** Option = 0 (Overall, Practice-Level Data) *****/
if @option = 0
begin
	select	@AvgOverallRating = round(avg(Rating), 2)
	from	#phys_rep
	where	RatingsSite = 'Sum All Sites'

	select	@TotalVolume = sum(Volume)
	from	#phys_rep
	where	RatingsSite = 'Sum All Sites'

	select	@CountOverBenchmark = count(NPI)
	from	#phys_rep
	where	RatingsSite = 'Sum All Sites'
	and		Rating >= 4.50

	select	@TotalPhysicianCount = count(NPI)
	from	#phys_rep
	where	RatingsSite = 'Sum All Sites'

	select	@NetworkScore = round(((@CountOverBenchmark * 1.0) / (@TotalPhysicianCount * 1.0) * 100.0), 0)

	select @SpiderDate = min(SpiderDate) from #phys_rep

	select @AvgOverallRating AvgOverallRating, @TotalVolume TotalVolume, @CountOverBenchmark CountOverBenchmark, @TotalPhysicianCount TotalPhysicianCount, @NetworkScore NetworkScore, @SpiderDate SpiderDate
			
end
/***** Option = 1 (Ratings Site Aggregates with Rating) *****/
if @option = 1
begin
	create table #ratings_sites(
		RatingsSite nvarchar(50),
		PhysicianCount int,
		AvgRating float,
		TotalVolume int
	)

	insert		#ratings_sites
	select		distinct RatingsSite,
				count(NPI),
				round(avg(Rating), 2),
				sum(Volume)
	from		#phys_rep
	where		Volume > 0
	and			RatingsSite <> 'Sum All Sites'
	group by	RatingsSite

	select		*
	from		#ratings_sites
	order by	PhysicianCount desc, AvgRating desc, TotalVolume desc, RatingsSite

	drop table #ratings_sites
end
/***** Option = 2 (Physician Results by RatingsSite, including overall) *****/
if @option = 2
begin
	if @RatingsSite is null
	begin
		select		CollectionName, SystemName, NPI, FirstName, MiddleName, LastName, RatingsSite, Rating, Volume, Percentile, Color
		from		#phys_rep
		where		RatingsSite = 'Sum All Sites'
		order by	CollectionName, Percentile desc, SystemName, Volume desc, LastName, FirstName
	end
	else
	begin
		select		CollectionName, SystemName, NPI, FirstName, MiddleName, LastName, RatingsSite, Rating, Volume, SourceLink
		from		#phys_rep
		where		RatingsSite = @RatingsSite
		order by	CollectionName, Percentile desc, SystemName, Volume desc, SourceLink desc, LastName, FirstName
	end
end
/***** Option = 3 (Physicians with Data) *****/
if @option = 3
begin
	create table #source_links(
		CollectionName nvarchar(200),
		SystemName nvarchar(200),
		NPI nvarchar(10),
		FirstName nvarchar(50),
		MiddelName nvarchar(50),
		LastName nvarchar(50),
		SourceLinkCount int
	)
	
	insert		#source_links
	select		CollectionName, SystemName, NPI, FirstName, MiddleName, LastName, count(SourceLink)
	from		#phys_rep
	where		SourceLink is not null
	group by	CollectionName, SystemName, NPI, FirstName, MiddleName, LastName

	if @RatingsSite is null
	begin
		set @RatingsSite = 'Sum All Sites'

		select	@PhysicianCountWithScore = count(NPI)
		from	#phys_rep
		where	RatingsSite = @RatingsSite
		and		Rating > 0

		select	@PhysicianCountWithSource = count(NPI)
		from	#source_links
		where	SourceLinkCount > 0

		select	@PhysicianCountWithoutScore = count(NPI)
		from	#phys_rep
		where	RatingsSite = @RatingsSite
		and		Rating = 0

		select	@PhysicianCountWithoutSource = count(NPI)
		from	#source_links
		where	isnull(SourceLinkCount, 0) = 0
	end
	else
	begin
		select	@PhysicianCountWithScore = count(NPI)
		from	#phys_rep
		where	RatingsSite = @RatingsSite
		and		Rating > 0

		select	@PhysicianCountWithSource = count(NPI)
		from	#phys_rep
		where	RatingsSite = @RatingsSite
		and		SourceLink is not null

		select	@PhysicianCountWithoutScore = count(NPI)
		from	#phys_rep
		where	RatingsSite = @RatingsSite
		and		Rating = 0

		select	@PhysicianCountWithoutSource = count(NPI)
		from	#phys_rep
		where	RatingsSite = @RatingsSite
		and		SourceLink is null
	end

	select	@RatingsSite RatingsSite,
			@PhysicianCountWithScore PhysicianCountWithScore, @PhysicianCountWithSource PhysicianCountWithSource,
			@PhysicianCountWithoutScore PhysicianCountWithoutScore, @PhysicianCountWithoutSource PhysicianCountWithoutSource

	drop table #source_links
end
/***** Option = 4 (Physicians with Source Link Data) *****/
if @option = 4
begin
	create table #source_link_counts(
		RatingsSite nvarchar(50),
		PhysicianCount int,
		TotalPhysicianCount int
	)
	
	insert		#source_link_counts(RatingsSite, PhysicianCount)
	select		RatingsSite, count(NPI)
	from		#phys_rep
	where		SourceLink is not null
	group by	RatingsSite

	declare @Totals int

	select @Totals = count(distinct NPI) from #phys_rep

	update #source_link_counts set TotalPhysicianCount = @Totals


	select		*
	from		#source_link_counts
	order by	PhysicianCount desc, RatingsSite

	drop table #source_link_counts
end

--select		*
--from		#phys_rep
--order by	Percentile desc, Volume desc, LastName, FirstName

drop table #phys_rep
