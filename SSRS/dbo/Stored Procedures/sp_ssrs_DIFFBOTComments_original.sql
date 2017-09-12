
create procedure [dbo].[sp_ssrs_DIFFBOTComments_original](
	@Database nvarchar(200),
	@BatchID int
)

as

/*
declare
@Database nvarchar(200),
@BatchID int
set @Database = 'Rothman'
set @BatchID = 2

exec sp_ssrs_DIFFBOTComments @Database, @BatchID
*/

declare
@LastBatchID int,
@CurrentDate datetime,
@LastDate datetime,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'select top 1 @TempLastBatchID = max(BatchID) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_Comments ' + @CR
set @sql = @sql + 'where BatchID < ''' + cast(@BatchID as nvarchar(5)) + ''' ' + @CR
set @parms = '@TempLastBatchID int output'
exec sp_executesql @sql, @parms, @TempLastBatchID = @LastBatchID output

set @sql = 'select top 1 @TempCurrentDate = max(SearchDate) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_Comments ' + @CR
set @sql = @sql + 'where BatchID = ''' + cast(@BatchID as nvarchar(5)) + ''' ' + @CR
set @parms = '@TempCurrentDate datetime output'
exec sp_executesql @sql, @parms, @TempCurrentDate = @CurrentDate output

set @sql = 'select top 1 @TempLastDate = max(SearchDate) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_Comments ' + @CR
set @sql = @sql + 'where BatchID = ''' + cast(isnull(@LastBatchID, @BatchID) as nvarchar(5)) + ''' ' + @CR
set @parms = '@TempLastDate datetime output'
exec sp_executesql @sql, @parms, @TempLastDate = @LastDate output

set @sql = 'select p.FirstName, p.MiddleName, p.LastName, c.* ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_Comments c ' + @CRset @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia p ' + @CRset @sql = @sql + 'on p.NPI = c.NPI ' + @CRset @sql = @sql + 'where p.Status = ''Active'' ' + @CRset @sql = @sql + 'and c.BatchID = ''' + cast(@BatchID as nvarchar(5)) + ''' ' + @CRset @sql = @sql + 'and cast(convert(varchar, c.CommentDate, 101) as datetime) > cast(''' + convert(varchar, @LastDate, 101) + ''' as datetime) ' + @CRexec(@sql)