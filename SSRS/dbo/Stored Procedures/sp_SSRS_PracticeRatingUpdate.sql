





CREATE procedure [dbo].[sp_SSRS_PracticeRatingUpdate] (
	@Database nvarchar(200)--,
	--@UpdatedDate nvarchar(50)
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
set @Database = 'panorama'

exec sp_SSRS_PracticeRatingUpdate @Database
*/

declare
@CustomerID nvarchar(10),
@CustomerSource nvarchar(400),
@CustomerLogo varbinary(max),
@NPI nvarchar(10),
@SiteCount int,
@Score float,
@VolumeDenom int,
@counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

declare @date datetime

set @sql = 'select @Tempdate = max(UpdatedDate) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianRatingUpdate'
set @parms = '@Tempdate datetime output'
exec sp_executesql @sql, @parms, @Tempdate = @date output

create table #physicians(ID int identity, NPI nvarchar(10))

set @sql = 'insert #physicians(NPI) ' + @CR
set @sql = @sql + 'select distinct NPI from ' + @Database + '.dbo.PhysicianRatingUpdate '
exec(@sql)

create table #baseline_data(
	NPI nvarchar(10),
	RatingsSite nvarchar(400),
	Score float
)

set @sql = 'insert #baseline_data ' + @CR
set @sql = @sql + 'select distinct NPI, RatingsSite, BaselineRating * BaselineVolume ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianRatingUpdate ' + @CR
set @sql = @sql + 'WHERE convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
exec(@sql)

create table #updated_data(
	NPI nvarchar(10),
	RatingsSite nvarchar(400),
	Score float
)

set @sql = 'insert #updated_data ' + @CR
set @sql = @sql + 'select distinct NPI, RatingsSite, UpdatedRating * UpdatedVolume ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianRatingUpdate ' + @CR
Set @sql = @sql + 'WHERE convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
exec(@sql)

create table #baseline_volume(NPI nvarchar(10), Volume int)
create table #updated_volume(NPI nvarchar(10), Volume int)

set @sql = 'insert #baseline_volume ' + @CR
set @sql = @sql + 'select distinct NPI, sum(BaselineVolume) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianRatingUpdate ' + @CR
Set @sql = @sql + 'WHERE convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + 'group by NPI ' + @CR
exec(@sql)

set @sql = 'insert #updated_volume ' + @CR
set @sql = @sql + 'select distinct NPI, sum(UpdatedVolume) ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianRatingUpdate ' + @CR
Set @sql = @sql + 'WHERE convert(varchar, UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + 'group by NPI ' + @CR
exec(@sql)

create table #baseline_final(NPI nvarchar(10), Score float)
create table #updated_final(NPI nvarchar(10), Score float)

set @counter = 1
while @counter <= (select max(ID) from #physicians)
begin
	select @NPI = NPI from #physicians where ID = @counter
	select @Score = round(sum(Score), 2) from #baseline_data where NPI = @NPI
	select @VolumeDenom = Volume from #baseline_volume where NPI = @NPI

	insert #baseline_final select @NPI, case when isnull(@VolumeDenom, 0) = 0 then 0 else @Score / @VolumeDenom end

	select @NPI = NPI from #physicians where ID = @counter
	select @Score = round(sum(Score), 2) from #updated_data where NPI = @NPI
	select @VolumeDenom = Volume from #updated_volume where NPI = @NPI

	insert #updated_final select @NPI, case when isnull(@VolumeDenom, 0) = 0 then 0 else @Score / @VolumeDenom end

	set @counter = @counter + 1
end

set @sql = 'SELECT distinct p.NPI, LastName, FirstName, b.Score AS AggregateBaselineRating, ' + @CR
set @sql = @sql + 'sum(BaselineVolume) AS AggregateBaselineVolume, u.Score AS AggregateUpdatedRating, ' + @CR
set @sql = @sql + 'sum(cast(UpdatedVolume as int)) AS AggregateUpdatedVolume, avg(u.Score) - avg(b.Score) AS AggregatedRatingDifference, ' + @CR
set @sql = @sql + 'sum(cast(UpdatedVolume as int)) - sum(cast(BaselineVolume as int)) AS AggregateVolumeDifference, p.UpdatedDate ' + @CR
set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysicianRatingUpdate p ' + @CR 
set @sql = @sql + 'inner join #baseline_final b ' + @CR
set @sql = @sql +  'on b.NPI = p.NPI ' + @CR
set @sql = @sql +  'inner join #updated_final u ' + @CR
set @sql = @sql +  'on u.NPI = p.NPI ' + @CR
Set @sql = @sql + 'WHERE convert(varchar, p.UpdatedDate, 101) = ''' + convert(varchar, @date, 101) + ''' ' + @CR
set @sql = @sql + 'Group by p.NPI, LastName, FirstName, updateddate, b.Score, u.Score ' + @CR
set @sql = @sql + 'Order By LastName ' + @CR
exec(@sql)

--Print @sql

--set @sql = 'select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID ' + @CR
--set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID'
--set @parms = '@TempCustomerSource varchar(400) output, @TempCustomerID nvarchar(50) output'
--exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

--select top 1 @CustomerLogo = BinData from MDVALUATE.dbo.MetricRangeMediaSection where NPI = @CustomerID


drop table #baseline_data
drop table #updated_data




