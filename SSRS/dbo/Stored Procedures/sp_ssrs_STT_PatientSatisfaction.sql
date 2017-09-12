





CREATE procedure [dbo].[sp_ssrs_STT_PatientSatisfaction] (@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200) = 'stt'

exec sp_ssrs_STT_PatientSatisfaction @Database
*/

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select PatientSatArchiveBenchmark.PrimaryGroupBenchmark, ' + @CR
set @sql = @sql + 'PhysCustomerID.CustomerID, ' + @CR
set @sql = @sql + 'PatientSatArchiveBenchmark.TimeFrameBenchmark,  ' + @CR
set @sql = @sql + 'PatientSatArchiveBenchmark.VICategoryBenchmark,  ' + @CR
set @sql = @sql + 'PhysicianMedia.NPI,  ' + @CR
set @sql = @sql + 'PhysicianMedia.FirstName, ' + @CR
set @sql = @sql + 'PhysicianMedia.LastName, ' + @CR
set @sql = @sql + 'PatientSatArchiveBenchmark.CategoryBenchmark,  ' + @CR
set @sql = @sql + 'PatientSatArchiveBenchmark.ObservedVolumeBenchmark,  ' + @CR
set @sql = @sql + '(PatientSatArchiveBenchmark.ObservedBenchmark / 100) as ObservedBenchmark,  ' + @CR
set @sql = @sql + '(PatientSatArchiveBenchmark.SpecialtyBenchmark / 100) as SpecialtyBenchmark,  ' + @CR
set @sql = @sql + '(PatientSatArchiveBenchmark.SystemBenchmark / 100) as SystemBenchmark,  ' + @CR
set @sql = @sql + 'PatientSatArchiveBenchmark.VarianceFromSpecialtyBenchmark,  ' + @CR
set @sql = @sql + 'PatientSatArchiveBenchmark.VarianceFromSystemBenchmark,  ' + @CR
set @sql = @sql + 'PatientSatArchiveBenchmark.SpecialtyPercentileBenchmark,  ' + @CR
set @sql = @sql + 'PatientSatArchiveBenchmark.SystemPercentileBenchmark, ' + @CR
set @sql = @sql + 'replace(VIMeasureRanges.SourceColumn, ''Source: '', '''') as SourceColumn,' + @CR
set @sql = @sql + 'PhysicianDoc.BinData as PhysicianPhoto ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PatientSatArchiveBenchmark  ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.PhysicianMedia ' + @CR
set @sql = @sql + 'on PhysicianMedia.NPI = substring(PatientSatArchiveBenchmark.XKey, 1, 10) ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.PhysCustomerID ' + @CR
set @sql = @sql + 'on physCustomerID.NPI = substring(PatientSatArchiveBenchmark.XKey, 1, 10) ' + @CR
set @sql = @sql + 'left join MDVALUATE.dbo.VIMeasureRanges ' + @CR
set @sql = @sql + 'on VIMeasureRanges.NPI = PhysCustomerID.CustomerID ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.PhysicianDoc ' + @CR
set @sql = @sql + 'on PhysicianDoc.NPI = substring(PatientSatArchiveBenchmark.XKey, 1, 10) ' + @CR
set @sql = @sql + 'where PhysicianMedia.Status = ''Active'' ' + @CR
set @sql = @sql + 'and VIMeasureRanges.VIMeasure = ''Patient Satisfaction'' ' + @CR
set @sql = @sql + '	and PatientSatArchiveBenchmark.TimeFrameBenchmark not like ''%q%'' ' + @CR
set @sql = @sql + '	and PatientSatArchiveBenchmark.TimeFrameBenchmark not in (''Composite'', ''Overall'') ' + @CR
--set @sql = @sql + '	and PatientSatArchiveBenchmark.TimeFrameBenchmark = ''' + @TimeFrame + ''' ' + @CR
set @sql = @sql + 'order by PhysicianMedia.LastName, ' + @CR
set @sql = @sql + 'case PatientSatArchiveBenchmark.CategoryBenchmark ' + @CR	
set @sql = @sql + '	when ''Standard Care Provider'' then 1 ' + @CR
set @sql = @sql + '	when ''Friendliness/courtesy of CP'' then 2 ' + @CR
set @sql = @sql + '	when ''CP explanation of prob/condition'' then 3 ' + @CR
set @sql = @sql + '	when ''CP concern for questions/worries'' then 4 ' + @CR
set @sql = @sql + '	when ''CP efforts to include in decisions'' then 5 ' + @CR
set @sql = @sql + '	when ''CP information about medications'' then 6 ' + @CR
set @sql = @sql + '	when ''CP instructions for follow-up care'' then 7 ' + @CR
set @sql = @sql + '	when ''CP spoke using clear language'' then 8 ' + @CR
set @sql = @sql + '	when ''Time CP spent with patient'' then 9 ' + @CR
set @sql = @sql + '	when ''Patients confidence in CP'' then 10 ' + @CR
set @sql = @sql + '	else 11 ' + @CR
set @sql = @sql + ' end' + @CR
exec(@sql)
--print @sql









