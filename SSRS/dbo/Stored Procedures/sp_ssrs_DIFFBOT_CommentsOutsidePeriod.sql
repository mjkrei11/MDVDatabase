﻿CREATE procedure sp_ssrs_DIFFBOT_CommentsOutsidePeriod (@TrendPeriod nvarchar(50))
from		MDVALUATE.dbo.SystemRecordsMedia
where		IsClient = 'Yes'
drop table #dbs
drop table #rep_trend