







CREATE procedure [dbo].[sp_ssrs_DIFFBOT_PhysicianRatingUpdate_Comments] (
	@Database nvarchar(200), 
	@Month int,
	@NPI nvarchar(10))

as

/*
declare
@Database nvarchar(200), @Month int
set @Database = 'Rothman'
set @Month = 6
set @NPI = ''

exec sp_ssrs_DIFFBOT_PhysicianRatingUpdate_Comments @Database, @Month, @NPI
*/

declare
@baseline_check int,
@record_check int,
@YearQuarter nvarchar(20),
@StartBatchID int,
@EndBatchID int,
@Logo varbinary(max),
@CustomerID nvarchar(50),
@CustomerSource nvarchar(120),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

select top 1 @Logo = cast(BinData as varbinary(max)) from MDVALUATE.dbo.MetricRangeMediaSection where NPI = @CustomerID

set @sql = 'select @TempStartBatchID = min(BatchID), @TempEndBatchID = max(BatchID) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
set @sql = @sql + 'where datepart(month, SearchDate) = ''' + cast(@Month as nvarchar(10)) + ''' and BatchID > 0 ' + @CR
set @parms = '@TempStartBatchID int output, @TempEndBatchID int output'
exec sp_executesql @sql, @parms, @TempStartBatchID = @StartBatchID output, @TempEndBatchID = @EndBatchID output

create table #comments(
	NPI nvarchar(10),
	RatingsSite nvarchar(100),
	CommentDate datetime,
	CommentRating nvarchar(max),
	CommentText nvarchar(max)
)

set @sql = 'insert #comments ' + @CR
set @sql = @sql + 'select distinct c.NPI, c.SiteName, convert(varchar, c.CommentDate, 101) as CommentDate, c.IsNegative, isnull(c.CommentText, ''None'')' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_Comments c  ' + @CR
set @sql = @sql + 'where datepart(month, c.CommentDate) = ''' + cast(@Month as nvarchar(5)) + ''' and datepart(year, c.CommentDate) =  ''2017'' ' + @CR
set @sql = @sql + 'and len(ltrim(rtrim(c.CommentText))) > 3 and c.CommentText <> ''show details'' ' + @CR
set @sql = @sql + 'and c.CustomerID = ''' + @CustomerID + ''' ' + @CR
set @sql = @sql + 'and c.SiteName in (''HealthGrades'', ''Vitals'', ''RateMDs'', ''UCompare'') ' + @CR
set @sql = @sql + 'and c.NPI = ''' + @NPI + ''' ' + @CR
--print(@sql)
exec(@sql)

select * from #comments --where NPI = '1770816134'

drop table #comments

































