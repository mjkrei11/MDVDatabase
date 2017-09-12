

CREATE procedure [dbo].[sp_ssrs_ReputationQA_Specialties](
	@Database nvarchar(200),
	@CompOption int,
	@RatingsSite nvarchar(50),
	@option int	
)

as

/*
declare
@Database nvarchar(200),
@CompOption int,
@RatingsSite nvarchar(50),
@option int

set @Database = 'MedStarOrtho'
set @RatingsSite = null
set @CompOption = 1
set @option = 0

exec sp_ssrs_ReputationQA_Specialties @Database, @CompOption, @RatingsSite, @option
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
@Specialty nvarchar(200),
@Percentile float,
@Color nvarchar(20),
@Rating decimal(3,2),
@counter int,
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
	Specialty nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(50),
	LastName nvarchar(200),
	RatingsSite nvarchar(50),
	Rating float,
	Volume int,
	Percentile int,
	Color nvarchar(20),
	SourceLink nvarchar(4000),
	SpiderDate datetime
)

set @sql = 'insert #phys_rep ' + @CR
set @sql = @sql + 'select media.CollectionID, media.CollectionName, media.SystemID, media.SystemName, metric.Specialty, media.NPI, media.FirstName, media.MiddleName, media.LastName, ' + @CR
set @sql = @sql + 'metric.RatingsSite, metric.Rating, metric.NumberOfRatings, metric.Percentile, metric.Color, metric.SourceLink, metric.LoadDate ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputation metric ' + @CR
set @sql = @sql + 'on metric.ComboKey = media.ComboKey ' + @CR
if @CompOption = 0
begin
	set @sql = @sql + 'where media.SystemID = media.CollectionID ' + @CR
end
if @CompOption = 1
begin
	set @sql = @sql + 'where media.SystemID <> media.CollectionID ' + @CR
end
set @sql = @sql + 'and media.NPI not like ''S%'' and media.NPI not like ''G%'' '
exec(@sql)

create table #specialties (ID int identity, Specialty nvarchar(200))
insert #specialties(Specialty) select distinct Specialty from #phys_rep

create table #docs (ID int identity, NPI nvarchar(10))

--option 0
create table #overall (
	Specialty nvarchar(200),
	AvgOverallRating decimal(3,2),
	TotalVolume int,
	CountOverBenchmark int,
	TotalPhysicianCount int,
	NetworkScore int,
	SpiderDate datetime,
	Color nvarchar(20)
)

--option 1
create table #ratings_sites(
	Specialty nvarchar(200),
	RatingsSite nvarchar(50),
	PhysicianCount int,
	AvgRating float,
	TotalVolume int
)

--option 3
create table #source_links (
	Specialty nvarchar(200),
	CollectionName nvarchar(200),
	SystemName nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(50),
	MiddelName nvarchar(50),
	LastName nvarchar(50),
	SourceLinkCount int
)

--option 4
create table #source_link_counts (
	Specialty nvarchar(200),
	RatingsSite nvarchar(50),
	PhysicianCount int,
	TotalPhysicianCount int
)

declare
@Totals int

set @counter = 1
while @counter <= (select max(ID) from #specialties)
begin
	select @Specialty = Specialty from #specialties where ID = @counter

	truncate table #docs
	insert #docs(NPI) select distinct NPI from #phys_rep where Specialty = @Specialty

	/***** Option = 0 (Overall, Practice-Level Data) *****/
	if @option = 0
	begin
		
		set @sql = 'select @TempPercentile = metric.Percentile, @TempColor = metric.Color, @TempRating = metric.Rating ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationMedia media '
		set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputation metric ' + @CR
		set @sql = @sql + 'on metric.ComboKey = media.ComboKey ' + @CR
		set @sql = @sql + 'where metric.RatingsSite = ''Sum All Sites'' ' + @CR
		set @sql = @sql + 'and metric.Specialty = ''' + @Specialty + ''' ' + @CR
		set @parms = '@TempPercentile float output, @TempColor nvarchar(20) output, @TempRating decimal(3,2) output'
		exec sp_executesql	@sql, @parms, @TempPercentile = @Percentile output, @TempColor = @Color output, @TempRating = @Rating output

		select		@AvgOverallRating = round(avg(p.Rating), 2)
		from		#phys_rep p
		inner join	#docs d
		on			d.NPI = p.NPI
		where		p.RatingsSite = 'Sum All Sites'
		and			p.Specialty = @Specialty

		select		@TotalVolume = sum(p.Volume)
		from		#phys_rep p
		inner join	#docs d
		on			d.NPI = p.NPI
		where		p.RatingsSite = 'Sum All Sites'
		and			p.Specialty = @Specialty

		select		@CountOverBenchmark = count(p.NPI)
		from		#phys_rep p
		inner join	#docs d
		on			d.NPI = p.NPI
		where		p.RatingsSite = 'Sum All Sites'
		and			p.Rating >= 4.50
		and			p.Specialty = @Specialty

		select		@TotalPhysicianCount = count(p.NPI)
		from		#phys_rep p
		inner join	#docs d
		on			d.NPI = p.NPI
		where		p.RatingsSite = 'Sum All Sites'
		and			p.Specialty = @Specialty

		--select	@NetworkScore = round(((@CountOverBenchmark * 1.0) / (@TotalPhysicianCount * 1.0) * 100.0), 0)
		select @NetworkScore = @Percentile

		select		@SpiderDate = min(p.SpiderDate)
		from		#phys_rep p
		inner join	#docs d
		on			d.NPI = p.NPI
		where		p.Specialty = @Specialty

		insert #overall select @Specialty, @Rating, @TotalVolume, @CountOverBenchmark, @TotalPhysicianCount, @NetworkScore, @SpiderDate, @Color	
	end

	/***** Option = 1 (Ratings Site Aggregates with Rating) *****/
	if @option = 1
	begin
		insert		#ratings_sites
		select		distinct p.Specialty, p.RatingsSite, count(p.NPI), round(avg(p.Rating), 2), sum(p.Volume)
		from		#phys_rep p
		inner join	#docs d
		on			d.NPI = p.NPI
		where		p.Volume > 0
		and			p.RatingsSite <> 'Sum All Sites'
		group by	p.Specialty, p.RatingsSite
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
		insert		#source_links
		select		p.Specialty, p.CollectionName, p.SystemName, p.NPI, p.FirstName, p.MiddleName, p.LastName, count(p.SourceLink)
		from		#phys_rep p
		inner join	#docs d
		on			d.NPI = p.NPI
		where		p.SourceLink is not null
		and			p.Specialty = @Specialty
		group by	p.CollectionName, p.SystemName, p.NPI, p.FirstName, p.MiddleName, p.LastName

		if @RatingsSite is null
		begin
			set @RatingsSite = 'Sum All Sites'

			select		@PhysicianCountWithScore = count(p.NPI)
			from		#phys_rep p
			inner join	#docs d
			on			d.NPI = p.NPI
			where		p.RatingsSite = @RatingsSite
			and			p.Specialty = @Specialty
			and			p.Rating > 0

			select		@PhysicianCountWithSource = count(NPI)
			from		#source_links
			where		SourceLinkCount > 0

			select		@PhysicianCountWithoutScore = count(p.NPI)
			from		#phys_rep p
			inner join	#docs d
			on			d.NPI = p.NPI
			where		p.RatingsSite = @RatingsSite
			and			p.Rating = 0
			and			p.Specialty = @Specialty

			select		@PhysicianCountWithoutSource = count(NPI)
			from		#source_links
			where		isnull(SourceLinkCount, 0) = 0
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
	end
	/***** Option = 4 (Physicians with Source Link Data) *****/
	if @option = 4
	begin	
		insert		#source_link_counts(Specialty, RatingsSite, PhysicianCount)
		select		p.Specialty, p.RatingsSite, count(p.NPI)
		from		#phys_rep p
		inner join	#docs d
		on			d.NPI = p.NPI
		where		p.SourceLink is not null
		and			p.Specialty = @Specialty
		group by	p.Specialty, p.RatingsSite

		select		@Totals = count(distinct p.NPI)
		from		#phys_rep p
		inner join	#docs d
		on			d.NPI = p.NPI
		where		p.Specialty = @Specialty

		update		#source_link_counts
		set			TotalPhysicianCount = @Totals
		where		Specialty = @Specialty
	end

	set @counter = @counter + 1
end

if @option = 0
begin
	select		*
	from		#overall
	order by	NetworkScore desc
end
if @option = 1
begin
	select		*
	from		#ratings_sites
	order by	Specialty, PhysicianCount desc, AvgRating desc, TotalVolume desc, RatingsSite
end
if @option = 4
begin
	select		*
	from		#source_link_counts
	order by	Specialty, PhysicianCount desc, RatingsSite
end

drop table #phys_rep
drop table #specialties
drop table #docs
drop table #overall
drop table #source_link_counts
drop table #source_links
drop table #ratings_sites
