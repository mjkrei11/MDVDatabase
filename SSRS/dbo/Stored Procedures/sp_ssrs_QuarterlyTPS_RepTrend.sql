










CREATE procedure [dbo].[sp_ssrs_QuarterlyTPS_RepTrend] (
	@Database nvarchar(200)

)

as
/*This reporst was created for TCO. It excludes UCompare ratings.*/
/*
declare
@Database nvarchar(200)


set @Database = 'TwinCities'


exec sp_ssrs_QuarterlyTPS_RepTrend @Database
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

set @sql = 'select a.NPI, a.FullName, a.FirstName, a.LastName, a.MiddleName, a.Specialty, b.RepTrendQtrSite as RatingSite, datepart(m, b.RepTrendQtrDate) as MonthNumber, convert(char(3), b.RepTrendQtrDate, 0) as RepTrendQtrDate, ' + @CR ----convert(varchar, b.RepTrendQtrDate) as RepTrendQtrDate,
set @sql = @sql + 'b.RepTrendQtrRating as AvgRating, b.RepTrendQtrCount as Ratings, b.RepTrendQtrCommentCount as Comments, ' + @CR
set @sql = @sql + 'b.RepTrendQtrRiskCount as FiveStarsNeeded, b.RepTrendQtrNetworkAvg as AvgPhysicianRating ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia a ' + @CR
set @sql = @sql + 'left outer join ' + @Database + '.dbo.VIRepQuarter b on b.NPITrend = a.NPITrend ' + @CR
set @sql = @sql + 'where b.RepTrendQtrPeriod = ''Q1, 2016'' and b.RepTrendQtrSite <> ''Summary'' and b.RepTrendQtrSite in (''HealthGrades'',''Vitals'',''RateMDs'') ' + @CR -- and b.RepTrendQtrSite in (''HealthGrades'',''Vitals'',''RateMDs'') this is for TwinCities
set @sql = @sql + 'and a.NPI = ''1538359757'' ' + @CR--1598761322, 1275649840
set @sql = @sql + 'group by a.NPI, a.FullName, a.FirstName, a.LastName, a.MiddleName, a.Specialty, b.RepTrendQtrSite, b.RepTrendQtrDate, ' + @CR
set @sql = @sql + 'b.RepTrendQtrRating, b.RepTrendQtrCount, b.RepTrendQtrCommentCount, ' + @CR
set @sql = @sql + 'b.RepTrendQtrRiskCount, b.RepTrendQtrNetworkAvg ' + @CR
set @sql = @sql + 'order by b.RepTrendQtrSite, MonthNumber ' + @CR
--print(@sql)
exec(@sql)

--select datename(month, getdate())








