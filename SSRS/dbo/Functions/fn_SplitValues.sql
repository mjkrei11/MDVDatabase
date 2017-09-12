create function [dbo].[fn_SplitValues](
	@List nvarchar(4000),
	@SplitOn nvarchar(5)
)  
returns @RtnValue table(
	Id int identity(1,1),
	Value nvarchar(4000)
)

as

begin
	while(charindex(@SplitOn, @List) > 0)
	begin 
		insert into @RtnValue(Value)
		select Value = ltrim(rtrim(substring(@List, 1, charindex(@SplitOn, @List) - 1))) 
		set @List = substring(@List, charindex(@SplitOn, @List) + len(@SplitOn), len(@List))
	end 

	insert into @RtnValue(Value)
	select Value = ltrim(rtrim(@List))
	return
end