﻿create procedure sp_ssrs_DIFFBOT_Monthly_Differences (
	@SiteName nvarchar(50),
	@Month int
@SiteName nvarchar(50) = 'HealthGrades',
@Month int = 3

exec sp_ssrs_DIFFBOT_Monthly_Differences @Database, @SiteName, @Month
*/

declare

/*
set @sql = ' ' + @CR
*/

set @sql = 'select @TempStartBatchID = min(BatchID), @TempEndBatchID = max(BatchID) ' + @CR

set @counter = 1
while @counter <= (select max(ID) from #sites)
begin
	select @SiteName = SiteName from #sites where ID = @counter

	set @sql = 'insert #data ' + @CR

	set @counter = @counter + 1
end

select * from #data order by LastName, FirstName, SiteName

drop table #sites
drop table #data