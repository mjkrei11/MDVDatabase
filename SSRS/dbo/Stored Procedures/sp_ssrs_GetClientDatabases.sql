





CREATE procedure [dbo].[sp_ssrs_GetClientDatabases]

as

--exec sp_ssrs_GetClientDatabases
select		null as ClientDb
union
select		SystemDatabase
from		MDVALUATE.dbo.SystemRecordsMedia
where		IsClient = 'Yes'
union
select		name
from		sys.databases
where		name like 'competition%'
union
select		name
from		sys.databases
where		name like 'bench_%'
