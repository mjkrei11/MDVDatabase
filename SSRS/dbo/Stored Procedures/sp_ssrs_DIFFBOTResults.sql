


CREATE procedure [dbo].[sp_ssrs_DIFFBOTResults](@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'Rothman'

exec sp_ssrs_DIFFBOTResults @Database
*/

declare 
@sql nvarchar(max), 
@parms nvarchar(max), 
@CR char(1) 

set @CR = char(13) 

create table #ID(
	CustomerID nvarchar(20),
	NPI nvarchar(20)
)

set @sql = 'insert #ID ' + @CR 
set @sql = @sql + 'select distinct CustomerID, NPI ' + @CR 
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID ' + @CR 
set @sql = @sql + 'where CustomerActive = 1 ' + @CR 
exec(@sql)

create table #DIFFBOT(
	SearchDate datetime,
	CustomerID nvarchar(20),
	NPI nvarchar(20),
	SiteName nvarchar(400),
	Rating decimal(10,1),
	Volume int,
	SiteURL nvarchar(max),
	CommentDate datetime,
	CommentRating nvarchar(4000),
	CommentText nvarchar(max),
	BatchID int
)

set @sql = 'insert #DIFFBOT ' + @CR 
set @sql = @sql + 'select distinct w.WorkingDate, r.CustomerID, r.NPI, r.SiteName, r.ResultRating, ' + @CR
set @sql = @sql + 'r.ResultVolume, r.ResultLink, c.CommentDate, c.CommentRating, c.CommentText, r.BatchID ' + @CR 
set @sql = @sql + 'from RepMgmt.dbo.DIFFBOT_WorkingLinks w ' + @CR 
set @sql = @sql + 'inner join #ID i ' + @CR 
set @sql = @sql + 'on i.CustomerID = w.CustomerID ' + @CR 
set @sql = @sql + 'and i.NPI = w.NPI ' + @CR 
set @sql = @sql + 'inner join RepMgmt.dbo.DIFFBOT_ResultLinks r ' + @CR 
set @sql = @sql + 'on w.NPI = r.NPI ' + @CR 
set @sql = @sql + 'and w.WorkingKey = r.WorkingKey ' + @CR
set @sql = @sql + 'left join RepMgmt.dbo.DIFFBOT_Comments c ' + @CR 
set @sql = @sql + 'on c.NPI = w.NPI ' + @CR 
set @sql = @sql + 'and c.SiteName = w.SiteName '
exec(@sql)

create table #report(
	CustomerName nvarchar(400),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	SearchDate datetime,
	SiteName nvarchar(400),
	Rating decimal(10,1),
	Volume int,
	SiteURL nvarchar(max),
	CommentDate datetime,
	CommentRating nvarchar(4000),
	CommentText nvarchar(max),
	BatchID int
)

set @sql = 'insert #report ' + @CR 
set @sql = @sql + 'select id.CustomerSource, p.NPI, p.FirstName, p.MiddleName, p.LastName, ' + @CR 
set @sql = @sql + 'd.SearchDate, d.SiteName, d.Rating, d.Volume, d.SiteURL, d.CommentDate, d.CommentRating, d.CommentText, d.BatchID ' + @CR 
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID id ' + @CR 
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianMedia p ' + @CR 
set @sql = @sql + 'on p.NPI = id.NPI ' + @CR 
set @sql = @sql + 'and p.Status = ''Active'' ' + @CR 
set @sql = @sql + 'inner join #DIFFBOT d ' + @CR 
set @sql = @sql + 'on d.NPI = p.NPI ' + @CR 
set @sql = @sql + 'and d.CustomerID = id.CustomerID ' + @CR  
exec(@sql)

--select * from #report where npi = '1629025994'

select		*
from		#report
order by	BatchID desc, CustomerName, LastName, FirstName, MiddleName, SiteName, CommentDate desc

drop table #ID
drop table #DIFFBOT
drop table #report


