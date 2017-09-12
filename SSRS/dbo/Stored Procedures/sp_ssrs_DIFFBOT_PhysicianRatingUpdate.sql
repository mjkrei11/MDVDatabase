













CREATE procedure [dbo].[sp_ssrs_DIFFBOT_PhysicianRatingUpdate] (@Database nvarchar(200), @Month int)

as

/*
declare
@Database nvarchar(200), @Month int
set @Database = 'Rothman'
set @Month = 1

exec sp_ssrs_DIFFBOT_PhysicianRatingUpdate @Database, @Month
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

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

select top 1 @Logo = cast(BinData as varbinary(max)) from MDVALUATE.dbo.MetricRangeMediaSection where NPI = @CustomerID

--old logic
--set @sql = 'select @TempBatchID = max(BatchID) ' + @CR
--set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks '
--set @parms = '@TempBatchID int output'
--exec sp_executesql @sql, @parms, @TempBatchID = @BatchID output

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

create table #current_ratings(
	NPI nvarchar(10),
	SiteName nvarchar(100),
	Rating decimal(2,1),
	Volume int,
	BaselineDate datetime,
	ResultLink nvarchar(max)
)

--set @sql = 'insert #current_ratings ' + @CR
--set @sql = @sql + 'select w.NPI, w.SiteName, isnull(r.ResultRating, 0.0), isnull(r.ResultVolume, 0), w.WorkingDate, r.ResultLink ' + @CR 
--set @sql = @sql + 'from RepMgmt.dbo.DIFFBOT_WorkingLinks w ' + @CR
--set @sql = @sql + 'left join ' + @Database + '.dbo.DIFFBOT_ResultLinks r on w.WorkingKey = r.WorkingKey and w.NPI = r.NPI ' + @CR
--set @sql = @sql + 'where w.BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''' ' + @CR
--set @sql = @sql + 'and w.CustomerID = ''' + @CustomerID + ''' ' + @CR
--set @sql = @sql + 'and w.SiteName in (''HealthGrades'', ''Vitals'', ''RateMDs'', ''UCompare'') ' + @CR
----print(@sql)
--exec(@sql)

set @sql = 'insert #current_ratings ' + @CR
set @sql = @sql + 'select NPI, SiteName, isnull(ResultRating, 0.0), isnull(ResultVolume, 0), SearchDate, ResultLink ' + @CR --, r.ResultLink ' + @CR 
set @sql = @sql + 'from  ' + @Database + '.dbo.DIFFBOT_ResultLinks  ' + @CR
set @sql = @sql + 'where BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''' ' + @CR
set @sql = @sql + 'and CustomerID = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and SiteName in (''HealthGrades'', ''Vitals'', ''RateMDs'', ''UCompare'') ' + @CR
--print(@sql)
exec(@sql)

--select * from #current_ratings where npi = '1629025994'

create table #comments(
	NPI nvarchar(10),
	SiteName nvarchar(100),
	CommentDate datetime,
	CommentRating nvarchar(max),
	CommentText nvarchar(max)
)

set @sql = 'insert #comments ' + @CR
set @sql = @sql + 'select distinct c.NPI, c.SiteName, convert(varchar, c.CommentDate, 101) as CommentDate, c.IsNegative, isnull(c.CommentText, ''None'')' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_Comments c  ' + @CR
--set @sql = @sql + 'where convert(varchar, c.CommentDate, 101) between cast(convert(varchar, GetDate(), 101) as datetime) - 30 and GetDate() ' + @CR --changed this to 30 instead of 14
set @sql = @sql + 'where datepart(month, c.CommentDate) = ''' + cast(@Month as nvarchar(5)) + ''' and datepart(year, c.CommentDate) =  ''2017'' ' + @CR
--datepart(year, getdate()) ' + @CR
set @sql = @sql + 'and len(ltrim(rtrim(c.CommentText))) > 3 and c.CommentText <> ''show details'' ' + @CR
set @sql = @sql + 'and c.CustomerID = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and c.SiteName in (''HealthGrades'', ''Vitals'', ''RateMDs'', ''UCompare'') ' + @CR
--set @sql = @sql + 'and c.CommentDate <> ''03/31/2016'' ' + @CR -- this is here to test that we do not bring in 3/31/2016
--set @sql = @sql + 'group by c.NPI, c.SiteName, c.CommentDate, c.IsNegative, c.CommentText ' + @CR
print(@sql)
exec(@sql)

create table #current(
	NPI nvarchar(10),
	SiteName nvarchar(100),
	Rating decimal(2,1),
	Volume int,
	BaselineDate datetime,
	ResultLink nvarchar(max),
	CommentDate datetime,
	CommentRating nvarchar(max),
	CommentText nvarchar(max)
)

insert		#current
select		distinct r.NPI, r.SiteName, r.Rating, r.Volume, r.BaselineDate, r.ResultLink, c.CommentDate, c.CommentRating, isnull(c.CommentText, 'None')
from		#current_ratings r
left join	#comments c
on			c.SiteName = r.SiteName
and			c.NPI = r.NPI
group by	r.NPI, r.SiteName, r.Rating, r.Volume, r.BaselineDate, r.ResultLink, c.CommentDate, c.CommentRating, c.CommentText

--select * from #current where NPI = '1629025994'

drop table #current_ratings
drop table #comments

create table #baseline(
	NPI nvarchar(10),
	SiteName nvarchar(100),
	Rating decimal(2,1),
	Volume int,
	BaselineDate datetime,
	IsSummaryBaseline int
)

set @sql = 'insert #baseline ' + @CR
set @sql = @sql + 'select NPI, SiteName, isnull(Rating, 0.0), isnull(Volume, 0), BaselineDate, IsSummaryBaseline ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.rep_core_baseline ' + @CR
set @sql = @sql + 'where IsBaseline = 1 ' + @CR
exec(@sql)

create table #middle(
	NPI nvarchar(10),
	SiteName nvarchar(100),
	Rating decimal(2,1),
	Volume int,
	BaselineDate datetime
)

set @sql = 'select @TempRecordCheck = count(*) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.rep_program_baseline'
set @parms = '@TempRecordCheck int output'
exec sp_executesql @sql, @parms, @TempRecordCheck = @record_check output

if isnull(@record_check, 0) > 0
begin
	set @sql = 'insert #middle ' + @CR
	set @sql = @sql + 'select NPI, SiteName, isnull(Rating, 0.0), isnull(Volume, 0), ProgramDate ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.rep_program_baseline ' + @CR
	set @sql = @sql + 'where IsBaseline = 1 ' + @CR
	exec(@sql)
end
else
begin
	set @sql = 'select @TempRecordCheck = count(*) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputation ' + @CR
	set @sql = @sql + 'where RatingsSite = ''Sum All Sites'' '
	set @parms = '@TempRecordCheck int output'
	exec sp_executesql @sql, @parms, @TempRecordCheck = @record_check output

	if isnull(@record_check, 0) > 0
	begin
		set @sql = 'insert #middle ' + @CR
		set @sql = @sql + 'select distinct media.NPI, ' + @CR
		set @sql = @sql + 'case metric.RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else metric.RatingsSite end, ' + @CR
		set @sql = @sql + 'metric.Rating, metric.NumberOfRatings, v.SpiderDate ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CR
		set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputation metric ' + @CR
		set @sql = @sql + 'on metric.ComboKey = media.ComboKey ' + @CR
		set @sql = @sql + 'left join ' + @Database + '.dbo.vw_PhysicianSearch v ' + @CR
		set @sql = @sql + 'on v.NPI = media.NPI ' + @CR
		set @sql = @sql + 'and v.LinkTarget = metric.SourceLink ' + @CR
		set @sql = @sql + 'where metric.RatingsSite in (''HealthGrades'',''Vitals'',''UCompare'',''Rate MD Secure'') ' + @CR
		set @sql = @sql + 'and media.CollectionID = media.SystemID ' + @CR
		set @sql = @sql + 'and v.SearchPattern = ''MasterSearch'' '
		--print(@sql)
		exec(@sql)
	end
	else
	begin
		set @sql = 'select @TempYearQuarter = max(YearQuarter) ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchiveMedia '
		set @parms = '@TempYearQuarter nvarchar(20) output'
		exec sp_executesql @sql, @parms, @TempYearQuarter = @YearQuarter output

		set @sql = 'insert #middle ' + @CR
		set @sql = @sql + 'select distinct media.NPI, ' + @CR
		set @sql = @sql + 'case metric.RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else metric.RatingsSite end, ' + @CR
		set @sql = @sql + 'metric.Rating, metric.NumberOfRatings, v.SpiderDate ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CR
		set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationArchive metric ' + @CR
		set @sql = @sql + 'on metric.XComboKey = media.XComboKey ' + @CR
		set @sql = @sql + 'left join MDVALUATE.dbo.vw_MasterPhysicianSearch v ' + @CR
		set @sql = @sql + 'on v.NPI = media.NPI ' + @CR
		set @sql = @sql + 'and v.SearchPattern = media.YearQuarter ' + @CR
		set @sql = @sql + 'and v.LinkTarget = metric.SourceLink ' + @CR
		set @sql = @sql + 'where media.YearQuarter = ''' + @YearQuarter + ''' ' + @CR
		set @sql = @sql + 'and metric.RatingsSite in (''HealthGrades'',''Vitals'',''UCompare'',''Rate MD Secure'') ' + @CR
		set @sql = @sql + 'and media.CollectionID = media.SystemID '
		--print(@sql)
		exec(@sql)
	end
end

create table #physician_rating_site_data(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	FullName nvarchar(400),
	RatingsSite nvarchar(50),
	ScoreType nvarchar(50),
	RatingScore decimal(2,1),
	VolumeScore int,
	ScoreDate datetime,
	RatingDifference decimal(2,1),
	VolumeDifference int,
	BaselineRating decimal(2,1),
	BaselineVolume int,
	BaselineDate datetime,
	UpdatedRating decimal(2,1),
	UpdatedVolume int,
	UpdatedDate datetime,
	CardProgramRating decimal(2,1),
	CardProgramVolume int,
	CardProgramDate datetime,
	Photo varbinary(max),
	Logo varbinary(max),
	SiteName nvarchar(50),
	ResultLink nvarchar(max),
	CommentDate datetime,
	CommentRating nvarchar(max),
	CommentText nvarchar(max)
)

select top 1 @baseline_check = IsSummaryBaseline from #baseline

if @baseline_check = 1
begin
	insert		#physician_rating_site_data(NPI, FirstName, LastName, FullName, RatingsSite, ScoreType,
				RatingScore, VolumeScore, ScoreDate, RatingDifference, VolumeDifference, UpdatedRating, UpdatedVolume, UpdatedDate, SiteName, CommentDate, CommentRating, CommentText, ResultLink, Photo, Logo)
	select		distinct p.NPI, p.FirstName, p.LastName, p.LastName + ', ' + p.FirstName, c.SiteName,
				'Baseline', b.Rating, b.Volume, b.BaselineDate, c.Rating - b.Rating, c.Volume - b.Volume,
				c.Rating, c.Volume, c.BaselineDate, c.SiteName, c.CommentDate, c.CommentRating, c.CommentText, c.ResultLink, p.Photo, p.Logo
	from		#physician_media p
	left join	#current c
	on			c.NPI = p.NPI
	left join	#baseline b
	on			b.NPI = p.NPI
	and			b.SiteName = c.SiteName
	--group by	p.NPI, p.FirstName, p.LastName, c.SiteName, b.Rating, b.Volume, b.BaselineDate, c.Rating - b.Rating, c.Volume - b.Volume,
	--			c.Rating, c.Volume, c.BaselineDate, c.SiteName, c.CommentDate, c.CommentRating, c.CommentText, c.ResultLink, p.Photo, p.Logo
end
else
begin
	insert		#physician_rating_site_data(NPI, FirstName, LastName, FullName, RatingsSite, ScoreType,
				RatingScore, VolumeScore, ScoreDate, RatingDifference, VolumeDifference, UpdatedRating, UpdatedVolume, UpdatedDate, SiteName, CommentDate, CommentRating, CommentText, ResultLink, Photo, Logo)
	select		distinct p.NPI, p.FirstName, p.LastName, p.LastName + ', ' + p.FirstName, c.SiteName,
				'Baseline', b.Rating, b.Volume, b.BaselineDate, c.Rating - b.Rating, c.Volume - b.Volume,
				c.Rating, c.Volume, c.BaselineDate, c.SiteName, c.CommentDate, c.CommentRating, c.CommentText, c.ResultLink, p.Photo, p.Logo
	from		#physician_media p
	left join	#current c
	on			c.NPI = p.NPI
	left join	#middle b
	on			b.NPI = p.NPI
	and			b.SiteName = c.SiteName
	--group by	p.NPI, p.FirstName, p.LastName, c.SiteName, b.Rating, b.Volume, b.BaselineDate,
	--			c.Rating, c.Volume, c.BaselineDate, c.SiteName, c.CommentDate, c.CommentRating, c.CommentText, c.ResultLink, p.Photo, p.Logo
end	

insert		#physician_rating_site_data(NPI, FirstName, LastName, FullName, RatingsSite, ScoreType,
			RatingScore, VolumeScore, ScoreDate, RatingDifference, VolumeDifference, UpdatedRating, UpdatedVolume, UpdatedDate, SiteName, CommentDate, CommentRating, CommentText, ResultLink, Photo, Logo)
select		distinct p.NPI, p.FirstName, p.LastName, p.LastName + ', ' + p.FirstName, c.SiteName,
			'Updated', isnull(c.Rating, 0.0), isnull(c.Volume, 0), c.BaselineDate, isnull(c.Rating - b.Rating, 0.0), isnull(c.Volume - b.Volume, 0),
			isnull(c.Rating, 0.0), isnull(c.Volume, 0), c.BaselineDate, c.SiteName, c.CommentDate, c.CommentRating, c.CommentText, c.ResultLink, p.Photo, p.Logo
from		#physician_media p
left join	#current c
on			c.NPI = p.NPI
left join	#middle b
on			b.NPI = p.NPI
and			b.SiteName = c.SiteName
--group by	p.NPI, p.FirstName, p.LastName, c.SiteName, c.Rating, b.Rating, c.Volume, b.Volume, c.BaselineDate, c.SiteName, c.CommentDate, c.CommentRating, c.CommentText, c.ResultLink, p.Photo, p.Logo

--select * from #physician_rating_site_data

update		p
set			p.BaselineDate = b.BaselineDate,
			p.BaselineRating = isnull(b.Rating, 0.0),
			p.BaselineVolume = isnull(b.Volume, 0)
from		#physician_rating_site_data p
left join	#baseline b
on			b.NPI = p.NPI
and			b.SiteName = p.RatingsSite

update		p
set			p.CardProgramDate = m.BaselineDate,
			p.CardProgramRating = isnull(m.Rating, 0.0),
			p.CardProgramVolume = isnull(m.Volume, 0)
from		#physician_rating_site_data p
left join	#middle m
on			m.NPI = p.NPI
and			m.SiteName = p.RatingsSite

select		distinct *
			--LastName, FirstName, RatingsSite, ScoreType, UpdatedVolume, UpdatedRating
from		#physician_rating_site_data
--where		RatingsSite = 'HealthGrades' and ScoreType = 'Updated' 
order by	LastName, FirstName, RatingsSite, ScoreType, UpdatedVolume desc, UpdatedRating desc, VolumeScore desc, RatingScore desc
--order by	LastName, FirstName, RatingsSite, ScoreType, UpdatedVolume, UpdatedRating


drop table #physician_rating_site_data
drop table #physician_media
drop table #current
drop table #middle
drop table #baseline













