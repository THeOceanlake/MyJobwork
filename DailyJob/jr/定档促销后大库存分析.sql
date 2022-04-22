
select * into #Tmp_PromotionPlan from [122.147.10.200].dappsource.dbo.Tmp_promotionPlan
where  sdh in ('20220211131327092','20220226133627980');

select * into #PromotionPlan_receipt from  [122.147.10.200].dappsource.dbo.PromotionPlan_Receipt
where sddfadh  in ('20220211131327092','20220226133627980');

select  * into #PromotionPlan_receipt_items from  [122.147.10.200].dappsource.dbo.PromotionPlan_Receipt_items
where sdh   in ( select distinct sdh from #PromotionPlan_receipt);

select * from #PromotionPlan_receipt_items
/*
    JR 定档促销的业务特点
    1、提前半月做计划，出预计订货量
    2、要求在促销之前，系统建议量或手工修改量需铺货到位-实际会有差异；
    3、促销中理论上人工不补货，如果库存较低，系统会及时补货

那么现在造成大库存会存在多个原因：
    1、系统预测量过大——预测销售与实际销售差别很大
    2、人工补货，人工补货分两种，促销前和促销中额外下单——数据上表现就是，整个期间人工订货占总体进货的占比大
库存时间点 定档日，促销开始日，促销结束日
销售区间：促销期间销售

*/


-- Step 1 ：取数
select c.sdh,c.sTitle,c.ReceiptType,c.bdate,c.edate,b.sfdbh,a.sspbh,a.nYjRjxl ,a.nJycglOld,a.nJycgl ,
a.nsl ,a.nsl_fd,a.nzdcl,a.Dctime,a.nkc，a.nsl_raw into #1 from #PromotionPlan_Receipt_Items a,#PromotionPlan_Receipt b,#tmp_PromotionPlan c
where a.sdh=b.sdh and b.sDdfadh=c.sdh  order by c.sdh

-- Step 2:历史库存表  drop table  #Tmp_mdkc_sl 
        select c_day_date drq, c_store_id sfdbh,c_gcode sspbh,c_number nkcsl,c_A nKcje into #Tmp_mdkc_sl  
         from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date in (to_date(''2022-02-28'',''yyyy/mm/dd''),to_date(''2022-03-14'',''yyyy/mm/dd''),
        to_date(''2022-03-29'',''yyyy/mm/dd''))');

-- Step 3:销售数据
select b.sdh, a.SHOP_CODE sfdbh,a.ITEM_CODE sspbh,sum(a.SALE_QTY) nxssl into #Tmp_xs 
from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
		join #1 b on a.ITEM_CODE=b.sSpbh and a.SHOP_CODE=b.sFdbh
		where    CONVERT(date,a.SALE_DATE)>=convert(date,b.bdate)   
         and  CONVERT(date,a.SALE_DATE)<=CONVERT(date,b.edate)
		  group by  b.sdh, a.SHOP_CODE,a.ITEM_CODE;

select * from #Tmp_xs a 

-- Step 4 订单数据
 
select  a.dYhrq,b.ddhrq dShrq,a. sdjlx sLx,b.sfdbh,b.sspbh,b.nsl nYhsl,b.ndhsl,b.sBzmx into #Tmp_yh_r
from [122.147.10.200].dappsource.dbo.tmp_yhb a 
inner join [122.147.10.200].dappsource.dbo.tmp_yhmx b
    on a.sdh=b.sdh and a.sFdbh=b.sFdbh
where 1=1  and a.dYhrq>=CONVERT(date,'2022-02-28')  
and (  a.dYhrq+2<GETDATE() or b.ddhrq is not null); 

 with  x1 as (select a.*,b.sdh scxdh from  #Tmp_yh_r a
  join #1 b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh  where  1=1 and a.dShrq>=CONVERT(date,b.bdate)
  and a.dShrq<=CONVERT(date,b.edate) )
select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id 
into #Tmp_yh 
from x1 a ;
 

-- D zixun 原表 drop table #2

select d.sdh scxdh, CONVERT(date,b.dctime) dYhrq,a.sdh,isnull(a.sfdbh,c.sfdbh) sfdbh,
isnull(b.sspbh,c.sspbh) sspbh,ISNULL(c.nsl,b.nsl) nCgsl,b.nsl_raw ncgsl_raw,'' genstate,''smemo
into #2 from [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT a
join [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT_items b  on a.sdh=b.sdh
left join  [122.147.10.200].dappsource.dbo.delivery_receipt_zt c on b.sdh=c.sdh and b.sspbh=c.sspbh
join #1 d on  isnull(a.sfdbh,c.sfdbh)=d.sfdbh and ISNULL(b.sspbh,c.sspbh)=d.sspbh
where 1=1 and CONVERT(date,b.dctime)>=CONVERT(date,d.bdate) and  ISNULL(c.nsl,b.nsl)>0
and CONVERT(date,b.dctime)<=CONVERT(date,d.edate);
 

 -- drop table #dzixun_raw
select a.* into #dzixun_raw  from #2 a
join #1 d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh and a.scxdh=d.sdh
where 1=1;


-- 单据汇总  drop table #TMP_dh_cal
select * into #BusType from [122.147.10.200].DAppSource.dbo.BusType;

with x0 as (
select scxdh, sfdbh,sspbh,dyhrq,dshrq,slx,nyhsl,ndhsl,sbzmx,id,'要货' flag
 -- ,isnull(c.sname,case when a.sbzmx like '%自动生成%' or a.sbzmx like ';;%' then '自动补货'
 -- end ) sSource 
 from #tmp_yh  a
-- left join #BusType c on 1=1 and CHARINDEX(c.sName,a.sbzmx,0)>1
)
select ISNULL(a.scxdh,b.scxdh) scxdh,  ISNULL(a.sFdbh,b.sFdbh) sfdbh,ISNULL(a.sspbh,b.sSpbh) sspbh,
ISNULL(a.dYhrq,b.dYhrq) dYhrq,a.dShrq, a.nYhsl,b.nCgsl nYhsl_raw,b.ncgsl_raw ncgsl_old,
a.ndhsl nShsl,b.GenState,b.sMemo,a.sLx,sbzmx sBz,a.flag,
ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
ISNULL(a.sspbh,b.sSpbh) order by isnull(a.dyhrq,b.dyhrq) desc) npm_cal,
case when a.sFdbh is null then '系统单' end is_auto,a.sSource into #TMP_dh_cal
  from x0 a full join #dzixun_raw b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and a.scxdh=b.scxdh
and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)>0 and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)<24 
where 1=1 ;


-- Step 5 : drop table #Tmp_qjyh

select a.scxdh,a.sfdbh,a.sspbh,sum(case when a.sBz like '%自动生成%' then isnull(a.nYhsl,0)  end ) nzdyhl,
sum(case when a.sBz not  like '%自动生成%' then isnull(a.nYhsl,0)  end ) nypyhl,
sum(case when a.sBz like '%自动生成%' then isnull(a.nshsl,0)  end ) nzddhl,
sum(case when a.sBz not  like '%自动生成%' then isnull(a.nShsl,0)  end ) nypshl 
  into #Tmp_qjyh from   #TMP_dh_cal  a
group by a.scxdh,a.sfdbh,a.sspbh

select * from Tmp_qjyh 

-- Step 6 :jc
select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #jc1
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh 
where 1=1  
and a.dsj>CONVERT(date,'2022-02-28')
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;

select b.sdh,a.sfdbh,a.sspbh,sum(a.nsl) nqjjc into #TMp_qjjc from #jc1 a 
join #1 b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and a.dsj>=CONVERT(date,b.Bdate) and a.dsj<dateadd(day,1,CONVERT(date,b.edate))
where 1=1 group by b.sdh,a.sfdbh,a.sspbh;


select * from #jc1 where sfdbh='012001' and sspbh='22080187'


select * from   #Tmp_qjyh where sfdbh='012001' and sspbh='22080187'

-- Step 7 :汇总数据
select a.sdh,a.sTitle,a.Bdate,a.Edate,a.sfdbh,a.sspbh,h.name,
case when g.SEND_CLASS_T='01' then '配送' when g.SEND_CLASS_T='02' then '直送'
when g.SEND_CLASS_T='03' then '一步越库' when g.SEND_CLASS_T='04' then '二步越库' end spsfs,g.MIN_PURCHASE_QTY,
a.nkc nddkc
,b.nkcsl ncxqkc,c.nkcsl ncshkc,a.nsl,a.nsl_raw,a.nsl_fd,a.nzdcl,
case when a.nsl_fd is not null and  a.nsl_fd>a.nJycgl then '手工改大' else '系统建议' end ssfxg, a.nJycglOld  nyjxl,
d.nxssl nsjxl,e.nqjjc nzjcl,f.nzdyhl,f.nypyhl,f.nzddhl,f.nypshl,
case when c.nkcsl>b.nkcsl then 'bd' end ,c.drq  from #1 a 
left join #Tmp_mdkc_sl b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and DATEDIFF(day,CONVERT(date,b.drq),CONVERT(date,a.Bdate))=1
left join #Tmp_mdkc_sl c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and  CONVERT(date,c.drq)=CONVERT(date,a.Edate)
left join #Tmp_xs d on a.sdh=d.sdh and a.sFdbh=d.sfdbh and a.sspbh=d.sSpbh
left join #TMp_qjjc e on a.sdh=e.sdh and a.sfdbh=e.sfdbh and a.sspbh=e.sspbh
left join #Tmp_qjyh f on a.sdh=f.scxdh and a.sfdbh=f.sfdbh and a.sspbh=f.sspbh
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT g on a.sfdbh=g.DEPT_CODE and a.sspbh=g.ITEM_CODE
left join DappSource_Dw.dbo.goods h on a.sspbh=h.code
where 1=1 order by a.sdh,a.sfdbh,a.sspbh;

/*
  1、销售预测准确率：实际销售与预测销售差异不超过20%
  2、库存变大的原因
  包装数：无其他进出
  最低陈列
*/
select a.sdh,a.sTitle,a.Bdate,a.Edate,a.sfdbh,a.sspbh,h.name,
case when g.SEND_CLASS_T='01' then '配送' when g.SEND_CLASS_T='02' then '直送'
when g.SEND_CLASS_T='03' then '一步越库' when g.SEND_CLASS_T='04' then '二步越库' end spsfs,g.MIN_PURCHASE_QTY,
a.nkc nddkc
,b.nkcsl ncxqkc,c.nkcsl ncshkc,a.nsl,a.nsl_raw,a.nsl_fd,a.nzdcl,
case when a.nsl_fd is not null and  a.nsl_fd>a.nJycgl then '手工改大' else '系统建议' end ssfxg, a.nJycglOld  nyjxl,
d.nxssl nsjxl,e.nqjjc nzjcl,f.nzdyhl,f.nypyhl,f.nzddhl,f.nypshl, j.nxssl,
case when   isnull(j.nxssl,0)=0 then 1000  when  isnull(j.nxssl,0)>0 then c.nkcsl*30.0/j.nxssl end  nsjzz,i.nPlzzts  into #r      from #1 a 
left join #Tmp_mdkc_sl b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and DATEDIFF(day,CONVERT(date,b.drq),CONVERT(date,a.Bdate))=1
left join #Tmp_mdkc_sl c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and  CONVERT(date,c.drq)=CONVERT(date,a.Edate)
left join #Tmp_xs d on a.sdh=d.sdh and a.sFdbh=d.sfdbh and a.sspbh=d.sSpbh
left join #TMp_qjjc e on a.sdh=e.sdh and a.sfdbh=e.sfdbh and a.sspbh=e.sspbh
left join #Tmp_qjyh f on a.sdh=f.scxdh and a.sfdbh=f.sfdbh and a.sspbh=f.sspbh
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT g on a.sfdbh=g.DEPT_CODE and a.sspbh=g.ITEM_CODE
left join DappSource_Dw.dbo.goods h on a.sspbh=h.code
left join DappSource_Dw.dbo.Tmp_sort_standard i on left(h.sort,4)=i.sFlbh and dateadd(day,1,CONVERT(date,a.edate))=i.drq
left join #Tmp_xs1 j on a.sdh=j.sdh and a.sfdbh=j.sfdbh and a.sspbh=j.sspbh
where 1=1 and a.sfdbh not in ('018320','018300','012011','012001','018308','018346','018390','018391')
  order by a.sdh,a.sfdbh,a.sspbh;


---------------- V1 
select * from

select c.bdate,c.edate,b.sfdbh,a.sspbh,a.nYjRjxl as 预计日均销量,a.nJycglOld as 预计总销量,a.nJycgl as 建议采购量,
a.nsl as 实际采购量 from PromotionPlan_Receipt_Items a,PromotionPlan_Receipt b,tmp_PromotionPlan c
where a.sdh=b.sdh and b.sDdfadh=c.sdh

 


select * into #Tmp_PromotionPlan from [122.147.10.200].dappsource.dbo.Tmp_promotionPlan
where  sdh in ('20220211131327092','20220226133627980');

select * into #PromotionPlan_receipt from  [122.147.10.200].dappsource.dbo.PromotionPlan_Receipt
where sddfadh  in ('20220211131327092','20220226133627980');

select  * into #PromotionPlan_receipt_items from  [122.147.10.200].dappsource.dbo.PromotionPlan_Receipt_items
where sdh   in ( select distinct sdh from #PromotionPlan_receipt);

select * from  #PromotionPlan_receipt_items

-- Step 1 ：取数 drop table #1 
select c.sdh,c.sTitle,c.ReceiptType,c.bdate,c.edate,b.sfdbh,a.sspbh,a.nYjRjxl ,a.nJycglOld,a.nJycgl ,a.nrjxl,
a.nsl ,a.nsl_fd,a.nzdcl,a.Dctime,a.nsl_raw,a.nKc into #1 from #PromotionPlan_Receipt_Items a,#PromotionPlan_Receipt b,#tmp_PromotionPlan c
where a.sdh=b.sdh and b.sDdfadh=c.sdh  order by c.sdh

-- Step 2:历史库存表  drop table  #Tmp_mdkc_sl 
        select c_day_date drq, c_store_id sfdbh,c_gcode sspbh,c_number nkcsl,c_A nKcje into #Tmp_mdkc_sl  
         from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date in (to_date(''2022-02-28'',''yyyy/mm/dd''),to_date(''2022-03-14'',''yyyy/mm/dd''),
        to_date(''2022-03-29'',''yyyy/mm/dd''))');

-- Step 3:销售数据
select b.sdh, a.SHOP_CODE sfdbh,a.ITEM_CODE sspbh,sum(a.SALE_QTY) nxssl into #Tmp_xs 
from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
		join #1 b on a.ITEM_CODE=b.sSpbh and a.SHOP_CODE=b.sFdbh
		where    CONVERT(date,a.SALE_DATE)>=convert(date,b.bdate)   
         and  CONVERT(date,a.SALE_DATE)<=CONVERT(date,b.edate)
		  group by  b.sdh, a.SHOP_CODE,a.ITEM_CODE;

select * from #Tmp_xs a 

-- Step 4 订单数据 -- drop table  #Tmp_yh_r
 
select  a.dYhrq,b.ddhrq dShrq,a. sdjlx sLx,b.sfdbh,b.sspbh,b.nsl nYhsl,b.ndhsl,b.sBzmx into #Tmp_yh_r
from [122.147.10.200].dappsource.dbo.tmp_yhb a 
inner join [122.147.10.200].dappsource.dbo.tmp_yhmx b
    on a.sdh=b.sdh and a.sFdbh=b.sFdbh
where 1=1  and a.dYhrq>=CONVERT(date,'2022-02-01')  
and (  a.dYhrq+2<GETDATE() or b.ddhrq is not null); 

-- drop table #Tmp_yh
 with  x1 as (select a.*,b.sdh scxdh from  #Tmp_yh_r a
  join #1 b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh  where  1=1 and a.dShrq>=CONVERT(date,b.bdate)
  and a.dShrq<=CONVERT(date,b.edate) )
select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id 
into #Tmp_yh 
from x1 a ;
 

-- D zixun 原表 drop table #2

select d.sdh scxdh, CONVERT(date,b.dctime) dYhrq,a.sdh,isnull(a.sfdbh,c.sfdbh) sfdbh,
isnull(b.sspbh,c.sspbh) sspbh,ISNULL(c.nsl,b.nsl) nCgsl,b.nsl_raw ncgsl_raw,'' genstate,''smemo
into #2 from [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT a
join [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT_items b  on a.sdh=b.sdh
left join  [122.147.10.200].dappsource.dbo.delivery_receipt_zt c on b.sdh=c.sdh and b.sspbh=c.sspbh
join #1 d on  isnull(a.sfdbh,c.sfdbh)=d.sfdbh and ISNULL(b.sspbh,c.sspbh)=d.sspbh
where 1=1 and CONVERT(date,b.dctime)>=CONVERT(date,'2022-02-01') and  ISNULL(c.nsl,b.nsl)>0
and CONVERT(date,b.dctime)<=CONVERT(date,d.edate);
 

 -- drop table #dzixun_raw
select a.* into #dzixun_raw  from #2 a
join #1 d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh and a.scxdh=d.sdh
where 1=1;


-- 单据汇总  drop table #TMP_dh_cal
select * into #BusType from [122.147.10.200].DAppSource.dbo.BusType;
select * from #BusType
with x0 as (
select scxdh, sfdbh,sspbh,dyhrq,dshrq,slx,nyhsl,ndhsl,sbzmx,id,'要货' flag from #tmp_yh  a
-- left join #BusType c on 1=1 and CHARINDEX(c.sName,a.sbzmx,0)>1 and sType='Delivery' and len(c.sParentseName)>0 
where   1=1
)
select ISNULL(a.scxdh,b.scxdh) scxdh,  ISNULL(a.sFdbh,b.sFdbh) sfdbh,ISNULL(a.sspbh,b.sSpbh) sspbh,
ISNULL(a.dYhrq,b.dYhrq) dYhrq,a.dShrq, a.nYhsl,b.nCgsl nYhsl_raw,b.ncgsl_raw ncgsl_old,
a.ndhsl nShsl,b.GenState,b.sMemo,a.sLx,sbzmx sBz,a.flag,
ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
ISNULL(a.sspbh,b.sSpbh) order by isnull(a.dyhrq,b.dyhrq) desc) npm_cal,
case when a.sFdbh is null then '系统单' end is_auto into #TMP_dh_cal
  from x0 a full join #dzixun_raw b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and a.scxdh=b.scxdh
and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)>0 and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)<24 
where 1=1 ;


-- Step 5 : drop table #Tmp_qjyh

select a.scxdh,a.sfdbh,a.sspbh,sum(case when a.sBz like '%自动生成%' and a.nYhsl_raw is not null and a.nYhsl_raw>=a.nYhsl then isnull(a.nYhsl,0)  end ) nzdyhl,
sum(case when a.sBz not  like '%自动生成%'  or ( a.sBz like '%自动生成%'  and a.nYhsl>a.nYhsl_raw) then isnull(a.nYhsl,0)  end ) nypyhl,
sum(case when a.sBz like '%自动生成%'  and a.nYhsl_raw is not null and a.nYhsl_raw>=a.nYhsl  then isnull(a.nshsl,0)  end ) nzddhl,
sum(case when a.sBz not  like '%自动生成%'  or ( a.sBz like '%自动生成%'  and a.nYhsl>a.nYhsl_raw)  then isnull(a.nShsl,0)  end ) nypshl 
  into #Tmp_qjyh from   #TMP_dh_cal  a
  join #1 b on a.scxdh=b.sdh and a.sfdbh=b.sfdbh and a.sspbh=b.sspbh 
where a.dShrq>=CONVERT(date,b.Dctime) and a.dShrq<=CONVERT(date,b.edate) and a.dShrq is not null
group by a.scxdh,a.sfdbh,a.sspbh

select * from #TMP_dh_cal  where sfdbh='018336' and sspbh='28010614' 


select * from #dzixun_raw  where sfdbh='012001' and sspbh='22020302' 
select * from #Tmp_yh  where sfdbh='018348' and sspbh='22090039' 
select * from #jc1   where sfdbh='018423' and sspbh='45040206' 

select * from #TMp_qjjc   where sfdbh='018423' and sspbh='45040206' 
select * from #1   where sfdbh='018423' and sspbh='45040206' 


-- Step 6 :jc
-- drop table #jc1
select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #jc1
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh 
where 1=1  
and a.dsj>CONVERT(date,'2022-02-15')
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;
-- drop table #TMp_qjjc
select b.sdh,a.sfdbh,a.sspbh,sum(isnull(a.nsl,0)) nqjjc into #TMp_qjjc from #jc1 a 
join #1 b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and a.dsj>=CONVERT(date,b.Dctime) and a.dsj<dateadd(day,1,CONVERT(date,b.edate))
where 1=1 group by b.sdh,a.sfdbh,a.sspbh;
 

-- zz  he xx
select b.sdh, a.SHOP_CODE sfdbh,a.ITEM_CODE sspbh,sum(a.SALE_QTY) nxssl into #Tmp_xs1 
from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
		join #1 b on a.ITEM_CODE=b.sSpbh and a.SHOP_CODE=b.sFdbh
		where    CONVERT(date,a.SALE_DATE)>=dateadd(day,-29,convert(date,b.edate))   
         and  CONVERT(date,a.SALE_DATE)<=CONVERT(date,b.edate)
		  group by  b.sdh, a.SHOP_CODE,a.ITEM_CODE;

-- Step 7 :汇总数据  drop table #r
select a.sdh,a.sTitle,a.Bdate,a.Edate,a.sfdbh,a.sspbh,h.name,
case when g.SEND_CLASS_T='01' then '配送' when g.SEND_CLASS_T='02' then '直送'
when g.SEND_CLASS_T='03' then '一步越库' when g.SEND_CLASS_T='04' then '二步越库' end spsfs,g.MIN_PURCHASE_QTY,
a.nkc nddkc
,b.nkcsl ncxqkc,c.nkcsl ncshkc,a.nsl,a.njycgl,a.nsl_fd,a.nzdcl,
case when a.nJycgl=0 and a.nsl=0 then '定档方案建议不进货'
     when a.nsl_fd is not null and  a.nsl_fd>a.nJycgl then '定档时手工改大'
     when a.nsl_fd is null and a.njycgl<a.nsl then '陈列和包装数过大' else '系统建议' end ssfxg, a.nJycglOld  nyjxl,
d.nxssl nsjxl,e.nqjjc nzjcl,f.nzdyhl,f.nypyhl,f.nzddhl,f.nypshl, j.nxssl nxl_30,
case when   isnull(j.nxssl,0)=0 then 1000  when  isnull(j.nxssl,0)>0 then c.nkcsl*30.0/j.nxssl end  nsjzz,isnull(i.nPlzzts,55) nPlzzts
,a.nrjxl  into #r      from #1 a 
left join #Tmp_mdkc_sl b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and DATEDIFF(day,CONVERT(date,b.drq),CONVERT(date,a.Bdate))=1
left join #Tmp_mdkc_sl c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and  CONVERT(date,c.drq)=CONVERT(date,a.Edate)
left join #Tmp_xs d on a.sdh=d.sdh and a.sFdbh=d.sfdbh and a.sspbh=d.sSpbh
left join #TMp_qjjc e on a.sdh=e.sdh and a.sfdbh=e.sfdbh and a.sspbh=e.sspbh
left join #Tmp_qjyh f on a.sdh=f.scxdh and a.sfdbh=f.sfdbh and a.sspbh=f.sspbh
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT g on a.sfdbh=g.DEPT_CODE and a.sspbh=g.ITEM_CODE
left join DappSource_Dw.dbo.goods h on a.sspbh=h.code
left join DappSource_Dw.dbo.Tmp_sort_standard i on left(h.sort,4)=i.sFlbh and dateadd(day,1,CONVERT(date,a.edate))=i.drq
left join #Tmp_xs1 j on a.sdh=j.sdh and a.sfdbh=j.sfdbh and a.sspbh=j.sspbh
where 1=1 and a.sfdbh not in ('018320','018300','012011','012001','018308','018346','018390','018391')
  order by a.sdh,a.sfdbh,a.sspbh;


select *,
case  when ISNULL(ncshkc,0)>10  and nsjzz>=nPlzzts then '高库存'  end sfgcc,
case when ISNULL(nsjxl,0)>=nyjxl*0.7 and ISNULL(nsjxl,0)<=nyjxl*1.3 then '预测准确' else '预测不准确' end ssfyc
    from #r


-- result anail
-- drop table #R_gck 
select *,CONVERT(varchar(30),'') syy1,CONVERT(varchar(30),'') syy into #R_gck
    from #r where  ISNULL(ncshkc,0)>10  and nsjzz>=nPlzzts; 

	
	update a set a.syy='本身高库存' from #R_gck a where njycgl=0 and nsl=0 and ISNULL(nzjcl,0)<=0 

	
	update a set a.syy='定档后硬配补货' from #R_gck a where njycgl=0 and nsl=0 and ISNULL(nzjcl,0)>0
	and len(a.syy)=0  and  nzjcl*0.5<=nypshl;

	update a set a.syy='自动补货' from #R_gck a where njycgl=0 and nsl=0 and ISNULL(nzjcl,0)>0
	and len(a.syy)=0  and  nzjcl*0.5<=nzddhl;

	update a set a.syy='定档后人工补货' from #R_gck a where njycgl=0 and nsl=0 and ISNULL(nzjcl,0)>0
	and len(a.syy)=0  and ncshkc*0.4<=nzjcl   ;



	update a set a.syy= case when  ssfxg='陈列和包装数过大' then  '陈列和包装数过大' 
	   when  ssfxg='系统建议' then '自动补货'  else ssfxg end  from #R_gck a where  nsl>0    and ISNULL(nzjcl,0)<=0
	and len(a.syy)=0    ;


	update a set a.syy= case when  ssfxg='陈列和包装数过大' then  '陈列和包装数过大'
	when  ssfxg='系统建议' then '自动补货' else ssfxg end  from #R_gck a where  nsl>0   and ISNULL(nzjcl,0)>0
	and len(a.syy)=0  and nzjcl<=nsl*1.1  ;
	-- 有建议量且进出大就按　来源分

	update a set a.syy= case  when  nzjcl*0.5<=nypshl   then '硬配补货'
	       when  nzjcl*0.5<=nzddhl then '自动补货' when   nzddhl is null and nypshl is null  then '其他人工补货'
		      end  from #R_gck a where  nsl>0   and ISNULL(nzjcl,0)>0
	and len(a.syy)=0  and nzjcl>nsl*1.1  ;

		update a set a.syy= case  when  nzjcl*0.5<=nypshl   then '定档后硬配补货'
	       when  nzjcl*0.5<=nzddhl then '自动补货' when   nzddhl is null and nypshl is null  then '其他人工补货'
		      end  from #R_gck a where  nsl=0   and ISNULL(nzjcl,0)>0
	and len(a.syy)=0    ;

	
		update a set a.syy='本身高库存'  from #R_gck a where  nsl=0   and ISNULL(nzjcl,0)<=0
	and len(a.syy)=0    ;

	
		update a set a.syy=case  when  nzjcl*0.5<=nypshl   then '定档后硬配补货'
	       when  nzjcl*0.5<=nzddhl then '自动补货'
		     
		    when   nzddhl is null and nypshl is null  then '定档后人工补货'
		     else   '定档后人工补货' end   from #R_gck a where  nsl=0   and ISNULL(nzjcl,0)>0
	    and len(a.syy)=0 or syy is null     ;

	select * from #R_gck a where syy is NULL 

	--
	select  a.sdh,a.syy,count(1) from #R_gck a where   1=1 group by a.sdh,a.syy  order by a.sdh 

	select a.*,
case  when ISNULL(a.ncshkc,0)>10  and a.nsjzz>=a.nPlzzts then '高库存'  end sfgcc,
case when ISNULL(a.nsjxl,0)<=10 and a.nyjxl<=10 then '预测准确'
when  ISNULL(a.nsjxl,0)>10 and a.nyjxl>10 and  ISNULL(a.nsjxl,0)>=a.nyjxl*0.7 and  ISNULL(a.nsjxl,0)<=a.nyjxl*1.3 then  '预测准确'
   else '预测不准确' end ssfyc,b.syy,c.SHIFT_PRICE njj,a.njycgl*c.SHIFT_PRICE njyje,a.nsl*c.SHIFT_PRICE nsjje from #r a 
	left join #R_gck b on a.sdh=b.sdh and a.sfdbh=b.sfdbh and a.sspbh=b.sspbh 
	left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT c on a.sfdbh=c.DEPT_CODE and a.sspbh=c.ITEM_CODE
	where 1=1 order by a.sdh,a.sfdbh,a.sspbh


		select a.*,
case  when ISNULL(a.ncshkc,0)>10  and a.nsjzz>=a.nPlzzts then '高库存'  end sfgcc,
case when ISNULL(a.nsjxl,0<=10 and a.nyjxl<=10 then '预测准确'
when  ISNULL(a.nsjxl,0)>10 and a.nyjxl>10 and  ISNULL(a.nsjxl,0)>=a.nyjxl*0.7 and  ISNULL(a.nsjxl,0)<=a.nyjxl*1.3 then  '预测准确'
   else '预测不准确' end ssfyc,b.syy from #r a 
	left join #R_gck b on a.sdh=b.sdh and a.sfdbh=b.sfdbh and a.sspbh=b.sspbh 
	where 1=1 order by a.sdh,a.sfdbh,a.sspbh

