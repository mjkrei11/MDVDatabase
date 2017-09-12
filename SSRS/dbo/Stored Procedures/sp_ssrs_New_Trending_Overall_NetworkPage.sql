























CREATE procedure [dbo].[sp_ssrs_New_Trending_Overall_NetworkPage] (
	@Database nvarchar(200)

)

as

/*
declare
@Database nvarchar(200)


set @Database = 'CSOG'


exec sp_ssrs_New_Trending_Overall_NetworkPage @Database
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


create table #_AllMetrics(
	NPI nvarchar(10), 
	FirstName nvarchar(100), 
	LastName nvarchar(100), 
	OrderID int,
	VICollectionID nvarchar(10), 
	CurrentMeasureName nvarchar(200), 
	CurrentOverall nvarchar(150),  
	CurrentOverallCode int, 
	CurrentMeasureDate datetime, 
	TrendCollectionID nvarchar(10),
	Category nvarchar(200),
	CategoryPercentile int,
	CategoryColor int, 
	TrendMeasureName nvarchar(150), 
	TrendMeasure int, 
	TrendColorCode int, 
	TrendQuarter nvarchar(8), 
	TrendQuarterOrder int, 
	TrendMeasureDate datetime, 
	SystemName nvarchar(200), 
	SystemID nvarchar(10), 
	ListID nvarchar(14), 
	ListElement nvarchar(200),
	MetricID int

) 	

set @sql = 'Insert #_AllMetrics(NPI, FirstName, LastName, OrderID, VICollectionID, CurrentMeasureName, CurrentOverall, CurrentOverallCode, CurrentMeasureDate, ' + @CR
set @sql = @sql + 'TrendCollectionID, Category, CategoryPercentile, CategoryColor, ' + @CR
set @sql = @sql + 'TrendMeasureName, TrendMeasure, TrendColorCode, TrendQuarter, TrendQuarterOrder, TrendMeasureDate, SystemName, SystemID, ListID, ListElement, MetricID) ' + @CR
set @sql = @sql + 'select v.NPI, i.FirstName, i.LastName, v.OrderID, v.VICollectionID, v.VIMeasureName AS CurrentMeasureName, v.VIMeasure AS CurrentOverall, ' + @CR
set @sql = @sql + 'v.ColorCode AS CurrentOverallColor, v.VIMeasureDate As CurrentMeasureDate, ' + @CR
set @sql = @sql + 't.TrendCollectionID, v.VICategory, v.VICategoryPercentile, v.VICategoryColor, t.TrendMeasureName, t.TrendMeasure, t.TrendColorCode, t.TrendQuarter, ' + @CR
set @sql = @sql + 'substring(t.TrendQuarter, 5,4) + substring(t.TrendQuarter,2,1) as TrendQuarterOrder,  t.TrendMeasureDate, i.SystemName, i.SystemID, metric.ListID, metric.ListElement, 2 as MetricID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.VIMeasureValues v ' + @CR
set @sql = @sql + 'left outer join ' + @Database + '.dbo.PhysicianMedia p on p.NPI = v.NPI ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.VITrendValues t on t.NPI = v.NPI and t.TrendCollectionID = v.VICollectionID and t.TrendMeasureName = v.VIMeasureName ' + @CR
set @sql = @sql + 'and t.TrendCategory = v.VICategory ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysVIndex i on i.SystemID = v.VICollectionID and i.SystemID = t.TrendCollectionID and i.NPI = v.NPI ' + @CR
set @sql = @sql + 'left outer join MDVALUATE.dbo.PickList metric on metric.ListID = v.NPI ' + @CR
set @sql = @sql + 'left outer join MDVALUATE.dbo.PickListMedia media on media.ListTypeID = metric.ListTypeID ' + @CR
set @sql = @sql + 'where v.VIMeasureName not like ''%Overall%'' and t.TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'group by v.NPI, i.FirstName, i.LastName, v.OrderID, v.VICollectionID, v.VIMeasureName, v.VIMeasure, ' + @CR
set @sql = @sql + 'v.ColorCode, v.VIMeasureDate, v.VICategory, v.VICategoryPercentile, v.VICategoryColor, t.TrendCollectionID, t.TrendMeasureName, t.TrendMeasure, ' + @CR
set @sql = @sql + 't.TrendColorCode, t.TrendQuarter, t.TrendMeasureDate, i.SystemName, i.SystemID, metric.ListID, metric.ListElement ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'select v.NPI, i.FirstName, i.LastName, v.OrderID, v.VICollectionID, v.VIMeasureName AS CurrentMeasureName, v.VIMeasure AS CurrentOverall, ' + @CR
set @sql = @sql + 'v.ColorCode AS CurrentOverallColor, v.VIMeasureDate As CurrentMeasureDate, ' + @CR
set @sql = @sql + 't.TrendCollectionID, v.VICategory, v.VICategoryPercentile, v.VICategoryColor, t.TrendMeasureName, t.TrendMeasure, t.TrendColorCode, t.TrendQuarter, ' + @CR
set @sql = @sql + 'substring(t.TrendQuarter, 5,4) + substring(t.TrendQuarter,2,1) as TrendQuarterOrder, t.TrendMeasureDate, i.SystemName, i.SystemID, metric.ListID, metric.ListElement, 2 as MetricID  ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.VIMeasureValues v ' + @CR
set @sql = @sql + 'left outer join ' + @Database + '.dbo.PhysicianMedia p on p.NPI = v.NPI ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.VITrendValues t on t.NPI = v.NPI and t.TrendCollectionID = v.VICollectionID and t.TrendMeasureName = v.VIMeasureName ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysVIndex i on i.SystemID = v.VICollectionID and i.SystemID = t.TrendCollectionID and i.NPI = v.NPI ' + @CR
set @sql = @sql + 'left outer join MDVALUATE.dbo.PickList metric on metric.ListID = v.NPI ' + @CR
set @sql = @sql + 'left outer join MDVALUATE.dbo.PickListMedia media on media.ListTypeID = metric.ListTypeID ' + @CR
set @sql = @sql + 'where v.VIMeasureName like ''%Overall%'' and t.TrendMeasureName like ''%Overall%'' ' + @CR
set @sql = @sql + 'group by v.NPI, i.FirstName, i.LastName, v.OrderID, v.VICollectionID, v.VIMeasureName, v.VIMeasure, ' + @CR
set @sql = @sql + 'v.ColorCode, v.VIMeasureDate, v.VICategory, v.VICategoryPercentile, v.VICategoryColor, t.TrendCollectionID, t.TrendMeasureName, t.TrendMeasure, ' + @CR
set @sql = @sql + 't.TrendColorCode, t.TrendQuarter, t.TrendMeasureDate, i.SystemName, i.SystemID, metric.ListID, metric.ListElement ' + @CR
set @sql = @sql + 'order by t.TrendCollectionID, v.NPI, TrendQuarterOrder desc ' + @CR
--print(@sql)
exec(@sql)

update #_AllMetrics
set MetricID = 1
where CurrentMeasureName like '%Overall%'

select *
from #_AllMetrics

drop table #_AllMetrics



















