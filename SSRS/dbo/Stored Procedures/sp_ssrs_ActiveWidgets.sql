


CREATE procedure [dbo].[sp_ssrs_ActiveWidgets]

AS

/* Test parameter */
/*
exec sp_ssrs_ActiveWidgets
*/


select OrganizationID, SystemName, FirstName, LastName, Rating, Volume, IsActive
from [MDV-Prod].WidgetData.dbo.AggregateWidgetData
where WidgetEntityTypeID = 1
order by SystemName, LastName

--Print @sql





