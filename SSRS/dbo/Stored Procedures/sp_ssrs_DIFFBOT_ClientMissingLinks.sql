CREATE procedure [dbo].[sp_ssrs_DIFFBOT_ClientMissingLinks] (@Database nvarchar(200))as/*declare@Database nvarchar(200)set @Database = 'Rothman'exec sp_ssrs_DIFFBOT_ClientMissingLinks @Database*/declare@CustomerID nvarchar(50),@CustomerSource nvarchar(120),@sql nvarchar(max),@parms nvarchar(max),@CR char(1)set @CR = char(13)set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output/*set @sql = ' ' + @CRset @sql = @sql + ' ' + @CRexec(@sql)
*/

declare
@BatchID int,
@NPI nvarchar(10),
@SiteName nvarchar(20),
@npi_counter int,
@site_counter int

set @sql = 'select @TempBatchID = max(BatchID) ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks'set @parms = '@TempBatchID int output'exec sp_executesql @sql, @parms, @TempBatchID = @BatchID output

create table #sites(ID int identity, SiteName nvarchar(20))
insert	#sites(SiteName)
select	'HealthGrades'
union
select	'Vitals'
union
select	'RateMDs'
union
select	'UCompare'

create table #site_name_counts (
	NPI nvarchar(10),
	FirstName nvarchar(200),
	LastName nvarchar(200),
	SiteNameCount int
)
set @sql = 'insert #site_name_counts ' + @CR
set @sql = @sql + 'select pm.NPI, pm.FirstName, pm.LastName, count(r.SiteName) as SiteNameCount ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia pm ' + @CR
set @sql = @sql + 'left join RepMgmt.dbo.DIFFBOT_WorkingLinks r ' + @CR
set @sql = @sql + 'on r.NPI = pm.NPI ' + @CR
set @sql = @sql + 'and r.SiteName in (select SiteName from #sites) ' + @CR
set @sql = @sql + 'and r.BatchID =''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
set @sql = @sql + 'where pm.Status = ''Active'' ' + @CR
set @sql = @sql + 'group by pm.NPI, pm.FirstName, pm.LastName ' + @CR
set @sql = @sql + 'order by SiteNameCount, pm.LastName, pm.FirstName '
exec(@sql)

create table #NPI (ID int identity, NPI nvarchar(10))
insert		#NPI(NPI)
select		distinct NPI
from		#site_name_counts
where		SiteNameCount < 4

create table #missing_links (
	NPI nvarchar(10),
	SiteName nvarchar(20),
	SiteLink nvarchar(4000)
)

set @npi_counter = 1
while @npi_counter <= (select max(ID) from #NPI)
begin
	select @NPI = NPI from #NPI where ID = @npi_counter

	set @site_counter = 1
	while @site_counter <= (select max(ID) from #sites)
	begin
		select @SiteName = SiteName from #sites where ID = @site_counter

		insert		#missing_links(NPI, SiteName)
		select		@NPI, @SiteName

		set @sql = 'update m ' + @CR
		set @sql = @sql + 'set m.SiteLink = r.WorkingLink ' + @CR
		set @sql = @sql + 'from #missing_links m ' + @CR
		set @sql = @sql + 'left join RepMgmt.dbo.DIFFBOT_WorkingLinks r ' + @CR
		set @sql = @sql + 'on r.NPI = m.NPI ' + @CR
		set @sql = @sql + 'where r.BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' ' + @CR
		set @sql = @sql + 'and r.NPI = ''' + @NPI + ''' ' + @CR
		set @sql = @sql + 'and r.SiteName = ''' + @SiteName + ''' '
		exec(@sql)

		set @site_counter = @site_counter + 1
	end
	set @npi_counter = @npi_counter + 1
end

set @sql = 'select pm.NPI, pm.FirstName, pm.MiddleName, pm.LastName, m.SiteName, m.SiteLink, ''' + cast(@BatchID as nvarchar(10)) + ''' as BatchID ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia pm ' + @CR
set @sql = @sql + 'inner join #missing_links m ' + @CR
set @sql = @sql + 'on m.NPI = pm.NPI ' + @CR
set @sql = @sql + 'where m.SiteLink is null ' + @CR
set @sql = @sql + 'order by LastName, FirstName, MiddleName, SiteName '
exec(@sql)

drop table #site_name_counts
drop table #NPI
drop table #missing_links
drop table #sites