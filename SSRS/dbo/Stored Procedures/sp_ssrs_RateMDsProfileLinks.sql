﻿CREATE procedure sp_ssrs_RateMDsProfileLinks
*/

set @sql = 'select distinct NPI, FirstName, LastName, replace(LinkTarget, ''%2B'', ''+'') LinkTarget ' + @CR