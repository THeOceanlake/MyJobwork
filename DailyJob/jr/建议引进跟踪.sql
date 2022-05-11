/*
跟踪的结构
实际的批次建议从时间点开始距现在的情况汇总，
未开通的商品的明细
开通但没有库存的商品
引进新品30天不动销
*/

-- select  分店编号 sFdbh,分店名称 sFdmc,商品编号 sSpbh,商品名称 sSpmc,建议 sJyl
--  into #1  from dbo.Tmp_Md_Sptz  where 建议<>'停购淘汰';

select * into #1 from DappSource_Dw.dbo.Tmp_Measures_list
where sadvice='建议引进' and sspbh not in (22060171,22060174,23012425,07021299,32011103,24041721,32020231,25030491,22020139,
 23021839,24042021,25041288,25022494,25041284,23050235,58010218,31060346,24041716,24041714,25041419,
 24042201,24060132,30010355,25041418,23060205,23060003,24060028,57020538,06010363,23060206,24060036,
 75060219,06010102,06010103,06010407,24060034,23060029,06010300,06010329,24042018,30010354,46010094,
 24042017) ;

 select * from #1 

-- Step 2:库存数据
select a.*,b.STOP_INTO,b.STOP_SALE,b.VALIDATE_FLAG,b.CHARACTER_TYPE,
b.c_introduce_date,b.ITEM_ETAGERE_CODE,c.CURR_STOCK nKcsl into #2   from #1 a 
left join Dappsource_DW.dbo.P_SHOP_ITEM_OUTPUT b on a.sfdbh=b.DEPT_CODE 
and a.sspbh=b.ITEM_CODE
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK c on a.sFdbh=c.STORE_CODE and a.sSpbh=c.ITEM_CODE
where 1=1   ;

-- drop table #tmp_xs
with x0 as (
select distinct Measure_batch,createTime,sfdbh from  #2  )
select b.Measure_batch,  a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,sum(a.SALE_REAL_QTY) nxssl,sum(a.SALE_REAL_AMOUNT) nxsje,SUM(a.SALE_COST) ncb
into #tmp_xs from  Dappsource_DW.dbo.P_SALE_TOTAL_LIST_OUTPUT a ,x0 b 
where  1=1 and a.SHOP_CODE=b.sFdbh and convert(date,a.SALE_DATE)>CONVERT(date,b.createTime)
and  convert(date,a.SALE_DATE)<CONVERT(date,GETDATE())
group by b.Measure_batch,a.SHOP_CODE,a.ITEM_CODE;

select * from #2 ;

-- drop table #5
select a.Measure_batch, a.sfdbh, COUNT(1) njsps,sum(case when a.STOP_INTO='N' then 1 else 0 end ) nyjsps,
sum(case when a.ITEM_ETAGERE_CODE is not null then  1 else 0 end ) nykcsps into #5 from #2  a
where 1=1
group by a.Measure_batch, a.sFdbh;

-- 1 总体概览
with x0 as (
select a.Measure_batch,a.sFdbh,COUNT(distinct  a.sSpbh) nxssps,sum(a.nxsje) nxsje,sum(nxsje-ncb) nxsml from #tmp_xs a 
join #2 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and a.Measure_batch=b.Measure_batch
group by a.Measure_batch, a.sFdbh
),
x1 as (select a.Measure_batch, a.sFdbh,COUNT(distinct  a.sSpbh) nxssps,sum(a.nxsje) nxsje,sum(nxsje-ncb) nxsml from #tmp_xs a 
group by a.Measure_batch, a.sFdbh)
select  a.*,b.nxssps,b.nxsje,b.nxsml,b.nxssps*1.0/a.nykcsps ndxl,b.nxsml*1.0/b.nxsje nmll from #5  a
left join x0 b on a.sFdbh=b.sFdbh and a.Measure_batch=b.Measure_batch
left join x1 c on a.sFdbh=c.sFdbh and a.Measure_batch=c.Measure_batch
where 1=1 ;

--- 2 开通未引进
select * from #2  a where  a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y' and  ISNULL(a.nkcsl,0)<=0
and a.ITEM_ETAGERE_CODE is null;

-- 3 引进但当前缺货
select * from #2  a where  a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y' and  ISNULL(a.nkcsl,0)<=0
and a.ITEM_ETAGERE_CODE is not  null;


select a.*,DATEDIFF(day,convert(date,a.ITEM_ETAGERE_CODE),convert(date,GETDATE()))+1 nday,b.nxssl,b.nxsje,b.ncb,
ISNULL(b.nxssl,0)/(DATEDIFF(day,convert(date,a.ITEM_ETAGERE_CODE),convert(date,GETDATE()))+1) nrjxl from #2  a 
left join #tmp_xs b  on a.Measure_batch=b.Measure_batch and a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
 where  a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y' 
and a.ITEM_ETAGERE_CODE is not null;

-- 4 新品引进不动销
select a.*,d.sflbh,d.sflmc,c.scgqy,DATEDIFF(day,convert(date,a.ITEM_ETAGERE_CODE),convert(date,GETDATE()))+1 nday,b.nxssl,b.nxsje,b.ncb,
ISNULL(b.nxssl,0)/(DATEDIFF(day,convert(date,a.ITEM_ETAGERE_CODE),convert(date,GETDATE()))+1) nrjxl from #2  a 
left join #tmp_xs b  on a.Measure_batch=b.Measure_batch and a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
left join dappsource_DW.dbo.goods c on a.sspbh=c.code
left join DappSource_Dw.dbo.tmp_spflb d on c.sort=d.sflbh
 where  a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y' 
 and b.nxssl is null and DATEDIFF(day,convert(date,a.ITEM_ETAGERE_CODE),convert(date,GETDATE()))+1>20
and a.ITEM_ETAGERE_CODE is not null;



/*      2022-05-11 数据               */
select 分店编号 sfdbh,商品编号 sspbh,商品名称 sspmc into #1 from  Tmp_Md_Sptz where 建议='建议引进'
and 商品编号 not in (22060171,22060174,23012425,07021299,32011103,24041721,32020231,25030491,22020139,
 23021839,24042021,25041288,25022494,25041284,23050235,58010218,31060346,24041716,24041714,25041419,
 24042201,24060132,30010355,25041418,23060205,23060003,24060028,57020538,06010363,23060206,24060036,
 75060219,06010102,06010103,06010407,24060034,23060029,06010300,06010329,24042018,30010354,46010094,
 24042017) ; 

 select * from #1 

-- Step 2:库存数据
select a.*,b.STOP_INTO,b.STOP_SALE,b.VALIDATE_FLAG,b.CHARACTER_TYPE,
b.c_introduce_date,b.ITEM_ETAGERE_CODE,c.CURR_STOCK nKcsl into #2   from #1 a 
left join Dappsource_DW.dbo.P_SHOP_ITEM_OUTPUT b on a.sfdbh=b.DEPT_CODE 
and a.sspbh=b.ITEM_CODE
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK c on a.sFdbh=c.STORE_CODE and a.sSpbh=c.ITEM_CODE
where 1=1   ;

-- drop table #tmp_xs
with x0 as (
select distinct  sfdbh,CONVERT(date,'2022-03-25') createTime from  #2  )
select   a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,sum(a.SALE_REAL_QTY) nxssl,sum(a.SALE_REAL_AMOUNT) nxsje,SUM(a.SALE_COST) ncb
into #tmp_xs from  Dappsource_DW.dbo.P_SALE_TOTAL_LIST_OUTPUT a ,x0 b 
where  1=1 and a.SHOP_CODE=b.sFdbh and convert(date,a.SALE_DATE)>CONVERT(date,b.createTime)
and  convert(date,a.SALE_DATE)<CONVERT(date,GETDATE())
group by  a.SHOP_CODE,a.ITEM_CODE;

select * from #tmp_xs  ;

-- drop table #5
select   a.sfdbh, COUNT(1) njsps,sum(case when a.STOP_INTO='N' then 1 else 0 end ) nyjsps,
sum(case when a.ITEM_ETAGERE_CODE is not null then  1 else 0 end ) nykcsps into #5 from #2  a
where 1=1
group by   a.sFdbh;

-- 1 总体概览
with x0 as (
select a.sFdbh,COUNT(distinct  a.sSpbh) nxssps,sum(a.nxsje) nxsje,sum(nxsje-ncb) nxsml from #tmp_xs a 
join #2 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  
group by  a.sFdbh
),
x1 as (select   a.sFdbh,COUNT(distinct  a.sSpbh) nxssps,sum(a.nxsje) nxsje,sum(nxsje-ncb) nxsml from #tmp_xs a 
group by   a.sFdbh)
select CONVERT(date,GETDATE()) drq, a.*,b.nxssps,b.nxsje,b.nxsml,b.nxssps*1.0/a.nykcsps ndxl,b.nxsml*1.0/b.nxsje nmll from #5  a
left join x0 b on a.sFdbh=b.sFdbh  
left join x1 c on a.sFdbh=c.sFdbh  
where 1=1 ;