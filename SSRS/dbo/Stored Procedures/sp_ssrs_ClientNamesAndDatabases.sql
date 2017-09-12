






CREATE procedure [dbo].[sp_ssrs_ClientNamesAndDatabases] 

as

/*

exec sp_ssrs_ClientNamesAndDatabases

*/


select distinct SystemDatabase, 
	SystemName
from MDVALUATE.dbo.SystemRecordsMedia
where IsClient = 'Yes'
	and CustomerTerminatedDate is null
	and SystemDatabase is not null
order by SystemName



