





CREATE procedure [dbo].[sp_ssrs_GetClientDatabases_Referral]

as

--exec sp_ssrs_GetClientDatabases_Referral
select		null as ClientDb
union
select		SystemDatabase
from		MDVALUATE.dbo.SystemRecordsMedia
where		IsClient = 'Yes'
