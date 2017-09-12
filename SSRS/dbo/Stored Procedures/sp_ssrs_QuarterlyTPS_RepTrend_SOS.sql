












CREATE procedure [dbo].[sp_ssrs_QuarterlyTPS_RepTrend_SOS] (
	@Database nvarchar(200), @Quarter nvarchar(20)

)

as
/*This reporst was created for SOS. They do not want comments on the report*/

/*
declare
@Database nvarchar(200),
@Quarter nvarchar(20)

set @Database = 'SOS'
set @Quarter = 'Q4, 2016'

exec sp_ssrs_QuarterlyTPS_RepTrend_SOS @Database, @Quarter
*/

declare
@SystemID nvarchar(10),
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

create table #RepTrendQuarter(
	NPI nvarchar(10), 
	FullName nvarchar(100), 
	LastName nvarchar(50), 
	FirstName nvarchar(50), 
	Specialty nvarchar(100), 
	Ratingsite nvarchar(200), 
	MonthNumber int, 
	RepTrendQtrDate int, 
	AvgRating nvarchar(40), 
	Ratings nvarchar(40), 
	Comments nvarchar(max), 
	FiveStarsNeeded nvarchar(20), 
	AvgPhysicianRating nvarchar(40), 
	WidgetRatingCount nvarchar(200), 
	WidgetRiskCount nvarchar(200), 
	WidgetRating nvarchar(200), 
	OrderID int,
	RepTrendQtrPeriod nvarchar(20)
) 
set @sql = 'insert #RepTrendQuarter ' + @CR
set @sql = @sql + 'select distinct a.NPI, a.FullName, a.LastName, a.FirstName, a.Specialty, b.RepTrendQtrSite as RatingSite, datepart(m, b.RepTrendQtrDate) as MonthNumber, datepart(m, b.RepTrendQtrDate) as RepTrendQtrDate, ' + @CR
set @sql = @sql + 'b.RepTrendQtrRating as AvgRating, b.RepTrendQtrCount as Ratings, b.RepTrendQtrCommentCount as Comments, ' + @CR
set @sql = @sql + 'b.RepTrendQtrRiskCount as FiveStarsNeeded, b.RepTrendQtrNetworkAvg as AvgPhysicianRating, c.WidgetValue as WidgetRatingCount, d.WidgetValue as WidgetRiskCount, e.WidgetValue as WidgetRating, 1, b.RepTrendQtrPeriod ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia a ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.VIRepQuarter b on b.NPITrend = a.NPITrend ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.VIRepWidgets c on c.NPITrend = b.NPITrend and c.WidgetQuarter = b.RepTrendQtrPeriod and c.WidgetValue = b.RepTrendQtrCount and c.WidgetName = ''RatingCount'' and c.WidgetElement = ''Current'' and c.WidgetTab = ''Quarterly'' ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.VIRepWidgets d on d.NPITrend = b.NPITrend and d.WidgetQuarter = b.RepTrendQtrPeriod and d.WidgetValue = b.RepTrendQtrRiskCount and d.WidgetName = ''RiskCount'' and d.WidgetElement = ''Current'' and d.WidgetTab = ''Quarterly'' ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.VIRepWidgets e on e.NPITrend = b.NPITrend and e.WidgetQuarter = b.RepTrendQtrPeriod and e.WidgetValue = b.RepTrendQtrRating and e.WidgetName = ''Rating'' and e.WidgetElement = ''Current'' and e.WidgetTab = ''Quarterly'' ' + @CR
--set @sql = @sql + 'where b.RepTrendQtrPeriod = ''Q1, 2016'' ' + @CR  --and b.RepTrendQtrSite <> ''Summary'' ' + @CR -- and b.RepTrendQtrSite in (''HealthGrades'',''Vitals'',''RateMDs'') this is for TwinCities
set @sql = @sql + 'where b.RepTrendQtrPeriod = ''' + @Quarter + ''' ' +@CR
--set @sql = @sql + 'and datepart(m, b.RepTrendQtrDate) = ''' + cast(@MonthNumber as nvarchar(5)) + ''' ' + @CR
set @sql = @sql + 'and a.NPI not like ''S%'' and a.NPI not like ''G%'' and a.LastName <> ''System'' ' + @CR
set @sql = @sql + 'order by b.RepTrendQtrSite, MonthNumber ' + @CR
--print(@sql)
exec(@sql)

update		#RepTrendQuarter
set			OrderID = 0
where		Ratingsite <> 'Summary'

select		*
from		#RepTrendQuarter
order by	LastName, FirstName, OrderID, Ratingsite

drop table #RepTrendQuarter


--select *
--from VIRepWidgets
--where WidgetQuarter = 'Q1, 2016'








