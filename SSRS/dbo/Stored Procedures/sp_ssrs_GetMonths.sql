create procedure sp_ssrs_GetMonths

as

select 1 as MonthNumber, 'January' as MonthDesc
union
select 2 as MonthNumber, 'February' as MonthDesc
union
select 3 as MonthNumber, 'March' as MonthDesc
union
select 4 as MonthNumber, 'April' as MonthDesc
union
select 5 as MonthNumber, 'May' as MonthDesc
union
select 6 as MonthNumber, 'June' as MonthDesc
union
select 7 as MonthNumber, 'July' as MonthDesc
union
select 8 as MonthNumber, 'August' as MonthDesc
union
select 9 as MonthNumber, 'September' as MonthDesc
union
select 10 as MonthNumber, 'October' as MonthDesc
union
select 11 as MonthNumber, 'November' as MonthDesc
union
select 12 as MonthNumber, 'December' as MonthDesc