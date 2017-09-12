
















CREATE procedure [dbo].[sp_ssrs_RepTrend_Baseline_RollingQuarters] (
	@Database nvarchar(200),
	@Quarter nvarchar(50)
)

as

/*
declare
@Database nvarchar(200), @Quarter nvarchar(50)
set @Database = 'HEA'
set @Quarter = 'Q2, 2017'

exec sp_ssrs_RepTrend_Baseline_RollingQuarters @Database, @Quarter
*/

declare
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

create table #physician_media(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	Photo varbinary(max),
	Logo varbinary(max),
	PrimaryCustomerSpecialty nvarchar(200)
)

set @sql = 'insert #physician_media ' + @CR
set @sql = @sql + 'select pm.NPI, pm.FirstName, pm.MiddleName, pm.LastName, pd.BinData, null, pm.PrimaryCustomerSpecialty ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia pm ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.PhysicianDoc pd ' + @CR
set @sql = @sql + 'on pd.NPI = pm.NPI ' + @CR
set @sql = @sql + 'and pd.DocType <> ''PDF'' ' + @CR
set @sql = @sql + 'where pm.Status = ''Active'' ' + @CR
--print @sql
exec(@sql)

update	#physician_media
set		Logo = @Logo

create table #Baseline (
	NPI nvarchar(10),
	BaselineSite nvarchar(200),
	BaselineNumberOfRatings int,
	BaselineNumberOfComments int,
	BaselineRating float,
	BaselineRiskCount int,
	BaselineIdentifier nvarchar(20)
)
set @sql = 'insert #Baseline ' + @CR
set @sql = @sql + 'select b.NPI, BaselineSite, BaselineNumberOfRatings, BaselineNumberOfComments, BaselineRating, BaselineRiskCount, BaselineIdentifier  ' + @CR
set @sql = @sql + 'from  ' + @Database + '.dbo.VIRepBaseline a ' + @CR
set @sql = @sql + 'inner join #physician_media b on b.NPI = substring(NPITrend,1, 10) ' + @CR
set @sql = @sql + 'order by OrderID  ' + @CR
exec(@sql)

create table #QuarterData (
	NPI nvarchar(10),
	RepTrendQtrSite nvarchar(200),
	--RepTrendQtrPeriod nvarchar(50),
	RepTrendQtrDate datetime,
	FormattedDate nvarchar(50),
	RepTrendQtrRating float,
	RepTrendQtrCount int,
	RepTrendQtrCommentCount int,
	RepTrendQtrRiskCount int,
	MonthCount int
)
set @sql = 'insert #QuarterData ' + @CR
set @sql = @sql + 'select b.NPI, RepTrendQtrSite, RepTrendQtrDate, ' + @CR --substring(RepTrendQtrPeriod,4,6) as RepTrendQtrPeriod, ' + @CR
set @sql = @sql + 'DATENAME(MONTH, RepTrendQtrDate) + '' '' + DATENAME(YEAR, RepTrendQtrDate) AS FormattedDate, ' + @CR
set @sql = @sql + 'RepTrendQtrRating, RepTrendQtrCount, RepTrendQtrCommentCount, RepTrendQtrRiskCount, null ' + @CR
set @sql = @sql + 'from  ' + @Database + '.dbo.VIRepQuarter a ' + @CR
set @sql = @sql + 'inner join #physician_media b on b.NPI = substring(NPITrend,1, 10) ' + @CR
set @sql = @sql + 'and RepTrendQtrPeriod = ''' + @Quarter + ''' ' + @CR
set @sql = @sql + 'order by RepTrendQtrDate, OrderID ' + @CR
--print @sql
exec(@sql)

create table #MonthOrder (
	MonthCount int IDENTITY(1,1),
	RepTrendQtrDate datetime
)
insert #MonthOrder
select distinct RepTrendQtrDate
from #QuarterData
order by RepTrendQtrDate

update a
set a.MonthCount = b.MonthCount
from #QuarterData a 
inner join #MonthOrder b on b.RepTrendQtrDate = a.RepTrendQtrDate

--select * from #QuarterData

create table #RepTrendData(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	Photo varbinary(max),
	Logo varbinary(max),
	PrimaryCustomerSpecialty nvarchar(200),
	SiteName nvarchar(200),
	Period nvarchar(200),
	RepTrendDate datetime,
	Rating float,
	NumberOfRatings int,
	CommentCount int,
	RiskCount int,
	MonthCount int,
	DataType nvarchar(20),
	RatingSiteOrder int
)
insert #RepTrendData
select	b.NPI, 
		b.FirstName, 
		b.MiddleName, 
		b.LastName, 
		b.Photo, 
		b.Logo, 
		b.PrimaryCustomerSpecialty, 
		a.BaselineSite as 'SiteName',
		'Baseline' as 'Period',
		a.BaselineIdentifier as 'RepTrendDate', 
		a.BaselineRating  as 'Rating', 
		a.BaselineNumberOfRatings  as 'NumberOfRatings', 
		a.BaselineNumberOfComments as 'CommentCount', 
		a.BaselineRiskCount as 'RiskCount',
		0 as 'MonthCount',
		'Baseline' as 'DataType',
		null as 'RatingSiteOrder'
from #Baseline a
	inner join #physician_media b on b.NPI = a.NPI
union
select	b.NPI, 
		b.FirstName, 
		b.MiddleName, 
		b.LastName, 
		b.Photo, 
		b.Logo, 
		b.PrimaryCustomerSpecialty, 
		c.RepTrendQtrSite as 'SiteName',
		c.FormattedDate as 'Period',
		c.RepTrendQtrDate as 'RepTrendDate',
		c.RepTrendQtrRating as 'Rating',
		c.RepTrendQtrCount as 'NumberOfRatings',
		c.RepTrendQtrCommentCount as 'CommentCount',
		c.RepTrendQtrRiskCount as 'RiskCount',
		c.MonthCount as 'MonthCount',
		'QuarterData' as 'DataType',
		null as 'RatingSiteOrder'
from #QuarterData c 
	inner join #physician_media b on b.NPI = c.NPI
order by LastName

/* RatingSiteOrder */
--Facebook
update #RepTrendData
set RatingSiteOrder = 1
where SiteName = 'Facebook'
--Google
update #RepTrendData
set RatingSiteOrder = 2
where SiteName = 'Google'
--HealthGrades
update #RepTrendData
set RatingSiteOrder = 3
where SiteName = 'HealthGrades'
--RateMDs
update #RepTrendData
set RatingSiteOrder = 4
where SiteName = 'RateMDs'
--UCompare
update #RepTrendData
set RatingSiteOrder = 5
where SiteName = 'UCompare'
--Vitals
update #RepTrendData
set RatingSiteOrder = 6
where SiteName = 'Vitals'
--WebMD
update #RepTrendData
set RatingSiteOrder = 7
where SiteName = 'WebMD'
--Wellness
update #RepTrendData
set RatingSiteOrder = 8
where SiteName = 'Wellness'
--Yahoo
update #RepTrendData
set RatingSiteOrder = 9
where SiteName = 'Yahoo'
--Yelp
update #RepTrendData
set RatingSiteOrder = 10
where SiteName = 'Yelp'
--ZocDoc
update #RepTrendData
set RatingSiteOrder = 10
where SiteName = 'ZocDoc'
--Summary
update #RepTrendData
set RatingSiteOrder = 10
where SiteName = 'Summary'

select	NPI ,
		FirstName ,
		MiddleName ,
		LastName,
		Photo ,
		Logo ,
		PrimaryCustomerSpecialty,
		SiteName,
		Period ,
		RepTrendDate,
		Rating,
		NumberOfRatings,
		CommentCount,
		RiskCount,
		MonthCount,
		DataType
from #RepTrendData
order by LastName, RatingSiteOrder

drop table #physician_media
drop table #Baseline
drop table #QuarterData
drop table #MonthOrder
drop table #RepTrendData

