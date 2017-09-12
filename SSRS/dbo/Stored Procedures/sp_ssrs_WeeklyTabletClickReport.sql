CREATE procedure sp_ssrs_WeeklyTabletClickReport(@Database nvarchar(200))as/*declare@Database nvarchar(200)set @Database = 'Rothman'exec sp_ssrs_WeeklyTabletClickReport @Database*/declare@CustomerID nvarchar(50),@CustomerSource nvarchar(120),@BatchID int,@sql nvarchar(max),@parms nvarchar(max),@CR char(1)set @CR = char(13)/*set @sql = ' ' + @CRset @sql = @sql + ' ' + @CRexec(@sql)*/set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID outputset @sql = 'select @TempBatchID = max(BatchID) ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks'set @parms = '@TempBatchID int output'exec sp_executesql @sql, @parms, @TempBatchID = @BatchID outputcreate table #ga(	NPI nvarchar(10),	LastName nvarchar(200),	FirstName nvarchar(200),	SiteName nvarchar(50),	Rating decimal(2,1),	Volume int,	BaselineDate datetime)set @sql = 'insert #ga ' + @CRset @sql = @sql + 'select distinct NPI, LastName, FirstName, SiteName, Rating, Volume, BaselineDate ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.GA_DIFFBOT_Baseline ' + @CRexec(@sql)

create table #diffbot(
	CustomerID nvarchar(10),
	NPI nvarchar(10),
	SiteName nvarchar(50),
	Rating decimal(2,1),
	Volume int,
	DiffbotDate datetime
)
--set @sql = 'insert #diffbot ' + @CR--set @sql = @sql + 'select distinct CustomerID, NPI, SiteName, ResultRating, ResultVolume, SearchDate ' + @CR--set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR--set @sql = @sql + 'where BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' '--exec(@sql)
insert		#diffbot
select		distinct CustomerID, NPI, SiteName, ResultRating, ResultVolume, SearchDate
from		RepMgmt.dbo.DIFFBOT_ResultLinks
where		BatchID = @BatchID
and			CustomerID = @CustomerID

create table #clicks(CustomerID nvarchar(10), NPI nvarchar(10), ClickVolume int)
insert		#clicks
select		r.CustomerID, r.NPI, sum(r.ClickVolume) as ClickVolume
from		RepMgmt.dbo.GA_Response r
inner join	#ga g
on			g.NPI = r.NPI
group by	r.CustomerID, r.NPI

create table #report(
	NPI nvarchar(10),
	LastName nvarchar(200),
	FirstName nvarchar(200),
	SiteName nvarchar(50),
	BaselineDate datetime,
	BT_Rating decimal(2,1),
	Current_Rating decimal(2,1),
	RatingDifference decimal(2,1),
	BT_Volume int,
	Current_Volume int,
	VolumeImprovement int,
	SurveyClicks int,
	EffectivenessRate float
)

insert		#report
select		distinct g.NPI, g.LastName, g.FirstName, g.SiteName, g.BaselineDate,
			g.Rating, d.Rating, d.Rating - g.Rating, g.Volume, d.Volume, d.Volume - g.Volume,
			c.ClickVolume, (cast((d.Volume - g.Volume) as float) / cast(c.ClickVolume as float))
from		#ga g
inner join	#clicks c
on			c.NPI = g.NPI
left join	#diffbot d
on			d.NPI = g.NPI
and			d.SiteName = g.SiteName
where		c.CustomerID = @CustomerID
order by	LastName, FirstName

update		#report
set			EffectivenessRate = 1
where		EffectivenessRate > 1

select		*
from		#report
order by	LastName, FirstName

drop table #ga
drop table #diffbot
drop table #clicks
drop table #report