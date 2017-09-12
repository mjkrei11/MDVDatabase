










CREATE procedure [dbo].[sp_SSRS_CompetitionValidationData_Reputation] (
	@Database nvarchar(200),
	@SystemID nvarchar(10)
)

AS

/* Test parameter */
/*
declare
@Database nvarchar(200),
@SystemID nvarchar(10)

Set @Database = 'CompetitionDemo'
set @SystemID = '1598700478'
*/
--exec sp_SSRS_CompetitionValidationData_Reputation 'Panorama', '1871539478'


declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

create table #SitesRatingText(
	PopupNumberOfSitesWithRatings varchar(400),
	NPI nvarchar(10),
	Popup2Row int,
	Popup2Col int,
	Popup2Quarter varchar(8)
)
create table #SitesRatingValue(
	PopupNumberOfSitesWithRatingsValue varchar(400),
	NPI2 nvarchar(10)

)
create table #TotalNumberOfRatingsText(
	PopupTotalNumberOfRatingText varchar(400),
	NPI3 nvarchar(10)
)
create table #TotalNumberOfRatingsValue(
	PopupTotalNumberOfRatingValue varchar(400),
	NPI4 nvarchar(10)
)
create table #AverageStarRatingText(
	PopupAverageStarRatingText varchar(400),
	NPI5 nvarchar(10)
)
create table #AverageStarRatingValue(
	PopupAverageStarRatingValue varchar(400),
	NPI6 nvarchar(10)
)
create table #ReputationData(
	FirstName varchar(40),
	LastName varchar(60),
	NPI varchar(10),
	MetricTitle varchar(40),
	VICategory varchar(40),
	RatingsSite varchar(120),
	Rating float,
	NumberOfRatings int,
	SystemID varchar(14),
	SystemName varchar(400),
	NumberOfSitesWithRatings int
)
--create table #PhysAvgSitesWithRatings(
--	PhysicianAvgSitesWithRatings int,
--	RatingsSite varchar(120),
--	NPI7 varchar(10)
--)

	Set @sql = 'INSERT #ReputationData(FirstName, LastName, NPI, MetricTitle, VICategory, RatingsSite, Rating, NumberOfRatings, SystemID, SystemName, NumberOfSitesWithRatings) ' + @CR
	Set @sql = @sql + 'SELECT media.FirstName, media.LastName, media.NPI, pmr.MetricTitle, pmr.VICategory, pmr.RatingsSite, ' + @CR
	Set @sql = @sql + 'pmr.Rating, pmr.NumberofRatings, pvi.SystemID, pvi.SystemName, ' + @CR
	Set @sql = @sql + '(SELECT Count(*) FROM ' + @Database + '.dbo.PhysMetReputation pmr2 ' + @CR
	Set @sql = @sql + 'WHERE pmr2.NumberofRatings > 0 AND pmr2.RatingsSite <> ''Sum All Sites'' AND pmr2.ComboKey = pmr.ComboKey) AS NumberOfSitesWithRatings ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysMetReputationMedia media ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysMetReputation pmr ON pmr.ComboKey = media.ComboKey ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysVIndex pvi ON pvi.NPI = media.NPI ' + @CR
	Set @sql = @sql + 'WHERE pmr.RatingsSite = ''Sum All Sites'' ' + @CR
	Set @sql = @sql + 'AND pvi.SystemID = ' + @SystemID + ' ' + @CR
	Set @sql = @sql + 'Order By LastName, FirstName '
	--Print @sql
	exec(@sql)

	--Set @sql = 'INSERT #PhysAvgSitesWithRatings(PhysicianAvgSitesWithRatings, pa.RatingsSite, NPI7) ' + @CR
	--Set @sql = @sql + 'SELECT count(distinct pa.RatingsSite), pa.RatingsSite, pa.NPI AS NPI7 FROM ' + @Database + '.dbo.PhysMetReputation pa ' + @CR
	--Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysVIndex pvi ON pa.NPI = pa.NPI ' + @CR
	--Set @sql = @sql + 'WHERE pa.NumberOfRatings <> 0 AND pa.RatingsSite <> ''Sum All Sites'' ' + @CR
	--Set @sql = @sql + 'AND pvi.SystemID = ' + @SystemID + ' ' + @CR
	--Set @sql = @sql + 'Group By pa.RatingsSite'

	--This will bring in the text only for "Number of Sites with Ratings"
	Set @sql = 'INSERT #SitesRatingText(PopupNumberOfSitesWithRatings, NPI, Popup2Row, Popup2Col, Popup2Quarter) ' + @CR
	Set @sql = @sql + 'SELECT distinct pvp.Popup2Value, pvi.NPI, pvp.Popup2Row, pvp.Popup2Col, pvp.Popup2Quarter ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysVIndex pvi ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysVPopups2 pvp ON pvp.NPI = pvi.NPI ' + @CR
	Set @sql = @sql + 'WHERE pvi.SystemID = ' + @SystemID + ' ' + @CR
	Set @sql = @sql + 'AND pvp.NPI NOT LIKE ''00000%'' ' + @CR
	Set @sql = @sql + 'AND pvp.Popup2MeasureName = ''Physician Reputation'' ' + @CR
	Set @sql = @sql + 'AND pvp.Popup2Row = 4 AND pvp.Popup2Col = 0 ' + @CR
	--Set @sql = @sql + 'AND pvp.NPI = ' + @NPI + ' ' + @CR
	Set @sql = @sql + 'AND pvp.NPI <> ' + @SystemID + ' ' + @CR
	--Print @sql
	exec(@sql)

	--This will bring in the value only for the "Number of Sites with Ratings"
	Set @sql = 'INSERT #SitesRatingValue(PopupNumberOfSitesWithRatingsValue, NPI2) ' + @CR
	Set @sql = @sql + 'SELECT distinct pvp2.Popup2Value AS Popup2Value2, pvi2.NPI AS NPI2 ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysVIndex pvi2 ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysVPopups2 pvp2 ON pvp2.NPI = pvi2.NPI ' + @CR
	Set @sql = @sql + 'WHERE pvi2.SystemID = ' + @SystemID + ' ' + @CR
	Set @sql = @sql + 'AND pvp2.NPI NOT LIKE ''00000%'' ' + @CR
	Set @sql = @sql + 'AND pvp2.Popup2MeasureName = ''Physician Reputation'' ' + @CR
	Set @sql = @sql + 'AND pvp2.Popup2Row = 4 AND pvp2.Popup2Col = 1 ' + @CR
	--Set @sql = @sql + 'AND pvp2.NPI = ' + @NPI + ' ' + @CR
	Set @sql = @sql + 'AND pvp2.NPI <> ' + @SystemID + ' ' + @CR
	exec(@sql)

	--This will bring in the text only for the "Total Number of Ratings"
	Set @sql = 'INSERT #TotalNumberOfRatingsText(PopupTotalNumberOfRatingText, NPI3) ' + @CR
	Set @sql = @sql + 'SELECT distinct pvp3.Popup2Value AS Popup2Value3, pvi3.NPI AS NPI3 ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysVIndex pvi3 ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysVPopups2 pvp3 ON pvp3.NPI = pvi3.NPI ' + @CR
	Set @sql = @sql + 'WHERE pvi3.SystemID = ' + @SystemID + ' ' + @CR
	Set @sql = @sql + 'AND pvp3.NPI NOT LIKE ''00000%'' ' + @CR
	Set @sql = @sql + 'AND pvp3.Popup2MeasureName = ''Physician Reputation'' ' + @CR
	Set @sql = @sql + 'AND pvp3.Popup2Row = 5 AND pvp3.Popup2Col = 0 ' + @CR
	--Set @sql = @sql + 'AND pvp3.NPI = ' + @NPI + ' ' + @CR
	Set @sql = @sql + 'AND pvp3.NPI <> ' + @SystemID + ' ' + @CR
	exec(@sql)

	--This will bring in the value only for the "Total Number of Ratings"
	Set @sql = 'INSERT #TotalNumberOfRatingsValue(PopupTotalNumberOfRatingValue, NPI4) ' + @CR
	Set @sql = @sql + 'SELECT distinct pvp4.Popup2Value AS Popup2Value4, pvi4.NPI AS NPI4 ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysVIndex pvi4 ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysVPopups2 pvp4 ON pvp4.NPI = pvi4.NPI ' + @CR
	Set @sql = @sql + 'WHERE pvi4.SystemID = ' + @SystemID + ' ' + @CR
	Set @sql = @sql + 'AND pvp4.NPI NOT LIKE ''00000%'' ' + @CR
	Set @sql = @sql + 'AND pvp4.Popup2MeasureName = ''Physician Reputation'' ' + @CR
	Set @sql = @sql + 'AND pvp4.Popup2Row = 5 AND pvp4.Popup2Col = 1 ' + @CR
	--Set @sql = @sql + 'AND pvp4.NPI = ' + @NPI + ' ' + @CR
	Set @sql = @sql + 'AND pvp4.NPI <> ' + @SystemID + ' ' + @CR
	exec(@sql)

	--This will bring in the text only for the "Average Star Rating"
	Set @sql = 'INSERT #AverageStarRatingText(PopupAverageStarRatingText, NPI5) ' + @CR
	Set @sql = @sql + 'SELECT distinct pvp5.Popup2Value AS Popup2Value5, pvi5.NPI AS NPI5 ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysVIndex pvi5 ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysVPopups2 pvp5 ON pvp5.NPI = pvi5.NPI ' + @CR
	Set @sql = @sql + 'WHERE pvi5.SystemID = ' + @SystemID + ' ' + @CR
	Set @sql = @sql + 'AND pvp5.NPI NOT LIKE ''00000%'' ' + @CR
	Set @sql = @sql + 'AND pvp5.Popup2MeasureName = ''Physician Reputation'' ' + @CR
	Set @sql = @sql + 'AND pvp5.Popup2Row = 6 AND pvp5.Popup2Col = 0 ' + @CR
	--Set @sql = @sql + 'AND pvp5.NPI = ' + @NPI + ' ' + @CR
	Set @sql = @sql + 'AND pvp5.NPI <> ' + @SystemID + ' ' + @CR
	exec(@sql)

	--This will bring in the value only for the "Average Star Rating"
	Set @sql = 'INSERT #AverageStarRatingValue(PopupAverageStarRatingValue, NPI6) ' + @CR
	Set @sql = @sql + 'SELECT distinct pvp6.Popup2Value AS Popup2Value6, pvi6.NPI AS NPI6 ' + @CR
	Set @sql = @sql + 'FROM ' + @Database + '.dbo.PhysVIndex pvi6 ' + @CR
	Set @sql = @sql + 'INNER JOIN ' + @Database + '.dbo.PhysVPopups2 pvp6 ON pvp6.NPI = pvi6.NPI ' + @CR
	Set @sql = @sql + 'WHERE pvi6.SystemID = ' + @SystemID + ' ' + @CR
	Set @sql = @sql + 'AND pvp6.NPI NOT LIKE ''00000%'' ' + @CR
	Set @sql = @sql + 'AND pvp6.Popup2MeasureName = ''Physician Reputation'' ' + @CR
	Set @sql = @sql + 'AND pvp6.Popup2Row = 6 AND pvp6.Popup2Col = 1 ' + @CR
	--Set @sql = @sql + 'AND pvp6.NPI = ' + @NPI + ' ' + @CR
	Set @sql = @sql + 'AND pvp6.NPI <> ' + @SystemID + ' ' + @CR
	exec(@sql)

	SELECT rd.FirstName, rd.LastName, rd.MetricTitle, rd.VICategory, rd.RatingsSite, rd.Rating, rd.NumberOfRatings, rd.SystemID,
		rd.SystemName, rd.NumberOfSitesWithRatings, --pa.PhysicianAvgSitesWithRatings, pa.RatingsSite,
		srt.PopupNumberOfSitesWithRatings, srt.NPI AS NPI, srt.Popup2Row, srt.Popup2Col, srt.Popup2Quarter,
		srv.PopupNumberOfSitesWithRatingsValue, tnr.PopupTotalNumberOfRatingText, tnrv.PopupTotalNumberOfRatingValue,
		asr.PopupAverageStarRatingText, asrv.PopupAverageStarRatingValue
	FROM #ReputationData rd
		--INNER JOIN #PhysAvgSitesWithRatings pa ON rd.NPI = pa.NPI7
		INNER JOIN #SitesRatingText srt ON rd.NPI = srt.NPI
		INNER JOIN #SitesRatingValue srv ON srt.NPI = srv.NPI2
		INNER JOIN #TotalNumberOfRatingsText tnr ON srt.NPI = tnr.NPI3
		INNER JOIN #TotalNumberOfRatingsValue tnrv ON srt.NPI = tnrv.NPI4
		INNER JOIN #AverageStarRatingText asr ON srt.NPI = asr.NPI5
		INNER JOIN #AverageStarRatingValue asrv ON srt.NPI = asrv.NPI6
	
	drop table #ReputationData
	--drop table #PhysAvgSitesWithRatings
	drop table #SitesRatingText
	drop table #SitesRatingValue
	drop table #TotalNumberOfRatingsText
	drop table #TotalNumberOfRatingsValue
	drop table #AverageStarRatingText
	drop table #AverageStarRatingValue
	







