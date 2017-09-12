CREATE procedure [dbo].[sp_SQL]

as

declare
@sql nvarchar(max),
@CR char(1)

set @CR = char(13)

set @sql = 'declare' + @CR
set @sql = @sql + '@Database nvarchar(255)' + @CR + @CR
set @sql = @sql + 'declare' + @CR
set @sql = @sql + '@CustomerID nvarchar(10),' + @CR
set @sql = @sql + '@CustomerSource nvarchar(255),' + @CR
set @sql = @sql + '@sql nvarchar(max),' + @CR
set @sql = @sql + '@parms nvarchar(max),' + @CR
set @sql = @sql + '@CR char(1)' + @CR + @CR
set @sql = @sql + 'set @CR = char(13)' + @CR + @CR
set @sql = @sql + '/*' + @CR
set @sql = @sql + 'set @sql = '' '' + @CR' + @CR
set @sql = @sql + 'set @sql = @sql + '' '' + @CR' + @CR
set @sql = @sql + 'exec(@sql)' + @CR + @CR
set @sql = @sql + 'set @sql = ''select top 1 @TempCustomerSource = CustomerSource, @TempCustomerID = CustomerID '' + @CR' + @CR
set @sql = @sql + 'set @sql = @sql + ''from ['' + @Database + ''].[dbo].PhysCustomerID''' + @CR
set @sql = @sql + 'set @parms = ''@TempCustomerSource varchar(255) output, @TempCustomerID nvarchar(10) output''' + @CR
set @sql = @sql + 'exec sp_executesql @sql, @parms, @TempCustomerSource = @CustomerSource output, @TempCustomerID = @CustomerID output' + @CR
set @sql = @sql + '*/' + @CR + @CR
set @sql = @sql + 'set @sql = '' '' + @CR' + @CR
set @sql = @sql + 'set @sql = @sql + '' '' + @CR' + @CR
set @sql = @sql + 'exec(@sql)'
print @sql