




















CREATE procedure [dbo].[sp_ssrs_Old_Trending_Overall_NetworkPage] (
	@Database nvarchar(200)

)

as

/*
declare
@Database nvarchar(200)


set @Database = 'Medstarortho'


exec sp_ssrs_Trending_Overall_NetworkPage @Database
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
TrendMeasureDate datetime, 
SystemName nvarchar(200), 
SystemID nvarchar(10), 
ListID nvarchar(14), 
ListElement nvarchar(200)

) 	

set @sql = 'Insert #_AllMetrics(NPI, FirstName, LastName, OrderID, VICollectionID, CurrentMeasureName, CurrentOverall, CurrentOverallCode, CurrentMeasureDate, ' + @CR
set @sql = @sql + 'TrendCollectionID, Category, CategoryPercentile, CategoryColor, ' + @CR
set @sql = @sql + 'TrendMeasureName, TrendMeasure, TrendColorCode, TrendQuarter, TrendMeasureDate, SystemName, SystemID, ListID, ListElement) ' + @CR
set @sql = @sql + 'select v.NPI, i.FirstName, i.LastName, v.OrderID, v.VICollectionID, v.VIMeasureName AS CurrentMeasureName, v.VIMeasure AS CurrentOverall, ' + @CR
set @sql = @sql + 'v.ColorCode AS CurrentOverallColor, v.VIMeasureDate As CurrentMeasureDate, ' + @CR
set @sql = @sql + 't.TrendCollectionID, v.VICategory, v.VICategoryPercentile, v.VICategoryColor, t.TrendMeasureName, t.TrendMeasure, t.TrendColorCode, t.TrendQuarter, t.TrendMeasureDate, ' + @CR
set @sql = @sql + 'i.SystemName, i.SystemID, metric.ListID, metric.ListElement ' + @CR
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
set @sql = @sql + 't.TrendCollectionID, v.VICategory, v.VICategoryPercentile, v.VICategoryColor, t.TrendMeasureName, t.TrendMeasure, t.TrendColorCode, t.TrendQuarter, t.TrendMeasureDate, ' + @CR
set @sql = @sql + 'i.SystemName, i.SystemID, metric.ListID, metric.ListElement ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.VIMeasureValues v ' + @CR
set @sql = @sql + 'left outer join ' + @Database + '.dbo.PhysicianMedia p on p.NPI = v.NPI ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.VITrendValues t on t.NPI = v.NPI and t.TrendCollectionID = v.VICollectionID and t.TrendMeasureName = v.VIMeasureName ' + @CR
--set @sql = @sql + 'and t.TrendCategory = v.TrendCategory ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysVIndex i on i.SystemID = v.VICollectionID and i.SystemID = t.TrendCollectionID and i.NPI = v.NPI ' + @CR
set @sql = @sql + 'left outer join MDVALUATE.dbo.PickList metric on metric.ListID = v.NPI ' + @CR
set @sql = @sql + 'left outer join MDVALUATE.dbo.PickListMedia media on media.ListTypeID = metric.ListTypeID ' + @CR
set @sql = @sql + 'where v.VIMeasureName like ''%Overall%'' and t.TrendMeasureName like ''%Overall%'' ' + @CR
set @sql = @sql + 'group by v.NPI, i.FirstName, i.LastName, v.OrderID, v.VICollectionID, v.VIMeasureName, v.VIMeasure, ' + @CR
set @sql = @sql + 'v.ColorCode, v.VIMeasureDate, v.VICategory, v.VICategoryPercentile, v.VICategoryColor, t.TrendCollectionID, t.TrendMeasureName, t.TrendMeasure, ' + @CR
set @sql = @sql + 't.TrendColorCode, t.TrendQuarter, t.TrendMeasureDate, i.SystemName, i.SystemID, metric.ListID, metric.ListElement ' + @CR
set @sql = @sql + 'order by t.TrendCollectionID, v.NPI, t.TrendQuarter ' + @CR
print(@sql)
exec(@sql)

/***** Creates a table for Quarter A that is being displayed in the report *****/

create table #Q2_2017(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q2_2017_TrendMeasureName nvarchar(150), 
Q2_2017_TrendMeasure int, 
Q2_2017_TrendColorCode int, 
Q2_2017_TrendQuarter nvarchar(8), 
Q2_2017_TrendMeasureDate datetime,
Q2_2017_Category nvarchar(200),
Q2_2017_CategoryPercentile int,
Q2_2017_CategoryColor int
) 

set @sql = @sql + 'Insert #Q2_2017(NPI, TrendCollectionID, Q2_2017_TrendMeasureName, Q2_2017_TrendMeasure, Q2_2017_TrendColorCode, Q2_2017_TrendQuarter, Q2_2017_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q2_2017_Category, Q2_2017_CategoryPercentile, Q2_2017_CategoryColor) ' + @CR
set @sql = @sql + 'Select NPI, TrendCollectionID, TrendMeasureName AS Q2_2017_TrendMeasureName, TrendMeasure AS Q2_2017_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q2_2017_TrendColorCode, TrendQuarter AS Q2_2017_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q2_2017_TrendMeasureDate, TrendCategory as Q2_2017_Category, TrendCategoryPercentile as Q2_2017_CategoryPercentile, TrendCategoryColor as Q2_2017_CatergoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q2, 2017'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select NPI, TrendCollectionID, TrendMeasureName AS Q2_2017_TrendMeasureName, TrendMeasure AS Q2_2017_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q2_2017_TrendColorCode, TrendQuarter AS Q2_2017_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q2_2017_TrendMeasureDate, TrendCategory as Q2_2017_Category, TrendCategoryPercentile as Q2_2017_CategoryPercentile, TrendCategoryColor as Q2_2017_CatergoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q2, 2017'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

/***** Creates a table for Quarter B that is being displayed in the report *****/

create table #Q1_2017(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q1_2017_TrendMeasureName nvarchar(150), 
Q1_2017_TrendMeasure int, 
Q1_2017_TrendColorCode int, 
Q1_2017_TrendQuarter nvarchar(8), 
Q1_2017_TrendMeasureDate datetime,
Q1_2017_Category nvarchar(200),
Q1_2017_CategoryPercentile int,
Q1_2017_CategoryColor int
) 

set @sql = @sql + 'Insert #Q1_2017(NPI, TrendCollectionID, Q1_2017_TrendMeasureName, Q1_2017_TrendMeasure, Q1_2017_TrendColorCode, Q1_2017_TrendQuarter, Q1_2017_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q1_2017_Category, Q1_2017_CategoryPercentile, Q1_2017_CategoryColor) ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q1_2017_TrendMeasureName, TrendMeasure AS Q1_2017_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q1_2017_TrendColorCode, TrendQuarter AS Q1_2017_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q1_2017_TrendMeasureDate, TrendCategory as Q1_2017_Category, TrendCategoryPercentile as Q1_2017_CategoryPercentile, TrendCategoryColor as Q1_2017_CatergoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q1, 2017'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select NPI, TrendCollectionID, TrendMeasureName AS Q1_2017_TrendMeasureName, TrendMeasure AS Q1_2017_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q1_2017_TrendColorCode, TrendQuarter AS Q1_2017_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q1_2017_TrendMeasureDate, TrendCategory as Q1_2017_Category, TrendCategoryPercentile as Q1_2017_CategoryPercentile, TrendCategoryColor as Q1_2017_CatergoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q1, 2017'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

/***** Creates a table for Quarter C that is being displayed in the report *****/

create table #Q4_2016(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q4_2016_TrendMeasureName nvarchar(150), 
Q4_2016_TrendMeasure int, 
Q4_2016_TrendColorCode int, 
Q4_2016_TrendQuarter nvarchar(8), 
Q4_2016_TrendMeasureDate datetime,
Q4_2016_Category nvarchar(200),
Q4_2016_CategoryPercentile int,
Q4_2016_CategoryColor int
) 

set @sql = @sql + 'Insert #Q4_2016(NPI, TrendCollectionID, Q4_2016_TrendMeasureName, Q4_2016_TrendMeasure, Q4_2016_TrendColorCode, Q4_2016_TrendQuarter, Q4_2016_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q4_2016_Category, Q4_2016_CategoryPercentile, Q4_2016_CategoryColor) ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q4_2016_TrendMeasureName, TrendMeasure AS Q4_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q4_2016_TrendColorCode, TrendQuarter AS Q4_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q4_2016_TrendMeasureDate, TrendCategory as Q4_2016_Category, TrendCategoryPercentile as Q4_2016_CategoryPercentile, TrendCategoryColor as Q4_2016_CatergoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q4, 2016'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select NPI, TrendCollectionID, TrendMeasureName AS Q4_2016_TrendMeasureName, TrendMeasure AS Q4_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q4_2016_TrendColorCode, TrendQuarter AS Q4_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q4_2016_TrendMeasureDate, TrendCategory as Q4_2016_Category, TrendCategoryPercentile as Q4_2016_CategoryPercentile, TrendCategoryColor as Q4_2016_CatergoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q4, 2016'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)


/***** Creates a table for Quarter D that is being displayed in the report *****/

create table #Q3_2016(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q3_2016_TrendMeasureName nvarchar(150), 
Q3_2016_TrendMeasure int, 
Q3_2016_TrendColorCode int, 
Q3_2016_TrendQuarter nvarchar(8), 
Q3_2016_TrendMeasureDate datetime,
Q3_2016_Category nvarchar(200),
Q3_2016_CategoryPercentile int,
Q3_2016_CategoryColor int
) 

set @sql = @sql + 'Insert #Q3_2016(NPI, TrendCollectionID, Q3_2016_TrendMeasureName, Q3_2016_TrendMeasure, Q3_2016_TrendColorCode, Q3_2016_TrendQuarter, Q3_2016_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q3_2016_Category, Q3_2016_CategoryPercentile, Q3_2016_CategoryColor) ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q3_2016_TrendMeasureName, TrendMeasure AS Q3_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q3_2016_TrendColorCode, TrendQuarter AS Q3_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q3_2016_TrendMeasureDate, TrendCategory as Q3_2016_Category, TrendCategoryPercentile as Q3_2016_CategoryPercentile, TrendCategoryColor as Q3_2016_CatergoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q3, 2016'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select NPI, TrendCollectionID, TrendMeasureName AS Q3_2016_TrendMeasureName, TrendMeasure AS Q3_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q3_2016_TrendColorCode, TrendQuarter AS Q3_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q3_2016_TrendMeasureDate, TrendCategory as Q3_2016_Category, TrendCategoryPercentile as Q3_2016_CategoryPercentile, TrendCategoryColor as Q3_2016_CatergoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q3, 2016'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

--select * from #Q3_2016 --This will need to point to the new temp table

/***** Creates a table for Quarter E that is being displayed in the report *****/

create table #Q2_2016(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q2_2016_TrendMeasureName nvarchar(150), 
Q2_2016_TrendMeasure int, 
Q2_2016_TrendColorCode int, 
Q2_2016_TrendQuarter nvarchar(8), 
Q2_2016_TrendMeasureDate datetime,
Q2_2016_Category nvarchar(200),
Q2_2016_CategoryPercentile int,
Q2_2016_CategoryColor int
) 

set @sql = @sql + 'Insert #Q2_2016(NPI, TrendCollectionID, Q2_2016_TrendMeasureName, Q2_2016_TrendMeasure, Q2_2016_TrendColorCode, Q2_2016_TrendQuarter, Q2_2016_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q2_2016_Category, Q2_2016_CategoryPercentile, Q2_2016_CategoryColor) ' + @CR
set @sql = @sql + 'Select NPI, TrendCollectionID, TrendMeasureName AS Q2_2016_TrendMeasureName, TrendMeasure AS Q2_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q2_2016_TrendColorCode, TrendQuarter AS Q2_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q2_2016_TrendMeasureDate, TrendCategory as Q2_2016_Category, TrendCategoryPercentile as Q2_2016_CategoryPercentile, TrendCategoryColor as Q2_2016_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q2, 2016'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select NPI, TrendCollectionID, TrendMeasureName AS Q2_2016_TrendMeasureName, TrendMeasure AS Q2_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q2_2016_TrendColorCode, TrendQuarter AS Q2_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q2_2016_TrendMeasureDate, TrendCategory as Q2_2016_Category, TrendCategoryPercentile as Q2_2016_CategoryPercentile, TrendCategoryColor as Q2_2016_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q2, 2016'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

--select * from #Q2_2016 --This will need to point to the new temp table

/***** Creates a table for Quarter F that is being displayed in the report *****/

create table #Q1_2016(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q1_2016_TrendMeasureName nvarchar(150), 
Q1_2016_TrendMeasure int, 
Q1_2016_TrendColorCode int, 
Q1_2016_TrendQuarter nvarchar(8), 
Q1_2016_TrendMeasureDate datetime,
Q1_2016_Category nvarchar(200),
Q1_2016_CategoryPercentile int,
Q1_2016_CategoryColor int
) 

set @sql = @sql + 'Insert #Q1_2016(NPI, TrendCollectionID, Q1_2016_TrendMeasureName, Q1_2016_TrendMeasure, Q1_2016_TrendColorCode, Q1_2016_TrendQuarter, Q1_2016_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q1_2016_Category, Q1_2016_CategoryPercentile, Q1_2016_CategoryColor) ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q1_2016_TrendMeasureName, TrendMeasure AS Q1_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q1_2016_TrendColorCode, TrendQuarter AS Q1_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q1_2016_TrendMeasureDate, TrendCategory as Q1_2016_Category, TrendCategoryPercentile as Q1_2016_CategoryPercentile, TrendCategoryColor as Q1_2016_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q1, 2016'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q1_2016_TrendMeasureName, TrendMeasure AS Q1_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q1_2016_TrendColorCode, TrendQuarter AS Q1_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q1_2016_TrendMeasureDate, TrendCategory as Q1_2016_Category, TrendCategoryPercentile as Q1_2016_CategoryPercentile, TrendCategoryColor as Q1_2016_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q1, 2016'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

--select * from #Q1_2016 --This will need to point to the new temp table


/***** Creates a table for Quarter G that is being displayed in the report *****/
create table #Q4_2015(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q4_2015_TrendMeasureName nvarchar(150), 
Q4_2015_TrendMeasure int, 
Q4_2015_TrendColorCode int, 
Q4_2015_TrendQuarter nvarchar(8), 
Q4_2015_TrendMeasureDate datetime,
Q4_2015_Category nvarchar(200),
Q4_2015_CategoryPercentile int,
Q4_2015_CategoryColor int

) 

set @sql = 'Insert #Q4_2015(NPI, TrendCollectionID, Q4_2015_TrendMeasureName, Q4_2015_TrendMeasure, Q4_2015_TrendColorCode, Q4_2015_TrendQuarter, Q4_2015_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q4_2015_Category, Q4_2015_CategoryPercentile, Q4_2015_CategoryColor) ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q4_2015_TrendMeasureName, TrendMeasure AS Q4_2015_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q4_2015_TrendColorCode, TrendQuarter AS Q4_2015_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q4_2015_TrendMeasureDate, TrendCategory as Q4_2015_Category, TrendCategoryPercentile as Q4_2015_CategoryPercentile, TrendCategoryColor as Q4_2015_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q4, 2015'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q4_2015_TrendMeasureName, TrendMeasure AS Q4_2015_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q4_2015_TrendColorCode, TrendQuarter AS Q4_2015_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q4_2015_TrendMeasureDate, TrendCategory as Q4_2015_Category, TrendCategoryPercentile as Q4_2015_CategoryPercentile, TrendCategoryColor as Q4_2015_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q4, 2015'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

--select * from #Q4_2015

/***** Creates a table for Quarter H that is being displayed in the report *****/
create table #Q3_2015(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q3_2015_TrendMeasureName nvarchar(150), 
Q3_2015_TrendMeasure int, 
Q3_2015_TrendColorCode int, 
Q3_2015_TrendQuarter nvarchar(8), 
Q3_2015_TrendMeasureDate datetime,
Q3_2015_Category nvarchar(200),
Q3_2015_CategoryPercentile int,
Q3_2015_CategoryColor int
) 

set @sql = 'Insert #Q3_2015(NPI, TrendCollectionID, Q3_2015_TrendMeasureName, Q3_2015_TrendMeasure, Q3_2015_TrendColorCode, Q3_2015_TrendQuarter, Q3_2015_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q3_2015_Category, Q3_2015_CategoryPercentile, Q3_2015_CategoryColor) ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q3_2015_TrendMeasureName, TrendMeasure AS Q3_2015_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q3_2015_TrendColorCode, TrendQuarter AS Q3_2015_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q3_2015_TrendMeasureDate, TrendCategory as Q3_2015_Category, TrendCategoryPercentile as Q3_2015_CategoryPercentile, TrendCategoryColor as Q3_2015_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q3, 2015'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q3_2015_TrendMeasureName, TrendMeasure AS Q3_2015_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q3_2015_TrendColorCode, TrendQuarter AS Q3_2015_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q3_2015_TrendMeasureDate, TrendCategory as Q3_2015_Category, TrendCategoryPercentile as Q3_2015_CategoryPercentile, TrendCategoryColor as Q3_2015_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q3, 2015'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

--select * from #Q3_2015

/***** Creates a table for Quarter I that is being displayed in the report *****/
create table #Q2_2015(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q2_2015_TrendMeasureName nvarchar(150), 
Q2_2015_TrendMeasure int, 
Q2_2015_TrendColorCode int, 
Q2_2015_TrendQuarter nvarchar(8), 
Q2_2015_TrendMeasureDate datetime,
Q2_2015_Category nvarchar(200),
Q2_2015_CategoryPercentile int,
Q2_2015_CategoryColor int
) 

set @sql = @sql + 'Insert #Q2_2015(NPI, TrendCollectionID, Q2_2015_TrendMeasureName, Q2_2015_TrendMeasure, Q2_2015_TrendColorCode, Q2_2015_TrendQuarter, Q2_2015_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q2_2015_Category, Q2_2015_CategoryPercentile, Q2_2015_CategoryColor) ' + @CR
set @sql = @sql + 'Select NPI, TrendCollectionID, TrendMeasureName AS Q2_2015_TrendMeasureName, TrendMeasure AS Q2_2015_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q2_2015_TrendColorCode, TrendQuarter AS Q2_2015_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q2_2015_TrendMeasureDate, TrendCategory as Q2_2015_Category, TrendCategoryPercentile as Q2_2015_CategoryPercentile, TrendCategoryColor as Q2_2015_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q2, 2015'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q2_2015_TrendMeasureName, TrendMeasure AS Q2_2015_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q2_2015_TrendColorCode, TrendQuarter AS Q2_2015_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q2_2015_TrendMeasureDate, TrendCategory as Q2_2015_Category, TrendCategoryPercentile as Q2_2015_CategoryPercentile, TrendCategoryColor as Q2_2015_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q2, 2015'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

--select * from #Q2_2015

/***** Creates a table for Quarter J that is being displayed in the report *****/
create table #Q1_2015(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q1_2015_TrendMeasureName nvarchar(150), 
Q1_2015_TrendMeasure int,
Q1_2015_TrendColorCode int, 
Q1_2015_TrendQuarter nvarchar(8), 
Q1_2015_TrendMeasureDate datetime,
Q1_2015_Category nvarchar(200),
Q1_2015_CategoryPercentile int,
Q1_2015_CategoryColor int
) 

set @sql = @sql + 'Insert #Q1_2015(NPI, TrendCollectionID, Q1_2015_TrendMeasureName, Q1_2015_TrendMeasure, Q1_2015_TrendColorCode, Q1_2015_TrendQuarter, Q1_2015_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q1_2015_Category, Q1_2015_CategoryPercentile, Q1_2015_CategoryColor) ' + @CR
set @sql = @sql + 'Select NPI, TrendCollectionID, TrendMeasureName AS Q1_2015_TrendMeasureName, TrendMeasure AS Q1_2015_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q1_2015_TrendColorCode, TrendQuarter AS Q1_2015_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q1_2015_TrendMeasureDate, TrendCategory as Q1_2015_Category, TrendCategoryPercentile as Q1_2015_CategoryPercentile, TrendCategoryColor as Q1_2015_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q1, 2015'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q1_2015_TrendMeasureName, TrendMeasure AS Q1_2015_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q1_2015_TrendColorCode, TrendQuarter AS Q1_2015_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q1_2015_TrendMeasureDate, TrendCategory as Q1_2015_Category, TrendCategoryPercentile as Q1_2015_CategoryPercentile, TrendCategoryColor as Q1_2015_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q1, 2015'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

--select * from #Q1_2015

/***** Creates a table for Quarter K that is being displayed in the report *****/
create table #Q4_2014(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q4_2014_TrendMeasureName nvarchar(150), 
Q4_2014_TrendMeasure int,
Q4_2014_TrendColorCode int, 
Q4_2014_TrendQuarter nvarchar(8), 
Q4_2014_TrendMeasureDate datetime,
Q4_2014_Category nvarchar(200),
Q4_2014_CategoryPercentile int,
Q4_2014_CategoryColor int
) 

set @sql = @sql + 'Insert #Q4_2014(NPI, TrendCollectionID, Q4_2014_TrendMeasureName, Q4_2014_TrendMeasure, Q4_2014_TrendColorCode, Q4_2014_TrendQuarter, Q4_2014_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q4_2014_Category, Q4_2014_CategoryPercentile, Q4_2014_CategoryColor) ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q4_2014_TrendMeasureName, TrendMeasure AS Q4_2014_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q4_2014_TrendColorCode, TrendQuarter AS Q4_2014_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q4_2014_TrendMeasureDate, TrendCategory as Q4_2014_Category, TrendCategoryPercentile as Q4_2014_CategoryPercentile, TrendCategoryColor as Q4_2014_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q4, 2014'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q4_2014_TrendMeasureName, TrendMeasure AS Q4_2014_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q4_2014_TrendColorCode, TrendQuarter AS Q4_2014_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q4_2014_TrendMeasureDate, TrendCategory as Q4_2014_Category, TrendCategoryPercentile as Q4_2014_CategoryPercentile, TrendCategoryColor as Q4_2014_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q4, 2014'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

/***** Creates a table for Quarter L that is being displayed in the report *****/
create table #Q3_2014(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q3_2014_TrendMeasureName nvarchar(150), 
Q3_2014_TrendMeasure int,
Q3_2014_TrendColorCode int, 
Q3_2014_TrendQuarter nvarchar(8), 
Q3_2014_TrendMeasureDate datetime,
Q3_2014_Category nvarchar(200),
Q3_2014_CategoryPercentile int,
Q3_2014_CategoryColor int
) 

set @sql = @sql + 'Insert #Q3_2014(NPI, TrendCollectionID, Q3_2014_TrendMeasureName, Q3_2014_TrendMeasure, Q3_2014_TrendColorCode, Q3_2014_TrendQuarter, Q3_2014_TrendMeasureDate, ' + @CR
set @sql = @sql + 'Q3_2014_Category, Q3_2014_CategoryPercentile, Q3_2014_CategoryColor) ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q3_2014_TrendMeasureName, TrendMeasure AS Q3_2014_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q3_2014_TrendColorCode, TrendQuarter AS Q3_2014_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q3_2014_TrendMeasureDate, TrendCategory as Q3_2014_Category, TrendCategoryPercentile as Q3_2014_CategoryPercentile, TrendCategoryColor as Q3_2014_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q3, 2014'' and TrendMeasureName not like ''%Overall%'' ' + @CR
set @sql = @sql + 'union ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q3_2014_TrendMeasureName, TrendMeasure AS Q3_2014_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q3_2014_TrendColorCode, TrendQuarter AS Q3_2014_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q3_2014_TrendMeasureDate, TrendCategory as Q3_2014_Category, TrendCategoryPercentile as Q3_2014_CategoryPercentile, TrendCategoryColor as Q3_2014_CategoryColor ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q3, 2014'' and TrendMeasureName like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

--select * from #Q4_2014

/***** Creates a table for Quarter L that is being displayed in the report *****/

/***** This will need to be commented out when we have 9 quarters of data, the temp table name will need to change as well
create table #Q4_2014(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q4_2014_TrendMeasureName nvarchar(150), 
Q4_2014_TrendMeasure int, 
Q4_2014_TrendColorCode int, 
Q4_2014_TrendQuarter nvarchar(8), 
Q4_2014_TrendMeasureDate datetime
) 

set @sql = @sql + 'Insert #Q4_2014(NPI, TrendCollectionID, Q4_2014_TrendMeasureName, Q4_2014_TrendMeasure, Q4_2014_TrendColorCode, Q4_2014_TrendQuarter, Q4_2014_TrendMeasureDate) ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q4_2014_TrendMeasureName, TrendMeasure AS Q4_2014_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q4_2014_TrendColorCode, TrendQuarter AS Q4_2014_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q4_2014_TrendMeasureDate ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q4, 2014'' and TrendMeasureName not like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

--select * from #Q4_2014 --This will need to point to the new temp table

*****/

/***** Creates a table for Quarter M or the 10th Quarter that is being displayed in the report *****/

/***** This will need to be commented out when we have 10 quarters of data, the temp table name will need to change as well
create table #Q4_2014(
NPI nvarchar(10), 
TrendCollectionID nvarchar(10), 
Q4_2014_TrendMeasureName nvarchar(150), 
Q4_2014_TrendMeasure int, 
Q4_2014_TrendColorCode int, 
Q4_2014_TrendQuarter nvarchar(8), 
Q4_2014_TrendMeasureDate datetime
) 

set @sql = @sql + 'Insert #Q4_2014(NPI, TrendCollectionID, Q4_2014_TrendMeasureName, Q4_2014_TrendMeasure, Q4_2014_TrendColorCode, Q4_2014_TrendQuarter, Q4_2014_TrendMeasureDate) ' + @CR
set @sql = @sql + 'Select	NPI, TrendCollectionID, TrendMeasureName AS Q4_2014_TrendMeasureName, TrendMeasure AS Q4_2014_TrendMeasure, ' + @CR
set @sql = @sql + 'TrendColorCode AS Q4_2014_TrendColorCode, TrendQuarter AS Q4_2014_TrendQuarter, ' + @CR
set @sql = @sql + 'TrendMeasureDate AS Q4_2014_TrendMeasureDate ' + @CR
set @sql = @sql + 'From ' + @Database + '.dbo.VITrendValues ' + @CR
set @sql = @sql + 'Where TrendQuarter = ''Q4, 2014'' and TrendMeasureName not like ''%Overall%'' ' + @CR
--print(@sql)
exec(@sql)

--select * from #Q4_2014 --This will need to point to the new temp table

*****/

create table #_All_Quarters(
	NPI nvarchar(10), 
	FirstName nvarchar(100), 
	LastName nvarchar(100), 
	OrderID int,
	VICollectionID nvarchar(10),
	CurrentMeasureName nvarchar(200), 
	CurrentOverall nvarchar(150), 
	CurrentOverallCode int, 
	CurrentMeasureDate datetime,  
	SystemName nvarchar(200), 
	SystemID nvarchar(10),
	ListID nvarchar(14), 
	ListElement nvarchar(200), 
	TrendMeasureName nvarchar(150), 
	TrendMeasure int,
	TrendColorCode int,
	TrendQuarter nvarchar(8),
	Q2_2017_TrendMeasureName nvarchar(150), 
	Q2_2017_TrendMeasure int, 
	Q2_2017_TrendColorCode int, 
	Q2_2017_TrendQuarter nvarchar(8),
	Q2_2017_TrendMeasureDate datetime,
	Q2_2017_Category nvarchar(100),
	Q2_2017_CategoryPercentile float,
	Q2_2017_CategoryColor int,
	Q1_2017_TrendMeasureName nvarchar(150), 
	Q1_2017_TrendMeasure int, 
	Q1_2017_TrendColorCode int, 
	Q1_2017_TrendQuarter nvarchar(8),
	Q1_2017_TrendMeasureDate datetime,
	Q1_2017_Category nvarchar(100),
	Q1_2017_CategoryPercentile float,
	Q1_2017_CategoryColor int,
	Q4_2016_TrendMeasureName nvarchar(150), 
	Q4_2016_TrendMeasure int, 
	Q4_2016_TrendColorCode int, 
	Q4_2016_TrendQuarter nvarchar(8),
	Q4_2016_TrendMeasureDate datetime,
	Q4_2016_Category nvarchar(100),
	Q4_2016_CategoryPercentile float,
	Q4_2016_CategoryColor int, 
	Q3_2016_TrendMeasureName nvarchar(150), 
	Q3_2016_TrendMeasure int, 
	Q3_2016_TrendColorCode int, 
	Q3_2016_TrendQuarter nvarchar(8),
	Q3_2016_TrendMeasureDate datetime,
	Q3_2016_Category nvarchar(100),
	Q3_2016_CategoryPercentile float,
	Q3_2016_CategoryColor int, 
	Q2_2016_TrendMeasureName nvarchar(150), 
	Q2_2016_TrendMeasure int, 
	Q2_2016_TrendColorCode int, 
	Q2_2016_TrendQuarter nvarchar(8),
	Q2_2016_TrendMeasureDate datetime,
	Q2_2016_Category nvarchar(100),
	Q2_2016_CategoryPercentile float,
	Q2_2016_CategoryColor int, 
	Q1_2016_TrendMeasureName nvarchar(150), 
	Q1_2016_TrendMeasure int, 
	Q1_2016_TrendColorCode int, 
	Q1_2016_TrendQuarter nvarchar(8),
	Q1_2016_TrendMeasureDate datetime,
	Q1_2016_Category nvarchar(100),
	Q1_2016_CategoryPercentile float,
	Q1_2016_CategoryColor int,
	Q4_2015_TrendMeasureName nvarchar(150), 
	Q4_2015_TrendMeasure int, 
	Q4_2015_TrendColorCode int, 
	Q4_2015_TrendQuarter nvarchar(8), 
	Q4_2015_TrendMeasureDate datetime,
	Q4_2015_Category nvarchar(100),
	Q4_2015_CategoryPercentile float,
	Q4_2015_CategoryColor int,
	Q3_2015_TrendMeasureName nvarchar(150), 
	Q3_2015_TrendMeasure int, 
	Q3_2015_TrendColorCode int, 
	Q3_2015_TrendQuarter nvarchar(8), 
	Q3_2015_TrendMeasureDate datetime,
	Q3_2015_Category nvarchar(100),
	Q3_2015_CategoryPercentile float,
	Q3_2015_CategoryColor int,
	Q2_2015_TrendMeasureName nvarchar(150), 
	Q2_2015_TrendMeasure int, 
	Q2_2015_TrendColorCode int, 
	Q2_2015_TrendQuarter nvarchar(8), 
	Q2_2015_TrendMeasureDate datetime,
	Q2_2015_Category nvarchar(100),
	Q2_2015_CategoryPercentile float,
	Q2_2015_CategoryColor int,
	Q1_2015_TrendMeasureName nvarchar(150), 
	Q1_2015_TrendMeasure int, 
	Q1_2015_TrendColorCode int, 
	Q1_2015_TrendQuarter nvarchar(8), 
	Q1_2015_TrendMeasureDate datetime,
	Q1_2015_Category nvarchar(100),
	Q1_2015_CategoryPercentile float,
	Q1_2015_CategoryColor int,
	Q4_2014_TrendMeasureName nvarchar(150),
	Q4_2014_TrendMeasure int, 
	Q4_2014_TrendColorCode int, 
	Q4_2014_TrendQuarter nvarchar(8), 
	Q4_2014_TrendMeasureDate datetime,
	Q4_2014_Category nvarchar(100),
	Q4_2014_CategoryPercentile float,
	Q4_2014_CategoryColor int,
	Q3_2014_TrendMeasureName nvarchar(150),
	Q3_2014_TrendMeasure int, 
	Q3_2014_TrendColorCode int, 
	Q3_2014_TrendQuarter nvarchar(8), 
	Q3_2014_TrendMeasureDate datetime,
	Q3_2014_Category nvarchar(100),
	Q3_2014_CategoryPercentile float,
	Q3_2014_CategoryColor int


	/***** This will need to commmented out when we have 9th quarter of data, these will need to be updated with the new values
	Q4_2014_TrendMeasureName nvarchar(150), 
	Q4_2014_TrendMeasure int, 
	Q4_2014_TrendColorCode int, 
	Q4_2014_TrendQuarter nvarchar(8),
	Q4_2014_TrendMeasureDate datetime 
	*****/

)
--removed TrendQuarter from the #_All_Quarters table
set @sql = 'insert #_All_Quarters ' + @CR
set @sql = @sql + 'Select distinct NPI, FirstName, LastName, OrderId, VICollectionID, CurrentMeasureName, CurrentOverall, CurrentOverallCode, CurrentMeasureDate, SystemName, SystemID, ' + @CR
set @sql = @sql + 'ListID, ListElement, TrendMeasureName, TrendMeasure, TrendColorCode, TrendQuarter, ' + @CR
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR --Q3, 2014
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR --Q4, 2014
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR --Q1, 2015
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR --Q2, 2015
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR --Q3, 2015
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR --Q4, 2015
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR --Q1, 2016
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR --Q2, 2016
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR --Q3, 2016
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR --Q4, 2016
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ' + @CR -- Q1, 2017
set @sql = @sql + 'NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL ' + @CR -- Q2, 2017
--set @sql = @sql + ',NULL, NULL, NULL, NULL, NULL ' + @CR -- This will need to be uncommented when add a new quarter
set @sql = @sql + 'from #_AllMetrics ' + @CR
exec(@sql)

--Q2, 2017
set @sql = 'update o ' + @CR
set @sql = @sql + 'set o.Q2_2017_TrendMeasureName = a.Q2_2017_TrendMeasureName, ' + @CR
set @sql = @sql + 'o.Q2_2017_TrendMeasure = a.Q2_2017_TrendMeasure, ' + @CR
set @sql = @sql + 'o.Q2_2017_TrendColorCode = a.Q2_2017_TrendColorCode, ' + @CR
set @sql = @sql + 'o.Q2_2017_TrendQuarter = a.Q2_2017_TrendQuarter, ' + @CR
set @sql = @sql + 'o.Q2_2017_TrendMeasureDate = a.Q2_2017_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q2_2017_Category = a.Q2_2017_Category, ' + @CR
set @sql = @sql + 'o.Q2_2017_CategoryPercentile = a.Q2_2017_CategoryPercentile, ' + @CR
set @sql = @sql + 'o.Q2_2017_CategoryColor = a.Q2_2017_CategoryColor ' + @CR
set @sql = @sql + 'from #_All_Quarters o ' + @CR
set @sql = @sql + 'left join #Q2_2017 a on a.NPI = o.NPI ' + @CR
	set @sql = @sql + 'and a.Q2_2017_TrendMeasureName = o.TrendMeasureName ' + @CR
exec(@sql)

--Q1, 2017
set @sql = 'update o ' + @CR
set @sql = @sql + 'set o.Q1_2017_TrendMeasureName = a.Q1_2017_TrendMeasureName, ' + @CR
set @sql = @sql + 'o.Q1_2017_TrendMeasure = a.Q1_2017_TrendMeasure, ' + @CR
set @sql = @sql + 'o.Q1_2017_TrendColorCode = a.Q1_2017_TrendColorCode, ' + @CR
set @sql = @sql + 'o.Q1_2017_TrendQuarter = a.Q1_2017_TrendQuarter, ' + @CR
set @sql = @sql + 'o.Q1_2017_TrendMeasureDate = a.Q1_2017_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q1_2017_Category = a.Q1_2017_Category, ' + @CR
set @sql = @sql + 'o.Q1_2017_CategoryPercentile = a.Q1_2017_CategoryPercentile, ' + @CR
set @sql = @sql + 'o.Q1_2017_CategoryColor = a.Q1_2017_CategoryColor ' + @CR
set @sql = @sql + 'from #_All_Quarters o ' + @CR
set @sql = @sql + 'left join #Q1_2017 a on a.NPI = o.NPI ' + @CR
	set @sql = @sql + 'and a.Q1_2017_TrendMeasureName = o.TrendMeasureName ' + @CR
exec(@sql)

--Q4, 2016
set @sql = 'update o ' + @CR
set @sql = @sql + 'set o.Q4_2016_TrendMeasureName = a.Q4_2016_TrendMeasureName, ' + @CR
set @sql = @sql + 'o.Q4_2016_TrendMeasure = a.Q4_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'o.Q4_2016_TrendColorCode = a.Q4_2016_TrendColorCode, ' + @CR
set @sql = @sql + 'o.Q4_2016_TrendQuarter = a.Q4_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'o.Q4_2016_TrendMeasureDate = a.Q4_2016_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q4_2016_Category = a.Q4_2016_Category, ' + @CR
set @sql = @sql + 'o.Q4_2016_CategoryPercentile = a.Q4_2016_CategoryPercentile, ' + @CR
set @sql = @sql + 'o.Q4_2016_CategoryColor = a.Q4_2016_CategoryColor ' + @CR
set @sql = @sql + 'from #_All_Quarters o ' + @CR
set @sql = @sql + 'left join #Q4_2016 a on a.NPI = o.NPI ' + @CR
	set @sql = @sql + 'and a.Q4_2016_TrendMeasureName = o.TrendMeasureName ' + @CR
exec(@sql)

--Q3, 2016
set @sql = 'update o ' + @CR
set @sql = @sql + 'set o.Q3_2016_TrendMeasureName = a.Q3_2016_TrendMeasureName, ' + @CR
set @sql = @sql + 'o.Q3_2016_TrendMeasure = a.Q3_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'o.Q3_2016_TrendColorCode = a.Q3_2016_TrendColorCode, ' + @CR
set @sql = @sql + 'o.Q3_2016_TrendQuarter = a.Q3_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'o.Q3_2016_TrendMeasureDate = a.Q3_2016_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q3_2016_Category = a.Q3_2016_Category, ' + @CR
set @sql = @sql + 'o.Q3_2016_CategoryPercentile = a.Q3_2016_CategoryPercentile, ' + @CR
set @sql = @sql + 'o.Q3_2016_CategoryColor = a.Q3_2016_CategoryColor ' + @CR
set @sql = @sql + 'from #_All_Quarters o ' + @CR
set @sql = @sql + 'left join #Q3_2016 a on a.NPI = o.NPI ' + @CR
	set @sql = @sql + 'and a.Q3_2016_TrendMeasureName = o.TrendMeasureName ' + @CR
exec(@sql)

--Q2, 2016
set @sql = 'update o ' + @CR
set @sql = @sql + 'set o.Q2_2016_TrendMeasureName = a.Q2_2016_TrendMeasureName, ' + @CR
set @sql = @sql + 'o.Q2_2016_TrendMeasure = a.Q2_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'o.Q2_2016_TrendColorCode = a.Q2_2016_TrendColorCode, ' + @CR
set @sql = @sql + 'o.Q2_2016_TrendQuarter = a.Q2_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'o.Q2_2016_TrendMeasureDate = a.Q2_2016_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q2_2016_Category = a.Q2_2016_Category, ' + @CR
set @sql = @sql + 'o.Q2_2016_CategoryPercentile = a.Q2_2016_CategoryPercentile, ' + @CR
set @sql = @sql + 'o.Q2_2016_CategoryColor = a.Q2_2016_CategoryColor ' + @CR
set @sql = @sql + 'from #_All_Quarters o ' + @CR
set @sql = @sql + 'left join #Q2_2016 a on a.NPI = o.NPI ' + @CR
	set @sql = @sql + 'and a.Q2_2016_TrendMeasureName = o.TrendMeasureName ' + @CR
exec(@sql)

--Q1, 2016
set @sql = 'update o ' + @CR
set @sql = @sql + 'set o.Q1_2016_TrendMeasureName = a.Q1_2016_TrendMeasureName, ' + @CR
set @sql = @sql + 'o.Q1_2016_TrendMeasure = a.Q1_2016_TrendMeasure, ' + @CR
set @sql = @sql + 'o.Q1_2016_TrendColorCode = a.Q1_2016_TrendColorCode, ' + @CR
set @sql = @sql + 'o.Q1_2016_TrendQuarter = a.Q1_2016_TrendQuarter, ' + @CR
set @sql = @sql + 'o.Q1_2016_TrendMeasureDate = a.Q1_2016_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q1_2016_Category = a.Q1_2016_Category, ' + @CR
set @sql = @sql + 'o.Q1_2016_CategoryPercentile = a.Q1_2016_CategoryPercentile, ' + @CR
set @sql = @sql + 'o.Q1_2016_CategoryColor = a.Q1_2016_CategoryColor ' + @CR
set @sql = @sql + 'from #_All_Quarters o ' + @CR
set @sql = @sql + 'left join #Q1_2016 a on a.NPI = o.NPI ' + @CR
	set @sql = @sql + 'and a.Q1_2016_TrendMeasureName = o.TrendMeasureName ' + @CR
exec(@sql)

--Q4, 2015
set @sql = 'update o ' + @CR
set @sql = @sql + 'set o.Q4_2015_TrendMeasureName = a.Q4_2015_TrendMeasureName, ' + @CR
set @sql = @sql + 'o.Q4_2015_TrendMeasure = a.Q4_2015_TrendMeasure, ' + @CR
set @sql = @sql + 'o.Q4_2015_TrendColorCode = a.Q4_2015_TrendColorCode, ' + @CR
set @sql = @sql + 'o.Q4_2015_TrendQuarter = a.Q4_2015_TrendQuarter, ' + @CR
set @sql = @sql + 'o.Q4_2015_TrendMeasureDate = a.Q4_2015_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q4_2015_Category = a.Q4_2015_Category, ' + @CR
set @sql = @sql + 'o.Q4_2015_CategoryPercentile = a.Q4_2015_CategoryPercentile, ' + @CR
set @sql = @sql + 'o.Q4_2015_CategoryColor = a.Q4_2015_CategoryColor ' + @CR
set @sql = @sql + 'from #_All_Quarters o ' + @CR
set @sql = @sql + 'left join #Q4_2015 a on a.NPI = o.NPI ' + @CR
	set @sql = @sql + 'and a.Q4_2015_TrendMeasureName = o.TrendMeasureName ' + @CR
exec(@sql)

--Q3, 2015
set @sql = 'update o ' + @CR
set @sql = @sql + 'set o.Q3_2015_TrendMeasureName = a.Q3_2015_TrendMeasureName, ' + @CR
set @sql = @sql + 'o.Q3_2015_TrendMeasure = a.Q3_2015_TrendMeasure, ' + @CR
set @sql = @sql + 'o.Q3_2015_TrendColorCode = a.Q3_2015_TrendColorCode, ' + @CR
set @sql = @sql + 'o.Q3_2015_TrendQuarter = a.Q3_2015_TrendQuarter, ' + @CR
set @sql = @sql + 'o.Q3_2015_TrendMeasureDate = a.Q3_2015_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q3_2015_Category = a.Q3_2015_Category, ' + @CR
set @sql = @sql + 'o.Q3_2015_CategoryPercentile = a.Q3_2015_CategoryPercentile, ' + @CR
set @sql = @sql + 'o.Q3_2015_CategoryColor = a.Q3_2015_CategoryColor ' + @CR
set @sql = @sql + 'from #_All_Quarters o ' + @CR
set @sql = @sql + 'left join #Q3_2015 a on a.NPI = o.NPI ' + @CR
	set @sql = @sql + 'and a.Q3_2015_TrendMeasureName = o.TrendMeasureName ' + @CR 
exec(@sql)

--Q2, 2015
set @sql = 'update o ' + @CR 
set @sql = @sql + 'set o.Q2_2015_TrendMeasureName = a.Q2_2015_TrendMeasureName, ' + @CR 
set @sql = @sql + 'o.Q2_2015_TrendMeasure = a.Q2_2015_TrendMeasure, ' + @CR 
set @sql = @sql + 'o.Q2_2015_TrendColorCode = a.Q2_2015_TrendColorCode, ' + @CR 
set @sql = @sql + 'o.Q2_2015_TrendQuarter = a.Q2_2015_TrendQuarter, ' + @CR 
set @sql = @sql + 'o.Q2_2015_TrendMeasureDate = a.Q2_2015_TrendMeasureDate, ' + @CR 
set @sql = @sql + 'o.Q2_2015_Category = a.Q2_2015_Category, ' + @CR
set @sql = @sql + 'o.Q2_2015_CategoryPercentile = a.Q2_2015_CategoryPercentile, ' + @CR
set @sql = @sql + 'o.Q2_2015_CategoryColor = a.Q2_2015_CategoryColor ' + @CR
set @sql = @sql + 'from #_All_Quarters o ' + @CR 
set @sql = @sql + 'left join #Q2_2015 a on a.NPI = o.NPI ' + @CR 
	set @sql = @sql + 'and a.Q2_2015_TrendMeasureName = o.TrendMeasureName ' + @CR  
exec(@sql)

--Q1, 2015
set @sql = 'update o ' + @CR 
set @sql = @sql + 'set o.Q1_2015_TrendMeasureName = a.Q1_2015_TrendMeasureName, ' + @CR 
set @sql = @sql + 'o.Q1_2015_TrendMeasure = a.Q1_2015_TrendMeasure, ' + @CR 
set @sql = @sql + 'o.Q1_2015_TrendColorCode = a.Q1_2015_TrendColorCode, ' + @CR 
set @sql = @sql + 'o.Q1_2015_TrendQuarter = a.Q1_2015_TrendQuarter, ' + @CR 
set @sql = @sql + 'o.Q1_2015_TrendMeasureDate = a.Q1_2015_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q1_2015_Category = a.Q1_2015_Category, ' + @CR
set @sql = @sql + 'o.Q1_2015_CategoryPercentile = a.Q1_2015_CategoryPercentile,' + @CR
set @sql = @sql + 'o.Q1_2015_CategoryColor = a.Q1_2015_CategoryColor ' + @CR 
set @sql = @sql + 'from #_All_Quarters o ' + @CR 
set @sql = @sql + 'left join #Q1_2015 a on a.NPI = o.NPI ' + @CR 
	set @sql = @sql + 'and a.Q1_2015_TrendMeasureName = o.TrendMeasureName ' + @CR  
exec(@sql)

--Q4, 2014
set @sql = 'update o ' + @CR
set @sql = @sql + 'set o.Q4_2014_TrendMeasureName = a.Q4_2014_TrendMeasureName, ' + @CR
set @sql = @sql + 'o.Q4_2014_TrendMeasure = a.Q4_2014_TrendMeasure, ' + @CR
set @sql = @sql + 'o.Q4_2014_TrendColorCode = a.Q4_2014_TrendColorCode, ' + @CR
set @sql = @sql + 'o.Q4_2014_TrendQuarter = a.Q4_2014_TrendQuarter, ' + @CR
set @sql = @sql + 'o.Q4_2014_TrendMeasureDate = a.Q4_2014_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q4_2014_Category = a.Q4_2014_Category, ' + @CR
set @sql = @sql + 'o.Q4_2014_CategoryPercentile = a.Q4_2014_CategoryPercentile,' + @CR
set @sql = @sql + 'o.Q4_2014_CategoryColor = a.Q4_2014_CategoryColor ' + @CR 
set @sql = @sql + 'from #_All_Quarters o ' + @CR
set @sql = @sql + 'left join #Q4_2014 a on a.NPI = o.NPI ' + @CR
	set @sql = @sql + 'and a.Q4_2014_TrendMeasureName = o.TrendMeasureName ' + @CR 
exec(@sql)

--Q3, 2014
set @sql = 'update o ' + @CR
set @sql = @sql + 'set o.Q3_2014_TrendMeasureName = a.Q3_2014_TrendMeasureName, ' + @CR
set @sql = @sql + 'o.Q3_2014_TrendMeasure = a.Q3_2014_TrendMeasure, ' + @CR
set @sql = @sql + 'o.Q3_2014_TrendColorCode = a.Q3_2014_TrendColorCode, ' + @CR
set @sql = @sql + 'o.Q3_2014_TrendQuarter = a.Q3_2014_TrendQuarter, ' + @CR
set @sql = @sql + 'o.Q3_2014_TrendMeasureDate = a.Q3_2014_TrendMeasureDate, ' + @CR
set @sql = @sql + 'o.Q3_2014_Category = a.Q3_2014_Category, ' + @CR
set @sql = @sql + 'o.Q3_2014_CategoryPercentile = a.Q3_2014_CategoryPercentile,' + @CR
set @sql = @sql + 'o.Q3_2014_CategoryColor = a.Q3_2014_CategoryColor ' + @CR 
set @sql = @sql + 'from #_All_Quarters o ' + @CR
set @sql = @sql + 'left join #Q3_2014 a on a.NPI = o.NPI ' + @CR
	set @sql = @sql + 'and a.Q3_2014_TrendMeasureName = o.TrendMeasureName ' + @CR 
exec(@sql)

--select * from #Q2_2016


select * from #_All_Quarters 
--where TrendMeasureName like '%Overall VI Measure' and TrendQuarter = 'Q1, 2016'
--where npi = '1649324195' --where NPI = '1003050535'--where TrendMeasureName like '%Overall%'
--where npi = '1164438818' 
--where NPI = '1972578359' and 
--where TrendMeasureName like '%Overall%'

drop table #_AllMetrics
drop table #Q4_2015
drop table #Q3_2015
drop table #Q2_2015
drop table #Q1_2015
drop table #Q4_2014
drop table #Q3_2014
drop table #_All_Quarters
drop table #Q1_2016
drop table #Q2_2016
drop table #Q3_2016
drop table #Q4_2016
drop table #Q1_2017
--drop table #Q4_2014-- This will need to be updated when the table is updated above for the 8th Quarter of Data

















