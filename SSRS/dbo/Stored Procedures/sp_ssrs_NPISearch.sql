﻿create procedure sp_ssrs_NPISearch (
*/

create table #npi (ID int identity, NPI nvarchar(10), NPIType nvarchar(50), Descr nvarchar(400), DbName nvarchar(200))
if @Database is not null
	set @sql = 'insert #npi(NPI, NPIType, Descr, DbName) ' + @CR
end
if @RunDb is not null
begin
	set @sql = 'insert #npi(NPI, NPIType, Descr, DbName) ' + @CR
	set @sql = 'insert #npi(NPI, NPIType, Descr, DbName) ' + @CR
	set @sql = @sql + 'select distinct CustomerID, ''Customer'', CustomerSource, ''' + @RunDb + ''' ' + @CR
end	

select * from #npi order by DbName, NPIType, Descr

drop table #npi