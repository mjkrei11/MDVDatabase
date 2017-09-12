





CREATE procedure [dbo].[sp_ssrs_RothmanAbsoluteClicks] (
	@Database nvarchar(200))--, 
	--@Month datetime)

AS

/* Test parameter */
/*
declare @Database nvarchar(200), @Month datetime
set @Database = 'Rothman'
set @Month = 8

--exec sp_ssrs_RothmanAbsoluteClicks 'Rothman', 'August'
*/
declare
--@StartDate datetime,
--@EndDate datetime,
@sql nvarchar(max),
--@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

--set @sql = 'select @TempBeginDate = min(EventDateTime), @TempEndDate = max(EventDateTime) ' + @CR
--set @sql = @sql + 'from DoctorRateReporting.dbo.Analytics_Activity ' + @CR
--set @sql = @sql + 'where datepart(month, EventDateTime) = '' + cast(@Month as nvarchar(10))''  ' + @CR
--set @parms = '@TempBeginDate int output, @TempEndDate int output'
--exec sp_executesql @sql, @parms, @TempBeginDate = @StartDate output, @TempEndDate = @EndDate output

set @sql = 'select top 10 a.NPI, p.FirstName, p.LastName, count(distinct a.InstanceKey) as AbsolutelyCount, avg(cast(ltrim(rtrim(i.AnswerValue)) as decimal(2,1))) as AnswerScore ' + @CR
set @sql = @sql + 'from DoctorRateReporting.dbo.Analytics_Activity a ' + @CR
set @sql = @sql + 'inner join DoctorRateReporting.dbo.Survey_InstanceAnswers i ' + @CR
set @sql = @sql + 'on i.InstanceKey = a.InstanceKey ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia p ' + @CR
set @sql = @sql + 'on p.NPI = a.NPI ' + @CR
set @sql = @sql + 'where a.NavigationButtonKey = ''6568C81A-EF28-415B-9193-8641524947E7'' ' + @CR
set @sql = @sql + 'and a.UserName not in (select UserLogin from MDVRouting2.dbo.MDValuateUserSecurity where Customer = ''MDVALUATE'') ' + @CR
set @sql = @sql + 'and i.QuestionKey = ''F2E39823-A5DC-4F77-9E1E-3128219F5E10'' and p.Status = ''Active'' ' + @CR
set @sql = @sql + 'and a.EventDateTime between ''2016-08-01'' and ''2016-09-01'' ' + @CR
set @sql = @sql + 'group by a.NPI, p.FirstName, p.LastName ' + @CR
set @sql = @sql + 'order by AbsolutelyCount desc ' + @CR
print @sql
exec(@sql)

--select top 10 a.NPI, count(distinct a.InstanceKey) as AbsolutelyCount, avg(cast(ltrim(rtrim(i.AnswerValue)) as decimal(2,1))) as AnswerScore
--from DoctorRateReporting.dbo.Analytics_Activity a
--inner join DoctorRateReporting.dbo.Survey_InstanceAnswers i
--on i.InstanceKey = a.InstanceKey
--where a.NavigationButtonKey = '6568C81A-EF28-415B-9193-8641524947E7'
--and a.UserName not in (select UserLogin from MDVRouting2.dbo.MDValuateUserSecurity where Customer = 'MDVALUATE')
--and i.QuestionKey = 'F2E39823-A5DC-4F77-9E1E-3128219F5E10'
--group by a.NPI
--order by AbsolutelyCount desc






