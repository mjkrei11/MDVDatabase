





CREATE procedure [dbo].[sp_ssrs_DIFFBOT_PhysicianRatingUpdate_Copy] (@Database nvarchar(200), @Month int)

as

/*
declare
@Database nvarchar(200), @Month int
set @Database = 'Rothman'
set @Month = 3

exec sp_ssrs_DIFFBOT_PhysicianRatingUpdate_Copy @Database, @Month
*/

declare
@baseline_check int,
@record_check int,
@YearQuarter nvarchar(20),
--@BatchID int,
@StartBatchID int,
@EndBatchID int,
@Logo varbinary(max),
@CustomerID nvarchar(50),
@CustomerSource nvarchar(120),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

select top 1 @Logo = cast(BinData as varbinary(max)) from MDVALUATE.dbo.MetricRangeMediaSection where NPI = @CustomerID

set @sql = 'select @TempStartBatchID = min(BatchID), @TempEndBatchID = max(BatchID) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where datepart(month, SearchDate) = ''' + cast(@Month as nvarchar(10)) + ''' and BatchID > 0 ' + @CR
set @parms = '@TempStartBatchID int output, @TempEndBatchID int output'
exec sp_executesql @sql, @parms, @TempStartBatchID = @StartBatchID output, @TempEndBatchID = @EndBatchID output

create table #physician_media(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	Photo varbinary(max),
	Logo varbinary(max)
)

set @sql = 'insert #physician_media ' + @CR
set @sql = @sql + 'select pm.NPI, pm.FirstName, pm.MiddleName, pm.LastName, pd.BinData, null ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia pm ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.PhysicianDoc pd ' + @CR
set @sql = @sql + 'on pd.NPI = pm.NPI ' + @CR
set @sql = @sql + 'and pd.DocType <> ''PDF'' ' + @CR
set @sql = @sql + 'where pm.Status = ''Active'' ' + @CR
exec(@sql)

update	#physician_media
set		Logo = @Logo

create table #sites(ID int identity, SiteName nvarchar(50))
insert #sites (SiteName) select 'HealthGrades'
insert #sites (SiteName) select 'Vitals'
insert #sites (SiteName) select 'UCompare'
insert #sites (SiteName) select 'RateMDs'

create table #npi (ID int identity, NPI nvarchar(10))
set @sql = 'insert #npi (NPI) select distinct NPI from ' + @Database + '.dbo.PhysicianMedia where Status = ''Active'' ' + @CR
exec(@sql)

create table #current_ratings(
	NPI nvarchar(10), 
	SiteName nvarchar(50), 
	ResultRating decimal(2,1), 
	ResultVolume int, 
	SearchDate datetime, 
	ResultLink nvarchar(4000)
)

declare @site_counter int, @npi_counter int, @SiteName nvarchar(50), @NPI nvarchar(10)

set @site_counter = 1
while @site_counter <= (select max(ID) from #sites)
begin
    select @SiteName = SiteName from #sites where ID = @site_counter

    set @npi_counter = 1
    while @npi_counter <= (select max(ID) from #npi)
    begin
        select @NPI = NPI from #npi where ID = @npi_counter

        set @sql = 'insert #current_ratings(NPI, SiteName, ResultRating, ResultVolume, SearchDate, ResultLink) ' + @CR
        set @sql = @sql + 'select top 1 NPI, SiteName, isnull(ResultRating, 0), isnull(ResultVolume, 0), SearchDate, ResultLink ' + @CR
        set @sql = @sql + 'from  ' + @Database + '.dbo.DIFFBOT_ResultLinks  ' + @CR
        set @sql = @sql + 'where SiteName = ''' + @SiteName + ''' ' + @CR
        set @sql = @sql + 'and NPI = ''' + @NPI + ''' ' + @CR
        set @sql = @sql + 'and BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''' ' + @CR
		--set @sql = @sql + 'and CustomerID = ''' + @CustomerID + ''' ' + @CR
        set @sql = @sql + 'order by ResultVolume desc ' + @CR
		--print(@sql)
		exec(@sql)

        set @npi_counter = @npi_counter + 1
    end

    set @site_counter = @site_counter + 1
end

--select * from #current_ratings where NPI = '1477864049'

drop table #sites
drop table #npi
--drop table #current_ratings

--select * from #current_ratings where npi = '1629025994'

--create table #comments(
--	NPI nvarchar(10),
--	SiteName nvarchar(100),
--	CommentDate datetime,
--	CommentRating nvarchar(max),
--	CommentText nvarchar(max)
--)

--set @sql = 'insert #comments ' + @CR
--set @sql = @sql + 'select distinct c.NPI, c.SiteName, convert(varchar, c.CommentDate, 101) as CommentDate, c.IsNegative, isnull(c.CommentText, ''None'')' + @CR
--set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_Comments c  ' + @CR
--set @sql = @sql + 'where datepart(month, c.CommentDate) = ''' + cast(@Month as nvarchar(5)) + ''' and datepart(year, c.CommentDate) =  ''2017'' ' + @CR
--set @sql = @sql + 'and len(ltrim(rtrim(c.CommentText))) > 3 and c.CommentText <> ''show details'' ' + @CR
--set @sql = @sql + 'and c.CustomerID = ''' + @CustomerID + ''' ' + @CR
--set @sql = @sql + 'and c.SiteName in (''HealthGrades'', ''Vitals'', ''RateMDs'', ''UCompare'') ' + @CR
----print(@sql)
--exec(@sql)

create table #current(
	NPI nvarchar(10),
	ScoreType nvarchar(20),
	SiteName nvarchar(100),
	Rating decimal(2,1),
	Volume int,
	CurrentDate datetime,
	ResultLink nvarchar(max)--,
	--CommentDate datetime,
	--CommentRating nvarchar(max),
	--CommentText nvarchar(max)
)

insert		#current
select		distinct r.NPI, 'Updated' as ScoreType, r.SiteName, r.ResultRating, r.ResultVolume, r.SearchDate, r.ResultLink--, c.CommentDate, c.CommentRating, isnull(c.CommentText, 'None')
from		#current_ratings r
--left join	#comments c
--on			c.SiteName = r.SiteName
--and			c.NPI = r.NPI
--group by	r.NPI, r.SiteName, r.ResultRating, r.ResultVolume, r.SearchDate, r.ResultLink, c.CommentDate, c.CommentRating, c.CommentText

--select * from #current where NPI = '1477864049'

drop table #current_ratings
--drop table #comments

create table #phys_sites(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	FullName nvarchar(400),
	BaselineRatingsSite nvarchar(50),
	BaselineScoreType nvarchar(50),
	BaselineRatingScore decimal(2,1),
	BaselineVolumeScore int,
	BaselineDate datetime,
	CurrentRatingsSite nvarchar(50),
	CurrentScoreType nvarchar(50),
	CurrentRatingScore decimal(2,1),
	CurrentVolumeScore int,
	CurrentDate datetime,
	Photo varbinary(max),
	Logo varbinary(max),
	ResultLink nvarchar(max),
	CommentDate datetime,
	CommentRating nvarchar(max),
	CommentText nvarchar(max)
)

insert #phys_sites
select	NPI, FirstName, LastName, null as FullName, 'HealthGrades' as SiteName, 'Baseline', '0' as Rating, '0' as Volume, 
		null as BaselineDate, 'HealthGrades' as CurrentRatingsSite, 'Updated' as CurrentScoreType, null as CurrentRatingScore, 
		null as CurrentVolumeScore, null as CurrentDate, null as Photo, null as Logo, null as ResultLink,
		null as CommentDate, null as CommentRating, null as CommentText
from #physician_media
union
select	NPI, FirstName, LastName, null as FullName, 'Vitals' as SiteName, 'Baseline', '0' as Rating, '0' as Volume,
		null as BaselineDate, 'Vitals' as CurrentRatingsSite, 'Updated' as CurrentScoreType, null as CurrentRatingScore, 
		null as CurrentVolumeScore, null as CurrentDate, null as Photo, null as Logo, null as ResultLink,
		null as CommentDate, null as CommentRating, null as CommentText 
from #physician_media
union
select	NPI, FirstName, LastName, null as FullName, 'UCompare' as SiteName, 'Baseline', '0' as Rating, '0' as Volume,
		null as BaselineDate, 'UCompare' as CurrentRatingsSite, 'Updated' as CurrentScoreType, null as CurrentRatingScore, 
		null as CurrentVolumeScore, null as CurrentDate, null as Photo, null as Logo, null as ResultLink,
		null as CommentDate, null as CommentRating, null as CommentText
from #physician_media
union
select	NPI, FirstName, LastName, null as FullName, 'RateMDs' as SiteName, 'Baseline', '0' as Rating, '0' as Volume, 
		null as BaselineDate, 'RateMDs' as CurrentRatingsSite, 'Updated' as CurrentScoreType, null as CurrentRatingScore, 
		null as CurrentVolumeScore, null as CurrentDate, null as Photo, null as Logo, null as ResultLink,
		null as CommentDate, null as CommentRating, null as CommentText
from #physician_media

--select * from #phys_sites

create table #baseline(
	NPI nvarchar(10),
	ScoreType nvarchar(20),
	SiteName nvarchar(100),
	Rating decimal(2,1),
	Volume int,
	BaselineDate datetime
)

set @sql = 'insert #baseline ' + @CR
set @sql = @sql + 'select substring(XComboKey,1,10) as NPI, ''Baseline'' as ScoreType, case RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else RatingsSite end, ' + @CR
set @sql = @sql + 'isnull(Rating, 0.0), isnull(NumberOfRatings, 0), ''5/6/2015'' as BaselineDate ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchive ' + @CR
set @sql = @sql + 'where XComboKey like ''%_1649324195_2015_Q2'' ' + @CR
--set @sql = @sql + 'where XComboKey like ''%_'' ''' + @CustomerID + ''' ''_2015_Q2'' ' + @CR
set @sql = @sql + 'and RatingsSite in (''HealthGrades'',''Ucompare'',''Rate MD Secure'',''Vitals'') ' + @CR
--print(@sql)
exec(@sql)

--select * from #baseline

create table #physician_rating_site_data(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	FullName nvarchar(400),
	BaselineRatingsSite nvarchar(50),
	BaselineScoreType nvarchar(50),
	BaselineRatingScore decimal(2,1),
	BaselineVolumeScore int,
	BaselineDate datetime,
	CurrentRatingsSite nvarchar(50),
	CurrentScoreType nvarchar(50),
	CurrentRatingScore decimal(2,1),
	CurrentVolumeScore int,
	CurrentDate datetime,
	Photo varbinary(max),
	Logo varbinary(max),
	ResultLink nvarchar(max),
	CommentDate datetime,
	CommentRating nvarchar(max),
	CommentText nvarchar(max)
)

insert	#physician_rating_site_data(NPI, FirstName, LastName, FullName, 
			BaselineRatingsSite, BaselineScoreType,	BaselineRatingScore, BaselineVolumeScore, BaselineDate, 
			CurrentRatingsSite, CurrentScoreType, CurrentRatingScore, CurrentVolumeScore, CurrentDate,
			Photo, Logo, ResultLink, CommentDate, CommentRating, CommentText)
select	distinct a.NPI, a.FirstName, a.LastName, a.LastName + ', ' + a.FirstName, b.SiteName,
		b.ScoreType, b.Rating, b.Volume, convert(nvarchar(11), b.BaselineDate, 101) as BaselineDate,
		c.SiteName, c.ScoreType, c.Rating, c.Volume, convert(nvarchar(11), c.CurrentDate, 101) as CurrentDate,
		a.Photo, a.Logo, c.ResultLink,
		NULL as CommentDate, NULL as CommentRating, NULL as CommentText
		--c.CommentDate, c.CommentRating, c.CommentText
from	#physician_media a
		left join #baseline b on b.NPI = a.NPI
		left join #current c on c.NPI = b.NPI	
			and c.SiteName = b.SiteName

--select *
--from #physician_rating_site_data

create table #physician_rating_site_data_Baseline(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	FullName nvarchar(400),
	BaselineRatingsSite nvarchar(50),
	BaselineScoreType nvarchar(50),
	BaselineRatingScore decimal(2,1),
	BaselineVolumeScore int,
	BaselineDate datetime,
	CurrentRatingsSite nvarchar(50),
	CurrentScoreType nvarchar(50),
	CurrentRatingScore decimal(2,1),
	CurrentVolumeScore int,
	CurrentDate datetime,
	Photo varbinary(max),
	Logo varbinary(max),
	ResultLink nvarchar(max),
	CommentDate datetime,
	CommentRating nvarchar(max),
	CommentText nvarchar(max)
)
set @sql = 'insert #physician_rating_site_data_Baseline(NPI, FirstName, LastName, FullName, ' + @CR
set @sql = @sql + 'BaselineRatingsSite, BaselineScoreType,	BaselineRatingScore, BaselineVolumeScore, BaselineDate, ' + @CR
set @sql = @sql + 'CurrentRatingsSite, CurrentScoreType, CurrentRatingScore, CurrentVolumeScore, CurrentDate, ' + @CR
set @sql = @sql + 'Photo, Logo, ResultLink, CommentDate, CommentRating, CommentText) ' + @CR 
set @sql = @sql + 'select distinct a.NPI, a.FirstName, a.LastName, a.LastName + '', '' + a.FirstName, case a.BaselineRatingsSite when ''Rate MD Secure'' then ''RateMDs'' else a.BaselineRatingsSite end, ' + @CR
set @sql = @sql + '''Baseline'' as BaselineScoreType, isnull(b.BaselineRating,0), isnull(b.BaselineNumberofRatings,0), substring(NPITrend,12,21) as BaselineDate, ' + @CR
set @sql = @sql + 'case d.SiteName when ''Rate MD Secure'' then ''RateMDs'' else d.SiteName end, ''Updated'' as CurrentScoreType, d.Rating, d.Volume, convert(nvarchar(11), d.CurrentDate, 101) as CurrentDate, ' + @CR
set @sql = @sql + 'c.Photo, c.Logo, d.ResultLink, ' + @CR
set @sql = @sql + 'NULL as CommentDate, NULL as CommentRating, NULL as CommentText ' + @CR
--set @sql = @sql + 'd.CommentDate, d.CommentRating, d.CommentText ' + @CR
set @sql = @sql + 'from #physician_rating_site_data a ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.VIRepBaseline b on substring(b.NPITrend,1,10) = a.NPI ' + @CR
set @sql = @sql + 'left join #physician_media c on c.NPI = substring(b.NPITrend,1,10) ' + @CR
set @sql = @sql + 'left join #current d on d.NPI = a.NPI and d.SiteName = b.BaselineSite ' + @CR 
set @sql = @sql + 'where a.BaselineRatingsSite is NULL ' + @CR
set @sql = @sql + 'and b.BaselineSite in (''HealthGrades'',''Ucompare'',''RateMDs'',''Vitals'') ' + @CR
--print(@sql)
exec(@sql)

--This updates the #phys_sites table with data from the #physician_rating_site_data_Baseline
update a
set a.FullName = b.FullName, 
	a.BaselineRatingScore = b.BaselineRatingScore,
	a.BaselineVolumeScore = b.BaselineVolumeScore, 
	a.BaselineDate = b.BaselineDate,
	a.CurrentRatingScore = b.CurrentRatingScore, 
	a.CurrentVolumeScore = b.CurrentVolumeScore, 
	a.CurrentDate = b.CurrentDate, 
	a.Photo = b.Photo, 
	a.Logo = b.Logo, 
	a.ResultLink = b.ResultLink--,
	--a.CommentDate = b.CommentDate, 
	--a.CommentRating = b.CommentRating, 
	--a.CommentText = b.CommentText
from #phys_sites a
left join #physician_rating_site_data_Baseline b on b.NPI = a.NPI	
	and b.CurrentRatingsSite = a.CurrentRatingsSite
	and b.BaselineScoreType = a.BaselineScoreType

/*
	If a baseline is coming from the #phys_sites table, 
	the FullName column will be blank
	as well as the BaselineRatingScore & BaselineVolumeScore.
	This update populates those blank columns.
*/
update a
set a.FullName = a.LastName + ', ' + a.FirstName, 
	a.BaselineRatingScore = '0.0',
	a.BaselineVolumeScore = '0'
from #phys_sites a
where a.FullName is null

--select * from #phys_sites order by LastName

delete from #physician_rating_site_data
where BaselineRatingsSite is NULL

create table #physician_ratings_volume(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	FullName nvarchar(400),
	RatingsSite nvarchar(50),
	ScoreType nvarchar(50),
	RatingScore decimal(2,1),
	VolumeScore int,
	ScoreDate datetime,
	BaselineRatingScore decimal(2,1),
	BaselineVolumeScore int,
	BaselineDate datetime,
	CurrentRatingsSite nvarchar(50),
	CurrentScoreType nvarchar(50),
	CurrentRatingScore decimal(2,1),
	CurrentVolumeScore int,
	CurrentDate datetime,
	Photo varbinary(max),
	Logo varbinary(max),
	ResultLink nvarchar(max),
	CommentDate datetime,
	CommentRating nvarchar(max),
	CommentText nvarchar(max)
)

insert #physician_ratings_volume
select	distinct NPI, 
		FirstName,
		LastName, 
		FullName, 
		BaselineRatingsSite as RatingsSite, 
		BaselineScoreType as ScoreType, 
		BaselineRatingScore as RatingScore, 
		BaselineVolumeScore as VolumeScore, 
		BaselineDate as ScoreDate,
		BaselineRatingScore, 
		BaselineVolumeScore, 
		BaselineDate,
		CurrentRatingsSite,
		CurrentScoreType, 
		CurrentRatingScore,
		CurrentVolumeScore, 
		CurrentDate, 
		Photo, 
		Logo, 
		ResultLink, 
		NULL as CommentDate,
		NULL as CommentRating,
		NULL as CommentText
from #phys_sites
where BaselineScoreType = 'Baseline'
union
select	distinct NPI, 
		FirstName,
		LastName, 
		FullName, 
		BaselineRatingsSite as RatingsSite, 
		BaselineScoreType as ScoreType, 
		BaselineRatingScore as RatingScore, 
		BaselineVolumeScore as VolumeScore, 
		BaselineDate as ScoreDate,
		BaselineRatingScore, 
		BaselineVolumeScore, 
		BaselineDate,
		CurrentRatingsSite,
		CurrentScoreType, 
		CurrentRatingScore,
		CurrentVolumeScore, 
		CurrentDate,  
		Photo, 
		Logo, 
		ResultLink, 
		NULL as CommentDate,
		NULL as CommentRating,
		NULL as CommentText
from #physician_rating_site_data
where BaselineScoreType = 'Baseline'
union
select	distinct NPI, 
		FirstName,
		LastName, 
		FullName, 
		CurrentRatingsSite as RatingsSite, 
		CurrentScoreType as ScoreType,
		CurrentRatingScore as RatingScore, 
		CurrentVolumeScore as VolumeScore, 
		CurrentDate as ScoreDate, 
		BaselineRatingScore, 
		BaselineVolumeScore, 
		BaselineDate,
		CurrentRatingsSite,
		CurrentScoreType, 
		CurrentRatingScore,
		CurrentVolumeScore, 
		CurrentDate, 
		Photo, 
		Logo, 
		ResultLink, 
		CommentDate,
		CommentRating,
		CommentText
from #physician_rating_site_data_Baseline
where CurrentScoreType = 'Updated'
union
select	distinct NPI, 
		FirstName,
		LastName, 
		FullName, 
		CurrentRatingsSite as RatingsSite, 
		CurrentScoreType as ScoreType,
		CurrentRatingScore as RatingScore, 
		CurrentVolumeScore as VolumeScore, 
		CurrentDate as ScoreDate, 
		BaselineRatingScore, 
		BaselineVolumeScore, 
		BaselineDate,
		CurrentRatingsSite,
		CurrentScoreType, 
		CurrentRatingScore,
		CurrentVolumeScore, 
		CurrentDate,  
		Photo, 
		Logo, 
		ResultLink, 
		CommentDate,
		CommentRating,
		CommentText
from #physician_rating_site_data
where CurrentScoreType = 'Updated'
order by LastName, FirstName, RatingsSite, ScoreType

/*	Get rid of Baseline NULL dates when there
	is a legit Baseline date for any given
	NPI and RatingsSite
*/
create table #dups
(
	ID int identity
,	NPI nvarchar(10)
,	RatingsSite nvarchar(50)
,	BaselineRecordCount int
)
insert		#dups(NPI, RatingsSite, BaselineRecordCount)
select		NPI, RatingsSite, count(*)
from		#physician_ratings_volume
where		ScoreType = 'Baseline'
group by	NPI, RatingsSite

delete		p
from		#dups d
inner join	#physician_ratings_volume p
on			p.NPI = d.NPI
and			p.RatingsSite = d.RatingsSite
where		d.BaselineRecordCount > 1
and			p.ScoreDate is null

/*
	This gets the distinct Baseline Date
	then that Baseline Date is updated 
	for any ScoreTypes that are a Baseline and
	the date is NULL
*/
create table #baseline_date(
	NPI nvarchar(10),
	ScoreDate datetime,
	Photo varbinary(max),
	Logo varbinary(max)
)
insert #baseline_date
select distinct NPI, ScoreDate, Photo, Logo
from #physician_ratings_volume
where ScoreType = 'Baseline'
	and ScoreDate is not null

update a
set a.ScoreDate = b.ScoreDate,
	a.BaselineDate = b.ScoreDate,
	a.Photo = b.Photo,
	a.Logo = b.Logo
from #physician_ratings_volume a 
	inner join #baseline_date b on b.NPI = a.NPI 
where a.ScoreType = 'Baseline'
	and a.ScoreDate is null

--select * from #physician_ratings_volume order by LastName

update a
set a.RatingsSite = b.SiteName,
	a.CurrentScoreType = b.ScoreType,
	a.CurrentRatingScore = b.Rating,
	a.CurrentVolumeScore = b.Volume,
	a.CurrentDate = b.CurrentDate--,
	--a.CommentDate = b.CommentDate,
	--a.CommentRating = b.CommentRating,
	--a.CommentText = b.CommentText
from #physician_ratings_volume a
	inner join #current b on b.NPI = a.NPI
		and b.ScoreType = a.CurrentScoreType
		and b.SiteName = a.CurrentRatingsSite

/*
	If a Updated CurrentRatingScore & CurrentVolumeScore is NULL,
	this update populates those blank columns.
*/
update #physician_ratings_volume
set CurrentRatingScore = '0.0',
	CurrentVolumeScore = '0'
where CurrentRatingScore is null

insert #physician_ratings_volume(NPI, FirstName, LastName, FullName, RatingsSite,
		ScoreType, RatingScore, VolumeScore,ScoreDate, BaselineRatingScore, BaselineVolumeScore,
		BaselineDate, CurrentRatingsSite, CurrentScoreType, CurrentRatingScore, CurrentVolumeScore,
		CurrentDate, Photo, Logo)
select	NPI, FirstName, LastName, FullName, RatingsSite, 'Updated' as ScoreType,
		CurrentRatingScore as RatingScore, CurrentVolumeScore as VolumeScore,
		NULL as ScoreDate, BaselineRatingScore, BaselineVolumeScore,
		BaselineDate, CurrentRatingsSite, CurrentScoreType, CurrentRatingScore, CurrentVolumeScore,
		CurrentDate, Photo, Logo
from #physician_ratings_volume
where ScoreType = 'Baseline'
and BaselineRatingScore = '0.0'

/*
	This gets the distinct Curent Date
	the Current Date is updated 
	for any ScoreTypes that are a Updated and
	the date is NULL
*/
create table #current_date(
	NPI nvarchar(10),
	ScoreDate datetime,
	Photo varbinary(max),
	Logo varbinary(max)
)
insert #current_date
select distinct NPI, ScoreDate, Photo, Logo
from #physician_ratings_volume
where ScoreType = 'Updated'
	and CurrentDate is not null

update a
set a.CurrentDate = convert(nvarchar(11), b.ScoreDate, 101),
	a.Photo = b.Photo,
	a.Logo = b.Logo
from #physician_ratings_volume a 
	inner join #current_date b on b.NPI = a.NPI 
where a.CurrentDate is null
	and a.CurrentRatingScore = '0.0'

/*	Get rid of Updated NULL dates when there
	NPI and RatingsSite
*/
create table #dups_updated
(
	ID int identity
,	NPI nvarchar(10)
,	RatingsSite nvarchar(50)
,	BaselineRecordCount int
)
insert		#dups_updated(NPI, RatingsSite, BaselineRecordCount)
select		NPI, RatingsSite, count(*)
from		#physician_ratings_volume
where		ScoreType = 'Updated'
group by	NPI, RatingsSite

delete		p
from		#dups_updated d
inner join	#physician_ratings_volume p
on			p.NPI = d.NPI
and			p.RatingsSite = d.RatingsSite
where		d.BaselineRecordCount > 1
and			p.ScoreDate is null

--select * from #physician_rating_site_data_Baseline order by LastName

/*This updates the ScoreDate with the CurrentDate if the ScoreDate is null for Updated data*/
update #physician_ratings_volume
set ScoreDate = convert(nvarchar(11), CurrentDate, 101)  
from #physician_ratings_volume 
where ScoreDate is null
	and ScoreType = 'Updated'

delete 
from #physician_ratings_volume
where RatingsSite is NULL

select distinct * from #physician_ratings_volume order by LastName

drop table #physician_rating_site_data
drop table #physician_rating_site_data_Baseline
drop table #physician_media
drop table #current
drop table #baseline
drop table #phys_sites
drop table #physician_ratings_volume
drop table #dups
drop table #baseline_date
drop table #current_date



























