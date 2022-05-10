-- 因素因子库
select * from bd_flys_value

-- 导入数据表和因素因子库查询
select * from dbo.Input_Xp_Sp_Fd a 
left join dbo.BD_Flys_Value b on a.sSpbh=b.sSpbh 
where   a.sFlbh='03030304'