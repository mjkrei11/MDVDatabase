
CREATE procedure [dbo].[sp_ssrs_PhysicianRatingUpdateDIFFBOT](@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'Rothman'

exec sp_ssrs_PhysicianRatingUpdateDIFFBOT @Database
*/

declare
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

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

declare
@BatchID int,
@record_check int,
@YearQuarter nvarchar(20),
@SpiderDate datetime

create table #core_baseline(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	SiteName nvarchar(100),
	Rating decimal(3,1),
	Volume int,
	BaselineDate datetime
)
set @sql = 'insert #core_baseline ' + @CR
set @sql = @sql + 'select pm.NPI, pm.FirstName, pm.LastName, b.SiteName, b.Rating, b.Volume, b.BaselineDate ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.rep_core_baseline b ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia pm ' + @CR
set @sql = @sql + 'on pm.NPI = b.NPI ' + @CR
set @sql = @sql + 'where b.IsBaseline = 1 '
exec(@sql)


create table #middle_baseline(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	SiteName nvarchar(100),
	Rating decimal(3,1),
	Volume int,
	BaselineDate datetime
)

set @sql = 'select @TempRecordCheck = count(*) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.rep_program_baseline'
set @parms = '@TempRecordCheck int output'
exec sp_executesql @sql, @parms, @TempRecordCheck = @record_check output
--set @record_check = 0

if isnull(@record_check, 0) > 0
begin	
	set @sql = 'insert #middle_baseline ' + @CR
	set @sql = @sql + 'select pm.NPI, pm.FirstName, pm.LastName, b.SiteName, b.Rating, b.Volume, b.ProgramDate ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.rep_program_baseline b ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia pm ' + @CR
	set @sql = @sql + 'on pm.NPI = b.NPI ' + @CR
	set @sql = @sql + 'where b.IsBaseline = 1 '
	exec(@sql)
end
else
begin
	set @sql = 'select @TempRecordCheck = count(*) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputation ' + @CR
	set @sql = @sql + 'where RatingsSite = ''Sum All Sites'' '
	set @parms = '@TempRecordCheck int output'
	exec sp_executesql @sql, @parms, @TempRecordCheck = @record_check output
	--set @record_check = 0

	if isnull(@record_check, 0) > 0
	begin
		set @sql = 'insert #middle_baseline ' + @CR
		set @sql = @sql + 'select distinct media.NPI, media.FirstName, media.LastName, ' + @CR
		set @sql = @sql + 'case metric.RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else metric.RatingsSite, ' + @CR
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
		exec(@sql)
	end
	else
	begin
		set @sql = 'select @TempYearQuarter = max(YearQuarter) ' + @CR
		set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchiveMedia '
		set @parms = '@TempYearQuarter nvarchar(20) output'
		exec sp_executesql @sql, @parms, @TempYearQuarter = @YearQuarter output

		set @sql = 'insert #middle_baseline ' + @CR
		set @sql = @sql + 'select distinct media.NPI, media.FirstName, media.LastName, ' + @CR
		set @sql = @sql + 'case metric.RatingsSite when ''Rate MD Secure'' then ''RateMDs'' else metric.RatingsSite, ' + @CR
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
		exec(@sql)
	end
end

set @sql = 'select @TempBatchID = max(BatchID) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks '
set @parms = '@TempBatchID int output'
exec sp_executesql @sql, @parms, @TempBatchID = @BatchID output

create table #current(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	SiteName nvarchar(100),
	Rating decimal(3,1),
	Volume int,
	BaselineDate datetime
)

set @sql = 'insert #current ' + @CR
set @sql = @sql + 'select pm.NPI, pm.FirstName, pm.LastName, r.SiteName, isnull(r.ResultRating, 0.0), isnull(r.ResultVolume, 0), r.SearchDate ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks r ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia pm ' + @CR
set @sql = @sql + 'on pm.NPI = r.NPI ' + @CR
set @sql = @sql + 'where r.BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' '
exec(@sql)

--select * from #core_baseline
--select * from #middle_baseline
--select * from #current

select		cb.NPI, cb.FirstName, cb.LastName, cb.SiteName, cb.Rating as OriginalRating, cb.Volume as OriginalVolume,
			mb.Rating as MiddleRating, mb.Volume as MiddleVolume, isnull(c.Rating, 0.0) as CurrentRating, isnull(c.Volume, 0) as CurrentVolume
from		#core_baseline cb
left join	#middle_baseline mb
on			mb.NPI = cb.NPI
and			mb.SiteName = cb.SiteName
left join	#current c
on			c.NPI = cb.NPI
and			c.SiteName = cb.SiteName
order by	c.LastName, c.FirstName, c.SiteName

drop table #core_baseline
drop table #middle_baseline
drop table #current
