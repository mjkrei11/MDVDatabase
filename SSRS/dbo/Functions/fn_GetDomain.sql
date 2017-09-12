



CREATE function [dbo].[fn_GetDomain] ( @LinkTarget nvarchar(max) )
returns nvarchar(max) as
begin
	declare @return nvarchar(4000)
	set @return = null
	if @LinkTarget like 'http%'
	begin	
		set @return = substring(@LinkTarget, (charindex('://', @LinkTarget, 1) + 3), 
				charindex('/', substring(@LinkTarget, (charindex('://', @LinkTarget, 1) + 3),
					len(@LinkTarget))) - 1)
	end
	else if @LinkTarget like '%.%.%/%' and @LinkTarget not like 'http%'
	begin
		set @return = substring(@LinkTarget, 1, charindex('/', @LinkTarget) -1)
	end
	
	return @return
end
