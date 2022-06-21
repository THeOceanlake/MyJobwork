
-- 更新字段长度
alter table T1 alter column F1 varchar(10);
-- 更新


-- 行列转换

SET @sql_str = 'SELECT *  FROM (
    SELECT convert(varchar,drq) 日期,syy,nzb FROM ^result) p PIVOT 
    (SUM([nzb]) FOR [syy] IN ( '+ @sql_col +'))   AS pvt 
ORDER BY pvt.[日期]'
EXEC (@sql_str) 

with x0 as(
select a.drq,a.syy,a.商品数或金额,a.商品数或金额*1.0/b.nsum nzb from ^date_mx a ,^sum b where a.drq=b.drq 
) 
select a.drq,a.syy,b.商品数或金额,b.nzb into ^result
from ^base_sp a left join x0 b on  a.drq=b.drq and a.syy=b.syy
where 1=1    
 
    SELECT convert(varchar,drq) 日期, max( case when syy='配送包装数过大' then nzb else 0 end) as '配送包装数过大',
	max( case when syy='人工下单' then nzb else 0 end) as '人工下单',
	max( case when syy='遗留库存' then nzb else 0 end) as '遗留库存',
	max( case when syy='最低陈列量' then nzb else 0 end) as '最低陈列量',
	max( case when syy='系统定额过大' then nzb else 0 end) as '系统定额过大',
	max( case when syy='新品' then nzb else 0 end) as '新品',
	max( case when syy='门店下单' then nzb else 0 end) as '门店下单',
	max( case when syy='DM' then nzb else 0 end) as 'DM',
	max( case when syy='逾期到货' then nzb else 0 end) as '逾期到货',
	max( case when syy='盘点' then nzb else 0 end) as '盘点',
	max( case when syy='调入(店间调拨)' then nzb else 0 end) as '调入(店间调拨)',
	FROM ^result 
	order by drq 