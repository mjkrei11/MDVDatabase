CREATE procedure [dbo].[sp_ssrs_UpdateRepWithDIFFBOTPreview] (@Database nvarchar(200))as/*declare @Database nvarchar(200) = 'Princeton'exec sp_ssrs_UpdateRepWithDIFFBOTPreview @Database*/declare@CustomerID nvarchar(10),@CustomerSource nvarchar(200),@BatchID int,@NPI nvarchar(10),
@SiteName nvarchar(50),
@counter int,@sql nvarchar(max),@parms nvarchar(max),@CR char(1)set @CR = char(13)set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CRset @sql = @sql + 'from [' + @Database + '].dbo.PhysCustomerID'set @parms = '@TempCustomerSource varchar(200) output, @TempCustomerID nvarchar(10) output'exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID outputset @sql = 'select top 1 @TempBatchID = max(BatchID) ' + @CRset @sql = @sql + 'from [' + @Database + '].dbo.DIFFBOT_ResultLinks'set @parms = '@TempBatchID int output'exec sp_executesql @sql, @parms, @TempBatchID = @BatchID output/*set @sql = ' ' + @CRset @sql = @sql + ' ' + @CRexec(@sql)*/
create table #sites
(
	ID int identity,
	SiteName nvarchar(50)
)
insert #sites (SiteName)
select distinct SiteName from RepMgmt.dbo.DIFFBOT_ResultLinks where CustomerID = @CustomerIDcreate table #NPI
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
endcreate table #rep(	ID int identity,	RepType nvarchar(20),	NPI nvarchar(10),	FirstName nvarchar(200),	LastName nvarchar(200),	RatingSite nvarchar(50),	RatingScore decimal(3,2),	RatingVolume int)create table #diffbot
(
	ID int identity
,	RepType nvarchar(20)
,	NPI nvarchar(10)
,	RatingSite nvarchar(50)
,	RatingLink nvarchar(4000)
,	RatingScore decimal(3,2)
,	RatingVolume int
)
set @sql = 'insert #rep(RepType, NPI, FirstName, LastName, RatingSite, RatingScore, RatingVolume) ' + @CRset @sql = @sql + 'select ''Reputation'', media.NPI, media.FirstName, media.LastName, metric.RatingsSite, ' + @CRset @sql = @sql + 'metric.Rating, metric.NumberOfRatings ' + @CRset @sql = @sql + 'from [' + @Database + '].dbo.PhysMetReputationMedia media ' + @CRset @sql = @sql + 'inner join [' + @Database + '].dbo.PhysMetReputation metric ' + @CRset @sql = @sql + 'on metric.ComboKey = media.ComboKey ' + @CRset @sql = @sql + 'inner join [' + @Database + '].dbo.PhysicianMedia p ' + @CRset @sql = @sql + 'on p.NPI = media.NPI ' + @CRset @sql = @sql + 'where media.SystemID = media.CollectionID ' + @CRset @sql = @sql + 'and p.Status <> ''Inactive'' ' + @CRexec(@sql)update #rep set RatingSite = replace(RatingSite, ' ', '')update #rep set RatingSite = 'RateMDs' where RatingSite = 'RateMDSecure'--set @sql = 'insert #diffbot(RepType, NPI, FirstName, LastName, RatingSite, RatingLink, RatingScore, RatingVolume) ' + @CR--set @sql = @sql + 'select ''DIFFBOT'', p.NPI, p.FirstName, p.LastName, d.SiteName, max(d.ResultLink),' + @CR--set @sql = @sql + 'max(d.ResultRating), max(d.ResultVolume)' + @CR--set @sql = @sql + 'from [' + @Database + '].dbo.DIFFBOT_ResultLinks d ' + @CR--set @sql = @sql + 'inner join [' + @Database + '].dbo.PhysicianMedia p ' + @CR--set @sql = @sql + 'on p.NPI = d.NPI ' + @CR--set @sql = @sql + 'where p.Status <> ''Inactive'' ' + @CR--set @sql = @sql + 'and d.BatchID = ''' + cast(@BatchID as nvarchar(5)) + ''' ' + @CR--set @sql = @sql + 'group by p.NPI, p.FirstName, p.LastName, d.SiteName ' + @CR--exec(@sql)set @counter = 1
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

delete from #diffbot where RatingLink is nullinsert		#diffbot(RepType, NPI, RatingSite, RatingScore, RatingVolume)select		'DIFFBOT',			NPI,			'SumAllSites',			cast(sum(RatingScore * RatingVolume) / sum(RatingVolume) as decimal(3,2)) RatingScore,			sum(RatingVolume) RatingVolumefrom		#diffbotwhere		RatingScore is not nullgroup by	NPI--select * from #diffbot where NPI = '1386658011'select		r.NPI, r.FirstName, r.LastName, r.RatingSite, r.RepType,			r.RatingScore, r.RatingVolume, d.RepType as DIFFBOTRepType, d.RatingSite as DIFFBOTRatingSite, d.RatingLink,			isnull(d.RatingScore, 0) as DIFFBOTRatingScore, isnull(d.RatingVolume, 0) as DIFFBOTRatingVolumefrom		#rep rleft join	#diffbot don			d.NPI = r.NPIand			d.RatingSite = r.RatingSiteorder by	r.LastName, r.FirstName, r.RatingVolume desc, r.RatingScore descdrop table #sites
drop table #NPIdrop table #repdrop table #diffbot