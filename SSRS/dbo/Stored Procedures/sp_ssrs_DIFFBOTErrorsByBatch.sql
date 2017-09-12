
CREATE procedure [dbo].[sp_ssrs_DIFFBOTErrorsByBatch] (@BatchID int)

as

/*
declare @BatchID int = null
exec sp_ssrs_DIFFBOTErrorsByBatch @BatchID
*/

declare
@Database nvarchar(200),
@counter int,
@sql nvarchar(max),
@parms nvarchar(max),
@CR char(1)

set @CR = char(13)

if @BatchID is null
begin
	select @BatchID = min(BatchID) from RepMgmt.dbo.DIFFBOT_WorkingLinks
end

select		distinct isnull(max(r.WorkingKey), newid()) WorkingKey, isnull(r.SourceKey, newid()) SourceKey,
			r.CustomerID, r.NPI, r.SiteName, r.WorkingLink ResultLink, @BatchID as BatchID
from		RepMgmt.dbo.DIFFBOT_Retry r
where		r.BatchID = @BatchID
and			replace(r.WorkingLink, 'http://', 'https://') not in
(
	select		replace(ResultLink, 'http://', 'https://')
	from		RepMgmt.dbo.DIFFBOT_ResultLinks
	where		BatchID = @BatchID
)
group by	r.SourceKey, r.CustomerID, r.NPI, r.SiteName, r.WorkingLink, r.BatchID
order by	r.SiteName, r.CustomerID, r.NPI, ResultLink