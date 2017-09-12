CREATE procedure [dbo].[sp_ssrs_RepTrendingDatabases]

as

--exec sp_ssrs_RepTrendingDatabases

select		'_ALL_' as SystemDatabase
union
select		distinct SystemDatabase
from		MDVALUATE.dbo.SystemRecordsMedia
where		IsClient = 'Yes'
and			CustomerTerminatedDate is null