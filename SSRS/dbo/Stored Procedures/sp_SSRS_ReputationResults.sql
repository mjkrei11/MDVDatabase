
CREATE procedure [dbo].[sp_SSRS_ReputationResults] @Database nvarchar(200)

AS

/* Test parameter */
/*
declare @Database nvarchar(200)
Set @Database = 'Developement'
*/
declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

Set @sql = 'SELECT pmr.ComboKey, pmrm.NPI, pmrm.FirstName, pmrm.MiddleName, pmrm.LastName, ' + @CR
Set @sql = @sql + 'pmrm.CollectionID, pmrm.CollectionName, pmrm.SystemID, pmrm.SystemName, pmr.Color, pmr.Percentile, ' + @CR
Set @sql = @sql + 'pmr.VIMeasure, pmr.RatingsSite, pmr.NumberOfRatings, pmr.RatingsProfile ' + @CR
Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysMetReputation pmr ' + @CR
Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysMetReputationMedia pmrm ON pmr.ComboKey = pmrm.ComboKey ' + @CR
Set @sql = @sql + 'WHERE pmr.RatingsSite = ''Sum All Sites'''
--Print @sql
exec(@sql)


