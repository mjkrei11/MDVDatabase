

CREATE procedure [dbo].[sp_ssrs_TCO_QuarterlyTPS_RepTrend] (
	@Database nvarchar(200), @Quarter nvarchar(20)

)

as

/*This reporst was created for TCO. It excludes UCompare ratings.*/
/*
declare
@Database nvarchar(200) = 'TwinCities',
@Quarter nvarchar(20) = 'Q4, 2016'

exec sp_ssrs_TCO_QuarterlyTPS_RepTrend @Database, @Quarter
*/

declare
@SystemID nvarchar(10),
@CustomerID nvarchar(50),
@CustomerSource nvarchar(120),
@sql nvarchar(max),
@parms nvarchar(max),
@counter int

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID '
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

/*
set @sql = ' '
set @sql = @sql + ' '
exec(@sql)
*/

declare
@MonthNumber int,
@Year int

set @sql = 'select top 1 @TempMonthNumber = max(datepart(m, RepTrendQtrDate)), @TempYear = max(datepart(y, RepTrendQtrDate)) '
set @sql = @sql + 'from ' + @Database + '.dbo.VIRepQuarter '
set @sql = @sql + 'where RepTrendQtrPeriod = ''' + @Quarter + ''' and RepTrendQtrSite <> ''Summary'' and RepTrendQtrSite in (''HealthGrades'',''Vitals'',''RateMDs'') '
set @parms = '@TempMonthNumber int output, @TempYear int output'
exec sp_executesql @sql, @parms, @TempMonthNumber = @MonthNumber output, @TempYear = @Year output

create table #phys_sites (NPITrend nvarchar(50), SiteName nvarchar(20), SiteValue float, Volume int, Risk int) 
set @sql = 'insert #phys_sites '
set @sql = @sql + 'select distinct a.NPITrend, a.RepTrendQtrSite, (cast(a.RepTrendQtrRating as float) * cast(a.RepTrendQtrCount as int)) as HealthGradesValue,
				cast(a.RepTrendQtrCount as int) HealthGradeVolume, cast(a.RepTrendQtrRiskCount as int) '
set @sql = @sql + 'from ' + @Database + '.dbo.VIRepQuarter a '
set @sql = @sql + 'where a.RepTrendQtrSite = ''HealthGrades'' and a.RepTrendQtrPeriod = ''' + @Quarter + ''' '
set @sql = @sql + 'and datepart(m, a.RepTrendQtrDate) = ''' + cast(@MonthNumber as nvarchar(5)) + ''' '
set @sql = @sql + 'and datepart(y, a.RepTrendQtrDate) = ''' + cast(@Year as nvarchar(4)) + ''' '
set @sql = @sql + 'union '
set @sql = @sql + 'select distinct a.NPITrend, a.RepTrendQtrSite, (cast(a.RepTrendQtrRating as float) * cast(a.RepTrendQtrCount as int)) as VitalsValue,
				cast(a.RepTrendQtrCount as int) VitalsVolume, cast(a.RepTrendQtrRiskCount as int) '
set @sql = @sql + 'from ' + @Database + '.dbo.VIRepQuarter a '
set @sql = @sql + 'where a.RepTrendQtrSite = ''Vitals'' and a.RepTrendQtrPeriod = ''' + @Quarter + ''' '
set @sql = @sql + 'and datepart(m, a.RepTrendQtrDate) = ''' + cast(@MonthNumber as nvarchar(5)) + ''' '
set @sql = @sql + 'and datepart(y, a.RepTrendQtrDate) = ''' + cast(@Year as nvarchar(4)) + ''' '
set @sql = @sql + 'union '
set @sql = @sql + 'select distinct a.NPITrend, a.RepTrendQtrSite, (cast(a.RepTrendQtrRating as float) * cast(a.RepTrendQtrCount as int)) as RateMDsValue,
				cast(a.RepTrendQtrCount as int) RateMDsVolume, cast(a.RepTrendQtrRiskCount as int) '
set @sql = @sql + 'from ' + @Database + '.dbo.VIRepQuarter a '
set @sql = @sql + 'where a.RepTrendQtrSite = ''RateMDs'' and a.RepTrendQtrPeriod = ''' + @Quarter + ''' '
set @sql = @sql + 'and datepart(m, a.RepTrendQtrDate) = ''' + cast(@MonthNumber as nvarchar(5)) + ''' '
set @sql = @sql + 'and datepart(y, a.RepTrendQtrDate) = ''' + cast(@Year as nvarchar(4)) + ''' '
print @sql
exec(@sql)

--select * from #phys_sites where NPITrend like '1235140534%'

create table #phys_avg_rating (NPITrend nvarchar(50), AverageWeightedRating decimal(3,2)) 
set @sql = 'insert #phys_avg_rating '
set @sql = @sql + 'select NPITrend, sum(SiteValue)/sum(Volume) as AverageWeightedRating '
set @sql = @sql + 'from #phys_sites '
set @sql = @sql + 'group by NPITrend '
exec(@sql)

--select * from #phys_avg_rating where NPITrend like '1235140534%'

create table #TCO_Trend(NPI nvarchar(10), FullName nvarchar(50), FirstName nvarchar(50), LastName nvarchar(50), MiddleName nvarchar(50), RatingSite nvarchar(20), MonthNumber int, RepTrendQtrDate nvarchar(5),
		AvgRating float, RepTrendQtrCount int, RepTrendQtrCommentCount int, RepTrendQtrNetworkAvg float, AverageWeightedRating decimal(3,2), 
		FiveStarsNeeded int, NumberOfRatings int, NewFiveStarsNeeded int)
set @sql = 'insert #TCO_Trend '
set @sql = @sql + 'select distinct a.NPI, a.FullName, a.FirstName, a.LastName, a.MiddleName, b.RepTrendQtrSite as RatingSite, datepart(m, b.RepTrendQtrDate) as MonthNumber, convert(char(3), b.RepTrendQtrDate, 0) as RepTrendQtrDate, ' ----convert(varchar, b.RepTrendQtrDate) as RepTrendQtrDate,
set @sql = @sql + 'b.RepTrendQtrRating as AvgRating, b.RepTrendQtrCount as Ratings, b.RepTrendQtrCommentCount as Comments, '
set @sql = @sql + 'b.RepTrendQtrNetworkAvg as AvgPhysicianRating, c.AverageWeightedRating, '
set @sql = @sql + '(select sum(cast(d.Risk as int)) where d.NPITrend = b.NPITrend) as FiveStarsNeeded, '
set @sql = @sql + '(select sum(cast(d.Volume as int)) where d.NPITrend = b.NPITrend) as NumberOfRatings, '
set @sql = @sql + '0 as NewFiveStarsNeeded '
set @sql = @sql + 'from ' + @Database + '.dbo.PhysVRepTrendMedia a '
set @sql = @sql + 'left outer join ' + @Database + '.dbo.VIRepQuarter b on b.NPITrend = a.NPITrend '
set @sql = @sql + 'left outer join #phys_avg_rating c on c.NPITrend = a.NPITrend '
set @sql = @sql + 'left outer join #phys_sites d on d.NPITrend = a.NPITrend '
set @sql = @sql + 'where b.RepTrendQtrPeriod = ''' + @Quarter + ''' and b.RepTrendQtrSite <> ''Summary'' and b.RepTrendQtrSite in (''HealthGrades'',''Vitals'',''RateMDs'') ' -- and b.RepTrendQtrSite in (''HealthGrades'',''Vitals'',''RateMDs'') this is for TwinCities
set @sql = @sql + 'and datepart(m, b.RepTrendQtrDate) = ''' + cast(@MonthNumber as nvarchar(5)) + ''' '
set @sql = @sql + 'and a.NPI not like ''S%'' and a.NPI not like ''G%'' '
set @sql = @sql + 'and a.LastName not like ''System'' '
set @sql = @sql + 'group by a.NPI, d.NPITrend, a.FullName, a.FirstName, a.LastName, a.MiddleName, b.RepTrendQtrSite, b.RepTrendQtrDate, '
set @sql = @sql + 'b.RepTrendQtrRating, b.RepTrendQtrCount, b.RepTrendQtrCommentCount, '
set @sql = @sql + 'b.RepTrendQtrRiskCount, b.RepTrendQtrNetworkAvg, b.NPITrend, b.RepTrendQtrSite, c.AverageWeightedRating '
set @sql = @sql + 'order by a.LastName '
--print(@sql)
exec(@sql)

--select * from #TCO_Trend

/***** 
This insert section is for physicians that do not have a certain rating site. In order for the rating site to showup blank on the bar graph
was to create blank data for that site. As the physicians receive a rating for one of the sites listed below, that insert will need to be removed.
*****/

insert #TCO_Trend select '1003058496', 'Eggert, Charles C MD', 'Charles', 'Eggert', 'C', 'HealthGrades', '', '', '0', '0', '0', '0', '0', '0', '0', '0'
insert #TCO_Trend select '1003058496', 'Eggert, Charles C MD', 'Charles', 'Eggert', 'C', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0'
insert #TCO_Trend select '1023014784', 'Vargas, Troy A DPM', 'Troy', 'Vargas', 'A', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1043445612', 'Bjerke, Brian P MD', 'Brian', 'Bjerke', 'P', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1043445612', 'Bjerke, Brian P MD', 'Brian', 'Bjerke', 'P', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1093924276', 'Holthusen, Scott M MD', 'Scott', 'Holthusen', 'M', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1144243973', 'Johnson, Neil R MD', 'Neil', 'Johnson', 'R', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1144462367', 'Dahl, Jason W MD', 'Jason', 'Dahl', 'W', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1154332401', 'Urban, Mark A MD', 'Mark', 'Urban', 'A', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1164535308', 'Barnett, Robert M MD', 'Robert', 'Barnett', 'M', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1174766505', 'Peterson, Erik J MD', 'Erik', 'Peterson', 'J', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1174766505', 'Peterson, Erik J MD', 'Erik', 'Peterson', 'J', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1184620858', 'Saterbak, Andrea M MD', 'Andrea', 'Saterbak', 'M', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1184870255', 'Kirksson, Eric E MD', 'Eric', 'Kirksson', 'E', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1194747543', 'Norgard, Randall J MD', 'Randall', 'Norgard', 'J', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1326060427', 'Olmsted, Stephen L MD', 'Stephen', 'Olmsted', 'L', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1326242371', 'Deal, Eric M MD', 'Eric', 'Deal', 'M', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1376730069', 'Dieterle, Jason P DO', 'Jason', 'Dieterle', 'P', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1437177458', 'Moen, Stephen A MD', 'Stephen', 'Moen', 'A', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1467465807', 'Kearns, John R MD', 'John', 'Kearns', 'R', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1487622510', 'Hartleben, Paul D MD', 'Paul', 'Hartleben', 'D', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1518070762', 'Friedland, Mark E MD', 'Mark', 'Friedland', 'E', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1528032315', 'Smith, Michael D MD', 'Michael', 'Smith', 'D', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1528064227', 'Berg, Melanie L DPM', 'Melanie', 'Berg', 'L', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1588839534', 'Clair, Benjamin L DPM', 'Benjamin', 'Clair', 'L', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1598761322', 'Palmer, David H MD', 'David', 'Palmer', 'H', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1609872381', 'Knowlan, Robert V MD', 'Robert', 'Knowlan', 'V', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1609887520', 'Conner, Thomas N MD', 'Thomas', 'Conner', 'N', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1619988490', 'Kraft, Patrick  G MD', 'Patrick ', 'Kraft', 'G', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1679773386', 'Wood, Jennifer H MD', 'Jennifer', 'Wood', 'H', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1699771386', 'Panek, Timothy J MD', 'Timothy', 'Panek', 'J', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1700897162', 'O''Neill, Brian T MD', 'Brian', 'O''Neill', 'T', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1720125180', 'O''Keefe, Patrick F MD', 'Patrick', 'O''Keefe', 'F', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1730390238', 'Seybold, Jeffrey D MD', 'Jeffrey', 'Seybold', 'D', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1730390238', 'Seybold, Jeffrey D MD', 'Jeffrey', 'Seybold', 'D', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1740458835', 'Holmes, Nicholas N MD', 'Nicholas', 'Holmes', 'N', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1770690687', 'Anderson, David R MD', 'David', 'Anderson', 'R', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1780695007', 'Smith, J Patrick P MD', 'J Patrick', 'Smith', 'P', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1790733442', 'Langer, Paul  R DPM', 'Paul ', 'Langer', 'R', 'Vitals', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1801807177', 'Fischer, Mark D MD', 'Mark', 'Fischer', 'D', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1811968365', 'Wulf, Corey A MD', 'Corey', 'Wulf', 'A', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1831205616', 'Vorlicky, Loren N MD', 'Loren', 'Vorlicky', 'N', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1912190075', 'Marek, Daniel J MD', 'Daniel', 'Marek', 'J', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1932123908', 'Fey, David C MD', 'David', 'Fey', 'C', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1932157682', 'Nemanich, Michael J MD', 'Michael', 'Nemanich', 'J', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 
insert #TCO_Trend select '1962413799', 'Cammack, Paul  M MD', 'Paul ', 'Cammack', 'M', 'RateMDs', '', '', '0', '0', '0', '0', '0', '0', '0', '0' 

update #TCO_Trend
set MonthNumber = @MonthNumber
--RepTrendQtrPeriod = @Quarter
where MonthNumber = ''

create table #AWR(NPI nvarchar(50), AverageWeightedRating  decimal(3,2), FiveStarsNeeded int, NumberOfRatings int)
insert #AWR
select NPI, AverageWeightedRating, FiveStarsNeeded, NumberOfRatings
from #TCO_Trend
where AverageWeightedRating <> 0

--select * from #AWR

update a
set a.AverageWeightedRating = b.AverageWeightedRating,
a.FiveStarsNeeded = b.FiveStarsNeeded,
a.NumberOfRatings = b.NumberOfRatings
from #TCO_Trend a 
inner join #AWR b on b.NPI = a.NPI
where a.AverageWeightedRating = 0

update #TCO_Trend
set NewFiveStarsNeeded = MDVALUATE.dbo.fn_GetReputationRisk(NumberOfRatings, AverageWeightedRating)

select * from #TCO_Trend order by LastName

drop table #TCO_Trend
drop table #phys_sites
drop table #phys_avg_rating
drop table #AWR









