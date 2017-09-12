

CREATE procedure [dbo].[sp_ssrs_DIFFBOTDiffReport](
	@BatchID int
)

as

/*
declare
@BatchID int
set @BatchID = 4

exec sp_ssrs_DIFFBOTDiffReport @BatchID
*/

declare
@Database nvarchar(200),
@CurrentDate datetime,
@LastDate datetime,
@LastBatchID int,
@counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #last_rep(
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	RatingsSite nvarchar(200),
	Rating float,
	Volume int,
	SearchDate datetime,
	ResultLink nvarchar(4000)
)

create table #current_rep(
	CustomerID nvarchar(10),
	Customer nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	RatingsSite nvarchar(200),
	Rating float,
	Volume int,
	SearchDate datetime,
	ResultLink nvarchar(4000)
)

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

set @counter = 1
while @counter <= (select max(ID) from #dbs)
begin
	select @Database = DbName from #dbs where ID = @counter
	
	set @sql = 'select top 1 @TempLastBatchID = max(BatchID) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
	set @sql = @sql + 'where BatchID < ''' + cast(@BatchID as nvarchar(5)) + ''' ' + @CR
	set @parms = '@TempLastBatchID int output'
	exec sp_executesql @sql, @parms, @TempLastBatchID = @LastBatchID output

	set @sql = 'select top 1 @TempCurrentDate = max(SearchDate) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
	set @sql = @sql + 'where BatchID = ''' + cast(@BatchID as nvarchar(5)) + ''' ' + @CR
	set @parms = '@TempCurrentDate datetime output'
	exec sp_executesql @sql, @parms, @TempCurrentDate = @CurrentDate output

	set @sql = 'select top 1 @TempLastDate = max(SearchDate) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
	set @sql = @sql + 'where BatchID = ''' + cast(isnull(@LastBatchID, @BatchID) as nvarchar(5)) + ''' ' + @CR
	set @parms = '@TempLastDate datetime output'
	exec sp_executesql @sql, @parms, @TempLastDate = @LastDate output

	set @sql = 'insert #last_rep ' + @CR
	set @sql = @sql + 'select distinct media.NPI, media.FirstName, media.LastName, r.SiteName, r.ResultRating, r.ResultVolume, r.SearchDate, r.ResultLink ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia media ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.DIFFBOT_ResultLinks r ' + @CR
	set @sql = @sql + 'on r.NPI = media.NPI ' + @CR
	set @sql = @sql + 'where r.BatchID = ''' + cast(@LastBatchID as nvarchar(5)) + ''' '
	exec(@sql)

	set @sql = 'insert #current_rep ' + @CR
	set @sql = @sql + 'select distinct id.CustomerID, id.CustomerSource, media.NPI, media.FirstName, ' + @CR
	set @sql = @sql + 'media.LastName, r.SiteName, r.ResultRating, r.ResultVolume, r.SearchDate, r.ResultLink ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia media ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysCustomerID id ' + @CR
	set @sql = @sql + 'on id.NPI = media.NPI ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.DIFFBOT_ResultLinks r ' + @CR
	set @sql = @sql + 'on r.NPI = media.NPI ' + @CR
	set @sql = @sql + 'where r.BatchID = ''' + cast(@BatchID as nvarchar(5)) + ''' ' + @CR
	set @sql = @sql + 'and media.Status = ''Active'' '
	exec(@sql)

	set @counter = @counter + 1
end

select		distinct d.CustomerID, d.Customer, r.NPI, r.FirstName, r.LastName, r.RatingsSite, r.Rating as PreviousRating,
			r.Volume as PreviousVolume, d.Rating as CurrentRating, d.Volume as CurrentVolume,
			r.SearchDate as PreviousSearchDate, d.SearchDate as CurrentSearchDate, d.ResultLink
from		#last_rep r
inner join	#current_rep d
on			d.NPI = r.NPI
and			d.RatingsSite = r.RatingsSite
and			d.ResultLink = r.ResultLink
where		(d.Rating <> r.Rating
or			d.Volume <> r.Volume)

drop table #last_rep
drop table #current_rep

