create function dbo.fn_GetGuid (@input nvarchar(max))
returns nvarchar(max)
as
begin
	declare
	@pattern nvarchar(max),
	@next_posit int

	select
	@pattern = '%[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]%',
	@next_posit = patindex(@pattern, @input)

	select @input = substring(@input, @next_posit, 36)

	return @input
end