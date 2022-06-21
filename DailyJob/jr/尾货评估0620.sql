-- -- Step 1: 基础数据准备
-- select a.sMonth,a.Bdate,a.Edate,a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,a.sgys,a.sgysmc into #raw_sp  
-- from DappSource_Dw.dbo.Tmp_TailCargo a 

 
-- -- Step 3:基础数据准备
-- -- drop table #1;
-- select a.sFdbh sFdbh,a.sFdmc sFdmc,a.sSpbh sSpbh,a.sSpmc sSpmc,a.smonth,a.Bdate,a.Edate,
-- b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
-- case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
-- when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
-- b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
-- ,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode  into #1 
-- from  #raw_sp  a 
-- left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT  b on b.DEPT_CODE=a.sFdbh and b.ITEM_CODE=a.sSpbh 
-- where 1=1 and a.sMonth='2022年5月计划' ;

-- -- drop table #Base_sp
-- select a.*,d.sort sPlbh into #Base_sp
-- from #1 a
-- left join DappSource_Dw.dbo.goods d on a.sSpbh=d.code
-- where 1=1  ; 

-- --当前库存 drop table #Base_1
-- select   a.*,ISNULL(b.CURR_STOCK,0)  nkcsl into #Base_1 from #Base_sp a
-- left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK  b
--      on   a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
-- where 1=1 ;



-- -- 销售数据 drop table #Tmp_xs1
-- select a.*,ceiling(datediff(HOUR,b.Bdate,a.sale_date)*1.0/240)*10 nxsqj,b.sMonth into #Tmp_xs1
-- from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT a
-- join #Base_1 b on a.SHOP_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
--     and a.sale_date>b.Bdate 
-- where 1=1  ;

-- -- 进出数据 drop table #2
-- select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #2
-- from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
-- join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
-- on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
-- where 1=1  and a.dsj>=convert(date,'2022-01-01') 
-- and  a.dsj<convert(date,GETDATE()) 
-- group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;

-- -- 推算库存  drop table #Tmp_qckc 


-- -- 使用历史日结库存
--  select a.sMonth,a.sFdbh,a.sSpbh,a.Bdate,isnull(b.nkcsl,0) nKcsl into #Tmp_qckc from #1  a
--  left join DappSource_Dw.dbo.tmp_kclsb b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh and a.Bdate=b.drq
--  where 1=1 ;

-- -- 展现形式
-- with xs as (select 
-- b.sMonth, b.shop_code sfdbh,b.item_code sspbh,SUM(b.SUBTOTAL-b.DISCOUNT) nxsje,
-- SUM(b.QTY) nxssl,SUM(b.QTY*b.INPUT_PRICE) ncb,
-- SUM(b.SUBTOTAL-b.DISCOUNT)-SUM(b.QTY*b.INPUT_PRICE) nml,
-- SUM(b.QTY*b.UNIT_PRICE) nyqxse,MAX(sale_date) max_xssj
-- 	from #Tmp_xs1 b group by b.sMonth,b.shop_code ,b.item_code 
-- )
-- select a.sMonth, a.sfdbh,a.sspbh,a.sspmc,a.splbh,a.spsfs,a.Stop_into,a.Stop_sale,
-- a.njj,a.nsj,a.njj*isnull(a.nkcsl,0) nkcje,
-- a.Return_attribute,a.c_disuse_date,a.Display_mode,
-- DATEDIFF(DAY,a.c_disuse_date,GETDATE()) nts,isnull(a.nkcsl,0) nqckc,b.nxssl,
-- a.nKcsl,b.max_xssj,b.nxsje,b.nml,b.nyqxse,b.ncb,
-- case when b.nxsje<>0 then b.nml/b.nxsje end nmll into #r  from #Base_1 a
-- left join xs b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and a.sMonth=b.sMonth
-- left join #tmp_qckc c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and a.sMonth=c.sMonth
-- where 1=1;

-- -- 1 完成进度
-- select a.sMonth,COUNT(1) nzsps,sum(case when ISNULL(a.nKcsl,0)<=0 then 1 else 0 end ) nqtsl,
-- sum(case when  ISNULL(a.nKcsl,0)>0 then 1 else 0 end) nwwcsl,sum(a.nKcsl*a.njj) ndqkcje,sum(nxsje) nxsje,
-- sum(nml) nxsml   from  #r a where a.Stop_into<>'N' group by a.smonth

-- select * from #r 

-- --2 折扣区间销售分布   
--  -- drop table #s1
--   select b.*,(b.SUBTOTAL-b.DISCOUNT)/b.qty  nsjsj into #s1
-- 	from #Tmp_xs1 b  
	
-- select  isnull(shop_code,'合计') sfdbh,case when qty*unit_price<>0 and   nsjsj/unit_price<0.1 then '1折以下'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.1 and nsjsj/unit_price<0.2 then '1折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.2 and nsjsj/unit_price<0.3 then '2折' 
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.3 and nsjsj/unit_price<0.4 then '3折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.4 and nsjsj/unit_price<0.5 then '4折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.5 and nsjsj/unit_price<0.6  then '5折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.6 and nsjsj/unit_price<0.7  then '6折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.7 and nsjsj/unit_price<0.8  then '7折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.8 and nsjsj/unit_price<0.9  then '8折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.9 and nsjsj/unit_price<1  then '9折'
--    when qty*unit_price<>0 and   nsjsj/unit_price>=1 then '原价'
--     end nsjzk ,COUNT(distinct item_code) nsps,SUM(SUBTOTAL-DISCOUNT) nxsje,SUM(qty) nxssl
--    ,sum(qty*input_price) nxscb,sum(qty*unit_price) nyqxse into #s2  from #s1
--      group by isnull(shop_code,'合计'),
--    case when qty*unit_price<>0 and   nsjsj/unit_price<0.1 then '1折以下'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.1 and nsjsj/unit_price<0.2 then '1折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.2 and nsjsj/unit_price<0.3 then '2折' 
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.3 and nsjsj/unit_price<0.4 then '3折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.4 and nsjsj/unit_price<0.5 then '4折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.5 and nsjsj/unit_price<0.6  then '5折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.6 and nsjsj/unit_price<0.7  then '6折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.7 and nsjsj/unit_price<0.8  then '7折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.8 and nsjsj/unit_price<0.9  then '8折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.9 and nsjsj/unit_price<1  then '9折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=1 then '原价'
--     end    with cube  ;
    
-- with x0 as (
--     select *,sum(nxsje) over(partition by sfdbh) nljxse,
--     row_number()over(partition by sfdbh 
--     order by CHARINDEX(nsjzk,'原价,9折,8折,7折,6折,5折,4折,3折,2折,1折,1折以下')) npm
--     from #s2  
--     where nsjzk is not null )
-- select  a.*    from x0  a  order by sfdbh, a.npm;

-- /*

-- select a.SHOP_CODE,a.ITEM_CODE,a.ITEM_NAME,b.sort,b.scgqy
-- ,a.UNIT_PRICE,a.SELL_PRICE,a.QTY,a.SALE_DATE,a.SUBTOTAL-a.DISCOUNT,a.nsjsj,a.INPUT_PRICE,a.c_print_type from #s1 a
-- left join DappSource_Dw.dbo.goods b on a.ITEM_CODE=b.code
-- where qty*unit_price<>0 and   nsjsj/unit_price<0.2
-- */



-- -------------  新版本
-- -- Step 1: 基础数据准备
-- select a.sMonth,a.Bdate,a.Edate,a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,a.sgys,a.sgysmc into #raw_sp  
-- from DappSource_Dw.dbo.Tmp_TailCargo a where a.sUpdate is null;

 
-- -- Step 3:基础数据准备
-- -- drop table #1;
-- select a.sFdbh sFdbh,a.sFdmc sFdmc,a.sSpbh sSpbh,a.sSpmc sSpmc,a.smonth,a.Bdate,a.Edate,
-- b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
-- case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
-- when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
-- b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
-- ,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode  into #1 
-- from  #raw_sp  a 
-- left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT  b on b.DEPT_CODE=a.sFdbh and b.ITEM_CODE=a.sSpbh 
-- where 1=1 and ( b.STOP_INTO<>'N' or b.STOP_INTO is null)  and a.sMonth='2022年5月计划' ;

-- -- drop table #Base_sp
-- select a.*,d.sort sPlbh into #Base_sp
-- from #1 a
-- left join DappSource_Dw.dbo.goods d on a.sSpbh=d.code
-- where 1=1  ; 

-- --当前库存 drop table #Base_1
-- select   a.*,ISNULL(b.nkcsl,0)  nkcsl,ISNULL(b.nkcje,0) nKcje into #Base_1 from #Base_sp a
-- left join DappSource_Dw.dbo.tmp_kclsb  b
--      on   a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and CONVERT(date,b.drq)=CONVERT(date,GETDATE()-1)
-- where 1=1 ;



-- -- 销售数据 drop table #Tmp_xs1
-- select a.*,ceiling(datediff(HOUR,b.Bdate,a.sale_date)*1.0/240)*10 nxsqj,b.sMonth into #Tmp_xs1
-- from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT a
-- join #Base_1 b on a.SHOP_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
--     and a.sale_date>=b.Bdate 
-- where 1=1  ;

-- -- 进出数据 drop table #2
-- select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #2
-- from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
-- join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
-- on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
-- where 1=1  and a.dsj>=convert(date,'2022-04-01') 
-- and  a.dsj<convert(date,GETDATE()) 
-- group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;

-- -- 推算库存  drop table #Tmp_qckc 


-- -- 使用历史日结库存
--  select a.sMonth,a.sFdbh,a.sSpbh,a.Bdate,isnull(b.nkcsl,0) nKcsl,ISNULL(b.nkcje,0) nkcje into #Tmp_qckc from #1  a
--  left join DappSource_Dw.dbo.tmp_kclsb b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh and a.Bdate=b.drq
--  where 1=1 ;

-- -- 展现形式 drop table #r
-- with xs as (select 
-- b.sMonth, b.shop_code sfdbh,b.item_code sspbh,SUM(b.SUBTOTAL-b.DISCOUNT) nxsje,
-- SUM(b.QTY) nxssl,SUM(b.QTY*b.INPUT_PRICE) ncb,
-- SUM(b.SUBTOTAL-b.DISCOUNT)-SUM(b.QTY*b.INPUT_PRICE) nml,
-- SUM(b.QTY*b.UNIT_PRICE) nyqxse,MAX(sale_date) max_xssj
-- 	from #Tmp_xs1 b group by b.sMonth,b.shop_code ,b.item_code 
-- )
-- select a.sMonth,a.Bdate,a.Edate, a.sfdbh,a.sspbh,a.sspmc,a.splbh,a.spsfs,a.Stop_into,a.Stop_sale,
-- a.njj,a.nsj,a.nkcje ,
-- a.Return_attribute,a.c_disuse_date,a.Display_mode,
-- DATEDIFF(DAY,a.c_disuse_date,GETDATE()) nts,isnull(c.nkcsl,0) nqckcsl,ISNULL(c.nkcje,0) nqckcje,b.nxssl,
-- a.nKcsl,b.max_xssj,b.nxsje,b.nml,b.nyqxse,b.ncb,
-- case when b.nxsje<>0 then b.nml/b.nxsje end nmll into #r  from #Base_1 a
-- left join xs b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and a.sMonth=b.sMonth
-- left join #tmp_qckc c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and a.sMonth=c.sMonth
-- where 1=1;

-- -- 1 完成进度
 
-- select a.sMonth,CONVERT(date,GETDATE()),COUNT(1) nzsps,sum(case when ISNULL(a.nKcsl,0)<=0 then 1 else 0 end ) nqtsl,
-- sum(case when  ISNULL(a.nKcsl,0)>0 then 1 else 0 end) nwwcsl,sum(a.nqckcje) ndqkcje,sum(a.nKcje) ndqkcje,sum(nxsje) nxsje,
-- sum(a.ncb) nxscb,sum(nml) nxsml,sum(b.nsl*a.njj)   from  #r a
-- left join #2 b on a.sFdbh=b.sfdbh and a.sspbh=b.sspbh and b.dsj>=a.Bdate and b.dsj<=a.Edate and 
-- b.sjcfl='调入(店间调拨)'
--  where a.Stop_into<>'N'  or a.STOP_INTO  is null 
--  group by a.smonth  order by 1
 

-- --2 折扣区间销售分布   
--  -- drop table #s1
--   select b.*,(b.SUBTOTAL-b.DISCOUNT)/b.qty  nsjsj into #s1
-- 	from #Tmp_xs1 b  

-- 	select * from #s1 
	
-- select a.smonth,   isnull(b.shop_code,'合计') sfdbh,case when qty*unit_price<>0 and   nsjsj/unit_price<0.1 then '1折以下'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.1 and nsjsj/unit_price<0.2 then '1折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.2 and nsjsj/unit_price<0.3 then '2折' 
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.3 and nsjsj/unit_price<0.4 then '3折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.4 and nsjsj/unit_price<0.5 then '4折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.5 and nsjsj/unit_price<0.6  then '5折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.6 and nsjsj/unit_price<0.7  then '6折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.7 and nsjsj/unit_price<0.8  then '7折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.8 and nsjsj/unit_price<0.9  then '8折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.9 and nsjsj/unit_price<1  then '9折'
--    when qty*unit_price<>0 and   nsjsj/unit_price>=1 then '原价'
--     end nsjzk ,COUNT(distinct item_code) nsps,SUM(SUBTOTAL-DISCOUNT) nxsje,SUM(qty) nxssl
--    ,sum(qty*input_price) nxscb,sum(qty*unit_price) nyqxse into #s2  from
--     #r a 
-- 	join #s1 b on a.sFdbh=b.SHOP_CODE and a.sSpbh=b.ITEM_CODE and CONVERT(date,b.SALE_DATE) between a.Bdate and a.Edate
--      group by a.sMonth, isnull(b.shop_code,'合计'),
--    case when qty*unit_price<>0 and   nsjsj/unit_price<0.1 then '1折以下'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.1 and nsjsj/unit_price<0.2 then '1折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.2 and nsjsj/unit_price<0.3 then '2折' 
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.3 and nsjsj/unit_price<0.4 then '3折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.4 and nsjsj/unit_price<0.5 then '4折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.5 and nsjsj/unit_price<0.6  then '5折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.6 and nsjsj/unit_price<0.7  then '6折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.7 and nsjsj/unit_price<0.8  then '7折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.8 and nsjsj/unit_price<0.9  then '8折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=0.9 and nsjsj/unit_price<1  then '9折'
--    when qty*unit_price<>0 and nsjsj/unit_price>=1 then '原价'
--     end    with cube  ;
    
-- with x0 as (
--     select *,sum(nxsje) over(partition by smonth, sfdbh) nljxse,
--     row_number()over(partition by sfdbh 
--     order by CHARINDEX(nsjzk,'原价,9折,8折,7折,6折,5折,4折,3折,2折,1折,1折以下')) npm
--     from #s2  
--     where nsjzk is not null )
-- select  a.*    from x0  a
-- where sfdbh  is null  order by sMonth, sfdbh, a.npm;

-- ---
-- select a.sMonth,sum(a.SUBTOTAL-a.DISCOUNT) nxsjc,sum(a.QTY*a.INPUT_PRICE) nxscb
--  from #s1 a where 1=1 and SELL_PRICE>nsjsj and nsjsj<=UNIT_PRICE*0.2
--  group by a.sMonth

--  select a.sMonth,sum(a.SUBTOTAL-a.DISCOUNT) nxsjc,sum(a.QTY*a.INPUT_PRICE) nxscb
--  from #s1 a where 1=1 and SELL_PRICE=nsjsj and nsjsj<=UNIT_PRICE*0.2
--  group by a.sMonth

 

--  select a.sMonth,a.SHOP_CODE,a.ITEM_CODE,sum(a.SUBTOTAL-a.DISCOUNT) nxsjc,sum(a.QTY*a.INPUT_PRICE) nxscb
--  from #s1 a where 1=1 and SELL_PRICE>nsjsj and nsjsj<=UNIT_PRICE*0.2
--  group by  a.sMonth,a.SHOP_CODE,a.ITEM_CODE  order by 4 desc

-- Step 1: 基础数据准备
select a.sMonth,a.Bdate,a.Edate,a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,a.sgys,a.sgysmc into #raw_sp  
from DappSource_Dw.dbo.Tmp_TailCargo a where a.sUpdate is null;

 
-- Step 3:基础数据准备
-- drop table #1;
select a.sFdbh sFdbh,a.sFdmc sFdmc,a.sSpbh sSpbh,a.sSpmc sSpmc,a.smonth,a.Bdate,a.Edate,
b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode  into #1 
from  #raw_sp  a 
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT  b on b.DEPT_CODE=a.sFdbh and b.ITEM_CODE=a.sSpbh 
where 1=1 and ( b.STOP_INTO<>'N' or b.STOP_INTO is null)  and a.sMonth='2022年5月计划' ;

-- drop table #Base_sp
select a.*,d.sort sPlbh into #Base_sp
from #1 a
left join DappSource_Dw.dbo.goods d on a.sSpbh=d.code
where 1=1  ; 

--当前库存 drop table #Base_1
select   a.*,ISNULL(b.nkcsl,0)  nkcsl,ISNULL(b.nkcje,0) nKcje into #Base_1 from #Base_sp a
left join DappSource_Dw.dbo.tmp_kclsb  b
     on   a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and CONVERT(date,b.drq)=CONVERT(date,GETDATE()-1)
where 1=1 ;



-- 销售数据 drop table #Tmp_xs1
select a.*,ceiling(datediff(HOUR,b.Bdate,a.sale_date)*1.0/240)*10 nxsqj,b.sMonth into #Tmp_xs1
from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT a
join #Base_1 b on a.SHOP_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
    and a.sale_date>=b.Bdate and a.SALE_DATE<CONVERT(date,GETDATE()) 
where 1=1  ;

-- 进出数据 drop table #2
select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #2
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
where 1=1  and a.dsj>=convert(date,'2022-04-01') 
and  a.dsj<convert(date,GETDATE()) 
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;

-- 推算库存  drop table #Tmp_qckc 


-- 使用历史日结库存
 select a.sMonth,a.sFdbh,a.sSpbh,a.Bdate,isnull(b.nkcsl,0) nKcsl,ISNULL(b.nkcje,0) nkcje into #Tmp_qckc from #1  a
 left join DappSource_Dw.dbo.tmp_kclsb b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh and a.Bdate=b.drq
 where 1=1 ;

-- 展现形式 drop table #r
with xs as (select 
b.sMonth, b.shop_code sfdbh,b.item_code sspbh,SUM(b.SUBTOTAL-b.DISCOUNT) nxsje,
SUM(b.QTY) nxssl,SUM(b.QTY*b.INPUT_PRICE) ncb,
SUM(b.SUBTOTAL-b.DISCOUNT)-SUM(b.QTY*b.INPUT_PRICE) nml,
SUM(b.QTY*b.UNIT_PRICE) nyqxse,MAX(sale_date) max_xssj
	from #Tmp_xs1 b group by b.sMonth,b.shop_code ,b.item_code 
)
select a.sMonth,a.Bdate,a.Edate, a.sfdbh,a.sspbh,a.sspmc,a.splbh,a.spsfs,a.Stop_into,a.Stop_sale,
a.njj,a.nsj,a.nkcje ,
a.Return_attribute,a.c_disuse_date,a.Display_mode,
DATEDIFF(DAY,a.c_disuse_date,GETDATE()) nts,isnull(c.nkcsl,0) nqckcsl,ISNULL(c.nkcje,0) nqckcje,b.nxssl,
a.nKcsl,b.max_xssj,b.nxsje,b.nml,b.nyqxse,b.ncb,
case when b.nxsje<>0 then b.nml/b.nxsje end nmll into #r  from #Base_1 a
left join xs b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and a.sMonth=b.sMonth
left join #tmp_qckc c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and a.sMonth=c.sMonth
where 1=1;

-- 1 完成进度
 
select a.sMonth,CONVERT(date,GETDATE()),COUNT(1) nzsps,sum(case when ISNULL(a.nKcsl,0)<=0 then 1 else 0 end ) nqtsl,
sum(case when  ISNULL(a.nKcsl,0)>0 then 1 else 0 end) nwwcsl,sum(a.nqckcje) ndqkcje,sum(a.nKcje) ndqkcje,sum(nxsje) nxsje,
sum(a.ncb) nxscb,sum(nml) nxsml,sum(b.nsl*a.njj)   from  #r a
left join #2 b on a.sFdbh=b.sfdbh and a.sspbh=b.sspbh and b.dsj>=a.Bdate and b.dsj<=a.Edate and 
b.sjcfl='调入(店间调拨)'
 where a.Stop_into<>'N'  or a.STOP_INTO  is null 
 group by a.smonth  order by 1

 select a.sMonth,CONVERT(date,GETDATE()),COUNT(1) nzsps,sum(case when ISNULL(a.nKcsl,0)<=0 then 1 else 0 end ) nqtsl,
sum(case when  ISNULL(a.nKcsl,0)>0 then 1 else 0 end) nwwcsl,sum(a.nqckcje) ndqkcje,sum(a.nKcje) ndqkcje,sum(nxsje) nxsje,
sum(a.ncb) nxscb,sum(nml) nxsml   from  #r a 
 where a.Stop_into<>'N'  or a.STOP_INTO  is null 
 group by a.smonth  order by 1;
 
 
 select a.sMonth,a.Bdate,a.Edate,
max(DATEDIFF(day,a.bdate,a.Edate)),
max(DATEDIFF(day,a.bdate,convert(date,getdate()))),COUNT(1) ,COUNT(distinct sFdbh) nfds,COUNT(distinct sSpbh) nsps
 from #r  a 
where 1=1  group by a.sMonth,a.Bdate,a.Edate
order by a.sMonth
 

--2 折扣区间销售分布   
 -- drop table #s1
  select b.*,(b.SUBTOTAL-b.DISCOUNT)/b.qty  nsjsj into #s1
	from #Tmp_xs1 b  

	select * from #s1 
	-- drop table #s2
select a.smonth,   isnull(b.shop_code,'合计') sfdbh,case when qty*unit_price<>0 and   nsjsj/unit_price<0.1 then '1折以下'
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
   ,sum(qty*input_price) nxscb,sum(qty*unit_price) nyqxse into #s2  from
    #r a 
	join #s1 b on a.sFdbh=b.SHOP_CODE and a.sSpbh=b.ITEM_CODE and CONVERT(date,b.SALE_DATE) between a.Bdate and a.Edate
     group by a.sMonth, isnull(b.shop_code,'合计'),
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
   when qty*unit_price<>0 and nsjsj/unit_price>=1 then '原价'
    end    with cube  ;
    
with x0 as (
    select *,sum(nxsje) over(partition by smonth, sfdbh) nljxse,
    row_number()over(partition by sfdbh 
    order by CHARINDEX(nsjzk,'原价,9折,8折,7折,6折,5折,4折,3折,2折,1折,1折以下')) npm
    from #s2  
    where nsjzk is not null )
select  a.*    from x0  a
where sfdbh  is null  order by sMonth, sfdbh, a.npm;

 
select a.sMonth,sum(a.SUBTOTAL-a.DISCOUNT) nxsjc,sum(a.QTY*a.INPUT_PRICE) nxscb
 from #s1 a where 1=1 and SELL_PRICE=nsjsj and nsjsj<=UNIT_PRICE*0.2
 group by a.sMonth  order by 1

 select a.sMonth,sum(a.SUBTOTAL-a.DISCOUNT) nxsjc,sum(a.QTY*a.INPUT_PRICE) nxscb
 from #s1 a where 1=1 and SELL_PRICE>nsjsj and nsjsj<=UNIT_PRICE*0.2
 group by a.sMonth  order by 1


 

 select a.sMonth,a.SHOP_CODE,a.ITEM_CODE,sum(a.SUBTOTAL-a.DISCOUNT) nxsjc,sum(a.QTY*a.INPUT_PRICE) nxscb
 from #s1 a where 1=1 and SELL_PRICE>nsjsj and nsjsj<=UNIT_PRICE*0.2
 group by  a.sMonth,a.SHOP_CODE,a.ITEM_CODE  order by 4 desc

 -- drop table #sjxs
 select a.sMonth,a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,a.ITEM_NAME sspmc,
 sum(a.SUBTOTAL-a.DISCOUNT) nxsje,sum(a.qty) nxssl,sum(a.QTY*a.INPUT_PRICE) nxscb,
 sum(a.UNIT_PRICE*a.QTY) nyqxse into #sjxs
   from #s1 a  where CONVERT(date,SALE_DATE)<CONVERT(date,GETDATE())
   group by  a.sMonth,a.SHOP_CODE  ,a.ITEM_CODE  ,a.ITEM_NAME;

select a.sMonth,case  when b.sFdbh is not null and  b.nxsje*1.0/b.nyqxse>=0.45 then 'y' 
when  b.sFdbh is not null and  b.nxsje*1.0/b.nyqxse<0.45  then   'N' 
when b.sFdbh is null  then 'bdx'  end ,
COUNT(1),sum(case when ISNULL(a.nKcsl,0)<=0 then 1 else 0 end ) nqtsl,
sum(case when  ISNULL(a.nKcsl,0)>0 then 1 else 0 end) nwwcsl,sum(a.nqckcje) nqckcje,sum(a.nKcje) ndqkcje,sum(b.nxsje),sum(b.nxscb)
from #r a 
left join #sjxs b on a.sMonth=b.sMonth and a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.nyqxse>0
where a.sMonth='2022年5月计划'  group by a.sMonth,case  when b.sFdbh is not null and  b.nxsje*1.0/b.nyqxse>=0.45 then 'y' 
when  b.sFdbh is not null and  b.nxsje*1.0/b.nyqxse<0.45  then   'N' 
when b.sFdbh is null  then 'bdx'  end


select a.sMonth,case  when b.sFdbh is not null and  b.nxsje*1.0/b.nyqxse>=0.65 then 'y' 
when  b.sFdbh is not null and  b.nxsje*1.0/b.nyqxse<0.65  then   'N' 
when b.sFdbh is null  then 'bdx'  end ,
COUNT(1),sum(case when ISNULL(a.nKcsl,0)<=0 then 1 else 0 end ) nqtsl,
sum(case when  ISNULL(a.nKcsl,0)>0 then 1 else 0 end) nwwcsl,sum(b.nxsje) ,sum(b.nyqxse),sum(b.nxscb)
from #r a 
left join #sjxs b on a.sMonth=b.sMonth and a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.nyqxse>0
where a.sMonth='2022年6月计划'  group by a.sMonth,case  when b.sFdbh is not null and  b.nxsje*1.0/b.nyqxse>=0.65 then 'y' 
when  b.sFdbh is not null and  b.nxsje*1.0/b.nyqxse<0.65  then   'N' 
when b.sFdbh is null  then 'bdx'  end




--------- 商品库龄计算

select CONVERT(date,a.dsj) dsj,a.sfdbh, b.sspbh,SUM(b.nsl) nsl  into #tmp_jc
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
where 1=1  and a.dsj>=convert(date,'2020-01-01') 
and  a.dsj<convert(date,GETDATE()) 
group by CONVERT(date,a.dsj),a.sfdbh ,b.sspbh;




 

select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc) npm
into #jcpm  from  #tmp_jc a 
where a.nsl>0;

select a.sMonth,a.Bdate,a.Edate,a.sFdbh,a.sSpbh,a.sSpmc,a.sPlbh,a.spsfs,a.STOP_INTO,a.STOP_SALE,a.njj,a.nsj,a.nkcsl
,a.nKcje,a.RETURN_ATTRIBUTE,case  when  isnull(c.validperiod,0)=0 and  c.scgqy='非食品部' then 750 
when  isnull(c.validperiod,0)=0 and  c.scgqy<>'非食品部' then 300 else  c.validperiod end nbzq  ,c.scgqy
,b.dsj,b.nsl,DATEDIFF(day,ISNULL(b.dsj,convert(date,'2020-01-01')),CONVERT(date,getdate())) ndys  into #bzq  from #r a 
left join #jcpm b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh  and b.npm=1
left join DappSource_Dw.dbo.goods c on a.sSpbh=c.code 
where 1=1  order by a.sMonth 


select a.*, a.ndys*1.0/a.nbzq nlb,case when a.ndys*1.0/a.nbzq >=0.7 then 'lq' else 'flq' end  from #bzq a 

 
 