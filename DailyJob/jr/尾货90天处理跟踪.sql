/* 
    当前处理批次的跟踪
    每批次，分阶段，每10天的情况-累计情况：销售额、回本率、完成率（品种数的清退）、库存处理进度
*/
-- Step 1: 基础数据准备
select * into #Tmp_mdsp from DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT
where DEPT_CODE in ('018329','018389','012006','012007');

select * into #goods from DappSource_Dw.dbo.goods

select * into #Tmp_fdb from DappSource_Dw.dbo.Tmp_FDB;
Select * into #Tmp_spflb from DappSource_Dw.dbo.Tmp_spflb

-- drop table #Tmp_xs
select a.* into #Tmp_xs from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT  a
where 1=1  and a.SALE_DATE>='2022-01-01' and a.SALE_DATE<'2022-04-02'
and a.SHOP_CODE in ('018329','012006','018389','012007');

select * into #R_dpzb from [122.147.10.202].dappresult.dbo.R_dpzb 
where sfdbh in ('018329','012006','018389','012007');

select * into #Tmp_de from  DappSource_Dw.dbo.sys_deliveryset 
where sfdbh in ('018329','012006','018389','012007');

-- Step 2: 处理批次
select '1月' smonth,convert(date,'2022-01-01') Bdate into #Tmp_time union
select '2月' smonth,convert(date,'2022-02-01') 

-- Step 3:基础数据准备
-- drop table #1;
select a.机构代码 sFdbh,a.门店名称 sFdmc,a.商品编码 sSpbh,a.商品名称 sSpmc,c.smonth,c.Bdate,
b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode  into #1 
from  DappSource_Dw.dbo.tmp_clkc_dr a 
left join #Tmp_mdsp b on b.DEPT_CODE=a.机构代码 and b.ITEM_CODE=a.商品编码
left join #Tmp_time c on a.清理计划时间=c.smonth
where DEPT_CODE in ('018329','018389','012006','018425','012007') and  a.清理计划时间='1月' ;

-- drop table #Base_sp
select a.*,d.sort sPlbh,e.nrjxl into #Base_sp
from #1 a
left join #R_dpzb b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh
left join #goods d on a.sSpbh=d.code
left join #Tmp_de e on a.sFdbh=e.sfdbh and a.sSpbh=e.sspbh
where 1=1  ; 

-- drop table #Base_1
select   a.*,ISNULL(b.CURR_STOCK,0)  nkcsl into #Base_1 from #Base_sp a
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK  b
     on   a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
where 1=1 ;

-- 进出数据 drop table #2
select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #2
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
where 1=1  and a.dsj>=convert(date,'2022-01-01') 
and  a.dsj<convert(date,GETDATE()) 
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;

-- 销售数据 drop table #Tmp_xs1
select a.*,ceiling(datediff(HOUR,b.Bdate,a.sale_date)*1.0/240)*10 nxsqj into #Tmp_xs1 from #Tmp_xs a
join #Base_1 b on a.SHOP_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
    and a.sale_date>b.Bdate
where 1=1  ;

select * from #tmp_xs1

-- 促销信息 drop table #Tmp_cx
select sdh,sFdbh,sspbh,Bdate,Edate,nLsj,nCxj,TJD_NCXJ,TJD_NJJ,CreateDate,CloseDate
into #Tmp_cx from DAppSource.dbo.tmp_Promotion
where  1=1 and CreateDate>=convert(date,'2022-01-01') 
and CreateDate<convert(date,getdate()) and sfdbh in ('018329','012006','018389','012007') ;

-- 推算库存  drop table #Tmp_qckc 
with x0 as( 
select a.shop_code sfdbh,a.item_code sspbh,SUM(qty) nxssl 
	from #Tmp_xs1 a group by a.shop_code  ,a.item_code )
,x1 as (select a.sfdbh,a.sspbh,SUM(nsl) njcsl,MAX(a.dsj) max_jcsj
, SUM( case when sjcfl IN ('损溢','盘点') then nsl else 0 end ) nshsl
,SUM( case when sjcfl IN ('调入(店间调拨)','调出','退配') then nsl else 0 end ) ndbsl
 from #2 a  group by sfdbh,sspbh)
select a.sfdbh,a.sspbh,a.nkcsl,b.nxssl,c.njcsl,c.max_jcsj,c.nshsl,c.ndbsl
, a.nkcsl+ISNULL(b.nxssl,0)-ISNULL(c.njcsl,0) nqckc into #Tmp_qckc  from #Base_1 a
left join x0 b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
left join x1 c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh
where 1=1;

-- 使用历史日结库存
  select c_store_id sfdbh,c_gcode sspbh,c_number nkcsl into #Tmp_mdkc   from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date=to_date(''2022-01-01'',''yyyy/mm/dd'' )');

select * from #Tmp_qckc a
left join  #Tmp_mdkc  b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh
where a.nqckc>0 and b.nkcsl is null
-- 
with xs as (select 
b.shop_code sfdbh,b.item_code sspbh,SUM(b.SUBTOTAL-b.DISCOUNT) nxsje,
SUM(b.QTY) nxssl,SUM(b.QTY*b.INPUT_PRICE) ncb,
SUM(b.SUBTOTAL-b.DISCOUNT)-SUM(b.QTY*b.INPUT_PRICE) nml,
SUM(b.QTY*b.UNIT_PRICE) nyqxse,MAX(sale_date) max_xssj
	from #Tmp_xs1 b group by b.shop_code  ,b.item_code 
),
cx as (select sfdbh,sspbh,bdate,edate,nlsj,ncxj,
case when nlsj=0 then ''  when  ncxj*1.0/nlsj>=0.5 then 'cg'  when ncxj*1.0/nlsj>=0.1 and  ncxj*1.0/nlsj<0.5
then '半价' else '一折' end scxfa  from #Tmp_cx  )
,cx1 as (select sfdbh,sspbh,COUNT(distinct scxfa) nfas from cx group by sfdbh,sspbh)
select a.sfdbh,a.sspbh,a.sspmc,a.splbh,a.spsfs,a.Stop_into,a.Stop_sale,
a.njj,a.nsj,a.njj*isnull(e.nkcsl,0) nkcje,
a.Return_attribute,a.c_disuse_date,a.Display_mode,
DATEDIFF(DAY,a.c_disuse_date,GETDATE()) nts,isnull(e.nkcsl,0) nqckc,c.njcsl,c.ndbsl,b.nxssl,
a.nKcsl,c.max_jcsj,b.max_xssj,b.nxsje,b.nml,b.nyqxse,b.ncb,d.nfas,
case when c.nshsl<0 then c.nshsl else 0 end *a.njj nshje,
case when b.nxsje<>0 then b.nml/b.nxsje end nmll into #r  from #Base_1 a
left join xs b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
left join #tmp_qckc c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh
left join cx1 d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh
left join #Tmp_mdkc  e on a.sFdbh=e.sfdbh and a.sSpbh=e.sspbh
where 1=1;
-- drop table #r

-- 已完成的
select  *  from #r where nKcsl=0

-- 已完成处理较快的，根据时间和进价筛选

select sfdbh, COUNT(1) nts,SUM(case when nkcsl=0 then 1 else 0 end ) ,
COUNT(1)-SUM(case when nkcsl=0 then 1 else 0 end ),SUM(nkcje) nkcje,
sum(nkcje)+sum(case when isnull(ndbsl,0)>=0 then 0 else ndbsl*njj end) ndb ,SUM(nKcsl*njj) ndqkcje
,SUM(ABS( nshje)) ,SUM(nxsje) nxsje,SUM(ncb) nxscb,SUM(nml),
SUM(nml)/SUM(nxsje) nxsmll,SUM(nyqxse) nyqxsje  from #r   group by sfdbh with cube


select * from #tmp_xs where item_code='59290072'

select a.sfdbh,b.门店名称,b.区域,a.sspbh,sspmc,splbh,spsfs,b.部门,
case when  stop_into='N' then '否' else '是' end stop_into,
case when  Stop_sale='N' then '否' else '是' end Stop_sale,njj,nsj,nkcje,nkcsl*njj ndqkcje
,Return_attribute,
c_disuse_date,Display_mode,nts,nqckc,njcsl,nxssl,nkcsl,max_jcsj,max_xssj,nxsje,ncb,
nml,nyqxse,nfas,nshje,nmll,nsjzk from #r a
left join Tmp_clkc_dr b on  a.sfdbh=b.机构代码 and a.sspbh=b.商品编码
where 1=1 order by  1,2

-- 有两种以上促销方案统计
select sfdbh, COUNT(1) nts,SUM(case when nfas<1 then 1 else 0 end ),
SUM(case when nfas=1 then 1 else 0 end ) ,
SUM(case when nfas>1 then 1 else 0 end )
  from #r   group by sfdbh with cube


select sfdbh,isnull(nsjzk,'无实际销售') ,COUNT(1) nxssps,SUM(nxssl) nxssl,SUM(nxsje) nxssje,SUM(nml) nml,
case when   sum(nxsje)<>0 then SUM(nml)/SUM(nxsje) end 
  from #r group by  sfdbh,isnull(nsjzk,'无实际销售') with cube
  order  by 1,2 desc;
  
  -- drop table #s1
  select b.*,(b.SUBTOTAL-b.DISCOUNT)/b.qty  nsjsj into #s1
	from #Tmp_xs1 b  
	
select  isnull(shop_code,'合计') sfdbh,case when qty*unit_price<>0 and   nsjsj/unit_price<0.1 then '1折以下'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.1 and nsjsj/unit_price<0.2 then '1折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.2 and nsjsj/unit_price<0.3 then '2折' 
   when qty*unit_price<>0 and nsjsj/unit_price>=0.3 and nsjsj/unit_price<0.4 then '3折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.4 and nsjsj/unit_price<0.5 then '4折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.5 and nsjsj/unit_price<0.6  then '5折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.6 and nsjsj/unit_price<0.7  then '6折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.7 and nsjsj/unit_price<0.8  then '7折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.8 and nsjsj/unit_price<0.9  then '8折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.9 and nsjsj/unit_price<1  then '9折'
   when qty*unit_price<>0 and   nsjsj/unit_price>=1 then '原价'
    end nsjzk ,COUNT(distinct item_code) nsps,SUM(SUBTOTAL-DISCOUNT) nxsje,SUM(qty) nxssl
   ,sum(qty*input_price) nxscb,sum(qty*unit_price) nyqxse into #s2  from #s1
     group by isnull(shop_code,'合计'),
   case when qty*unit_price<>0 and   nsjsj/unit_price<0.1 then '1折以下'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.1 and nsjsj/unit_price<0.2 then '1折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.2 and nsjsj/unit_price<0.3 then '2折' 
   when qty*unit_price<>0 and nsjsj/unit_price>=0.3 and nsjsj/unit_price<0.4 then '3折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.4 and nsjsj/unit_price<0.5 then '4折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.5 and nsjsj/unit_price<0.6  then '5折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.6 and nsjsj/unit_price<0.7  then '6折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.7 and nsjsj/unit_price<0.8  then '7折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.8 and nsjsj/unit_price<0.9  then '8折'
   when qty*unit_price<>0 and nsjsj/unit_price>=0.9 and nsjsj/unit_price<1  then '9折'
   when qty*unit_price<>0 and   nsjsj/unit_price>=1 then '原价'
    end    with cube 
     order by sfdbh,CHARINDEX(2,'原价,9折,8折,7折,6折,5折,4折,3折,2折,1折,1折以下');
    
    with x0 as (
     select *,sum(nxsje) over(partition by sfdbh) nljxse,
     row_number()over(partition by sfdbh 
     order by CHARINDEX(nsjzk,'原价,9折,8折,7折,6折,5折,4折,3折,2折,1折,1折以下')) npm
     from #s2  
     where nsjzk is not null )
     select  a.*    from x0  a 
      order by sfdbh, a.npm

----- 2022-04-14 版本
/*
 进出是不看的
 进度衡量？
*/
-- Step 1: 基础数据准备
select * into #Tmp_mdsp from DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT
where DEPT_CODE in ('018329','018389','012006','012007');

select * into #goods from DappSource_Dw.dbo.goods

select * into #Tmp_fdb from DappSource_Dw.dbo.Tmp_FDB;
Select * into #Tmp_spflb from DappSource_Dw.dbo.Tmp_spflb

-- drop table #Tmp_xs
select a.* into #Tmp_xs from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT  a
where 1=1  and a.SALE_DATE>='2022-01-01' and a.SALE_DATE<'2022-04-15'
and a.SHOP_CODE in ('018329','012006','018389','012007');


select * into #Tmp_de from  DappSource_Dw.dbo.sys_deliveryset 
where sfdbh in ('018329','012006','018389','012007');



-- Step 2: 处理批次
select '1月' smonth,convert(date,'2022-01-01') Bdate into #Tmp_time union
select '2月' smonth,convert(date,'2022-02-01') 

-- Step 3:基础数据准备
-- drop table #1;
select a.机构代码 sFdbh,a.门店名称 sFdmc,a.商品编码 sSpbh,a.商品名称 sSpmc,c.smonth,c.Bdate,
b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode  into #1 
from  DappSource_Dw.dbo.tmp_clkc_dr a 
left join #Tmp_mdsp b on b.DEPT_CODE=a.机构代码 and b.ITEM_CODE=a.商品编码
left join #Tmp_time c on a.清理计划时间=c.smonth
where DEPT_CODE in ('018329','018389','012006','018425','012007') and  a.清理计划时间='2月' ;

-- drop table #Base_sp
select a.*,d.sort sPlbh into #Base_sp
from #1 a
left join #goods d on a.sSpbh=d.code
where 1=1  ; 

-- drop table #Base_1
select   a.*,ISNULL(b.CURR_STOCK,0)  nkcsl into #Base_1 from #Base_sp a
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK  b
     on   a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
where 1=1 ;



-- 销售数据 drop table #Tmp_xs1
select a.*,ceiling(datediff(HOUR,b.Bdate,a.sale_date)*1.0/240)*10 nxsqj into #Tmp_xs1
from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT a
join #Base_1 b on a.SHOP_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
    and a.sale_date>b.Bdate 
where 1=1  ;

select * from #tmp_xs1

-- 促销信息 drop table #Tmp_cx
select sdh,sFdbh,sspbh,Bdate,Edate,nLsj,nCxj,TJD_NCXJ,TJD_NJJ,CreateDate,CloseDate
into #Tmp_cx from DAppSource.dbo.tmp_Promotion
where  1=1 and CreateDate>=convert(date,'2022-01-01') 
and CreateDate<convert(date,getdate()) and sfdbh in ('018329','012006','018389','012007') ;

-- 推算库存  drop table #Tmp_qckc 
with x0 as( 
select a.shop_code sfdbh,a.item_code sspbh,SUM(qty) nxssl 
	from #Tmp_xs1 a group by a.shop_code  ,a.item_code )
,x1 as (select a.sfdbh,a.sspbh,SUM(nsl) njcsl,MAX(a.dsj) max_jcsj
, SUM( case when sjcfl IN ('损溢','盘点') then nsl else 0 end ) nshsl
,SUM( case when sjcfl IN ('调入(店间调拨)','调出','退配') then nsl else 0 end ) ndbsl
 from #2 a  group by sfdbh,sspbh)
select a.sfdbh,a.sspbh,a.nkcsl,b.nxssl,c.njcsl,c.max_jcsj,c.nshsl,c.ndbsl
, a.nkcsl+ISNULL(b.nxssl,0)-ISNULL(c.njcsl,0) nqckc into #Tmp_qckc  from #Base_1 a
left join x0 b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
left join x1 c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh
where 1=1;

-- 使用历史日结库存
  select c_store_id sfdbh,c_gcode sspbh,c_number nkcsl into #Tmp_mdkc   from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date=to_date(''2022-02-01'',''yyyy/mm/dd'' )');

select * from #Tmp_xs1
-- 
with xs as (select 
b.shop_code sfdbh,b.item_code sspbh,SUM(b.SUBTOTAL-b.DISCOUNT) nxsje,
SUM(b.QTY) nxssl,SUM(b.QTY*b.INPUT_PRICE) ncb,
SUM(b.SUBTOTAL-b.DISCOUNT)-SUM(b.QTY*b.INPUT_PRICE) nml,
SUM(b.QTY*b.UNIT_PRICE) nyqxse,MAX(sale_date) max_xssj
	from #Tmp_xs1 b group by b.shop_code  ,b.item_code 
),
cx as (select sfdbh,sspbh,bdate,edate,nlsj,ncxj,
case when nlsj=0 then ''  when  ncxj*1.0/nlsj>=0.5 then 'cg'  when ncxj*1.0/nlsj>=0.1 and  ncxj*1.0/nlsj<0.5
then '半价' else '一折' end scxfa  from #Tmp_cx  )
,cx1 as (select sfdbh,sspbh,COUNT(distinct scxfa) nfas from cx group by sfdbh,sspbh)
select a.sfdbh,a.sspbh,a.sspmc,a.splbh,a.spsfs,a.Stop_into,a.Stop_sale,
a.njj,a.nsj,a.njj*isnull(e.nkcsl,0) nkcje,
a.Return_attribute,a.c_disuse_date,a.Display_mode,
DATEDIFF(DAY,a.c_disuse_date,GETDATE()) nts,isnull(e.nkcsl,0) nqckc,c.njcsl,c.ndbsl,b.nxssl,
a.nKcsl,c.max_jcsj,b.max_xssj,b.nxsje,b.nml,b.nyqxse,b.ncb,d.nfas,
case when c.nshsl<0 then c.nshsl else 0 end *a.njj nshje,
case when b.nxsje<>0 then b.nml/b.nxsje end nmll into #r  from #Base_1 a
left join xs b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
left join #tmp_qckc c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh
left join cx1 d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh
left join #Tmp_mdkc  e on a.sFdbh=e.sfdbh and a.sSpbh=e.sspbh
where 1=1;
-- drop table #r

-- 已完成的
select  *  from #r where nKcsl=0

-- 已完成处理较快的，根据时间和进价筛选

select sfdbh, COUNT(1) nts,SUM(case when nkcsl=0 then 1 else 0 end ) ,
COUNT(1)-SUM(case when nkcsl=0 then 1 else 0 end ),SUM(nkcje) nkcje,
sum(nkcje)+sum(case when isnull(ndbsl,0)>=0 then 0 else ndbsl*njj end) ndb ,SUM(nKcsl*njj) ndqkcje
,SUM(ABS( nshje)) ,SUM(nxsje) nxsje,SUM(ncb) nxscb,SUM(nml),
SUM(nml)/SUM(nxsje) nxsmll,SUM(nyqxse) nyqxsje  from #r   group by sfdbh with cube


select * from #tmp_xs where item_code='59290072'

select a.sfdbh,b.门店名称,b.区域,a.sspbh,sspmc,splbh,spsfs,b.部门,
case when  stop_into='N' then '否' else '是' end stop_into,
case when  Stop_sale='N' then '否' else '是' end Stop_sale,njj,nsj,nkcje,nkcsl*njj ndqkcje
,Return_attribute,
c_disuse_date,Display_mode,nts,nqckc,njcsl,nxssl,nkcsl,max_jcsj,max_xssj,nxsje,ncb,
nml,nyqxse,nfas,nshje,nmll,nsjzk from #r a
left join Tmp_clkc_dr b on  a.sfdbh=b.机构代码 and a.sspbh=b.商品编码
where 1=1 order by  1,2

-- 有两种以上促销方案统计
select sfdbh, COUNT(1) nts,SUM(case when nfas<1 then 1 else 0 end ),
SUM(case when nfas=1 then 1 else 0 end ) ,
SUM(case when nfas>1 then 1 else 0 end )
  from #r   group by sfdbh with cube


select sfdbh,isnull(nsjzk,'无实际销售') ,COUNT(1) nxssps,SUM(nxssl) nxssl,SUM(nxsje) nxssje,SUM(nml) nml,
case when   sum(nxsje)<>0 then SUM(nml)/SUM(nxsje) end 
  from #r group by  sfdbh,isnull(nsjzk,'无实际销售') with cube
  order  by 1,2 desc;



-------------- 04-15 版本
/*
实际销售价和区间？

*/
-- 不同的价格对应不同的销售数据

-- Step 1: 基础数据准备
select * into #Tmp_mdsp from DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT
where DEPT_CODE in ('018329','018389','012006','012007');

select * into #goods from DappSource_Dw.dbo.goods

select * into #Tmp_fdb from DappSource_Dw.dbo.Tmp_FDB;
Select * into #Tmp_spflb from DappSource_Dw.dbo.Tmp_spflb

-- drop table #Tmp_xs
select a.* into #Tmp_xs from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT  a
where 1=1  and a.SALE_DATE>='2022-02-01' and a.SALE_DATE<'2022-04-15'
and a.SHOP_CODE in ('018329','012006','018389','012007');


select * into #Tmp_de from  DappSource_Dw.dbo.sys_deliveryset 
where sfdbh in ('018329','012006','018389','012007');



-- Step 2: 处理批次 drop table #Tmp_time 
select '1月' smonth,convert(date,'2022-01-01') Bdate,CONVERT(date,'2022-04-01') edate into #Tmp_time union
select '2月' smonth,convert(date,'2022-02-01') ,CONVERT(date,'2022-05-01')
union
select '3月' smonth,convert(date,'2022-03-01') ,CONVERT(date,'2022-06-01')
union
select '4月' smonth,convert(date,'2022-04-01') ,CONVERT(date,'2022-07-01')
;

-- Step 3:基础数据准备
-- drop table #1;  
select *  into #Tmp_1 from DappSource_Dw.dbo.Tmp_dr_0419

select a.机构代码 sFdbh,a.门店名称 sFdmc,a.商品编码 sSpbh,a.商品名称 sSpmc,c.smonth,c.Bdate,c.edate,
b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode  into #1 
from  DappSource_Dw.dbo.tmp_clkc_dr a 
left join #Tmp_mdsp b on b.DEPT_CODE=a.机构代码 and b.ITEM_CODE=a.商品编码
left join #Tmp_time c on a.清理计划时间=c.smonth
where DEPT_CODE in ('018329','018389','012006','018425','012007') and  a.清理计划时间='2月' ;

-- drop table #Base_sp
select a.*,d.sort sPlbh into #Base_sp
from #1 a
left join #goods d on a.sSpbh=d.code
where 1=1  ; 

-- drop table #Base_1
select   a.*,ISNULL(b.CURR_STOCK,0)  nkcsl into #Base_1 from #Base_sp a
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK  b
     on   a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
where 1=1 ;



-- 销售数据 drop table #Tmp_xs1
select a.*,ceiling(datediff(HOUR,b.Bdate,a.sale_date)*1.0/240)*10 nxsqj into #Tmp_xs1
from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT a
join #Base_1 b on a.SHOP_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
    and a.sale_date>=b.Bdate and a.SALE_DATE<GETDATE()
where 1=1  ;

select * from #tmp_xs1

-- -- 促销信息 drop table #Tmp_cx
-- select sdh,sFdbh,sspbh,Bdate,Edate,nLsj,nCxj,TJD_NCXJ,TJD_NJJ,CreateDate,CloseDate
-- into #Tmp_cx from DAppSource.dbo.tmp_Promotion
-- where  1=1 and CreateDate>=convert(date,'2022-01-01') 
-- and CreateDate<convert(date,getdate()) and sfdbh in ('018329','012006','018389','012007') ;

-- -- 推算库存  drop table #Tmp_qckc 
-- with x0 as( 
-- select a.shop_code sfdbh,a.item_code sspbh,SUM(qty) nxssl 
-- 	from #Tmp_xs1 a group by a.shop_code  ,a.item_code )
-- ,x1 as (select a.sfdbh,a.sspbh,SUM(nsl) njcsl,MAX(a.dsj) max_jcsj
-- , SUM( case when sjcfl IN ('损溢','盘点') then nsl else 0 end ) nshsl
-- ,SUM( case when sjcfl IN ('调入(店间调拨)','调出','退配') then nsl else 0 end ) ndbsl
--  from #2 a  group by sfdbh,sspbh)
-- select a.sfdbh,a.sspbh,a.nkcsl,b.nxssl,c.njcsl,c.max_jcsj,c.nshsl,c.ndbsl
-- , a.nkcsl+ISNULL(b.nxssl,0)-ISNULL(c.njcsl,0) nqckc into #Tmp_qckc  from #Base_1 a
-- left join x0 b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
-- left join x1 c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh
-- where 1=1;

-- 使用历史日结库存
  select  c_day_date drq, c_store_id sfdbh,c_gcode sspbh,c_number nkcsl into #Tmp_mdkc   from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date in ( to_date(''2022-02-01'',''yyyy/mm/dd'' ),to_date(''2022-03-01'',''yyyy/mm/dd'' ))');


-- xs1 drop table #
select b.smonth, a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1) nxsjg,sum(a.QTY) nxssl
into #Tmp_xs_hz from
 #Tmp_xs1 a, #Tmp_time b
 where  1=1 and convert(date,a.sale_date)>=b.Bdate and convert(date,a.sale_date)<=b.edate 
 and a.QTY>0
   group by b.smonth, a.SHOP_CODE  ,a.ITEM_CODE  ,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1)
 order by 1,2, 4 desc;

  

 select b.smonth, a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,a.SALE_DATE,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1) nxsjg,
 ROW_NUMBER()over(partition by a.shop_code,a.item_code order by a.sale_date desc) npm into #Tmp_lastxs  from
 #Tmp_xs1 a, #Tmp_time b
 where  1=1 and convert(date,a.sale_date)>=b.Bdate and convert(date,a.sale_date)<=b.edate 
 and a.QTY>0;
 -- drop table #r
 with x0 as(
 select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.nxssl desc) npm from #Tmp_xs_hz a
),x1 as (select a.sFdbh,a.sSpbh,min(nxsjg) nzdxsj,sum(a.nxssl) nzxssl  from #Tmp_xs_hz  a group by a.sFdbh,a.sSpbh )
select a.smonth,a.Bdate,a.edate,a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,a.njj,a.nsj,a.spsfs,a.nPsbzs,
a.sPlbh,b.nkcsl nQckc,a.nkcsl ndqkcsl,a.STOP_INTO,a.DISPLAY_MODE,DATEDIFF(day,GETDATE(),a.edate) nsysj
,DATEDIFF(DAY,a.Bdate,CONVERT(date,GETDATE())) ngcsj,c.nxsjg nxsj_maxxl,d.nzxssl,d.nzdxsj,e.nxsjg nxsjg_last,e.SALE_DATE drq_last
 into #r  from #Base_1 a 
left join #Tmp_mdkc b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh 
left  join x0 c on a.sfdbh=c.sfdbh and a.sSpbh=c.sSpbh and c.npm=1  
left join x1 d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh 
left join #Tmp_lastxs e on a.sFdbh=e.sFdbh and a.sSpbh=e.sSpbh and e.npm=1
where 1=1 ;


select *,case when a.STOP_INTO='N' then '状态开通,请核查！'
  when ISNULL(a.ndqkcsl,0)=0 and  a.STOP_INTO<>'N'  then '已清退'
  when ISNULL(a.ndqkcsl,0)<0 and  a.STOP_INTO<>'N'  then '负库存'
  when ISNULL(a.ndqkcsl,0)>0 and  a.STOP_INTO<>'N'  then '未完成' end sflag1,
  case  when  ISNULL(a.ndqkcsl,0)>0 and  a.STOP_INTO<>'N' then 
			 case  
          when ISNULL(a.nzxssl,0)<=0 then 
					  case
              when a.nsysj>=50 and a.nsysj<70 then '建议5折销售'
              when a.nsysj>=30 and a.nsysj<50 then '建议3折销售' 
              else '建议标签售价的一折出清'
            end
		      when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj*0.9  then '建议'+left(CONVERT(varchar,a.nxsj_maxxl),5)+'销售'  
				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj*0.9 and a.nsysj>=30 
				    and a.nxsj_maxxl>=a.nsj*0.2  then '建议加大力度'
				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj*0.9  
				    and a.nxsj_maxxl<a.nsj*0.2  then '建议标签售价的一折出清'  
				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj*0.9 and a.nsysj<30
					  and a.nxsj_maxxl>=a.nsj*0.2  then '建议2折销售'
				  when a.nsysj<=0 then '0.01元出清'
		end  
  end       from #r a  order by smonth,a.sfdbh,a.sspbh
  /*
  说明
      给出两种状态：一个是当前处理的实际情况，一种是未处理完的下一步建议
      当前实际
            已清退：指状态已关闭，且当前库存量为0
            负库存：状态已关闭，但当前库存为负
            状态开通：指在清退计划单中，但是目前是可进状态，当作完成了
            未完成：状态已关，但当前有库存
      未完成商品下一步建议，需要加一个库存衡量
        1、开始至当前无销售的
          1.1 剩余天数>-70天，建议当前促销价销售
          1.2 剩余时间>50天，小于70天——执行20天后，建议5折销售：就是说卖了20天没有卖动，直接5折；
          1.3 剩余时间>=30天，小于50天，建议降价：就是说可能5折也没卖动，再降价，3折
          1.4 剩余时间不足30天，原售价2折出清
        2、方案执行后有销售的  
          2.1 有销售，且按促销期实际日结周转天数低于剩余天数—按当前促销价执行
          2.2 有销售，但剩余天数不足以售完，但剩余天数超过30天，建议梯次降价
          2.3 有销售，但剩余天数不足以售完，且剩余天数小于30天，建议2折
          2.5 超出截止日期的  0.01元出清
          剩余时间提前10天，比如总周期为90天，但剩余库存周转超过80天就当做不足以售完
          周转计算：剩余库存/(促销开始后销量/经过的时间)
  */

------- v0419
-- Step 1: 基础数据准备

-- drop table #Tmp_xs

-- Step 2: 处理批次 drop table #Tmp_time 
select '1月' smonth,convert(date,'2022-01-01') Bdate,CONVERT(date,'2022-04-01') edate into #Tmp_time union
select '2月' smonth,convert(date,'2022-02-01') ,CONVERT(date,'2022-05-01')
union
select '3月' smonth,convert(date,'2022-03-01') ,CONVERT(date,'2022-06-01')
union
select '4月' smonth,convert(date,'2022-04-01') ,CONVERT(date,'2022-07-01')
;

select '1月' smonth,convert(date,'2022-01-01') Bdate,dateadd(day,-1,CONVERT(date,'2022-04-01')) edate into #Tmp_time union
select '2月' smonth,convert(date,'2022-02-01') ,dateadd(day,-1,CONVERT(date,'2022-05-01'))
union
select '3月' smonth,convert(date,'2022-03-01') ,dateadd(day,-1,CONVERT(date,'2022-06-01'))
union
select '4月' smonth,convert(date,'2022-04-01') ,dateadd(day,-1,CONVERT(date,'2022-07-01'))
;
 
-- Step 3:基础数据准备
select *  into #Tmp_1 from DappSource_Dw.dbo.Tmp_dr_0419

-- drop table #1;  
select  a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,c.smonth,c.Bdate,c.edate,
b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode  into #1 
from  #Tmp_1 a 
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on b.DEPT_CODE=a.sfdbh and b.ITEM_CODE=a.sspbh
left join #Tmp_time c on a.清理计划时间=c.smonth
where  1=1   ;

-- drop table #Base_sp
select a.*,d.sort sPlbh into #Base_sp
from #1 a
left join  DappSource_Dw.dbo.goods d on a.sSpbh=d.code
where 1=1  ; 

-- drop table #Base_1
select   a.*,ISNULL(b.CURR_STOCK,0)  nkcsl into #Base_1 from #Base_sp a
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK  b
     on   a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
where 1=1 ;



-- 销售数据 drop table #Tmp_xs1
select a.*,ceiling(datediff(HOUR,b.Bdate,a.sale_date)*1.0/240)*10 nxsqj into #Tmp_xs1
from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT a
join #Base_1 b on a.SHOP_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
    and a.sale_date>=b.Bdate and a.SALE_DATE<GETDATE()
where 1=1  ;

-- -- 促销信息 drop table #Tmp_cx
-- select sdh,sFdbh,sspbh,Bdate,Edate,nLsj,nCxj,TJD_NCXJ,TJD_NJJ,CreateDate,CloseDate
-- into #Tmp_cx from DAppSource.dbo.tmp_Promotion
-- where  1=1 and CreateDate>=convert(date,'2022-01-01') 
-- and CreateDate<convert(date,getdate()) and sfdbh in ('018329','012006','018389','012007') ;



-- 使用历史日结库存 drop table   #Tmp_mdkc
  select c_day_date drq, c_store_id sfdbh,c_gcode sspbh,c_number nkcsl into #Tmp_mdkc   from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date in ( to_date(''2022-02-01'',''yyyy/mm/dd'' ), to_date(''2022-03-01'',''yyyy/mm/dd'' ), to_date(''2022-04-01'',''yyyy/mm/dd'' )    )');


-- xs1 drop table #Tmp_xs_hz
select b.smonth, a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1) nxsjg,sum(a.QTY) nxssl
into #Tmp_xs_hz from
 #Tmp_xs1 a, #Tmp_time b
 where  1=1 and convert(date,a.sale_date)>=b.Bdate and convert(date,a.sale_date)<=b.edate 
 and a.QTY>0
   group by b.smonth, a.SHOP_CODE  ,a.ITEM_CODE  ,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1)
 order by 1,2, 4 desc;


 select b.smonth, a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,a.SALE_DATE,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1) nxsjg,
 ROW_NUMBER()over(partition by b.smonth, a.shop_code,a.item_code order by a.sale_date desc) npm into #Tmp_lastxs  from
 #Tmp_xs1 a, #Tmp_time b
 where  1=1 and convert(date,a.sale_date)>=b.Bdate and convert(date,a.sale_date)<=b.edate 
 and a.QTY>0;

 -- drop table #r
 with x0 as(
 select a.*,ROW_NUMBER()over(partition by a.smonth, a.sfdbh,a.sspbh order by a.nxssl desc) npm from #Tmp_xs_hz a
),x1 as (select a.smonth, a.sFdbh,a.sSpbh,min(nxsjg) nzdxsj,sum(a.nxssl) nzxssl  from #Tmp_xs_hz  a group by a.smonth, a.sFdbh,a.sSpbh )
select a.smonth,a.Bdate,a.edate,a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,a.njj,a.nsj,a.spsfs,a.nPsbzs,
a.sPlbh,b.nkcsl nQckc,a.nkcsl ndqkcsl,d.nzxssl,a.STOP_INTO,a.DISPLAY_MODE,DATEDIFF(day,GETDATE(),a.edate)-1 nsysj
,DATEDIFF(DAY,a.Bdate,CONVERT(date,GETDATE()))-1 ngcsj,c.nxsjg nxsj_maxxl,d.nzdxsj,e.nxsjg nxsjg_last,e.SALE_DATE drq_last
 into #r  from #Base_1 a 
left join #Tmp_mdkc b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh and a.Bdate=b.drq 
left  join x0 c on a.sfdbh=c.sfdbh and a.sSpbh=c.sSpbh and c.npm=1 and a.smonth=c.smonth  
left join x1 d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh  and a.smonth=d.smonth 
left join #Tmp_lastxs e on a.sFdbh=e.sFdbh and a.sSpbh=e.sSpbh and e.npm=1 and a.smonth=e.smonth
where 1=1 ;


-- select *,ngcsj/(ngcsj+nsysj) nsjjd,case when isnull(ndqkcsl,0)<=0 then 1
-- else isnull(nzxssl,0)/(isnull(nzxssl,0)+isnull(ndqkcsl,0))  end ,case when a.STOP_INTO='N' then '状态开通,请核查！'
--   when ISNULL(a.ndqkcsl,0)=0 and  a.STOP_INTO<>'N'  then '已清退'
--   when ISNULL(a.ndqkcsl,0)<0 and  a.STOP_INTO<>'N'  then '负库存'
--   when ISNULL(a.ndqkcsl,0)>0 and  a.STOP_INTO<>'N'  then '未完成' end sflag1,
--   case  when  ISNULL(a.ndqkcsl,0)>0 and  a.STOP_INTO<>'N' then 
-- 			 case  
--           when ISNULL(a.nzxssl,0)<=0 then 
-- 					  case
--               when a.nsysj>=70 then ''
--               when a.nsysj>=50 and a.nsysj<70 then '建议5折销售'
--               when a.nsysj>=30 and a.nsysj<50 then '建议3折销售' 
--               else '建议标签售价的2折出清'
--             end
-- 		      when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj*0.9  then '建议'+left(CONVERT(varchar,a.nxsj_maxxl),5)+'销售'  
-- 				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj*0.9 and a.nsysj>=50 
-- 				    and a.nxsj_maxxl>=a.nsj*0.2  then '建议5折销售'
--           when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj*0.9 and a.nsysj>=30 
--           and a.nsysj<50  and a.nxsj_maxxl>=a.nsj*0.2  then '建议3折销售'
-- 				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj*0.9   
-- 				    and a.nxsj_maxxl<a.nsj*0.2  then '建议标签售价的2折出清'  
--           -- when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj*0.9  and a.nsysj<30 
-- 				  --   and a.nxsj_maxxl<a.nsj*0.2  then '0.01元出清'  
-- 				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj*0.9 and a.nsysj<30
-- 					  and a.nxsj_maxxl>=a.nsj*0.2  then '建议标签售价的2折出清'
-- 				  when a.nsysj<=0 then '0.01元出清'
-- 		end  
--   end       from #r a  order by smonth,a.sfdbh,a.sspbh

--   select * from #Base_1


--   select *,ngcsj*1.0/(ngcsj+nsysj) nsjjd,case when isnull(ndqkcsl,0)<=0 then 1
-- else isnull(nzxssl,0)/(isnull(nzxssl,0)+isnull(ndqkcsl,0))  end ,case when a.STOP_INTO='N' then '状态开通,请核查！'
--   when ISNULL(a.ndqkcsl,0)=0 and  a.STOP_INTO<>'N'  then '已清退'
--   when ISNULL(a.ndqkcsl,0)<0 and  a.STOP_INTO<>'N'  then '负库存'
--   when ISNULL(a.ndqkcsl,0)>0 and  a.STOP_INTO<>'N'  then '未完成' end sflag1,
--   case  when  ISNULL(a.ndqkcsl,0)>0 and  a.STOP_INTO<>'N' then 
-- 			 case  
--           when ISNULL(a.nzxssl,0)<=0 then 
-- 					  case
-- 			when a.nsysj>=70 then '按当前方案执行'
--               when a.nsysj>=50 and a.nsysj<70 then '建议5折销售'
--               when a.nsysj>=30 and a.nsysj<50 then '建议3折销售' 
--               else '建议标签售价的2折出清'
--             end
-- 		      when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj-10  then '建议当前促销价销售'  
			
--           when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj*0.9 and a.nsysj>=30 
--             then '建议梯次降价' 
-- 				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj*0.9 and a.nsysj<30
-- 					  then '建议标签售价的2折出清'
-- 				  when a.nsysj<=0 then '0.01元出清'
-- 		end  
--   end       from #r a  order by smonth,a.sfdbh,a.sspbh


  select *,ngcsj*1.0/(ngcsj+nsysj) nsjjd,case when isnull(ndqkcsl,0)<=0 then 1
else isnull(nzxssl,0)/(isnull(nzxssl,0)+isnull(ndqkcsl,0))  end ,case when a.STOP_INTO='N' then '状态开通,请核查！'
  when ISNULL(a.ndqkcsl,0)=0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null)  then '已清退'
  when ISNULL(a.ndqkcsl,0)<0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)  then '负库存'
  when ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)   then '未完成' end sflag1,
  case  when  ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null) then 
			 case  
          when ISNULL(a.nzxssl,0)<=0 then 
					  case
			when a.nsysj>=70 then '按当前方案执行'
              when a.nsysj>=50 and a.nsysj<70 then '建议5折销售'
              when a.nsysj>=30 and a.nsysj<50 then '建议3折销售' 
              else '建议标签售价的2折出清'
            end
		      when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj-10  then '建议当前促销价销售'  
			
          when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and a.nsysj>=30 
            then '建议梯次降价' 
				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and a.nsysj<30
					  then '建议标签售价的2折出清'
				  when a.nsysj<=0 then '0.01元出清'
		end  
  end       from #r a where 1=1  order by smonth,a.sfdbh,a.sspbh


  ---------------------------------------- 分割线--------------------------------------------
  ----------- V4.25版


-- drop table #Tmp_xs
select a.* into #Tmp_xs from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT  a
where 1=1  and a.SALE_DATE>='2022-02-01' and a.SALE_DATE<GETDATE();


select * into #Tmp_de from  DappSource_Dw.dbo.sys_deliveryset 
where sfdbh in ('018329','012006','018389','012007');


-- Step 2: 处理批次 drop table #Tmp_time 
select '1月' smonth,convert(date,'2022-01-01') Bdate,dateadd(day,-1,CONVERT(date,'2022-04-01')) edate into #Tmp_time union
select '2月' smonth,convert(date,'2022-02-01') ,dateadd(day,-1,CONVERT(date,'2022-05-01'))
union
select '3月' smonth,convert(date,'2022-03-01') ,dateadd(day,-1,CONVERT(date,'2022-06-01'))
union
select '4月' smonth,convert(date,'2022-04-01') ,dateadd(day,-1,CONVERT(date,'2022-07-01'))
;
 
-- Step 3:基础数据准备
select *  into #Tmp_1 from DappSource_Dw.dbo.Tmp_dr_0419

-- drop table #1;  
select  a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,c.smonth,c.Bdate,c.edate,
b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode  into #1 
from  #Tmp_1 a 
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on b.DEPT_CODE=a.sfdbh and b.ITEM_CODE=a.sspbh
left join #Tmp_time c on a.清理计划时间=c.smonth
where  1=1  and a.sFdbh<>'015901'  ;

-- drop table #Base_sp
select a.*,d.sort sPlbh into #Base_sp
from #1 a
left join  DappSource_Dw.dbo.goods d on a.sSpbh=d.code
where 1=1  ; 

-- drop table #Base_1
select   a.*,ISNULL(b.CURR_STOCK,0)  nkcsl into #Base_1 from #Base_sp a
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK  b
     on   a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
where 1=1 ;



-- 销售数据 drop table #Tmp_xs1
select a.*,ceiling(datediff(HOUR,b.Bdate,a.sale_date)*1.0/240)*10 nxsqj into #Tmp_xs1
from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT a
join #Base_1 b on a.SHOP_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
    and a.sale_date>=b.Bdate and a.SALE_DATE<GETDATE()
where 1=1  ;

-- -- 促销信息 drop table #Tmp_cx

 select sdh,sFdbh,sspbh,Bdate,Edate,nLsj,nCxj,TJD_NCXJ,TJD_NJJ,CreateDate,CloseDate,sZt,adate
 into #Tmp_cx from  [122.147.10.200].DappSource.dbo.tmp_Promotion
 where  1=1 and CONVERT(date,a.Edate)>=convert(date,'2022-02-01') 
   ;

 -- drop table #tmp_cxgx
select a.sFdbh,a.sspbh,a.smonth,b.bdate,b.edate,b.nlsj,b.ncxj,b.szt
,b.adate,ROW_NUMBER()over(partition by a.smonth,a.sfdbh,a.sspbh
order by convert(date,b.aDate) desc) npm into #tmp_cxgx from #Base_1 a 
left join #Tmp_cx b on a.sFdbh=b.sfdbh and a.sspbh=b.sspbh 
and b.szt not in ('已结束','已作废')
and CONVERT(date,b.Edate)>=CONVERT(date,a.Bdate)   
where 1=1 


 -- drop table #tmp_cxgx1
select a.sFdbh,a.sspbh,a.smonth,b.bdate,b.edate,b.nlsj,b.ncxj,b.szt
,b.adate,ROW_NUMBER()over(partition by a.smonth,a.sfdbh,a.sspbh
order by convert(date,b.aDate) desc) npm into #tmp_cxgx from #Base_1 a 
left join #Tmp_cx b on a.sFdbh=b.sfdbh and a.sspbh=b.sspbh 
-- and b.szt not in ('已结束','已作废')
and CONVERT(date,b.Edate)>=CONVERT(date,a.Bdate)   
where 1=1 

select * from #tmp_cxgx a where npm=1 order by smonth


-- 使用历史日结库存 drop table   #Tmp_mdkc
select c_day_date drq, c_store_id sfdbh,c_gcode sspbh,c_number nkcsl into #Tmp_mdkc   from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date in ( to_date(''2022-02-01'',''yyyy/mm/dd'' ), to_date(''2022-03-01'',''yyyy/mm/dd'' ), to_date(''2022-04-01'',''yyyy/mm/dd'' )    )');


-- xs1 drop table #Tmp_xs_hz
select b.smonth, a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1) nxsjg,sum(a.QTY) nxssl
into #Tmp_xs_hz from
 #Tmp_xs1 a, #Tmp_time b
 where  1=1 and convert(date,a.sale_date)>=b.Bdate and convert(date,a.sale_date)<=b.edate 
 and a.QTY>0
   group by b.smonth, a.SHOP_CODE  ,a.ITEM_CODE  ,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1)
 order by 1,2, 4 desc;

 -- drop table #Tmp_lastxs 
 select b.smonth, a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,a.SALE_DATE,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1) nxsjg,
 ROW_NUMBER()over(partition by b.smonth, a.shop_code,a.item_code order by a.sale_date desc) npm into #Tmp_lastxs  from
 #Tmp_xs1 a, #Tmp_time b
 where  1=1 and convert(date,a.sale_date)>=b.Bdate and convert(date,a.sale_date)<=b.edate 
 and a.QTY>0;

--  -- drop table #r
--  with x0 as(
--  select a.*,ROW_NUMBER()over(partition by a.smonth, a.sfdbh,a.sspbh order by a.nxssl desc) npm from #Tmp_xs_hz a
-- ),x1 as (select a.smonth, a.sFdbh,a.sSpbh,min(nxsjg) nzdxsj,sum(a.nxssl) nzxssl  from #Tmp_xs_hz  a group by a.smonth, a.sFdbh,a.sSpbh )
-- select a.smonth,a.Bdate,a.edate,a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,a.njj,a.nsj,a.spsfs,a.nPsbzs,
-- a.sPlbh,b.nkcsl nQckc,a.nkcsl ndqkcsl,d.nzxssl,a.STOP_INTO,a.DISPLAY_MODE,DATEDIFF(day,GETDATE(),a.edate)-1 nsysj
-- ,DATEDIFF(DAY,a.Bdate,CONVERT(date,GETDATE()))-1 ngcsj,c.nxsjg nxsj_maxxl,d.nzdxsj,e.nxsjg nxsjg_last,e.SALE_DATE drq_last
-- ,f.ncxj into #r  from #Base_1 a 
-- left join #Tmp_mdkc b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh and a.Bdate=b.drq 
-- left  join x0 c on a.sfdbh=c.sfdbh and a.sSpbh=c.sSpbh and c.npm=1 and a.smonth=c.smonth  
-- left join x1 d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh  and a.smonth=d.smonth 
-- left join #Tmp_lastxs e on a.sFdbh=e.sFdbh and a.sSpbh=e.sSpbh and e.npm=1 and a.smonth=e.smonth
-- left join #tmp_cxgx f on a.sFdbh=f.sFdbh and a.sspbh=f.sspbh and f.npm=1
-- where 1=1 ;
-- select * from #r 

-- select *,ngcsj*1.0/(ngcsj+nsysj) nsjjd,case when isnull(ndqkcsl,0)<=0 then 1
-- else isnull(nzxssl,0)/(isnull(nzxssl,0)+isnull(ndqkcsl,0))  end ,case when a.STOP_INTO='N' then '状态开通,请核查！'
--   when ISNULL(a.ndqkcsl,0)=0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null)  then '已清退'
--   when ISNULL(a.ndqkcsl,0)<0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)  then '负库存'
--   when ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)   then '未完成' end sflag1,
--   case  when  ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null) then 
-- 			 case  
--           when ISNULL(a.nzxssl,0)<=0 then 
-- 					  case
-- 			when a.nsysj>=70 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.7 then '建议标签售价的7折销售' else  '建议当前促销价销售'   end 
--               when a.nsysj>=50 and a.nsysj<70 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.5 then '建议标签售价的5折销售' else  '建议当前促销价销售'   end 
--               when a.nsysj>=30 and a.nsysj<50 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.3 then '建议标签售价的3折销售' else  '建议当前促销价销售'   end 
--               else '建议标签售价的2折出清'
--             end
-- 		      when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj-10  then '建议当前促销价销售'  
-- 			-- 30 Days 
--           when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and a.nsysj>=70 
--             then case  when ISNULL(a.ncxj,0)>a.nsj*0.75 then '建议标签售价的7折销售' else  '建议当前促销价销售'   end 
-- 		when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and a.nsysj>=50 and a.nsysj<70 
--             then case  when ISNULL(a.ncxj,0)>a.nsj*0.55 then '建议标签售价的5折销售' else  '建议当前促销价销售'   end
-- 		when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and a.nsysj>=30 and a.nsysj<50 
--             then case  when ISNULL(a.ncxj,0)>a.nsj*0.35 then '建议标签售价的3折销售' else  '建议当前促销价销售'   end   
-- 				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and a.nsysj<30
-- 					  then '建议标签售价的2折出清'
-- 				  when a.nsysj<=0 then '0.01元出清'
-- 		end  
--   end       from #r a where 1=1  order by smonth,a.sfdbh,a.sspbh
  
--    select * from #Tmp_cx where sspbh='23022049' and sfdbh='018400'

   /*
   按时间进度
   时间进度	折扣率
    15%之内	8折
    15%-30%	7折
    30%-45%	6折
    45%-60%	5折
    60%-75%	3折
    75%以上	2折

   */
   /*
select *,ngcsj*1.0/(ngcsj+nsysj) nsjjd,case when isnull(ndqkcsl,0)<=0 then 1
else isnull(nzxssl,0)/(isnull(nzxssl,0)+isnull(ndqkcsl,0))  end ,case when a.STOP_INTO='N' then '状态开通,请核查！'
  when ISNULL(a.ndqkcsl,0)=0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null)  then '已清退'
  when ISNULL(a.ndqkcsl,0)<0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)  then '负库存'
  when ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)   then '未完成' end sflag1,
  case  when  ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null) then 
			 case  
          when ISNULL(a.nzxssl,0)<=0 then 
					  case
			when a.nsysj>=70 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.7 then '建议标签售价的7折销售' else  '建议当前促销价销售'   end 
              when a.nsysj>=50 and a.nsysj<70 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.5 then '建议标签售价的5折销售' else  '建议当前促销价销售'   end 
              when a.nsysj>=30 and a.nsysj<50 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.3 then '建议标签售价的3折销售' else  '建议当前促销价销售'   end 
              else '建议标签售价的2折出清'
            end
		      when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj-10  then '建议当前促销价销售'  
			-- 30 Days 
          when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and a.nsysj>=70 
            then case  when ISNULL(a.ncxj,0)>a.nsj*0.75 then '建议标签售价的7折销售' else  '建议当前促销价销售'   end 
		when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and a.nsysj>=50 and a.nsysj<70 
            then case  when ISNULL(a.ncxj,0)>a.nsj*0.55 then '建议标签售价的5折销售' else  '建议当前促销价销售'   end
		when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and a.nsysj>=30 and a.nsysj<50 
            then case  when ISNULL(a.ncxj,0)>a.nsj*0.35 then '建议标签售价的3折销售' else  '建议当前促销价销售'   end   
				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and a.nsysj<30
					  then '建议标签售价的2折出清'
				  when a.nsysj<=0 then '0.01元出清'
		end  
  end       from #r a where 1=1  order by smonth,a.sfdbh,a.sspbh
*/

select *,ngcsj*1.0/(ngcsj+nsysj) nsjjd,case when isnull(ndqkcsl,0)<=0 then 1
else isnull(nzxssl,0)/(isnull(nzxssl,0)+isnull(ndqkcsl,0))  end ,case when a.STOP_INTO='N' then '状态开通,请核查！'
  when ISNULL(a.ndqkcsl,0)=0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null)  then '已清退'
  when ISNULL(a.ndqkcsl,0)<0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)  then '负库存'
  when ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)   then '未完成' end sflag1,
  case  when  ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null) then 
			 case  
          when ISNULL(a.nzxssl,0)<=0 then 
					  case
			when ngcsj*1.0/(ngcsj+nsysj)<0.15 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.85 or a.ncxj is null  then '建议标签售价的8折销售' else  '建议当前促销价销售'   end 
      when ngcsj*1.0/(ngcsj+nsysj)>=0.15 and ngcsj*1.0/(ngcsj+nsysj)<0.3 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.75 or a.ncxj is null then '建议标签售价的7折销售' else  '建议当前促销价销售'   end 
      when ngcsj*1.0/(ngcsj+nsysj)>=0.3 and ngcsj*1.0/(ngcsj+nsysj)<0.45 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.65 or a.ncxj is null then '建议标签售价的6折销售' else  '建议当前促销价销售'   end 
      when ngcsj*1.0/(ngcsj+nsysj)>=0.45 and ngcsj*1.0/(ngcsj+nsysj)<0.6 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.55 or a.ncxj is null then '建议标签售价的5折销售' else  '建议当前促销价销售'   end 
      when ngcsj*1.0/(ngcsj+nsysj)>=0.6 and ngcsj*1.0/(ngcsj+nsysj)<0.75 then  case  when ISNULL(a.ncxj,0)>=a.nsj*0.35  or a.ncxj is null then '建议标签售价的3折销售' else  '建议当前促销价销售'   end 
              else '建议标签售价的2折出清'
            end
		  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj-10  then '建议当前促销价销售'  
			-- 30 Days 
      when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj and ngcsj*1.0/(ngcsj+nsysj)>=0.15 and   ngcsj*1.0/(ngcsj+nsysj)<0.3 
            then case  when ISNULL(a.ncxj,0)>a.nsj*0.75 or a.nCxj is null   then '建议标签售价的7折销售' else  '建议当前促销价销售'   end 
		when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj and  ngcsj*1.0/(ngcsj+nsysj)>=0.3 and   ngcsj*1.0/(ngcsj+nsysj)<0.45
            then case  when ISNULL(a.ncxj,0)>a.nsj*0.65 or a.nCxj is null then '建议标签售价的6折销售' else  '建议当前促销价销售'   end
    when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj and  ngcsj*1.0/(ngcsj+nsysj)>=0.45 and   ngcsj*1.0/(ngcsj+nsysj)<0.6
            then case  when ISNULL(a.ncxj,0)>a.nsj*0.55 or a.nCxj is null then '建议标签售价的5折销售' else  '建议当前促销价销售'   end
		when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj and  ngcsj*1.0/(ngcsj+nsysj)>=0.6 and   ngcsj*1.0/(ngcsj+nsysj)<0.75
            then case  when ISNULL(a.ncxj,0)>a.nsj*0.35 or a.nCxj is null then '建议标签售价的3折销售' else  '建议当前促销价销售'   end  
				  when ISNULL(a.nzxssl,0)>0  and a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj and ngcsj*1.0/(ngcsj+nsysj)>=0.75
					  then '建议标签售价的2折出清'
		when a.nsysj<=0 then '0.01元出清'
		end  
  end       from #r a
  left join #tmp_cxgx1 b on a.smonth=b.smonth and a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and b.npm=1
  where 1=1  order by smonth,a.sfdbh,a.sspbh

  /*
  给出两种状态：一个是当前处理的实际情况，一种是未处理完的下一步建议
      当前实际
            已清退：指状态已关闭，且当前库存量为0
            负库存：状态已关闭，但当前库存为负
            状态开通：指在清退计划单中，但是目前是可进状态，当作完成了
            未完成：状态已关，但当前有库存
      未完成商品下一步建议，需要加一个库存衡量
        1、开始至当前无销售的
          1.1 时间进度15%以内， 建议标签售价的8折销售，如果当前促销价低于8折按当前促销价
          1.2 时间进度15%-30%以内， 建议标签售价的7折销售，如果当前促销价低于7折按当前促销价
          1.3 时间进度30%-45%以内， 建议标签售价的6折销售，如果当前促销价低于6折按当前促销价
          1.4 时间进度45%-60%以内， 建议标签售价的5折销售，如果当前促销价低于5折按当前促销价
          1.5 时间进度60%-75%以内， 建议标签售价的3折销售，如果当前促销价低于3折按当前促销价
          1.4 时间进度》=75%， 建议标签售价的2折销售 
        2、方案执行后有销售的  
          2.1 有销售，且按促销期实际日结周转天数低于剩余天数—按当前方案执行
          2.2 有销售，但剩余天数不足以售完，时间进度15%以内， 建议标签售价的8折销售，如果当前促销价低于8折按当前促销价
          2.3 有销售，但剩余天数不足以售完，时间进度15%-30%以内， 建议标签售价的7折销售，如果当前促销价低于7折按当前促销价
          2.4 有销售，但剩余天数不足以售完，时间进度30%-45%以内， 建议标签售价的6折销售，如果当前促销价低于6折按当前促销价
          2.5 有销售，但剩余天数不足以售完，时间进度45%-60%以内， 建议标签售价的5折销售，如果当前促销价低于5折按当前促销价
          2.6 有销售，但剩余天数不足以售完，时间进度60%-75%以内， 建议标签售价的3折销售，如果当前促销价低于3折按当前促销价
          2.7 有销售，但剩余天数不足以售完，时间进度>=75%以内， 建议标签售价的2折销售 
          2.8 超出截止日期的  0.01元出清
          时间进度=已经过天数/(方案总天数)
          周转计算：剩余库存/(促销开始后销量/经过的时间)
  */


  -------- 2022-05-06 版本
   /*
   第一次（采购）三周  5月1日-5月21日  ： 共21天
  第二次（系统）三周  5月22日-6月11日 ： 共21天
  第三次 （系统）两周  6月12日-6月25日  ： 共14天
  第四次（系统） 两周  6月26日-7月9日   ： 共14天             
  第五次（门店执行黄码签）：  7月10日-7月31日   ： 共21天

  系统在下次开始时间前4天出清单；

  给出两种状态：一个是当前处理的实际情况，一种是未处理完的下一步建议
      当前实际
            已清退：指状态已关闭，且当前库存量为0
            负库存：状态已关闭，但当前库存为负
            状态开通：指在清退计划单中，但是目前是可进状态，当作完成了
            未完成：状态已关，但当前有库存
      未完成商品下一步建议，需要加一个库存衡量
      每21天是一个周期
        1、开始至当前无销售的
          1.1 时间进度21以内， 采购方案执行
          1.2 时间进度21-42以内， 建议标签售价的7折销售，如果当前促销价低于7折按当前促销价
          1.3 时间进度43-56天以内， 建议标签售价的5折销售，如果当前促销价低于5折按当前促销价
          1.4 时间进度57-70天以内， 建议标签售价的3折销售，如果当前促销价低于3折按当前促销价
          1.5  时间进度>71天，门店黄码标签——2折销售
        2、方案执行后有销售的  
          2.1 有销售，且按促销期实际日结周转天数低于剩余天数—按当前方案执行
          2.2 有销售，但剩余天数不足以售完，时间进度21以内， 采购方案执行
          2.3 有销售，但剩余天数不足以售完，时间进度21-42以内， 建议标签售价的7折销售，如果当前促销价低于7折按当前促销价
          2.4 有销售，但剩余天数不足以售完，时间进度43-56以内， 建议标签售价的5折销售，如果当前促销价低于5折按当前促销价
          2.5 有销售，但剩余天数不足以售完，时间进度56-70天，建议标签售价的3折销售，如果当前促销价低于3折按当前促销价
          2.6 有销售，但剩余天数不足以售完，时间进度>71天，门店黄码标签——2折销售
          超出截止日期的  0.01元出清
          时间进度=已经过天数/(方案总天数)
          周转计算：剩余库存/(促销开始后销量/经过的时间)
  */
  -- drop table #Tmp_xs
select a.* into #Tmp_xs from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT  a
where 1=1  and a.SALE_DATE>='2022-02-01' and a.SALE_DATE<GETDATE();


select * into #Tmp_de from  DappSource_Dw.dbo.sys_deliveryset 
where 1=1;


-- Step 2: 处理批次 drop table #Tmp_time 
select '1月' smonth,convert(date,'2022-01-01') Bdate,dateadd(day,-1,CONVERT(date,'2022-04-01')) edate into #Tmp_time union
select '2月' smonth,convert(date,'2022-02-01') ,dateadd(day,-1,CONVERT(date,'2022-05-01'))
union
select '3月' smonth,convert(date,'2022-03-01') ,dateadd(day,-1,CONVERT(date,'2022-06-01'))
union
select '4月' smonth,convert(date,'2022-04-01') ,dateadd(day,-1,CONVERT(date,'2022-07-01'))
;
 
-- Step 3:基础数据准备
select *  into #Tmp_1 from DappSource_Dw.dbo.Tmp_dr_0419

-- drop table #1;  
select  a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,c.smonth,c.Bdate,c.edate,
b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode  into #1 
from  #Tmp_1 a 
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on b.DEPT_CODE=a.sfdbh and b.ITEM_CODE=a.sspbh
left join #Tmp_time c on a.清理计划时间=c.smonth
where  1=1  and a.sFdbh<>'015901'  ;

-- drop table #Base_sp
select a.*,d.sort sPlbh into #Base_sp
from #1 a
left join  DappSource_Dw.dbo.goods d on a.sSpbh=d.code
where 1=1  ; 

-- drop table #Base_1
select   a.*,ISNULL(b.CURR_STOCK,0)  nkcsl into #Base_1 from #Base_sp a
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK  b
     on   a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
where 1=1 ;



-- 销售数据 drop table #Tmp_xs1
select a.*,ceiling(datediff(HOUR,b.Bdate,a.sale_date)*1.0/240)*10 nxsqj into #Tmp_xs1
from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT a
join #Base_1 b on a.SHOP_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
    and a.sale_date>=b.Bdate and a.SALE_DATE<GETDATE()
where 1=1  ;

-- -- 促销信息 drop table #Tmp_cx

 select sdh,sFdbh,sspbh,Bdate,Edate,nLsj,nCxj,TJD_NCXJ,TJD_NJJ,CreateDate,CloseDate,sZt,adate
 into #Tmp_cx from  [122.147.10.200].DappSource.dbo.tmp_Promotion a
 where  1=1 and CONVERT(date,a.Edate)>=convert(date,'2022-02-01') 
   ;

 -- drop table #tmp_cxgx
select a.sFdbh,a.sspbh,a.smonth,b.bdate,b.edate,b.nlsj,b.ncxj,b.szt
,b.adate,ROW_NUMBER()over(partition by a.smonth,a.sfdbh,a.sspbh
order by convert(date,b.aDate) desc) npm into #tmp_cxgx from #Base_1 a 
left join #Tmp_cx b on a.sFdbh=b.sfdbh and a.sspbh=b.sspbh 
and b.szt not in ('已结束','已作废')
and CONVERT(date,b.Edate)>=CONVERT(date,a.Bdate)   
where 1=1 


 -- drop table #tmp_cxgx1
select a.sFdbh,a.sspbh,a.smonth,b.bdate,b.edate,b.nlsj,b.ncxj,b.szt
,b.adate,ROW_NUMBER()over(partition by a.smonth,a.sfdbh,a.sspbh
order by convert(date,b.aDate) desc) npm into #tmp_cxgx1 from #Base_1 a 
left join #Tmp_cx b on a.sFdbh=b.sfdbh and a.sspbh=b.sspbh 
-- and b.szt not in ('已结束','已作废')
and CONVERT(date,b.Edate)>=CONVERT(date,a.Bdate)   
where 1=1 

-- 使用历史日结库存 drop table   #Tmp_mdkc
select c_day_date drq, c_store_id sfdbh,c_gcode sspbh,c_number nkcsl into #Tmp_mdkc   from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date in ( to_date(''2022-02-01'',''yyyy/mm/dd'' ), to_date(''2022-03-01'',''yyyy/mm/dd'' ), to_date(''2022-04-01'',''yyyy/mm/dd'' )    )');


-- xs1 drop table #Tmp_xs_hz
select b.smonth, a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1) nxsjg,sum(a.QTY) nxssl
into #Tmp_xs_hz from
 #Tmp_xs1 a, #Tmp_time b
 where  1=1 and convert(date,a.sale_date)>=b.Bdate and convert(date,a.sale_date)<=b.edate 
 and a.QTY>0
   group by b.smonth, a.SHOP_CODE  ,a.ITEM_CODE  ,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1)
 order by 1,2, 4 desc;

 -- drop table #Tmp_lastxs 
 select b.smonth, a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,a.SALE_DATE,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1) nxsjg,
 ROW_NUMBER()over(partition by b.smonth, a.shop_code,a.item_code order by a.sale_date desc) npm into #Tmp_lastxs  from
 #Tmp_xs1 a, #Tmp_time b
 where  1=1 and convert(date,a.sale_date)>=b.Bdate and convert(date,a.sale_date)<=b.edate 
 and a.QTY>0;

 -- drop table #r
 with x0 as(
 select a.*,ROW_NUMBER()over(partition by a.smonth, a.sfdbh,a.sspbh order by a.nxssl desc) npm from #Tmp_xs_hz a
),x1 as (select a.smonth, a.sFdbh,a.sSpbh,min(nxsjg) nzdxsj,sum(a.nxssl) nzxssl  from #Tmp_xs_hz  a group by a.smonth, a.sFdbh,a.sSpbh )
select a.smonth,a.Bdate,a.edate,a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,a.njj,a.nsj,a.spsfs,a.nPsbzs,
a.sPlbh,b.nkcsl nQckc,a.nkcsl ndqkcsl,d.nzxssl,a.STOP_INTO,a.DISPLAY_MODE,DATEDIFF(day,GETDATE(),a.edate)-1 nsysj
,DATEDIFF(DAY,a.Bdate,CONVERT(date,GETDATE()))-1 ngcsj,c.nxsjg nxsj_maxxl,d.nzdxsj,e.nxsjg nxsjg_last,e.SALE_DATE drq_last
,f.ncxj into #r  from #Base_1 a 
left join #Tmp_mdkc b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh and a.Bdate=b.drq 
left  join x0 c on a.sfdbh=c.sfdbh and a.sSpbh=c.sSpbh and c.npm=1 and a.smonth=c.smonth  
left join x1 d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh  and a.smonth=d.smonth 
left join #Tmp_lastxs e on a.sFdbh=e.sFdbh and a.sSpbh=e.sSpbh and e.npm=1 and a.smonth=e.smonth
left join #tmp_cxgx f on a.sFdbh=f.sFdbh and a.sspbh=f.sspbh and f.npm=1
where 1=1 ;


declare @tql int;
set @tql=4;
 select a.*,ngcsj*1.0/(ngcsj+nsysj) nsjjd,case when isnull(ndqkcsl,0)<=0 then 1
else isnull(nzxssl,0)/(isnull(nzxssl,0)+isnull(ndqkcsl,0))  end nkcjd ,case when a.STOP_INTO='N' then '状态开通,请核查！'
  when ISNULL(a.ndqkcsl,0)=0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null)  then '已清退'
  when ISNULL(a.ndqkcsl,0)<0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)  then '负库存'
  when ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)   then '未完成' end sflag1,
  case  when  ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null) then 
			case  
          when ISNULL(a.nzxssl,0)<=0 then 
					  case
              when DATEDIFF(day,a.bdate,GETDATE())>=0 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=21  then CONVERT(money,'')     
              when DATEDIFF(day,a.bdate,GETDATE())+@tql>21 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=42  then  
                  case  when ISNULL(a.ncxj,0)>=a.nsj*0.73 or a.ncxj is null then a.nsj*0.7 else a.nCxj  end
              when DATEDIFF(day,a.bdate,GETDATE())+@tql>42 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=56  then  
                  case  when ISNULL(a.ncxj,0)>=a.nsj*0.53 or a.ncxj is null then a.nsj*0.5 else a.nCxj  end 
              when DATEDIFF(day,a.bdate,GETDATE())+@tql>56 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=70  then  
                  case  when ISNULL(a.ncxj,0)>=a.nsj*0.33 or a.ncxj is null then a.nsj*0.3 else a.nCxj  end  
              when DATEDIFF(day,a.bdate,GETDATE())+@tql>70 and  convert(date,GETDATE())<=a.edate  then  
                  case  when ISNULL(a.ncxj,0)>=a.nsj*0.23 or a.ncxj is null then a.nsj*0.2 else a.nCxj  end 
              when convert(date,GETDATE())>a.edate   then 0.01
            end
		    when ISNULL(a.nzxssl,0)>0  then 
           case  when  a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj-10  then  case when a.ncxj is null then a.nsj*0.8 else a.ncxj end 
              when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and DATEDIFF(day,a.bdate,GETDATE())>=0 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=21
                  then CONVERT(money,'')
              when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())>21 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=42
                then case  when ISNULL(a.ncxj,0)>=a.nsj*0.73 or a.nCxj is null then a.nsj*0.7  else  a.nCxj   end
              when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())>42 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=56
                then case  when ISNULL(a.ncxj,0)>=a.nsj*0.53 or a.nCxj is null then a.nsj*0.5  else  a.nCxj   end
              when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())>56 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=70
                then case  when ISNULL(a.ncxj,0)>=a.nsj*0.33 or a.nCxj is null then a.nsj*0.3  else  a.nCxj   end
              when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())+@tql>70 and   convert(date,GETDATE())<=a.edate 
                then case  when ISNULL(a.ncxj,0)>=a.nsj*0.23 or a.nCxj is null then a.nsj*0.2  else  a.nCxj   end
              when convert(date,GETDATE())>a.edate   then 0.01
          end
		  end  
  end njg_raw,  case  when  ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null) then 
			case  
          when ISNULL(a.nzxssl,0)<=0 then 
					  case
              when DATEDIFF(day,a.bdate,GETDATE())>=0 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=21  then '当前是采购定价阶段，系统不提供建议值'     
              when DATEDIFF(day,a.bdate,GETDATE())+@tql>21 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=42  then  
                  case  when ISNULL(a.ncxj,0)>=a.nsj*0.73 or a.ncxj is null then '系统建议值' else '原采购价'  end
              when DATEDIFF(day,a.bdate,GETDATE())+@tql>42 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=56  then  
                  case  when ISNULL(a.ncxj,0)>=a.nsj*0.53 or a.ncxj is null then '系统建议值' else '原采购价'  end 
              when DATEDIFF(day,a.bdate,GETDATE())+@tql>56 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=70  then  
                  case  when ISNULL(a.ncxj,0)>=a.nsj*0.33 or a.ncxj is null then '系统建议值' else '原采购价'  end  
              when DATEDIFF(day,a.bdate,GETDATE())+@tql>70 and  convert(date,GETDATE())<=a.edate  then  
                  case  when ISNULL(a.ncxj,0)>=a.nsj*0.23 or a.ncxj is null then '系统建议值' else '原采购价'  end 
              when convert(date,GETDATE())>a.edate   then '出清价'
            end
		    when ISNULL(a.nzxssl,0)>0  then 
           case  when  a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj-10  then  case when a.ncxj is null then '系统建议值' else '原采购价' end  
              when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and DATEDIFF(day,a.bdate,GETDATE())>=0 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=21
                  then '当前是采购定价阶段，系统不提供建议值'  
              when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())>21 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=42
                then case  when ISNULL(a.ncxj,0)>=a.nsj*0.73 or a.nCxj is null then '系统建议值' else '原采购价'   end
              when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())>42 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=56
                then case  when ISNULL(a.ncxj,0)>=a.nsj*0.53 or a.nCxj is null then '系统建议值' else '原采购价'   end
              when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())>56 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=70
                then case  when ISNULL(a.ncxj,0)>=a.nsj*0.33 or a.nCxj is null then '系统建议值' else '原采购价'  end
              when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())+@tql>70 and   convert(date,GETDATE())<=a.edate 
                then case  when ISNULL(a.ncxj,0)>=a.nsj*0.23 or a.nCxj is null then '系统建议值' else '原采购价'   end
              when convert(date,GETDATE())>a.edate   then '出清价'
          end
		  end  
  end sscource into #r1 from #r a
  left join #tmp_cxgx1 b on a.smonth=b.smonth and a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and b.npm=1
  where 1=1  order by a.smonth,a.sfdbh,a.sspbh

 select a.smonth,a.Bdate,a.edate,a.sFdbh,a.sfdmc,a.sspbh,a.sspmc,a.njj,a.nsj,a.spsfs,a.sPlbh,b.sflmc,a.nQckc,a.ndqkcsl,a.nzxssl,
  a.STOP_INTO,a.nsysj,a.ngcsj,a.ncxj,a.nsjjd,a.nkcjd,a.sflag1,a.njg_raw,sscource,
  case when  sscource='出清价' then 0.01 else  CAST(ROUND(a.njg_raw,2) as numeric(8,2)) end njg_cal  into #r2 from #r1 a 
  left join DappSource_Dw.dbo.tmp_spflb b on a.sPlbh=b.sflbh where smonth is not null 
    order by 1

   select a.smonth,a.Bdate,a.edate,a.sFdbh,a.sfdmc,a.sspbh,a.sspmc,a.njj,a.nsj,a.spsfs,a.sPlbh,a.sflmc,a.nQckc,a.ndqkcsl,a.nzxssl,
  a.STOP_INTO,a.nsysj,a.ngcsj,a.ncxj,a.nsjjd,a.nkcjd,a.sflag1,a.njg_raw,
  case   when  sscource   not in ('系统建议值','出清价')    then CAST(ROUND(a.njg_cal,1) as numeric(8,2))
         when  sscource ='出清价' then convert(numeric(8,2),0.01)
         when sscource ='系统建议值'  then   
			case when a.nsj<=10 and  a.njg_cal%1 in (0.1,0.4,0.7) then a.njg_cal+0.1 
			     when a.nsj<=10 and  a.njg_cal%1 not in (0.1,0.4,0.7) then CAST(ROUND(a.njg_cal,1) as numeric(8,2))
			     when a.nsj>10 and a.nsj<=100 and  a.njg_cal%1 =0 and a.njg_cal%10<=5
					   then floor(a.njg_cal/10)*10+5
				 when a.nsj>10 and a.nsj<=100 and  a.njg_cal%1 =0 and a.njg_cal%10 between 6 and 8.5
					   then floor(a.njg_cal/10)*10+8
			     when a.nsj>10 and a.nsj<=100 and  a.njg_cal%1 =0 and a.njg_cal%10>8.5
					   then a.njg_cal 
				 -- xiaoshu
				 when a.nsj>10 and a.nsj<=100 and  a.njg_cal%1 <>0 and a.njg_cal%1<=0.5
					   then floor(a.njg_cal/1)+0.5
				 when a.nsj>10 and a.nsj<=100 and  a.njg_cal%1 <>0 and a.njg_cal%1 between 0.51 and 0.85
					   then floor(a.njg_cal/1)+0.8
			    when a.nsj>10 and a.nsj<=100 and a.njg_cal%1 <>0 and a.njg_cal%1 >0.85
					   then floor(a.njg_cal/1)+0.9
				 
				 when a.nsj>100   and a.njg_cal%10<=5
					   then floor(a.njg_cal/10)*10+5
				 when a.nsj>100  and a.njg_cal%10 between 5.01 and 8.5
					   then floor(a.njg_cal/10)*10+8
			     when a.nsj>100  and a.njg_cal%10>8.5
					   then floor(a.njg_cal/10)*10+9
			end
  end ,case when a.sflag1='未完成' and  DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 18 and 21 
    OR DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 19 and 42 
    or  DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 53 and 56
    or DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 67 and 76 then '制作下一阶段促销单' else '' end from #r2 a  
     order by 1

-- insert into dbo.Tmp_TailCargo(smonth,Bdate,Edate,sfdbh,sfdmc,sSpbh,sSpmc,nTjj,nTsj,sManager)
--  select '2022年5月计划',convert(date,'2022-05-01') ,dateadd(day,-1,convert(date,'2022-08-01')),
--  sfdbh,sfdmc,sspbh,sspmc,convert(money,ntjj),convert(money,ntsj),scgjl from #1 


---------------  作业版
-- Step 1 获取计划方案
select * into #Tmp_Tail from dbo.Tmp_TailCargo a
where a.sfdbh<>'015901' and ( DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 18 and 21 
    OR DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 19 and 42 
    or  DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 53 and 56
    or DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 67 and 76) ;

--Step  2 :如果不在出建议的日期，不执行计算
if (select COUNT(1) from #Tmp_Tail)>0
  begin
      -- Step 3：取最早销售
      select a.* into #Tmp_xs from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT  a
      where 1=1  and a.SALE_DATE>=(select min(Bdate) from #Tmp_Tail) and a.SALE_DATE<GETDATE();
      -- Step 4:基础数据准备
      select  a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,a.smonth,a.Bdate,a.edate,
      b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
      case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
      when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
      b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
      ,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode,a.ntjj  into #1 
      from  #Tmp_Tail a 
      left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on b.DEPT_CODE=a.sfdbh and b.ITEM_CODE=a.sspbh
      where  1=1  and a.sFdbh<>'015901'  ;
  
      --Step 5:获取当前库存数据
      -- drop table #Base_sp
      select a.*,d.sort sPlbh into #Base_sp
      from #1 a
      left join   dbo.goods d on a.sSpbh=d.code
      where 1=1  ; 

      select   a.*,ISNULL(b.CURR_STOCK,0)  nkcsl into #Base_1 from #Base_sp a
      left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK  b
          on   a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
      where 1=1 ;



      --Step 6 销售数据汇总 drop table #Tmp_xs1
      select a.*,ceiling(datediff(HOUR,b.Bdate,a.sale_date)*1.0/240)*10 nxsqj into #Tmp_xs1
      from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT a
      join #Base_1 b on a.SHOP_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
          and a.sale_date>=b.Bdate and a.SALE_DATE<GETDATE()
      where 1=1  ;

      --Step 7: 促销信息 drop table #Tmp_cx

      select sdh,sFdbh,sspbh,Bdate,Edate,nLsj,nCxj,TJD_NCXJ,TJD_NJJ,CreateDate,CloseDate,sZt,adate
      into #Tmp_cx from  [122.147.10.200].DappSource.dbo.tmp_Promotion a
      where  1=1 and CONVERT(date,a.Edate)>=(select min(Bdate) from #Tmp_Tail) ;

      --Step 8: drop table #tmp_cxgx
      select a.sFdbh,a.sspbh,a.smonth,b.bdate,b.edate,b.nlsj,b.ncxj,b.szt
      ,b.adate,ROW_NUMBER()over(partition by a.smonth,a.sfdbh,a.sspbh
      order by convert(date,b.aDate) desc) npm into #tmp_cxgx from #Base_1 a 
      left join #Tmp_cx b on a.sFdbh=b.sfdbh and a.sspbh=b.sspbh 
      -- and b.szt not in ('已结束','已作废')
      and CONVERT(date,b.Edate)>=CONVERT(date,a.Bdate)   
      where 1=1 ;

    -- 使用历史日结库存 drop table   #Tmp_mdkc
    select a.Bdate drq, a.sfdbh,a.sspbh,isnull(b.nkcsl,0) nkcsl into #Tmp_mdkc   
    from   #Tmp_Tail a 
    left join dbo.Tmp_Kclsb b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and a.Bdate=b.drq;


-- xs1 drop table #Tmp_xs_hz
    select b.smonth, a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1) nxsjg,sum(a.QTY) nxssl
    into #Tmp_xs_hz from
    #Tmp_xs1 a, (select distinct  smonth,bdate,edate from #Tmp_Tail) b
    where  1=1 and convert(date,a.sale_date)>=b.Bdate and convert(date,a.sale_date)<=b.edate 
    and a.QTY>0
      group by b.smonth, a.SHOP_CODE  ,a.ITEM_CODE  ,round((a.SUBTOTAL-a.DISCOUNT)*1.0/a.QTY,1)
    order by 1,2, 4 desc;


    -- drop table #r
    with x0 as(
    select a.*,ROW_NUMBER()over(partition by a.smonth, a.sfdbh,a.sspbh order by a.nxssl desc) npm from #Tmp_xs_hz a
    ),x1 as (select a.smonth, a.sFdbh,a.sSpbh,min(nxsjg) nzdxsj,sum(a.nxssl) nzxssl  from #Tmp_xs_hz  a group by a.smonth, a.sFdbh,a.sSpbh )
    select a.smonth,a.Bdate,a.edate,a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,a.njj,a.nsj,a.ntjj,a.spsfs,a.nPsbzs,
    a.sPlbh,b.nkcsl nQckc,a.nkcsl ndqkcsl,d.nzxssl,a.STOP_INTO,a.DISPLAY_MODE,DATEDIFF(day,GETDATE(),a.edate)-1 nsysj
    ,DATEDIFF(DAY,a.Bdate,CONVERT(date,GETDATE()))-1 ngcsj,c.nxsjg nxsj_maxxl,d.nzdxsj
    ,f.ncxj into #r  from #Base_1 a 
    left join #Tmp_mdkc b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh and a.Bdate=b.drq 
    left  join x0 c on a.sfdbh=c.sfdbh and a.sSpbh=c.sSpbh and c.npm=1 and a.smonth=c.smonth  
    left join x1 d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh  and a.smonth=d.smonth 
    left join #tmp_cxgx f on a.sFdbh=f.sFdbh and a.sspbh=f.sspbh and f.npm=1
    where 1=1 ;


      declare @tql int;
      set @tql=4;
      select a.*,ngcsj*1.0/(ngcsj+nsysj) nsjjd,case when isnull(ndqkcsl,0)<=0 then 1
      else isnull(nzxssl,0)/(isnull(nzxssl,0)+isnull(ndqkcsl,0))  end nkcjd ,case when a.STOP_INTO='N' then '状态开通,请核查！'
        when ISNULL(a.ndqkcsl,0)=0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null)  then '已清退'
        when ISNULL(a.ndqkcsl,0)<0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)  then '负库存'
        when ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N' or a.STOP_INTO is null)   then '未完成' end sflag1,
        case  when  ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null) then 
            case  
                when ISNULL(a.nzxssl,0)<=0 then 
                  case
                    when DATEDIFF(day,a.bdate,GETDATE())>=0 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=21  then CONVERT(money,'')     
                    when DATEDIFF(day,a.bdate,GETDATE())+@tql>21 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=42  then  
                        case  when ISNULL(a.ncxj,0)>=a.nsj*0.73 or a.ncxj is null then a.nsj*0.7 else a.nCxj  end
                    when DATEDIFF(day,a.bdate,GETDATE())+@tql>42 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=56  then  
                        case  when ISNULL(a.ncxj,0)>=a.nsj*0.53 or a.ncxj is null then a.nsj*0.5 else a.nCxj  end 
                    when DATEDIFF(day,a.bdate,GETDATE())+@tql>56 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=70  then  
                        case  when ISNULL(a.ncxj,0)>=a.nsj*0.33 or a.ncxj is null then a.nsj*0.3 else a.nCxj  end  
                    when DATEDIFF(day,a.bdate,GETDATE())+@tql>70 and  convert(date,GETDATE())<=a.edate  then  
                        case  when ISNULL(a.ncxj,0)>=a.nsj*0.23 or a.ncxj is null then a.nsj*0.2 else a.nCxj  end 
                    when convert(date,GETDATE())>a.edate   then 0.01
                  end
              when ISNULL(a.nzxssl,0)>0  then 
                case  when  a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj-10  then  case when a.ncxj is null then a.nsj*0.8 else a.ncxj end 
                    when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and DATEDIFF(day,a.bdate,GETDATE())>=0 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=21
                        then CONVERT(money,'')
                    when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())>21 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=42
                      then case  when ISNULL(a.ncxj,0)>=a.nsj*0.73 or a.nCxj is null then a.nsj*0.7  else  a.nCxj   end
                    when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())>42 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=56
                      then case  when ISNULL(a.ncxj,0)>=a.nsj*0.53 or a.nCxj is null then a.nsj*0.5  else  a.nCxj   end
                    when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())>56 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=70
                      then case  when ISNULL(a.ncxj,0)>=a.nsj*0.33 or a.nCxj is null then a.nsj*0.3  else  a.nCxj   end
                    when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())+@tql>70 and   convert(date,GETDATE())<=a.edate 
                      then case  when ISNULL(a.ncxj,0)>=a.nsj*0.23 or a.nCxj is null then a.nsj*0.2  else  a.nCxj   end
                    when convert(date,GETDATE())>a.edate   then 0.01
                end
            end  
        end njg_raw,  case  when  ISNULL(a.ndqkcsl,0)>0 and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null) then 
            case  
                when ISNULL(a.nzxssl,0)<=0 then 
                  case
                    when DATEDIFF(day,a.bdate,GETDATE())>=0 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=21  then '当前是采购定价阶段，系统不提供建议值'     
                    when DATEDIFF(day,a.bdate,GETDATE())+@tql>21 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=42  then  
                        case  when ISNULL(a.ncxj,0)>=a.nsj*0.73 or a.ncxj is null then '系统建议值' else '原采购价'  end
                    when DATEDIFF(day,a.bdate,GETDATE())+@tql>42 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=56  then  
                        case  when ISNULL(a.ncxj,0)>=a.nsj*0.53 or a.ncxj is null then '系统建议值' else '原采购价'  end 
                    when DATEDIFF(day,a.bdate,GETDATE())+@tql>56 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=70  then  
                        case  when ISNULL(a.ncxj,0)>=a.nsj*0.33 or a.ncxj is null then '系统建议值' else '原采购价'  end  
                    when DATEDIFF(day,a.bdate,GETDATE())+@tql>70 and  convert(date,GETDATE())<=a.edate  then  
                        case  when ISNULL(a.ncxj,0)>=a.nsj*0.23 or a.ncxj is null then '系统建议值' else '原采购价'  end 
                    when convert(date,GETDATE())>a.edate   then '出清价'
                  end
              when ISNULL(a.nzxssl,0)>0  then 
                case  
                    when DATEDIFF(day,a.bdate,GETDATE())>=0 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=21  then '当前是采购定价阶段，系统不提供建议值'
                    when  a.ndqkcsl*a.ngcsj*1.0/a.nzxssl<a.nsysj-10 and DATEDIFF(day,a.bdate,GETDATE())+@tql>21  then  case when a.ncxj is null then '系统建议值' else '原采购价' end  
                    when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10 and DATEDIFF(day,a.bdate,GETDATE())>=0 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=21
                        then '当前是采购定价阶段，系统不提供建议值'  
                    when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())+@tql>21 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=42
                      then case  when ISNULL(a.ncxj,0)>=a.nsj*0.73 or a.nCxj is null then '系统建议值' else '原采购价'   end
                    when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())+@tql>42 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=56
                      then case  when ISNULL(a.ncxj,0)>=a.nsj*0.53 or a.nCxj is null then '系统建议值' else '原采购价'   end
                    when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())+@tql>56 and DATEDIFF(day,a.bdate,GETDATE())+@tql<=70
                      then case  when ISNULL(a.ncxj,0)>=a.nsj*0.33 or a.nCxj is null then '系统建议值' else '原采购价'  end
                    when   a.ndqkcsl*a.ngcsj*1.0/a.nzxssl>=a.nsysj-10  and  DATEDIFF(day,a.bdate,GETDATE())+@tql>70 and   convert(date,GETDATE())<=a.edate 
                      then case  when ISNULL(a.ncxj,0)>=a.nsj*0.23 or a.nCxj is null then '系统建议值' else '原采购价'   end
                    when convert(date,GETDATE())>a.edate   then '出清价'
                end
            end  
        end sscource into #r1 from #r a
        where 1=1  order by a.smonth,a.sfdbh,a.sspbh;

  select a.smonth,a.Bdate,a.edate,a.sFdbh,a.sfdmc,a.sspbh,a.sspmc,a.njj,a.nsj,a.ntjj,a.spsfs,a.sPlbh,b.sflmc,a.nQckc,a.ndqkcsl,a.nzxssl,
  a.STOP_INTO,a.nsysj,a.ngcsj,a.ncxj,a.nsjjd,a.nkcjd,a.sflag1,a.njg_raw,
  case when sflag1<>'未完成' then ''
    when isnull(a.ntjj,0)<=0 then '无特进价,不出建议' else   sscource end sscource,
  case when isnull(a.nTjj,0)<=0 then convert(money,NULL)
    when  sscource='出清价' and a.ntjj>0 then 0.01  
    when sscource<>'出清价' and a.ntjj>0  then CAST(ROUND(a.njg_raw,2) as numeric(8,2)) end njg_cal  into #r2 from #r1 a 
  left join DappSource_Dw.dbo.tmp_spflb b on a.sPlbh=b.sflbh where smonth is not null 
    order by 1;
delete Tmp_TailCargo_Suggest where drq=CONVERT(date,GETDATE());
insert into Tmp_TailCargo_Suggest(drq,sMonth,sFdbh,sSpbh,Bdate,Edate,nPsj,nLsj,nQckc,nDqkc,nZxssl,ndays_already,nDays_remaining,sZt,sstage,
nsjjd,nkccljd,nCxj_last,ncxj_suggest,sSftj)
select GETDATE() drq, a.smonth,a.sFdbh,a.sspbh,a.Bdate,a.edate,a.njj,a.nsj,a.nQckc,a.ndqkcsl,a.nzxssl,
  a.ngcsj,a.nsysj,sflag1,sscource,a.nsjjd,a.nkcjd,a.ncxj,
  case  when sscource in ('当前是采购定价阶段，系统不提供建议值','无特进价,不出建议') then convert(money,NULL)
        when  sscource   not in ('系统建议值','出清价','无特进价,不出建议','当前是采购定价阶段，系统不提供建议值')
            then CAST(ROUND(a.njg_cal,1) as numeric(8,2))
        when  sscource ='出清价' then convert(numeric(8,2),0.01)
        when sscource ='系统建议值'  then   
			case when a.nsj<=10 and  a.njg_cal%1 in (0.1,0.4,0.7) then a.njg_cal+0.1 
			     when a.nsj<=10 and  a.njg_cal%1 not in (0.1,0.4,0.7) then CAST(ROUND(a.njg_cal,1) as numeric(8,2))
			     when a.nsj>10 and a.nsj<=100 and  a.njg_cal%1 =0 and a.njg_cal%10<=5
					   then floor(a.njg_cal/10)*10+5
				 when a.nsj>10 and a.nsj<=100 and  a.njg_cal%1 =0 and a.njg_cal%10 between 6 and 8.5
					   then floor(a.njg_cal/10)*10+8
			     when a.nsj>10 and a.nsj<=100 and  a.njg_cal%1 =0 and a.njg_cal%10>8.5
					   then a.njg_cal 
				 -- xiaoshu
				 when a.nsj>10 and a.nsj<=100 and  a.njg_cal%1 <>0 and a.njg_cal%1<=0.5
					   then floor(a.njg_cal/1)+0.5
				 when a.nsj>10 and a.nsj<=100 and  a.njg_cal%1 <>0 and a.njg_cal%1 between 0.51 and 0.85
					   then floor(a.njg_cal/1)+0.8
			    when a.nsj>10 and a.nsj<=100 and a.njg_cal%1 <>0 and a.njg_cal%1 >0.85
					   then floor(a.njg_cal/1)+0.9	 
				 when a.nsj>100   and a.njg_cal%10<=5
					   then floor(a.njg_cal/10)*10+5
				 when a.nsj>100  and a.njg_cal%10 between 5.01 and 8.5
					   then floor(a.njg_cal/10)*10+8
			     when a.nsj>100  and a.njg_cal%10>8.5
					   then floor(a.njg_cal/10)*10+9
			end
  end ,case when a.sflag1='未完成' and  DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 18 and 21 
    OR DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 19 and 42 
    or  DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 53 and 56
    or DATEDIFF(day,convert(date,a.Bdate),CONVERT(date,getdate())) between 67 and 76 then '需要准备下一阶段促销单' else '' end from #r2 a  
    order by 1;

  end;
else 
  begin
    return
  end;