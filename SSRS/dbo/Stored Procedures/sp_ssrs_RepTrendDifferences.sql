CREATE procedure sp_ssrs_RepTrendDifferences (
	@Server_A nvarchar(200),
	@Server_B nvarchar(200),
	@Database_A nvarchar(200)
)

as

/*
declare
@Server_A nvarchar(200) = 'QA',
@Server_B nvarchar(200) = 'PROD',
@Database_A nvarchar(200) = 'CSNA2'

exec sp_ssrs_RepTrendDifferences @Server_A, @Server_B, @Database_A
*/

declare
@Database_B nvarchar(200),
@sql nvarchar(max),
@parms nvarchar(max)

select @Server_A = String from ScriptBox.dbo.Servers where Label = @Server_A
select @Server_B = String from ScriptBox.dbo.Servers where Label = @Server_B

set @sql = 'select top 1 @TempDatabase_B = name 'set @sql = @sql + 'from [' + @Server_B + '].master.dbo.sysdatabases 'set @sql = @sql + 'where name like ''' + replace(@Database_A, '2', '') + '%'' 'set @parms = '@TempDatabase_B nvarchar(200) output'exec sp_executesql @sql, @parms, @TempDatabase_B = @Database_B output

set @sql = 'select distinct media.NPI, media.LastName, media.FirstName, media.TrendDate, dev.NPITrend, dev.SummarySite, '
set @sql = @sql + 'dev.PreviousNoRatings as PreviousNoRatings_A, dev.PreviousNoComments as PreviousNoComments_A, dev.PreviousAvgRating as PreviousAvgRatings_A, '
set @sql = @sql + 'dev.CurrentNoRatings as CurrentNoRatings_A, dev.CurrentNoComments as CurrentNoComments_A, dev.CurrentAvgRating as CurrentAvgRating_A, '
set @sql = @sql + 'dev.DeltaNoRatings as DeltaNoRatings_A, dev.DeltaNoComments as DeltaNoComments_A, dev.DeltaAvgRating as DeltaAvgRating_A, '
set @sql = @sql + 'qa.PreviousNoRatings as PreviousNoRatings_B, qa.PreviousNoComments as PreviousNoComments_B, qa.PreviousAvgRating as PreviousAvgRatings_B, '
set @sql = @sql + 'qa.CurrentNoRatings as CurrentNoRatings_B, qa.CurrentNoComments as CurrentNoComments_B, qa.CurrentAvgRating as CurrentAvgRating_B, '
set @sql = @sql + 'qa.DeltaNoRatings as DeltaNoRatings_B, qa.DeltaNoComments as DeltaNoComments_B, qa.DeltaAvgRating as DeltaAvgRating_B '
set @sql = @sql + 'from [' + @Server_A + '].[' + @Database_A + '].dbo.VIRepSummary dev '
set @sql = @sql + 'inner join [' + @Server_A + '].[' + @Database_A + '].dbo.PhysVRepTrendMedia media '
set @sql = @sql + 'on media.NPITrend = dev.NPITrend '
set @sql = @sql + 'inner join [' + @Server_B + '].[' + @Database_B + '].dbo.VIRepSummary qa '
set @sql = @sql + 'on qa.NPITrend = dev.NPITrend '
set @sql = @sql + 'and qa.SummarySite = dev.SummarySite '
if @Server_A = 'DEV'
begin
	set @sql = @sql + 'where dev.SummaryTab = ''Weekly'' '
end
else
begin
	set @sql = @sql + 'where 1 = 1 '
end
set @sql = @sql + 'and (dev.PreviousNoRatings <> qa.PreviousNoRatings '
set @sql = @sql + 'or dev.PreviousAvgRating <> qa.PreviousAvgRating '
set @sql = @sql + 'or dev.PreviousNoComments <> qa.PreviousNoComments '
set @sql = @sql + 'or dev.CurrentNoRatings <> qa.CurrentNoRatings '
set @sql = @sql + 'or dev.CurrentAvgRating <> qa.CurrentAvgRating '
set @sql = @sql + 'or dev.CurrentNoComments <> qa.CurrentNoComments '
set @sql = @sql + 'or dev.DeltaNoRatings <> qa.DeltaNoRatings '
set @sql = @sql + 'or dev.DeltaAvgRating <> qa.DeltaAvgRating '
set @sql = @sql + 'or dev.DeltaNoComments <> qa.DeltaNoComments) '
set @sql = @sql + 'order by media.TrendDate, media.LastName, media.FirstName '
exec(@sql)