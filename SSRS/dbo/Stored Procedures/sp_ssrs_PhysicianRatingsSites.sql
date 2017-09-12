
CREATE procedure [dbo].[sp_ssrs_PhysicianRatingsSites](@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'morush'

exec sp_ssrs_PhysicianRatingsSites @Database
*/

declare
@CustomerID nvarchar(10),
@CustomerSource nvarchar(400),
@CustomerLogo varbinary(max),
@MDVLogo varbinary(max),
@NPI nvarchar(10),
@counter int,
@Link nvarchar(4000),
@link_counter int,
@SearchPattern nvarchar(20),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
set @parms = '@TempCustomerSource varchar(400) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

select top 1 @CustomerLogo = BinData from MDVALUATE.dbo.MetricRangeMediaSection where NPI = @CustomerID
select top 1 @SearchPattern = min(SearchPattern) from MDVALUATE.dbo.MasterPhysicianSearchMedia where PrimaryCustomerID = @CustomerID

create table #MDV_Master_Search(
	NPI nvarchar(10),
	SpiderDate datetime,
	RatingsSite nvarchar(400),
	LinkTarget nvarchar(4000)
)

insert		#MDV_Master_Search
select		distinct media.NPI, metric.SpiderDate, case when metric.LinkTarget like '%www.healthgrades.com%' then 'HealthGrades'
			when metric.LinkTarget like '%www.vitals.com%' then 'Vitals' when metric.LinkTarget like '%www.ucomparehealthcare.com%' then 'UCompare'
			when metric.LinkTarget like '%www.ratemds.com%' then 'RateMDs' end, metric.LinkTarget
from		MDVALUATE.dbo.MasterPhysicianSearchMedia media
inner join	MDVALUATE.dbo.MasterSearchResults metric
on			metric.SearchID = media.SearchID
where		media.PrimaryCustomerID = @CustomerID
and			media.SearchPattern = @SearchPattern

create table #report(
	ID int identity,
	GroupLevel int,
	CustomerName nvarchar(400),
	CustomerLogo varbinary(max),
	MDVLogo varbinary(max),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	FullName nvarchar(500),
	RatingsSite nvarchar(200),
	SourceLink nvarchar(4000),
	BaselineRating float,
	BaselineVolume int,
	Percentile float,
	Color nvarchar(20),
	BaselineDate datetime
)

set @sql = 'insert #report(CustomerName, NPI, FirstName, LastName, FullName, RatingsSite, SourceLink, BaselineRating, BaselineVolume, Percentile, Color, BaselineDate) ' + @CR
set @sql = @sql + 'select distinct ''' + @CustomerSource + ''' as CustomerName, media.NPI, media.FirstName, media.LastName, ' + @CR
set @sql = @sql + 'media.FirstName + '' '' + isnull(media.MiddleName, media.LastName) + case when media.MiddleName is not null then '' '' + media.LastName else '''' end as FullName, ' + @CR
set @sql = @sql + 'case when metric.RatingsSite = ''Sum All Sites'' then ''Aggregate Score'' else metric.RatingsSite end as RatingsSite, ' + @CR
set @sql = @sql + 'metric.SourceLink, metric.Rating, metric.NumberOfRatings, metric.Percentile, metric.Color, (select top 1 m.SpiderDate from #MDV_Master_Search m join ' + @Database + '.dbo.PhysMetReputationArchiveMedia media2 on m.NPI = media2.NPI join ' + @Database + '.dbo.PhysMetReputationArchive metric2 on metric.XComboKey = media.XComboKey and m.RatingsSite = metric2.RatingsSite ) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysMetReputationArchiveMedia media ' + @CR
set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetReputationArchive metric ' + @CR
set @sql = @sql + 'on metric.XComboKey = media.XComboKey ' + @CR
set @sql = @sql + 'where media.CollectionID = media.SystemID ' + @CR
set @sql = @sql + 'and	metric.SourceLink is not null ' + @CR
set @sql = @sql + 'and	metric.RatingsSite in (''HealthGrades'',''Vitals'',''Rate MD Secure'',''Ucompare'') ' + @CR
set @sql = @sql + 'and media.YearQuarter = ''' + @SearchPattern + ''' ' + @CR
set @sql = @sql + 'order by media.LastName, media.FirstName, media.NPI, RatingsSite ' + @CR
exec(@sql)

create table #NPI(ID int identity, NPI nvarchar(10))
insert #NPI select distinct NPI from #report

create table #links(ID int identity, NPI nvarchar(10), Link nvarchar(4000))

set @counter = 1
while @counter <= (select max(ID) from #NPI)
begin
	select @NPI = NPI from #NPI where ID = @counter

	truncate table #links

	insert	#links(NPI, Link)
	select	distinct NPI, SourceLink
	from	#report
	where	NPI = @NPI

	set @link_counter = 1
	while @link_counter <= (select max(ID) from #links)
	begin
		select @Link = Link from #links where ID = @link_counter

		update	#report
		set		GroupLevel = @link_counter
		where	NPI = @NPI
		and		SourceLink = @Link

		set @link_counter = @link_counter + 1
	end

	set @counter = @counter + 1
end

update		#report
set			CustomerLogo = @CustomerLogo

select		*
from		#report
order by	LastName, FirstName, NPI, GroupLevel

drop table #report
drop table #links
drop table #MDV_Master_Search