create procedure sp_ssrs_NPISearch (	@Database nvarchar(200),	@RunDb nvarchar(200),	@NPI nvarchar(10))as/*declare@Database nvarchar(200),@RunDb nvarchar(200),@NPI nvarchar(10)select@Database = null,@RunDb = 'MDVALUATE',@NPI = '1619351160'exec sp_ssrs_NPISearch @Database, @RunDb, @NPI*/declare@CustomerID nvarchar(50),@CustomerSource nvarchar(120),@sql nvarchar(max),@parms nvarchar(max),@CR char(1)set @CR = char(13)/*set @sql = ' ' + @CRset @sql = @sql + ' ' + @CRexec(@sql)
*/

create table #npi (ID int identity, NPI nvarchar(10), NPIType nvarchar(50), Descr nvarchar(400), DbName nvarchar(200))
if @Database is not nullbegin	set @sql = 'insert #npi(NPI, NPIType, Descr, DbName) ' + @CR	set @sql = @sql + 'select NPI, ''Physician'', LastName + '', '' + FirstName, ''' + @Database + ''' ' + @CR	set @sql = @sql + 'from ' + @Database + '.dbo.PhysicianMedia ' + @CR	set @sql = @sql + 'where NPI = ''' + @NPI + ''' ' + @CR	exec(@sql)
	set @sql = 'insert #npi(NPI, NPIType, Descr, DbName) ' + @CR	set @sql = @sql + 'select distinct CustomerID, ''Customer'', CustomerSource, ''' + @Database + ''' ' + @CR	set @sql = @sql + 'from ' + @Database + '.dbo.PhysCustomerID ' + @CR	set @sql = @sql + 'where CustomerID = ''' + @NPI + ''' ' + @CR	exec(@sql)
end
if @RunDb is not null
begin
	set @sql = 'insert #npi(NPI, NPIType, Descr, DbName) ' + @CR	set @sql = @sql + 'select NPI, ''Physician'', LastName + '', '' + FirstName, ''' + @RunDb + ''' ' + @CR	set @sql = @sql + 'from ' + @RunDb + '.dbo.MasterPhysicianMedia ' + @CR	set @sql = @sql + 'where NPI = ''' + @NPI + ''' ' + @CR	exec(@sql)
	set @sql = 'insert #npi(NPI, NPIType, Descr, DbName) ' + @CR
	set @sql = @sql + 'select distinct CustomerID, ''Customer'', CustomerSource, ''' + @RunDb + ''' ' + @CR	set @sql = @sql + 'from ' + @RunDb + '.dbo.MasterPhysCustomerID ' + @CR	set @sql = @sql + 'where CustomerID = ''' + @NPI + ''' ' + @CR	exec(@sql)
end	

select * from #npi order by DbName, NPIType, Descr

drop table #npi