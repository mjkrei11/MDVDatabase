
CREATE procedure [dbo].[sp_ssrs_DIFFBOTUpdatedClientRatings] (@Database nvarchar(200))

as

/*
declare
@Database nvarchar(200)
set @Database = 'MedStarOrtho'

exec sp_ssrs_DIFFBOTUpdatedClientRatings @Database
*/

declare
@CustomerID nvarchar(50),
@CustomerSource nvarchar(120),
@BatchID int,
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
set @parms = '@TempCustomerSource varchar(120) output, @TempCustomerID nvarchar(50) output'
exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output

if @Database like 'Competition%'
begin
	set @sql = 'select @TempBatchID = min(BatchID) ' + @CR
	set @sql = @sql + 'from RepMgmt.dbo.DIFFBOT_ResultLinks ' + @CR
	set @sql = @sql + 'where CustomerID = ''' + @CustomerID + ''''
	set @parms = '@TempBatchID int output'
	exec sp_executesql @sql, @parms, @TempBatchID = @BatchID output
end
else
begin
	set @sql = 'select @TempBatchID = min(BatchID) ' + @CR
	set @sql = @sql + 'from ' + @Database + '.dbo.DIFFBOT_ResultLinks ' + @CR
	set @parms = '@TempBatchID int output'
	exec sp_executesql @sql, @parms, @TempBatchID = @BatchID output
end

set @sql = 'select v.NPI, v.FirstName, v.LastName, v.SearchPattern, dbo.fn_GetDomain(v.LinkTarget) as Domain, v.LinkTarget, v.RatingText, ' + @CR
set @sql = @sql + 'replace(replace(v.OriginalRatingText, char(13), ''''), char(10), '''') as OriginalRatingText ' + @CR
set @sql = @sql + 'from ' + @Database + '.dbo.vw_PhysicianSearch v ' + @CR
set @sql = @sql + 'where v.SearchPattern = ''MasterSearch'' ' + @CR
set @sql = @sql + 'and dbo.fn_GetDomain(v.LinkTarget) in ( ' + @CR
set @sql = @sql + '''www.healthgrades.com'',''www.ratemds.com'',''www.ucomparehealthcare.com'', ' + @CR
set @sql = @sql + '''www.vitals.com'',''www.wellness.com'',''www.zocdoc.com'',''www.yelp.com'',''doctor.webmd.com'',''www.facebook.com'',''www.google.com'') ' + @CR
set @sql = @sql + 'and v.RatingText is not null ' + @CR
set @sql = @sql + 'and v.NPI <> v.LastName ' + @CR
if @Database like 'Competition%'
begin
	set @sql = @sql + 'and v.NPI in (select distinct NPI from RepMgmt.dbo.DIFFBOT_ResultLinks where BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' and ResultVolume is not null) ' + @CR
end
else
begin
	set @sql = @sql + 'and v.NPI in (select distinct NPI from ' + @Database + '.dbo.DIFFBOT_ResultLinks where BatchID = ''' + cast(@BatchID as nvarchar(10)) + ''' and ResultVolume is not null) ' + @CR
end
set @sql = @sql + 'order by v.LastName, v.FirstName, v.MiddleName, v.LinkTarget ' + @CR
exec(@sql)
