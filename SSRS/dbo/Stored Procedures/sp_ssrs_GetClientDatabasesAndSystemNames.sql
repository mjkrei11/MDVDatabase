






CREATE procedure [dbo].[sp_ssrs_GetClientDatabasesAndSystemNames]

as

--exec sp_ssrs_GetClientDatabasesAndSystemNames

select		SystemDatabase, SystemName
from		MDVALUATE.dbo.SystemRecordsMedia
where		IsClient = 'Yes'
and			CustomerTerminatedDate is null
and			SystemDatabase is not null
order by	SystemName
