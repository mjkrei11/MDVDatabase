














CREATE procedure [dbo].[sp_SSRS_PhysicianRatingUpdate] (
	@Database nvarchar(200)--,
	--@UpdatedDate nvarchar(50)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'MORUSH'

exec sp_SSRS_PhysicianRatingUpdate @Database
*/

declare
@CustomerID nvarchar(10),
@CustomerSource nvarchar(400),
@CustomerLogo varbinary(max),
@SearchPattern nvarchar(50),
@parms nvarchar(max),
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(400) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

select top 1 @CustomerLogo = BinData from MDVALUATE.dbo.MetricRangeMediaSection where NPI = @CustomerID
select top 1 @SearchPattern = min(SearchPattern) from MDVALUATE.dbo.MasterPhysicianSearchMedia where PrimaryCustomerID = @CustomerID

create table #MDV_Master_Search(
	NPI nvarchar(10),
	SpiderDate datetime,
	RatingsSite nvarchar(400),
	LinkTarget nvarchar(4000)
)

insert		#MDV_Master_Search
select		distinct media.NPI, metric.SpiderDate, case when metric.LinkTarget like '%www.healthgrades.com%' then 'HealthGrades'
			when metric.LinkTarget like '%www.vitals.com%' then 'Vitals' when metric.LinkTarget like '%www.ucomparehealthcare.com%' then 'UCompare'
			when metric.LinkTarget like '%www.ratemds.com%' then 'RateMDs' end, metric.LinkTarget
from		MDVALUATE.dbo.MasterPhysicianSearchMedia media
inner join	MDVALUATE.dbo.MasterSearchResults metric
on			metric.SearchID = media.SearchID
where		media.PrimaryCustomerID = @CustomerID
and			media.SearchPattern = @SearchPattern

create table #report_data(
    NPI nvarchar(10),
    FirstName nvarchar(50),
    LastName nvarchar(50),
    FullName nvarchar(150),
    RatingsSite nvarchar(50),
    ScoreType nvarchar(20),
    RatingScore float,
    VolumeScore int,
    ScoreDate datetime,
    RatingDifference float,
    VolumeDifference int,
    Photo varbinary(max),
	Logo varbinary(max),
	BaselineRating float,
	BaselineVolume int,
	BaselineDate datetime,
	UpdatedRating nvarchar(10),
	UpdatedVolume int,
	UpdatedDate nvarchar(50),
	TableRatingDifference float,
	TableVolumeDifference int,
	CardProgramRating float,
	CardProgramVolume int,
	CardProgramDate datetime

)

declare @date datetime

set @sql = 'select @Tempdate = max(UpdatedDate) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianRatingUpdate'
set @parms = '@Tempdate datetime output'
exec sp_executesql @sql, @parms, @Tempdate = @date output

Set @sql = 'insert #report_data(NPI, FirstName, LastName, FullName, RatingsSite, ScoreType, RatingScore, VolumeScore, ScoreDate, RatingDifference, VolumeDifference, Photo, ' + @CR
Set @sql = @sql + 'BaselineRating, BaselineVolume, BaselineDate, UpdatedRating, UpdatedVolume, UpdatedDate, ' + @CR
Set @sql = @sql + 'TableRatingDifference, TableVolumeDifference, CardProgramRating, CardProgramVolume, CardProgramDate) ' + @CR
Set @sql = @sql + 'select u.NPI, u.FirstName, u.LastName, u.FullName, u.RatingsSite, ''Baseline'', u.BaselineRating, u.BaselineVolume, u.BaselineDate, u.RatingDifference, u.VolumeDifference, ' + @CR
Set @sql = @sql + 'cast(d.BinData as varbinary(max)), ' + @CR
Set @sql = @sql + '(select distinct s.BaselineRating from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.BaselineVolume from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate), ' + @CR
Set @sql = @sql + '(select distinct s.BaselineDate from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct cast(s.UpdatedRating as nvarchar(10)) from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.UpdatedVolume from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.UpdatedDate from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.RatingDifference from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.VolumeDifference from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.CardProgramRating from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.CardProgramVolume from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.CardProgramDate from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ) ' + @CR
Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianRatingUpdate u ' + @CR
Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysicianDoc d ON d.NPI = u.NPI ' + @CR 
Set @sql = @sql + 'WHERE convert(varchar, u.UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
Set @sql = @sql + 'and d.DocType <> ''PDF'' '  + @CR    
Set @sql = @sql + 'union ' + @CR
Set @sql = @sql + 'select u.NPI, u.FirstName, u.LastName,  u.FullName, u.RatingsSite, ''Updated'', u.UpdatedRating, u.UpdatedVolume, u.UpdatedDate, u.RatingDifference, u.VolumeDifference, ' + @CR
Set @sql = @sql + 'cast(d.BinData as varbinary(max)), ' + @CR
Set @sql = @sql + '(select distinct s.BaselineRating from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.BaselineVolume from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.BaselineDate from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct cast(s.UpdatedRating as nvarchar(10)) from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.UpdatedVolume from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.UpdatedDate from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.RatingDifference from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.VolumeDifference from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.CardProgramRating from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.CardProgramVolume from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ), ' + @CR
Set @sql = @sql + '(select distinct s.CardProgramDate from ' + @Database + '.dbo.PhysicianRatingUpdate s where s.NPI = u.NPI and s.RatingsSite = u.RatingsSite and s.UpdatedDate = u.UpdatedDate ) ' + @CR
Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianRatingUpdate u ' + @CR
Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysicianDoc d ON d.NPI = u.NPI ' + @CR
Set @sql = @sql + 'WHERE convert(varchar, u.UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
Set @sql = @sql + 'and d.DocType <> ''PDF'' '  + @CR    
--Set @sql = @sql + 'WHERE u.UpdatedDate NOT LIKE ''2015-07-09%'' '  + @CR  
--print(@sql) 
exec(@sql)

update		#report_data
set			Logo = @CustomerLogo

select        *
from        #report_data
where		UpdatedDate = @date
order by    LastName, FirstName, RatingsSite, ScoreType

drop table #report_data
drop table #MDV_Master_Search

Print @sql

















