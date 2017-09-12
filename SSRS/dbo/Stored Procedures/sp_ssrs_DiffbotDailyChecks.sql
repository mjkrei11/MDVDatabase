﻿create procedure sp_ssrs_DiffbotDailyChecksasdeclare@Database nvarchar(200)declare@CustomerID nvarchar(50),@CustomerSource nvarchar(120),@BatchID int,@sql nvarchar(max),@parms nvarchar(max),@CR char(1)set @CR = char(13)/*set @sql = ' ' + @CRset @sql = @sql + ' ' + @CRexec(@sql)*/select @BatchID = max(BatchID) from RepMgmt.dbo.DIFFBOT_WorkingLinkscreate table #systems(ID int identity, SystemID nvarchar(10), SystemName nvarchar(200))insert		#systems(SystemID, SystemName)select		distinct d.CustomerID, s.SystemNamefrom		RepMgmt.dbo.DIFFBOT_ResultLinks dinner join	MDVALUATE.dbo.SystemRecordsMedia son			s.SystemID = d.CustomerIDwhere		d.BatchID in (@BatchID, @BatchID - 1)create table #physicians(ID int identity, NPI nvarchar(10), FirstName nvarchar(100), LastName nvarchar(100), SystemID nvarchar(10))insert		#physicians(NPI, FirstName, LastName, SystemID)select		distinct d.NPI, m.FirstName, m.LastName, d.CustomerIDfrom		RepMgmt.dbo.DIFFBOT_ResultLinks dinner join	MDVALUATE.dbo.MasterPhysicianMedia mon			m.NPI = d.NPIwhere		d.BatchID in (@BatchID, @BatchID - 1)select		distinct s.SystemName, p.LastName, p.FirstName, d.SiteName, d.ResultLink, d.ResultVolume Volume, d.ResultRating Rating, d.BatchID, s.SystemID, p.NPI--, d.ResultKey, d.RawResultKeyfrom		RepMgmt.dbo.DIFFBOT_ResultLinks dinner join	#systems son			s.SystemID = d.CustomerIDinner join	#physicians pon			p.NPI = d.NPIand			p.SystemID = s.SystemIDwhere		d.BatchID in (@BatchID, @BatchID - 1)order by	s.SystemName, p.LastName, p.FirstName, d.SiteName, d.ResultLink, d.BatchID descdrop table #systemsdrop table #physicians