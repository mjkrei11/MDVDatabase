




CREATE procedure [dbo].[sp_ssrs_RatingLinkVerification](
	@Database nvarchar(200)
)

as

/***** Test parameter *****/
/*
declare @Database nvarchar(200) = 'WNSAZ'
exec sp_ssrs_RatingLinkVerification @Database
*/

declare
@NPI nvarchar(10),
@FirstName nvarchar(120),
@MiddleName nvarchar(60),
@LastName nvarchar(120)

declare
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1),
@counter int

set @CR = char(13)

/*
set @sql = ' ' + @CR
set @sql = @sql + ' ' + @CR
exec(@sql)
*/

create table #physicians(
	ID int identity,
	Customer nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(120),
	MiddleName nvarchar(60),
	LastName nvarchar(120)
)

set @sql = 'insert #physicians(Customer, NPI, FirstName, MiddleName, LastName) ' + @CR
set @sql = @sql + 'select distinct isnull(id.CustomerSource, psm.FirstName), psm.NPI, psm.FirstName, psm.MiddleName, psm.LastName ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.PhysCustomerID id ' + @CR
set @sql = @sql + 'on id.NPI = psm.NPI ' + @CR
set @sql = @sql + 'where Status = ''Active'' ' + @CR
exec(@sql)

create table #ratings_domains(
	ID int identity,
	Domain nvarchar(200)
)

set @sql = 'insert #ratings_domains(Domain) ' + @CR
set @sql = @sql + 'select distinct dbo.fn_GetDomain(sr.LinkTarget) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.SearchResults sr ' + @CR
set @sql = @sql + 'inner join MDVALUATE.dbo.SiteMappings metric ' + @CR
set @sql = @sql + 'on dbo.fn_GetDomain(metric.SiteURL) = dbo.fn_GetDomain(sr.LinkTarget) ' + @CR
set @sql = @sql + 'inner join MDVALUATE.dbo.SiteDataMedia media ' + @CR
set @sql = @sql + 'on media.MappingID = metric.MappingID ' + @CR
--set @sql = @sql + 'where sr.RatingText is not null ' + @CR
set @sql = @sql + 'where media.Provider = ''Global'' ' + @CR
set @sql = @sql + 'and media.MappingName = ''Ratings'' ' + @CR
set @sql = @sql + 'and metric.CalculationFlag = 1 ' + @CR
exec(@sql)

set @sql = 'insert #ratings_domains(Domain) ' + @CR
set @sql = @sql + 'select ''www.google.com'' ' + @CR
exec(@sql)

create table #links(
	Domain nvarchar(400),
	GroupPractice nvarchar(400),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	LinkTarget nvarchar(4000),
	LinkLabel nvarchar(4000),
	RatingText nvarchar(400),
	ResultNumber int
)

create table #final_links(
	Domain nvarchar(400),
	GroupPractice nvarchar(400),
	NPI nvarchar(10),
	FirstName nvarchar(200),
	MiddleName nvarchar(200),
	LastName nvarchar(200),
	LinkTarget nvarchar(4000),
	LinkLabel nvarchar(4000),
	RatingText nvarchar(400),
	ResultNumber int
)

create table #result_numbers
(
	ID int identity,
	NPI nvarchar(10),
	LinkTarget nvarchar(4000),
	ResultNumber int
)

set @counter = 1
while @counter <= (select max(ID) from #physicians)
begin
	select @NPI = NPI, @FirstName = FirstName, @MiddleName = MiddleName, @LastName = LastName from #physicians where ID = @counter

	set @sql = 'insert #links(Domain, GroupPractice, NPI, FirstName, MiddleName, LastName, LinkTarget) ' + @CR
	set @sql = @sql + 'select distinct r.Domain, id.CustomerSource, psm.NPI, psm.FirstName, psm.MiddleName, psm.LastName, ' + @CR
	set @sql = @sql + 'sr.LinkTarget ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysCustomerID id ' + @CR
	set @sql = @sql + 'on id.NPI = psm.NPI ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
	set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
	set @sql = @sql + 'and sr.LinkType = ''Rating'' ' + @CR
	set @sql = @sql + 'inner join #ratings_domains r ' + @CR
	set @sql = @sql + 'on r.Domain = dbo.fn_GetDomain(sr.LinkTarget) ' + @CR
	set @sql = @sql + 'where sr.MatchRank is null ' + @CR
	set @sql = @sql + 'and psm.NPI = ''' + @NPI + ''''
	exec(@sql)

	set @sql = 'update l ' + @CR
	set @sql = @sql + 'set l.LinkLabel = sr.LinkLabel, l.RatingText = sr.RatingText ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
	set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
	set @sql = @sql + 'inner join #links l ' + @CR
	set @sql = @sql + 'on l.NPI = psm.NPI ' + @CR
	set @sql = @sql + 'and l.LinkTarget = sr.LinkTarget '
	exec(@sql)

	set @sql = 'update l ' + @CR
	set @sql = @sql + 'set l.RatingText = sr.RatingText ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
	set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
	set @sql = @sql + 'inner join #links l ' + @CR
	set @sql = @sql + 'on l.NPI = psm.NPI ' + @CR
	set @sql = @sql + 'and l.LinkTarget = sr.LinkTarget ' + @CR
	set @sql = @sql + 'where sr.RatingText is not null '
	exec(@sql)

	set @sql = 'insert #result_numbers(NPI, LinkTarget, ResultNumber) ' + @CR
	set @sql = @sql + 'select distinct l.NPI, l.LinkTarget, max(sr.ResultNumber) ' + @CR
	set @sql = @sql + 'from #links l ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
	set @sql = @sql + 'on psm.NPI = l.NPI ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
	set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
	set @sql = @sql + 'and sr.LinkTarget = l.LinkTarget ' + @CR
	set @sql = @sql + 'where psm.NPI = ''' + @NPI + ''''
	set @sql = @sql + 'group by l.NPI, l.LinkTarget ' + @CR
	exec(@sql)

	set @sql = 'update l ' + @CR
	set @sql = @sql + 'set l.ResultNumber = r.ResultNumber ' + @CR
	set @sql = @sql + 'from #links l ' + @CR
	set @sql = @sql + 'inner join #result_numbers r ' + @CR
	set @sql = @sql + 'on r.NPI = l.NPI ' + @CR
	set @sql = @sql + 'and r.LinkTarget = l.LinkTarget ' + @CR
	exec(@sql)

	insert		#final_links
	select		Domain, GroupPractice, @NPI, @FirstName, @MiddleName, @LastName, LinkTarget, LinkLabel, RatingText, ResultNumber
	from		#links
	where		((LinkTarget like '%' + @FirstName + '%'
	and			LinkTarget like '%' + @LastName + '%')
	or			(LinkLabel like '%' + @FirstName + '%'
	and			LinkLabel like '%' + @LastName + '%'))

	truncate table #links

	set @counter = @counter + 1
end

select		*
from		#final_links
order by	GroupPractice, LastName, FirstName, MiddleName, Domain, LinkTarget

drop table #ratings_domains
drop table #links
drop table #result_numbers
drop table #physicians
drop table #final_links



