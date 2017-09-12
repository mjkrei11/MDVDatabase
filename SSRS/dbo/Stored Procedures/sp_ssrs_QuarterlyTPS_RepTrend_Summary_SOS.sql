






CREATE procedure [dbo].[sp_ssrs_QuarterlyTPS_RepTrend_Summary_SOS] (
	@Database nvarchar(200)

)

as
/*This reporst was created for SOS. They do not want comments on the report*/

/*
declare
@Database nvarchar(200)
set @Database = 'SOS'

exec sp_ssrs_QuarterlyTPS_RepTrend_Summary_SOS @Database
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

set @sql = 'select a.NPI, a.FullName, a.Specialty, b.RepTrendQtrSite as RatingSite_Summary, datepart(m, b.RepTrendQtrDate) as RepTrendQtrDate_Summary, ' + @CR
set @sql = @sql + 'b.RepTrendQtrRating as AvgRating_Summary, b.RepTrendQtrCount as Ratings_Summary, b.RepTrendQtrCommentCount as Comments_Summary, ' + @CR
set @sql = @sql + 'b.RepTrendQtrRiskCount as FiveStarsNeeded_Summary, b.RepTrendQtrNetworkAvg as AvgPhysicianRating_Summary ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia a ' + @CR
set @sql = @sql + 'left outer join ' + @Database + '.dbo.VIRepQuarter b on b.NPITrend = a.NPITrend ' + @CR
set @sql = @sql + 'where b.RepTrendQtrPeriod = ''Q1, 2016'' and b.RepTrendQtrSite = ''Summary'' ' + @CR -- and b.RepTrendQtrSite in (''HealthGrades'',''Vitals'',''RateMDs'') this is for TwinCities
set @sql = @sql + 'and b.RepTrendQtrDate <> ''2015-10-31 00:00:00.000'' ' + @CR
--set @sql = @sql + 'and a.NPI = ''1124083480'' ' + @CR
set @sql = @sql + 'group by a.NPI, a.FullName, a.Specialty, b.RepTrendQtrSite, b.RepTrendQtrDate, ' + @CR
set @sql = @sql + 'b.RepTrendQtrRating, b.RepTrendQtrCount, b.RepTrendQtrCommentCount, ' + @CR
set @sql = @sql + 'b.RepTrendQtrRiskCount, b.RepTrendQtrNetworkAvg ' + @CR
set @sql = @sql + 'order by b.RepTrendQtrSite ' + @CR

print(@sql)
exec(@sql)






