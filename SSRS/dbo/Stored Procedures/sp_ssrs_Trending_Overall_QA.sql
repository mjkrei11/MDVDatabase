






CREATE procedure [dbo].[sp_ssrs_Trending_Overall_QA] (
	@Database nvarchar(200)

)

as

/*
declare
@Database nvarchar(200)


set @Database = 'TwinCities'


exec sp_ssrs_Trending_Overall_QA @Database
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

set @sql = 'select v.NPI, p.FirstName, p.LastName,v.VICollectionID, v.VIMeasureName AS CurrentMeasureName, v.VIMeasure AS CurrentOverall, ' + @CR
set @sql = @sql + 'v.ColorCode AS CurrentOverallColor, v.VIMeasureDate As CurrentMeasureDate, ' + @CR
set @sql = @sql + 't.TrendCollectionID, t.TrendMeasureName, t.TrendMeasure, t.TrendColorCode, t.TrendQuarter, t.TrendMeasureDate, ' + @CR
set @sql = @sql + 'i.SystemName, i.SystemID, metric.ListID, metric.ListElement ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.VIMeasureValues v ' + @CR
set @sql = @sql + 'left outer join ' + @Database + '.dbo.PhysicianMedia p on p.NPI = v.NPI ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.VITrendValues t on t.NPI = v.NPI and t.TrendCollectionID = v.VICollectionID and t.TrendMeasureName = v.VIMeasureName ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysVIndex i on i.SystemID = v.VICollectionID and i.SystemID = t.TrendCollectionID ' + @CR
set @sql = @sql + 'left outer join MDVALUATE.dbo.PickList metric on metric.ListID = v.NPI ' + @CR
set @sql = @sql + 'left outer join MDVALUATE.dbo.PickListMedia media on media.ListTypeID = metric.ListTypeID ' + @CR
set @sql = @sql + 'where v.VIMeasureName like ''%Overall%'' and t.TrendMeasureName like ''%Overall%'' ' + @CR
set @sql = @sql + 'group by v.NPI, p.FirstName, p.LastName,v.VICollectionID, v.VIMeasureName, v.VIMeasure, ' + @CR
set @sql = @sql + 'v.ColorCode, v.VIMeasureDate, t.TrendCollectionID, t.TrendMeasureName, t.TrendMeasure, ' + @CR
set @sql = @sql + 't.TrendColorCode, t.TrendQuarter, t.TrendMeasureDate, i.SystemName, i.SystemID, metric.ListID, metric.ListElement ' + @CR
set @sql = @sql + 'order by t.TrendCollectionID, v.NPI, t.TrendQuarter ' + @CR
print(@sql)
exec(@sql)

--set @sql = 'select distinct t.NPI, p.FirstName, p.LastName, t.TrendCollectionID, t.TrendMeasureName, t.TrendMeasure, t.TrendColorCode, t.TrendQuarter, ' + @CR
--set @sql = @sql + 'i.SystemName, i.SystemID, metric.ListID, metric.ListElement  ' + @CR
--set @sql = @sql + 'from ' + @Database + '.dbo.VITrendValues t ' + @CR
--set @sql = @sql + 'left outer join ' + @Database + '.dbo.PhysicianMedia p on p.NPI = t.NPI ' + @CR
--set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysVIndex i on i.SystemID = t.TrendCollectionID ' + @CR
--set @sql = @sql + 'left outer join MDVALUATE.dbo.PickList metric on metric.ListID = t.NPI ' + @CR
--set @sql = @sql + 'left outer join MDVALUATE.dbo.PickListMedia media on media.ListTypeID = metric.ListTypeID ' + @CR
--set @sql = @sql + 'where t.TrendMeasureName like ''%Overall%'' ' + @CR
--set @sql = @sql + 'group by t.NPI, p.FirstName, p.LastName, t.TrendCollectionID, t.TrendMeasureName, t.TrendMeasure, t.TrendColorCode, t.TrendQuarter, ' + @CR
--set @sql = @sql + 'i.SystemName, i.SystemID, metric.ListID, metric.ListElement ' + @CR
--set @sql = @sql + 'order by t.TrendCollectionID, t.NPI, t.TrendQuarter ' + @CR
----print(@sql)
--exec(@sql)







