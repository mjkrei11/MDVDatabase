
create procedure [dbo].[sp_ssrs_GetDIFFBOTBatches_ALL]

as

/*
exec sp_ssrs_GetDIFFBOTBatches_ALL
*/

declare
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

select distinct BatchID, cast(BatchID as nvarchar(5)) + ' - ' + convert(varchar, SearchDate, 101) as BatchDate
from RepMgmt.dbo.DIFFBOT_ResultLinks
order by BatchID desc