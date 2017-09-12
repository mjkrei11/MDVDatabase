




CREATE procedure [dbo].[sp_SSRS_Sales_PhysicianReputationData] (@Database nvarchar(200),
	@Option int
)

AS

/* Test parameter */
/*
declare @Database nvarchar(200),
	@Option int

Set @Database = 'Panorama'
Set @Option = 1
*/
declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

if @Option = 0 /***** Without Competition *****/
Begin
	Set @sql = 'SELECT media.NPI, media.FirstName, media.MiddleName, media.LastName, media.SystemName,  media.SystemID, media.ComboKey, ' + @CR
	Set @sql = @sql + 'rep.RatingsSite, rep.Specialty, rep.VIMeasure, rep.Rating, rep.NumberOfRatings, ' + @CR
	Set @sql = @sql + 'rep.Percentile, rep.Color, rep.RatingsProfile ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysMetReputation rep ON media.ComboKey = rep.ComboKey ' + @CR
	Set @sql = @sql + 'WHERE rep.Rating <> 0 AND media.SystemID = media.CollectionID ' + @CR
	Set @sql = @sql + 'Order By media.LastName '
End
if @Option = 1 /***** With Competition *****/
Begin
	Set @sql = 'SELECT media.NPI, media.FirstName, media.MiddleName, media.LastName, media.SystemName,  media.SystemID, media.ComboKey, ' + @CR
	Set @sql = @sql + 'rep.RatingsSite, rep.Specialty, rep.VIMeasure, rep.Rating, rep.NumberOfRatings, ' + @CR
	Set @sql = @sql + 'rep.Percentile, rep.Color, rep.RatingsProfile ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysMetReputation rep ON media.ComboKey = rep.ComboKey ' + @CR
	Set @sql = @sql + 'WHERE rep.Rating <> 0 AND media.SystemID <> media.CollectionID ' + @CR
	Set @sql = @sql + 'Order By media.LastName '
End
--Print @sql
exec(@sql)







