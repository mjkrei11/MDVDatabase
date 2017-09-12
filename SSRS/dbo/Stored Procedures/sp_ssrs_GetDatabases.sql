



CREATE procedure [dbo].[sp_ssrs_GetDatabases]

as

--exec sp_ssrs_GetDatabases
select		null as name
union
select		name
from		sys.databases
where		name not in ('master','tempdb','model','msdb','ReportServer','ReportServerTempDB',
							'MDVALUATE','NPI','BizConfig_DEV','ScriptBox','SSRS','z_ProspectingClean')
and			name not like '%_backup'


