


CREATE procedure [dbo].[sp_ssrs_MatchedLinksQA_Competition](@CustomerID nvarchar(10), @MatchRankOption nvarchar(20))

as

/* Test parameter */
/*
declare
@CustomerID nvarchar(10),
@MatchRankOption nvarchar(20)

set @CustomerID = '1649324195'
set @MatchRankOption = 'all'

exec sp_ssrs_MatchedLinksQA_Competition @CustomerID, @MatchRankOption
*/

declare
@Database nvarchar(200),
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #competitors(ID int identity, CompetitorID nvarchar(10), HoldingDb nvarchar(200))
insert		#competitors(CompetitorID, HoldingDb)
select		distinct metric.CompetitorID, media.HoldingDb
from		MDVALUATE.dbo.CompetitionMappingMedia media
inner join	MDVALUATE.dbo.CompetitionMapping metric
on			metric.CollectionID = media.CollectionID
where		media.CustomerID = @CustomerID

select top 1 @Database = isnull(HoldingDb, 'MDVALUATE') from #competitors

create table #NPI(ID int identity, NPI nvarchar(10))
insert		#NPI(NPI)
select		distinct mpm.NPI
from		MDVALUATE.dbo.MasterPhysicianMedia mpm
inner join	MDVALUATE.dbo.MasterPhysicianSystems mps
on			mps.NPI = mpm.NPI
inner join	#competitors c
on			c.CompetitorID = mps.SystemSystemID
union
select		distinct mps.SystemSystemID
from		MDVALUATE.dbo.MasterPhysicianMedia mpm
inner join	MDVALUATE.dbo.MasterPhysicianSystems mps
on			mps.NPI = mpm.NPI
inner join	#competitors c
on			c.CompetitorID = mps.SystemSystemID

set @sql = 'select distinct v.PrimaryCustomerSource, v.NPI, v.FirstName, v.MiddleName, v.LastName, v.SearchEngine , v.SearchPattern, ' + @CR
set @sql = @sql + 'dbo.fn_GetDomain(v.LinkTarget) as Domain, v.LinkTarget, v.LinkType, v.MatchRule, v.MatchRank, v.RatingText, v.ResultNumber ' + @CR
if @Database = 'MDVALUATE'
begin
	set @sql = @sql + 'from ' + @Database + '.dbo.vw_MasterPhysicianSearch v ' + @CR
end
else
begin
	set @sql = @sql + 'from ' + @Database + '.dbo.vw_PhysicianSearch v ' + @CR
end
set @sql = @sql + 'inner join #NPI n ' + @CR
set @sql = @sql + 'on n.NPI = v.NPI ' + @CR
set @sql = @sql + 'where v.Status = ''Active'' ' + @CR
if @MatchRankOption = 'matched'
begin
	set @sql = @sql + 'and v.MatchRank > 0 ' + @CR
end
if @MatchRankOption = 'un-matched'
begin
	set @sql = @sql + 'and v.MatchRank = 0 ' + @CR
end
if @MatchRankOption = 'all'
begin
	set @sql = @sql + 'and v.MatchRank is not null ' + @CR
end
set @sql = @sql + 'and v.LinkType is not null ' + @CR
set @sql = @sql + 'order by v.PrimaryCustomerSource, v.LastName, v.FirstName, v.MiddleName, v.NPI'
exec(@sql)

drop table #competitors
drop table #NPI
