﻿CREATE procedure [dbo].[sp_ssrs_UpdateRepWithDIFFBOTPreview] (@Database nvarchar(200))
@SiteName nvarchar(50),
@counter int,
create table #sites
(
	ID int identity,
	SiteName nvarchar(50)
)
insert #sites (SiteName)
select distinct SiteName from RepMgmt.dbo.DIFFBOT_ResultLinks where CustomerID = @CustomerID
(
	ID int identity
,	NPI nvarchar(10)
,	RatingSite nvarchar(50)
)

set @counter = 1
while @counter <= (select max(ID) from #sites)
begin
	select @SiteName = SiteName from #sites where ID = @counter

	set @sql = 'insert #NPI(NPI, RatingSite) ' + @CR
	set @sql = @sql + 'select distinct p.NPI, ''' + @SiteName + ''' ' + @CR
	set @sql = @sql + 'from [' + @Database + '].dbo.PhysicianMedia p ' + @CR
	set @sql = @sql + 'where p.Status <> ''Inactive'' ' + @CR
	exec(@sql)

	set @counter = @counter + 1
end
(
	ID int identity
,	RepType nvarchar(20)
,	NPI nvarchar(10)
,	RatingSite nvarchar(50)
,	RatingLink nvarchar(4000)
,	RatingScore decimal(3,2)
,	RatingVolume int
)

while @counter <= (select max(ID) from #NPI)
begin
	select @NPI = NPI, @SiteName = RatingSite from #NPI where ID = @counter

	set @sql = 'insert #diffbot(RepType, NPI, RatingSite, RatingLink, RatingScore, RatingVolume) ' + @CR
	set @sql = @sql + 'select top 1 ''DIFFBOT'', ''' + @NPI + ''', ''' + @SiteName + ''', d.ResultLink,' + @CR
	set @sql = @sql + 'isnull(d.ResultRating, 0.00), isnull(d.ResultVolume, 0)' + @CR
	set @sql = @sql + 'from #NPI p ' + @CR
	set @sql = @sql + 'left join [' + @Database + '].dbo.DIFFBOT_ResultLinks d ' + @CR
	set @sql = @sql + 'on p.NPI = d.NPI ' + @CR
	set @sql = @sql + 'and p.RatingSite = d.SiteName ' + @CR
	set @sql = @sql + 'and d.BatchID = ''' + cast(@BatchID as nvarchar(5)) + ''' ' + @CR
	set @sql = @sql + 'where p.NPI = ''' + @NPI + ''' ' + @CR
	set @sql = @sql + 'and p.RatingSite = ''' + @SiteName + ''' ' + @CR
	set @sql = @sql + 'order by d.ResultVolume desc, d.ResultRating desc ' + @CR
	exec(@sql)

	set @counter = @counter + 1
end

delete from #diffbot where RatingLink is null
drop table #NPI