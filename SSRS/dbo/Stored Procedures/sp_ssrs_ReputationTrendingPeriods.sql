﻿create procedure sp_ssrs_ReputationTrendingPeriods (
*/

set @sql = 'select distinct StartDate + '' - '' + EndDate as Period ' + @CR