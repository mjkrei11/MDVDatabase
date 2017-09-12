﻿

CREATE procedure [dbo].[sp_ssrs_LinkVerification] (@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'Competition'

--exec sp_ssrs_LinkVerification 'Panorama'
*/

declare
@NPI nvarchar(10),
@FirstName nvarchar(120),
@MiddleName nvarchar(60),
@LastName nvarchar(120),
@NickName nvarchar(120)

declare
@counter int,
@sql nvarchar(max),
@CR char(1)
set @CR = char(13)

create table #physicians(
	ID int identity,
	Customer nvarchar(200),
	NPI nvarchar(10),
	FirstName nvarchar(120),
	MiddleName nvarchar(60),
	LastName nvarchar(120),
	NickName nvarchar(120)
)

set @sql = 'insert #physicians(Customer, NPI, FirstName, MiddleName, LastName, NickName) ' + @CR
set @sql = @sql + 'select distinct isnull(id.CustomerSource, search.FirstName), search.NPI, search.FirstName, search.MiddleName, search.LastName, psm.NickName ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia search ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.PhysicianMedia psm ' + @CR
set @sql = @sql + 'on search.NPI = psm.NPI ' + @CR
set @sql = @sql + 'left join ' + @Database + '.dbo.PhysCustomerID id ' + @CR
set @sql = @sql + 'on id.NPI = psm.NPI ' + @CR
set @sql = @sql + 'where search.Status = ''Active'' ' + @CR
exec(@sql)

create table #links(
	NPI nvarchar(10),
	LinkTarget nvarchar(4000),
	LinkLabel nvarchar(4000),
	LinkType nvarchar(20),
	ResultNumber int
)

create table #final_links(
	LinkGroup nvarchar(200),
	NPI nvarchar(10),
	LinkTarget nvarchar(4000),
	LinkLabel nvarchar(4000),
	LinkType nvarchar(20),
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
	select @NPI = NPI, @FirstName = FirstName, @MiddleName = MiddleName, @LastName = LastName, @NickName = NickName from #physicians where ID = @counter

	set @sql = 'insert #links(NPI, LinkTarget, LinkType) ' + @CR
	set @sql = @sql + 'select distinct psm.NPI, sr.LinkTarget, sr.LinkType ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
	set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
	set @sql = @sql + 'where psm.NPI = ''' + @NPI + ''' ' + @CR
	set @sql = @sql + 'and sr.LinkType is not null ' + @CR
	set @sql = @sql + 'and sr.MatchRank is null ' + @CR
	exec(@sql)

	set @sql = 'update l ' + @CR
	set @sql = @sql + 'set l.LinkLabel = sr.LinkLabel ' + @CR
	set @sql = @sql + 'from #links l ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.PhysicianSearchMedia psm ' + @CR
	set @sql = @sql + 'on psm.NPI = l.NPI ' + @CR
	set @sql = @sql + 'inner join ' + @Database + '.dbo.SearchResults sr ' + @CR
	set @sql = @sql + 'on sr.SearchID = psm.SearchID ' + @CR
	set @sql = @sql + 'and sr.LinkTarget = l.LinkTarget ' + @CR
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

	if @NPI = @LastName
	begin
		insert		#final_links
		select		'Practice Social', @NPI, LinkTarget, LinkLabel, LinkType, ResultNumber
		from		#links
		where		LinkType like 'Social -%'

		insert		#final_links
		select		'Practice Other', @NPI, LInkTarget, LinkLabel, LinkType, ResultNumber
		from		#links
		where		(LinkType in ('Rating', 'Personal')
		or			LinkType like '%- Profile'
		or			LinkType like '%- Directory')

		insert		#final_links
		select		'Practice Outliers', @NPI, LinkTarget, LinkLabel, LinkType, ResultNumber
		from		#links
		where		LinkTarget not in (select distinct LinkTarget from #final_links)
	end
	else
	begin
		insert		#final_links
		select		'Physician CORE', @NPI, LinkTarget, LinkLabel, LinkType, ResultNumber
		from		#links
		where		((LinkTarget like '%' + @FirstName + '%'
		and			LinkTarget like '%' + @LastName + '%')
		or			(LinkTarget like '%' + @NickName + '%'
		and			LinkTarget like '%' + @LastName + '%')
		or			(LinkLabel like '%' + @FirstName + '%'
		and			LinkLabel like '%' + @LastName + '%')
		or			(LinkLabel like '%' + @NickName + '%'
		and			LinkLabel like '%' + @LastName + '%'))
		and			(LinkType  in ('Rating', 'Personal')
		or			LinkType like '%- Profile')

		insert		#final_links
		select		'Physician CORE', @NPI, LinkTarget, LinkLabel, LinkType, ResultNumber
		from		#links
		where		LinkType like '%- Directory'

		insert		#final_links
		select		'Physician Social', @NPI, LinkTarget, LinkLabel, LinkType, ResultNumber
		from		#links
		where		((LinkTarget like '%' + @FirstName + '%'
		and			LinkTarget like '%' + @LastName + '%')
		or			(LinkTarget like '%' + @NickName + '%'
		and			LinkTarget like '%' + @LastName + '%')
		or			(LinkLabel like '%' + @FirstName + '%'
		and			LinkLabel like '%' + @LastName + '%')
		or			(LinkLabel like '%' + @NickName + '%'
		and			LinkLabel like '%' + @LastName + '%'))
		and			LinkType like 'Social -%'

		insert		#final_links
		select		'Physican Outliers', @NPI, LinkTarget, LinkLabel, LinkType, ResultNumber
		from		#links
		where		LinkTarget not in (select distinct LinkTarget from #final_links)
		and			(LinkType in ('Rating', 'Personal')
		or			LinkType like '%- Profile'
		or			LinkType like '%- Directory')
	end

	truncate table #links

	set @counter = @counter + 1
end

select		f.LinkGroup, p.Customer, p.NPI, p.FirstName, p.MiddleName, p.LastName, f.LinkTarget, f.LinkLabel, f.LinkType, f.ResultNumber
from		#final_links f
inner join	#physicians p
on			p.NPI = f.NPI
order by	f.LinkGroup, p.Customer, p.LastName, p.FirstName, p.MiddleName, p.NPI, f.LinkType, f.LinkTarget, f.ResultNumber

drop table #links
drop table #final_links
drop table #physicians
drop table #result_numbers