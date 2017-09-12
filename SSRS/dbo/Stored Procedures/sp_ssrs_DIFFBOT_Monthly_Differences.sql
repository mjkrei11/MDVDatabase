create procedure sp_ssrs_DIFFBOT_Monthly_Differences (	@Database nvarchar(200),
	@SiteName nvarchar(50),
	@Month int)as/*declare@Database nvarchar(200) = 'OrthoAtlanta',
@SiteName nvarchar(50) = 'HealthGrades',
@Month int = 3

exec sp_ssrs_DIFFBOT_Monthly_Differences @Database, @SiteName, @Month
*/

declare@CustomerID nvarchar(50),@CustomerSource nvarchar(120),@StartBatchID int,@EndBatchID int,@counter int,@sql nvarchar(max),@parms nvarchar(max),@CR char(1)set @CR = char(13)

/*
set @sql = ' ' + @CRset @sql = @sql + ' ' + @CRexec(@sql)
*/

set @sql = 'select @TempStartBatchID = min(BatchID), @TempEndBatchID = max(BatchID) ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CRset @sql = @sql + 'where datepart(month, SearchDate) = ''' + cast(@Month as nvarchar(10)) + ''' and BatchID > 0 ' + @CRset @parms = '@TempStartBatchID int output, @TempEndBatchID int output'exec sp_executesql @sql, @parms, @TempStartBatchID = @StartBatchID output, @TempEndBatchID = @EndBatchID outputcreate table #sites(ID int identity, SiteName nvarchar(50))create table #data(	NPI nvarchar(10),	FirstName nvarchar(200),	LastName nvarchar(200),	FormattedName nvarchar(400),	SiteName nvarchar(50),	StartingDate nvarchar(20),	StartingVolume int,	StartingRating decimal(2,1),	EndingDate nvarchar(20),	EndingVolume int,	EndingRating decimal(2,1))set @sql = 'insert #sites(SiteName) ' + @CRset @sql = @sql + 'select distinct SiteName ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CRif @SiteName is not nullbegin	set @sql = @sql + 'where SiteName = ''' + @SiteName + ''' ' + @CRendset @sql = @sql + 'order by SiteName ' + @CRexec(@sql)

set @counter = 1
while @counter <= (select max(ID) from #sites)
begin
	select @SiteName = SiteName from #sites where ID = @counter

	set @sql = 'insert #data ' + @CR	set @sql = @sql + 'select pm.NPI, pm.FirstName, pm.LastName, pm.LastName + '', '' + pm.FirstName as FormattedName, ''' + @SiteName + ''', ' + @CR	set @sql = @sql + '(select convert(varchar, max(d2.SearchDate), 101) from ' + @Database + '.dbo.DIFFBOT_ResultLinks d2 where d2.NPI = pm.NPI and d2.SiteName = ''' + @SiteName + ''' and d2.BatchID = ''' + cast(@StartBatchID as nvarchar(10)) + '''), ' + @CR	set @sql = @sql + '(select max(d2.ResultVolume) from ' + @Database + '.dbo.DIFFBOT_ResultLinks d2 where d2.NPI = pm.NPI and d2.SiteName = ''' + @SiteName + ''' and d2.BatchID = ''' + cast(@StartBatchID as nvarchar(10)) + '''), ' + @CR	set @sql = @sql + '(select max(d2.ResultRating) from ' + @Database + '.dbo.DIFFBOT_ResultLinks d2 where d2.NPI = pm.NPI and d2.SiteName = ''' + @SiteName + ''' and d2.BatchID = ''' + cast(@StartBatchID as nvarchar(10)) + '''), ' + @CR	set @sql = @sql + '(select convert(varchar, max(d2.SearchDate), 101) from ' + @Database + '.dbo.DIFFBOT_ResultLinks d2 where d2.NPI = pm.NPI and d2.SiteName = ''' + @SiteName + ''' and d2.BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + '''), ' + @CR	set @sql = @sql + '(select max(d2.ResultVolume) from ' + @Database + '.dbo.DIFFBOT_ResultLinks d2 where d2.NPI = pm.NPI and d2.SiteName = ''' + @SiteName + ''' and d2.BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + '''), ' + @CR	set @sql = @sql + '(select max(d2.ResultRating) from ' + @Database + '.dbo.DIFFBOT_ResultLinks d2 where d2.NPI = pm.NPI and d2.SiteName = ''' + @SiteName + ''' and d2.BatchID = ''' + cast(@EndBatchID as nvarchar(10)) + ''') ' + @CR	set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia pm ' + @CR	set @sql = @sql + 'where pm.Status = ''Active'' ' + @CR	exec(@sql)

	set @counter = @counter + 1
end

select * from #data order by LastName, FirstName, SiteName

drop table #sites
drop table #data