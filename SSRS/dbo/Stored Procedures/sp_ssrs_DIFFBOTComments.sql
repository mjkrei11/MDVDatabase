


CREATE procedure [dbo].[sp_ssrs_DIFFBOTComments](
	@BatchID int
)

as

/*
declare
@BatchID int
set @BatchID = 32

exec sp_ssrs_DIFFBOTComments @BatchID
*/

declare
@Database nvarchar(200),
@LastBatchID int,
@CurrentDate datetime,
@LastDate datetime,
@counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #customer_ids(ID int identity, CustomerID nvarchar(10))
insert	#customer_ids(CustomerID)
select	distinct CustomerID from RepMgmt.dbo.DIFFBOT_WorkingLinks
where	BatchID = @BatchID

create table #dbs(ID int identity, CustomerID nvarchar(10), DbName nvarchar(200))
insert		#dbs(CustomerID, DbName)
select		distinct SystemID, SystemDatabase
from		MDVALUATE.dbo.SystemRecordsMedia srm
inner join	#customer_ids c
on			c.CustomerID = srm.SystemID

create table #comments(
	DbName nvarchar(200),
	CustomerID nvarchar(10),
	Customer nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(100),
	MiddleName nvarchar(100),
	LastName nvarchar(100),
	SiteName nvarchar(50),
	CommentDate datetime,
	CommentRating nvarchar(max),
	CommentText nvarchar(max),
	CommentKey uniqueidentifier
)

set @counter = 1
while @counter <= (select max(ID) from #dbs)
begin
	select @Database = DbName from #dbs where ID = @counter

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

	set @sql = 'insert #comments ' + @CR
	set @sql = @sql + 'select ''' + @Database + ''', id.CustomerID, id.CustomerSource, p.NPI, p.FirstName, p.MiddleName, p.LastName, c.SiteName, ' + @CR
	set @sql = @sql + 'convert(varchar, c.CommentDate, 101) as CommentDate, case when c.IsNegative = 1 then ''Negative'' else ''Not Negative'' end as CommentRating, c.CommentText, c.CommentKey ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_Comments c ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia p ' + @CR
	set @sql = @sql + 'on p.NPI = c.NPI ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysCustomerID id ' + @CR
	set @sql = @sql + 'on id.NPI = p.NPI ' + @CR
	set @sql = @sql + 'where p.Status = ''Active'' ' + @CR
	set @sql = @sql + 'and c.BatchID = ''' + cast(@BatchID as nvarchar(5)) + ''' ' + @CR
	set @sql = @sql + 'and cast(convert(varchar, c.CommentDate, 101) as datetime) >= cast(''' + convert(varchar, @LastDate, 101) + ''' as datetime) ' + @CR
	exec(@sql)

	set @counter = @counter + 1
end

select * from #comments

drop table #comments

