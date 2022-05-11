-- 自动补货商品明细
select a.sfdbh,b.sflbh into #zdbhfl
from [122.147.10.200].dappsource.dbo.sys_deliverysort a,
[122.147.160.32].DApplicationBI.dbo.tmp_spflb b where  b.sflbh like a.sflbh+'%' and LEN(b.sflbh)=8
or b.sflbh in ('1309','2103','2104');


-- 商品范围

select a.DEPT_CODE sFdbh,a.ITEM_CODE sSpbh,b.sspmc,b.sPlbh,a.SHOP_SUPPLIER_CODE sgys,
a.SHIFT_PRICE njj,a.RETAIL_PRICE nsj,case when c.sfdbh is  not  null then 1 else 0 end szdbh,
case when a.SEND_CLASS_T='01' then '配送' when a.SEND_CLASS_T='02' then '直送'
when a.SEND_CLASS_T='03' then '一步越库' when a.SEND_CLASS_T='04' then '二步越库' end spsfs
,e.nrjxl*a.RETAIL_PRICE nrjxse,e.nsx nzgsl,e.nxx nzdsl,e.nrjxl,e.nzdcl,e.nzdcl_offset
,e.nZdcl_Offset_Bdate,e.nZdcl_Offset_Edate,e.ifPromotion,d.qpc ncgbzs,a.min_purchase_qty nPsbzs
into #Base_sp
from [122.147.160.32].DApplicationBI.dbo.P_SHOP_ITEM_OUTPUT a
join [122.147.10.202].dappresult.dbo.R_dpzb b 
on a.DEPT_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
left join #zdbhfl c on b.sfdbh=c.sfdbh and b.sPlbh=c.sflbh
join [122.147.160.32].DApplicationBI.dbo.goods d on a.ITEM_CODE=d.code
left join [122.147.10.200].dappsource.dbo.sys_deliveryset e on a.DEPT_CODE=e.sfdbh and a.ITEM_CODE=e.sspbh
where 1=1 and   a.DEPT_CODE in ('018329','012006','012007','018389','018418','018336','018425') and a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y'
and b.enddate>GETDATE()-13 and
(( d.sort>'20' and d.sort<'40') or (
LEFT(d.sort,4) in ('1105','1307','1309','1406') ))
and LEFT(d.sort,4)<>'2201';


-- 生成零库存表 drop table  #mdlkcsp
select a.*,ISNULL(b.CURR_STOCK,0)nsl,CONVERT(varchar(20),'') syy,
CONVERT(datetime,'') dzhyhrq into #mdlkcsp from #Base_sp a
left join  [122.147.160.32].DApplicationBI.dbo.V_D_PRICE_AND_STOCK b on  a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
where ISNULL(b.CURR_STOCK,0)<=a.nrjxl*3;
--  门店在要货数据

with x0 as (
select a.dYhrq,b.ddhrq dShrq,a. sdjlx sLx,b.sfdbh,b.sspbh,b.nsl nYhsl,b.ndhsl,b.sBzmx
from [122.147.10.200].dappsource.dbo.tmp_yhb a 
inner join [122.147.10.200].dappsource.dbo.tmp_yhmx b
on a.sdh=b.sdh and a.sFdbh=b.sFdbh
where 1=1 and a.sFdbh in ('018329','012006','012007','018389','018418','018336','018425') and a.dYhrq>=CONVERT(date,GETDATE()-180) 
and (  a.dYhrq+2<GETDATE() or b.ddhrq is not null))
,x1 as (select a.* from  x0 a
join  #base_sp c on a.sFdbh=c.sFdbh and a.sspbh=c.sSpbh
join [122.147.160.32].DApplicationBI.dbo.vendor d on c.sGys=d.code  
where  1=1 )
select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id 
into #Tmp_yh 
from x0 a ;


-- D zixun 原表

select CONVERT(date,b.dctime) dYhrq,a.sdh,isnull(a.sfdbh,c.sfdbh) sfdbh,
isnull(b.sspbh,c.sspbh) sspbh,ISNULL(c.nsl,b.nsl) nCgsl,b.nsl_raw ncgsl_raw,'' genstate,''smemo
into #1 from [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT a
join [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT_items b  on a.sdh=b.sdh
left join  [122.147.10.200].dappsource.dbo.delivery_receipt_zt c on b.sdh=c.sdh and b.sspbh=c.sspbh
where 1=1 and isnull(a.sfdbh,c.sfdbh) in ('018329','012006','012007','018389','018418','018336','018425')
and CONVERT(date,b.dctime)>=CONVERT(date,GETDATE()-180) and  ISNULL(c.nsl,b.nsl)>0;

select a.* into #dzixun_raw  from #1 a
join #base_sp d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh
join [122.147.160.32].DApplicationBI.dbo.vendor e on d.sGys=e.code 
where 1=1 and 
((d.spsfs='配送' and dateadd(day,2,a.dYhrq)<CONVERT(date,GETDATE()))
or (d.spsfs<>'配送'  and +dateadd(day,ISNULL(e.ValidDay,5),a.dYhrq)
<CONVERT(date,GETDATE())));


-- 单据汇总
select * into #BusType from [122.147.10.200].DAppSource.dbo.BusType;

with x0 as (
select sfdbh,sspbh,dyhrq,dshrq,slx,nyhsl,ndhsl,sbzmx,id,'要货' flag,
isnull(c.sname,case when a.sbzmx like '%自动生成%' or a.sbzmx like ';;%' then '自动补货'
 end ) sSource from #tmp_yh  a
left join #BusType c on 1=1 and CHARINDEX(c.sName,a.sbzmx,0)>1   and sType='Delivery' and len(c.sParentseName)>0 
)
select  ISNULL(a.sFdbh,b.sFdbh) sfdbh,ISNULL(a.sspbh,b.sSpbh) sspbh,
ISNULL(a.dYhrq,b.dYhrq) dYhrq,a.dShrq, a.nYhsl,b.nCgsl nYhsl_raw,b.ncgsl_raw ncgsl_old,
a.ndhsl nShsl,b.GenState,b.sMemo,a.sLx,sbzmx sBz,a.flag,
ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
ISNULL(a.sspbh,b.sSpbh) order by isnull(a.dyhrq,b.dyhrq) desc) npm_cal,
case when a.sFdbh is null then '系统单' end is_auto,a.sSource into #TMP_dh_cal
  from x0 a full join #dzixun_raw b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)>0 and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)<24 
where 1=1 ;
 
-- 最后的销售日期和进出

select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #2
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
where 1=1 and a.sfdbh in ('018329','018336','012007','018389','018418','012006','018425')
and a.sfdbh not like '015%' and a.dsj>CONVERT(date,GETDATE()-30)
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;



select *,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl) npm
into #jcmx0
  from #2 a   where a.nsl<0;



select * into #3 from [122.147.10.200].DAppSource.dbo.tmp_xs
 where 1=1 and sfdbh in ('018329','018336','012007','018389','018418','012006','018425') 
and drq>CONVERT(date,getdate()-14);


--  drop  table #xsrq

select a.sfdbh,a.sspbh,CONVERT(date,b.drq) max_xs,SUM(b.nxssl_pro) nxssl,
ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by CONVERT(date,b.drq) desc) npm 
into #xsrq
from #mdlkcsp a,#3 b where a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
group by a.sfdbh,a.sspbh,CONVERT(date,b.drq);


-- 分原因
-- 暂不补货

update a  set  a.syy='暂不补货',a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliveryGysEx b 
where a.sgys=b.sgys ;

update a  set  a.syy='暂不补货',a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliverySortEx b
where a.splbh like b.sflbh+'%' and a.sfdbh=b.sfdbh ;

update a  set  a.syy='暂不补货',a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliverySpEx b
where a.sspbh=b.sspbh and b.begindate<GETDATE() and b.enddate>GETDATE()
and nflag=1 ;


update a set a.syy=b.sJcfl from #mdlkcsp a 
join #jcmx0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
where  (b.dSj>c.max_xs or c.sFdbh is null)  and b.nSl<-2 and (( a.sPsfs='配送' and b.dSj>CONVERT(date,GETDATE()-5)) 
or (a.sPsfs<>'配送' and b.dSj>CONVERT(date,GETDATE()-14)));

-- 配送商品无库位

select * into #5 from [122.147.10.200].DAppSource.dbo.t_tihi;

update a set a.syy='DC无库位' from #mdlkcsp a
left join #5 b on a.sspbh=b.SIZE_DESC
where 1=1 and LEN(a.syy)=0 and a.sPsfs='配送' and b.SIZE_DESC
 is null ;


-- 突发销售

update a set a.syy='突发销售' from #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
where len(a.syy)=0  and  (( a.sPsfs='配送' and c.max_xs>CONVERT(date,GETDATE()-5)) 
or (a.sPsfs<>'配送' and c.max_xs>CONVERT(date,GETDATE()-14))) and c.nXssl>a.nRjxl*5 and c.nXssl>2      
and   c.nXssl>=round(a.nzgsl*0.8,0) and (c.max_xs>b.dShrq or b.dShrq is null) ;


-- 起订量不足

select * into #6 from  [122.147.10.200].DAppSource.dbo.Rectification_MinSet_Ys
where drq>=CONVERT(date,GETDATE()-32);


update a set a.syy='未达起订量' from #mdlkcsp a
left join #Tmp_dh_cal  b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
join #6 c   on case when a.spsfs<>'直送' then '015901' else  a.sfdbh end=c.sfdbh and a.sspbh=c.sspbh
where c.drq>b.dyhrq or b.sfdbh is null ;


update a set  a.syy= case when  c.IntoDate>GETDATE()-5 then  '系统定额不足' 
else '新品' end   from  #mdlkcsp a 
 left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  and   b.dYhrq>=convert(date,GETDATE()-30)
 left join  [122.147.10.202].DAppresult.dbo.Index_Sp c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh 
where 1=1  and   len(a.syy)=0  
and  a.sZdbh=1   and b.sfdbh is null;

update a set  a.syy='人工未下单'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
and b.dYhrq>convert(date,GETDATE()-7)
where 1=1  and   len(a.syy)=0  and  a.sZdbh=0   and b.sfdbh is null;


-- Step 6.2 直送商品，供应商未送，采购单，供应商到货量为空
update a set a.dzhyhrq=b.dYhrq,a.syy=
case when spsfs='直送' then '直送' else '越库' end +'供应商未送货'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
where 1=1    and  len(a.syy)=0  and a.sPsfs<>'配送' and isnull(b.nShsl,0)=0 ;
 


-- Step 6.4 供应商送货不足，采购量到货量低于90%
update a set a.dzhyhrq=b.dYhrq,
a.syy=case when spsfs='直送' then '直送' else '越库' end+'供应商送货不足'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
where 1=1  and  len(a.syy)=0  and a.sPsfs<>'配送' and b.nYhsl>0  and  b.nShsl*1.0/b.nYhsl<0.9 ;

-- Step 6.5 人工订货不足，szdbh=0
update a set a.syy='人工未下单'  from  #mdlkcsp a 
left  join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)=0 ;

update a set a.dzhyhrq=b.dYhrq,a.syy='人工订货不足'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)>0  and b.nShsl*1.0/b.nYhsl>=0.9 ;


-- Step 6.6 DC未送货 或 送货不足
update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心未送货'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
where 1=1  and   len(a.syy)=0  and b.sfdbh is not null  and   isnull(b.nShsl,0)=0 and a.sPsfs<>'直送'
and b.nYhsl>0;

update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心送货不足'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
where 1=1  and   len(a.syy)=0  and b.nShsl>0 and  b.nYhsl*1.0/b.nShsl<0.9 and a.sPsfs<>'直送' ;
-- 更新物流有货未配 drop table   #dckc
select distinct a.sSpbh into #dckc from #mdlkcsp a 
join [122.147.10.200].DAppSource.dbo.T_Dckclsb b
on a.sSpbh=b.sSpbh and b.QtyAllow>0 and  a.syy='物流中心未送货' and 
DATEDIFF(day,a.dzhyhrq,CONVERT(date,b.sRq)) between 0 and 7
where  1=1; 

update a set a.syy='物流中心有货未送' from  #mdlkcsp a join #dckc b  on a.sspbh=b.sspbh
where a.syy='物流中心未送货'  ;

update a set a.syy='物流中心无货未送' from  #mdlkcsp a  
where a.syy='物流中心未送货' ;
-- Step 6.7 :系统未下单，或定额不足
-- 系统未下单 需要考虑节奏日，如果即使到节奏日出了单，那也是定额不足，后面用异常出单修正原来的原因
update a set  a.syy='系统定额不足'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
where 1=1  and   len(a.syy)=0  
and  a.sZdbh=1   and b.sfdbh is null;

-- Step 6.8:系统定额不足,但如果是手工改小的采购单 
update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
where 1=1  and   len(a.syy)=0   and b.nShsl>0   and  b.nShsl*1.0/b.nYhsl>=0.9
and  a.sZdbh=1 and b.ncgsl_old<=b.nyhsl 
and (b.sbz like '%自动%' or b.sbz like ';;%') ;

--Step 6.9: 人工改小或删单
update a set a.dzhyhrq=b.dYhrq,a.syy='人工减量或删单'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
and ((b.nShsl>0  and b.nYHsl_raw<b.ncgsl_old 
	and isnull(b.nYhsl,0)>0) or (b.ncgsl_old>0 and b.nYhsl is null ))
where 1=1  and   len(a.syy)=0   
and  a.sZdbh=1  and b.sfdbh is not null ;


--Step 6.10: 系统定额不足，人工未减量，供应商到货
update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
where 1=1  and   len(a.syy)=0   and b.nShsl>0 and  b.nShsl*1.0/b.nYhsl>=0.9
and  a.sZdbh=1  and b.nYhsl_raw=b.nYhsl  and b.nYhsl_raw>=b.ncgsl_old ;


 update a set a.syy='其他' from #mdlkcsp a    where len(a.syy)=0  ; 
 delete from dbo.TMP_MDLKCYY where drq=convert(date,GETDATE());
 -- delete from dbo.TMP_MDLKCYY where drq=convert(date,GETDATE()-90);
 insert into dbo.TMP_MDLKCYY(drq,sfdbh,sspbh,sspmc,sfl,nZdsl,nZgsl,szdbh,ssfkj,spsfs,syy,dzhyhrq,nrjxl,nrjxse,nsl)
 select convert(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sSpmc,a.splbh,a.nZdsl ,a.nZgsl ,a.sZdbh,'1' sSfkj,a.sPsfs,a.syy,
  a.dzhyhrq,a.nRjxl,a.nRjxse,a.nsl   from  #mdlkcsp a ;
  
  
 delete from [122.147.160.32].DApplicationBI.dbo.TMP_MDLKCYY where drq=convert(date,GETDATE()); 
 insert into [122.147.160.32].DApplicationBI.dbo.TMP_MDLKCYY(drq,sfdbh,sspbh,sspmc,sfl,nZdsl,nZgsl,szdbh,ssfkj,spsfs,syy,dzhyhrq,nrjxl,nrjxse,nsl)
 select convert(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sSpmc,a.splbh,a.nZdsl ,a.nZgsl ,a.sZdbh,'1' sSfkj,a.sPsfs,a.syy,
  a.dzhyhrq,a.nRjxl,a.nRjxse,a.nsl   from  #mdlkcsp a ;

 
-- 第二部分 门店大库存
-- Step 2.1 ：大库存数据生成 进出按进出，要货按最后要货日期   drop table #mddkc

select sFlbh,sFlmc,nPlzzts into #tmp_flbb from   DappSource_Dw.dbo.Tmp_sort_standard
where drq = (select max(drq) from  DappSource_Dw.dbo.Tmp_sort_standard)
with x0 as (
select a.*,b.CURR_STOCK nsl, convert(numeric(15,4),case when  a.nrjxl*a.nsj=0 
then 300 else b.CURR_STOCK*a.njj*1.0/(a.nRjxl*a.nsj) end) nzzts, isnull(c.nPlzzts,0) nPlzzts
from #base_sp a 
left join [122.147.160.32].DApplicationBI.dbo.V_D_PRICE_AND_STOCK b on a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE 
left join #tmp_flbb c on LEFT(a.splbh,2)=c.sflbh 
where 1=1 and ISNULL(b.CURR_STOCK,0)>6 and ISNULL(b.CURR_STOCK,0)*a.nJj>50 
and   case when a.nRjxl*a.nsj=0 then 300 else 
   ISNULL(b.CURR_STOCK,0)*a.njj*1.0/(a.nRjxl*a.nsj) end>=isnull(c.nPlzzts,0) )
select a.sFdbh,a.sSpbh,a.sspmc ,a.sPlbh sFl,b.munit sdw,b.billto sGys,a.nJj,a.nSj
,a.szdbh,a.sPsfs,a.nRjxl,a.nRjxl*a.nsj nrjxse,a.nsl,a.nzgsl,a.nzdcl
, a.nzzts,a.nPsbzs,a.nCgbzs,convert(date,Null) dzhyhr,convert(date,Null) dzhdhr, 
convert(varchar(20),'') syy,convert(varchar(5),'') sfwqzs,convert(varchar(20),'') sfcx,
convert(money,Null) nYhsl,convert(money,Null) nDhsl,a.nzdcl_offset,
a.nZdcl_Offset_Edate,a.nZdcl_Offset_Bdate ,CONVERT(varchar(200),'') sSource,a.nPlzzts into #mddkc
  from x0  a 
join [122.147.160.32].DApplicationBI.dbo.goods b on   a.sspbh=b.code
where 1=1     ; 


--Step 2.2:最后一次进货
select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #jc1

from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
where 1=1 and a.sfdbh in ('018329','012007','018336','018389','018418','012006','018425') 
and a.sfdbh not like '015%' 
and a.dsj>CONVERT(date,GETDATE()-180)
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;


-- drop table #jcmx

with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,
ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and  a.nsl>=2 and a.nsl>b.nsl*0.2)
select * into #jcmx from x0  where npm<=2;
 
-- Step 2.2.0:多点陈列和配送包装数 drop table  #de_history
select sfdbh,sspbh,spsfs,nzdcl,nZdcl_offset,max(drq) drq_max,min(drq) min_drq  into #de_history
from  DappSource_Dw.dbo.sys_deliveryset
where  drq>=convert(date,getdate()-180)
and sfdbh in ('018329','018336','012007','018389','018418','012006','018425') 
group by  sfdbh,sspbh,spsfs,nzdcl,nZdcl_offset;

--  原因划分
-- Step 2.3:遗留库存
with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and a.nsl>0  )
update a set a.syy='遗留库存'   from #mddkc  a 
left join x0 b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
where 1=1  and b.sFdbh is null;

-- 
with x1 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and a.nsl>0  )
,x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc  ) nyhpm
,a.nrjxl,a.nrjxse, a.nsl,d.sSource  from #mddkc a 
 join x1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  [122.147.160.32].DApplicationBI.dbo.vendor c on a.sGys=c.code  
 left join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh 
where  1=1   and len(a.syy)=0   and d.dShrq is not null
  and convert(date,d.dshrq)=CONVERT(date,b.dsj)  )
update a set a.syy=case when isnull(c.nZdcl_offset,0)>=4
 and   c.nZdcl_offset >=a.nsl*0.5 then   '多点陈列'  when ISNULL(c.nzdcl,0)>=4
 and   c.nZdcl >=a.nsl*0.5 then '最低陈列量' end ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl,
 a.nZdcl=c.nZdcl,a.nZdcl_offset=c.nZdcl_offset,a.sSource=b.sSource
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
   join #de_history c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and 
   (( c.nZdcl_offset >=a.nsl*0.5 and isnull(c.nZdcl_offset,0)>=4 )
    or (ISNULL(c.nzdcl,0)>=4 and  c.nZdcl >=a.nsl*0.5  ))
  and  (CONVERT(date,b.dYhrq)>=CONVERT(date,c.min_drq)   
and CONVERT(date,b.dYhrq)<=CONVERT(date,c.drq_max) or  (CONVERT(date,b.dYhrq)<CONVERT(date,c.min_drq)))
 where  1=1     ;
select * from #mddkc where syy  is null 

-- Step 2.7:对盘点调拨 划分：盘点，调拨量大于当前库存数量的20%
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
and len(a.syy)=0 and b.npm=1;
/*
select * from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
and  a.sspbh='23080011'  and a.sfdbh='018329';
*/
 
 
-- Step 2.8:对最后一次到货的包装数：>5 且
 update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
  from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('配送','二步越库') 
and    a.nPsbzs>=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 and b.npm=1 ;
 

update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
  from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('直送','一步越库')
and     a.nPsbzs >=a.nsl*0.6
and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 and b.npm=1  ;
       
-- Step 2.9 :最后一次要货查是谁下的单 如果系统单，
--但是到货量大 那么就是人工原因，到货量小于系统单，系统原因，其他 手工原因
--如果是在采购里面加单的话，那么就是手工加量或加单
-- 有单据 无进出,对有正常进出无单的 划为其他
with x0 as(
select a.sFdbh,a.sSpbh,isnull(d.dShrq,b.dsj) dSj,isnull(d.nShsl,b.ndhsl) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
 join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
	 and b.sjcfl   in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
left join  [122.147.160.32].DApplicationBI.dbo.vendor c on a.sGys=c.code  
left  join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
  and d.dShrq is not null  and convert(date,d.dshrq)=CONVERT(date,b.dsj)
where  1=1   and len(a.syy)=0    )
update a set a.syy= '其他'
  ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl 
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
 where  1=1 and b.dyhrq is null     ;

with x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
-- join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
left join  [122.147.160.32].DApplicationBI.dbo.vendor c on a.sGys=c.code  
 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
where  1=1   and len(a.syy)=0 and d.dShrq is not null
  and isnull(d.nShsl,0)>=a.nsl*0.2 
  -- and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
   )
update a set a.syy=   
case  when (b.sbz like '%自动生成%' or b.sbz like ';;%') 
        and ( b.ncgsl_old is not null and b.nyhsl_raw<=b.ncgsl_old  
        and b.nYhsl<=b.nYhsl_raw )    then '系统定额过大' 
    when   (b.sbz like '%自动生成%' or b.sbz like ';;%') 
       and ( b.ncgsl_old is   null and b.nyhsl_raw IS not null 
       and b.nYhsl<=b.nYhsl_raw )    then '人工加量或加单' 
when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like '硬配%'
           then '采购硬配' 
 when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like 'APP补货%'
           then '门店下单' 
when   b.sbz   like '%自采订单%'   then '人工下单' 
when   b.sbz   like '%DM%'   then 'DM'
when   b.sbz   like '%新品%'   then '新品'
else '人工下单' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl ,a.sSource=b.sSource
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
 ;

/*
select a.sFdbh,a.sSpbh,isnull(d.dShrq,b.dsj) dSj,isnull(d.nShsl,b.ndhsl) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  dbo.vendor c on a.sGys=c.code  
left join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
and     d.dShrq is not null  and isnull(d.nShsl,0)>=a.nsl*0.2 
 and convert(date,d.dShrq)=convert(date,b.dsj)
where  1=1  and a.sspbh='23080011'
  
*/

-- Step 2.10:往前追溯一次
update #mddkc set sfwqzs='是' where len(syy)=0;

-- 进出再生成,不设量限制 drop table #jcmx1
with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and  a.nsl>0 )
select * into #jcmx1 from x0  where npm<=2;


-- Step 2.12:对盘点调拨 划分：第二次盘点，调拨量大于当前库存数量的0.1就算
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1 and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
join   #jcmx1 c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=2 and c.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品') 
where  1=1 and len(a.syy)=0;
-- Step 2.13:对最后一次到货的包装数：库存数量小于包装数的1.2倍，最后一次到货量等于包装数
update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
 from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
where  1=1  and len(a.syy)=0 and  a.sPsfs in ('配送','二步越库')
and    a.nPsbzs >=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 ;

update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('直送','一步越库') 
and    a.nPsbzs >=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5  ;

-- Step 2.14:要货到货匹配再查一次

with x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
 -- join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  [122.147.160.32].DApplicationBI.dbo.vendor c on a.sGys=c.code  
 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
where  1=1   and len(a.syy)=0 and d.dShrq is not null
 -- and convert(date,d.dshrq)<=CONVERT(date,b.dsj) 
   )
update a set a.syy=   
case when (b.sbz like '%自动生成%' or b.sbz like ';;%') 
        and ( b.ncgsl_old is not null and b.nyhsl_raw<=b.ncgsl_old  
        and b.nYhsl<=b.nYhsl_raw )    then '系统定额过大' 
    when   (b.sbz like '%自动生成%' or b.sbz like ';;%') 
       and ( b.ncgsl_old is   null and b.nyhsl_raw IS not null 
       and b.nYhsl<=b.nYhsl_raw )    then '人工加量或加单' 
when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like '硬配%'
           then '采购硬配' 
 when   b.sbz not like '自动生成%' and b.sbz not like ';;%' and b.sbz like 'APP补货%'
           then '门店下单' 
when   b.sbz   like '%自采订单%'   then '人工下单' 
when   b.sbz   like '%DM%'   then 'DM'
when   b.sbz   like '%新品%'   then '新品'
else '人工下单' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl ,a.sSource=b.sSource
 from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1;
-- Step 2.15:   更新剩余 
update a set a.syy='其他'  from #mddkc a  where  1=1   and len(a.syy)=0 ;
-- 3 促销
select a.sFdbh,a.sspbh into #tmp_cx from [122.147.10.200].DAppSource.dbo.tmp_Promotion a 
where 1=1 and a.sZt<>'已结束'
and case when CONVERT(date,a.Bdate)>=a.Adate then CONVERT(date,a.Bdate)
else a.Adate end <GETDATE() and  case when 
CONVERT(date,a.Edate)>=a.CloseDate or a.CloseDate is null then CONVERT(date,a.Edate)
else a.CloseDate end >=GETDATE()
union
select b.sFdbh,b.sspbh
from  [122.147.10.200].DAppSource.dbo.tmp_promotionplan_items b
 where 1=1
and case when CONVERT(date,b.Bdate)>=b.DcTime then CONVERT(date,b.Bdate)
else b.DcTime end <GETDATE() and CONVERT(date,b.Bdate)>GETDATE();

update a set a.sfcx='是' from #mddkc  a
join #tmp_cx b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1;

-- drop table   #dhyq 
select a.sfdbh,a.sspbh into #dhyq from #tmp_dh_cal a
join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where  a.npm_cal=1 and b.npm_cal=2 and 
datediff(day,convert(date,a.dyhrq),convert(date,b.dshrq))>=0
and datediff(hour,b.dyhrq,a.dyhrq)>30
and a.ncgsl_old is not null 
and a.dshrq is not null 
order by a.sfdbh,a.sspbh; 

 
update a set a.syy='逾期到货' from #mddkc a
join #dhyq b on   a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 ;

update a set a.syy='人工下单' from #mddkc a
join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
	and CONVERT(date,a.dzhyhr)=CONVERT(date,b.dyhrq)
where a.syy='系统定额过大' and
  b.sbz not like ';;%'  and b.sbz not like ';;。自动生成%' 
 

-- Step 2.18:写入结果
delete from  dbo.tmp_mdspzzyy where drq=convert(date,GETDATE());
-- delete from  dbo.tmp_mdspzzyy where drq=convert(date,GETDATE()-90);
insert into dbo.tmp_mdspzzyy(drq,sfdbh,sspbh,sspmc,sfl,sgys,njj,nsj,szdbh,spsfs,nrjxse,nrjxl,nkc,nzzts,npsbzs,ncgbzs,dzhdhr,dzhyhr,
syy,sfwqzs,nbzzzts,sfcx,nDhsl,sSource)
select CONVERT(date,GETDATE()) drq, a.sFdbh,a.sSpbh,sSpmc,sFl,sGys,nJj,nSj,sZdbh,sPsfs,nrjxse,nRjxl,nsl,nzzts,nPsbzs,
nCgbzs,dzhdhr,dzhyhr,syy,sfwqzs, a.nPlzzts nbzzzts,a.sfcx,nDhsl,a.sSource from #mddkc a
where 1=1  ;

delete from [122.147.160.32].DApplicationBI.dbo.tmp_mdspzzyy where drq=convert(date,GETDATE());
insert into [122.147.160.32].DApplicationBI.dbo.tmp_mdspzzyy(drq,sfdbh,sspbh,sspmc,sfl,sgys,njj,nsj,szdbh,spsfs,nrjxse,nrjxl,nkc,nzzts,npsbzs,ncgbzs,dzhdhr,dzhyhr,
syy,sfwqzs,nbzzzts,sfcx,nDhsl,sSource)
select CONVERT(date,GETDATE()) drq, a.sFdbh,a.sSpbh,sSpmc,sFl,sGys,nJj,nSj,sZdbh,sPsfs,nrjxse,nRjxl,nsl,nzzts,nPsbzs,
nCgbzs,dzhdhr,dzhyhr,syy,sfwqzs,a.nPlzzts nbzzzts,a.sfcx,nDhsl,a.sSource from #mddkc a
where 1=1  ;


-- 按嘉荣标准存的表
select CONVERT(date,GETDATE()) drq, a.sFdbh,a.sSpbh,sSpmc,sFl,sGys,nJj,nSj,sZdbh,sPsfs,nrjxse,nRjxl,nsl,nzzts,nPsbzs,
nCgbzs,dzhdhr,dzhyhr,syy,sfwqzs, a.nPlzzts nbzzzts,a.sfcx,nDhsl,a.sSource  into TMP_ZZ_0331 from #mddkc a
where 1=1  ;


------------- 2022-04-07  版本
-- 自动补货商品明细
select a.sfdbh,b.sflbh into #zdbhfl
from [122.147.10.200].dappsource.dbo.sys_deliverysort a,
Dappsource_DW.dbo.tmp_spflb b where  b.sflbh like a.sflbh+'%' and LEN(b.sflbh)=8
or b.sflbh in ('1309','2103','2104');


-- 商品范围
/**/
select * into #dpzb from [122.147.10.202].dappresult.dbo.R_dpzb;
select sfdbh,sfdmc,smdlx,sDq,sQy into #Tmp_fdb from DappSource_Dw.dbo.tmp_fdb 
where   smdlx   in ('大店A','大店B','小店','中店A','中店B') and sJylx='连锁门店'
and dkyrq is not null and sjc not like '%取消%'; 
-- drop table #Base_sp

select a.DEPT_CODE sFdbh,a.ITEM_CODE sSpbh,b.sspmc,b.sPlbh,a.SHOP_SUPPLIER_CODE sgys,
a.SHIFT_PRICE njj,a.RETAIL_PRICE nsj,case when c.sfdbh is  not  null then 1 else 0 end szdbh,
case when a.SEND_CLASS_T='01' then '配送' when a.SEND_CLASS_T='02' then '直送'
when a.SEND_CLASS_T='03' then '一步越库' when a.SEND_CLASS_T='04' then '二步越库' end spsfs
,e.nrjxl*a.RETAIL_PRICE nrjxse,e.nsx nzgsl,e.nxx nzdsl,e.nrjxl,e.nzdcl,e.nzdcl_offset
,e.nZdcl_Offset_Bdate,e.nZdcl_Offset_Edate,e.ifPromotion,d.qpc ncgbzs,a.min_purchase_qty nPsbzs
into #Base_sp
from Dappsource_DW.dbo.P_SHOP_ITEM_OUTPUT a
join  #dpzb b on a.DEPT_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
left join #zdbhfl c on b.sfdbh=c.sfdbh and b.sPlbh=c.sflbh
join Dappsource_DW.dbo.goods d on a.ITEM_CODE=d.code
left join [122.147.10.200].dappsource.dbo.sys_deliveryset e on a.DEPT_CODE=e.sfdbh and a.ITEM_CODE=e.sspbh
join DappSource_Dw.dbo.tmp_fdb  f on  a.DEPT_CODE=f.sfdbh  and 
  f.smdlx   in ('大店A','大店B','小店','中店A','中店B') and f.sJylx='连锁门店'
and f.dkyrq is not null and f.sjc not like '%取消%'
where 1=1 and a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y' and a.CHARACTER_TYPE='N'
and b.enddate>GETDATE()-13 and
(( d.sort>'20' and d.sort<'40') or (
LEFT(d.sort,4) in ('1105','1307','1406') ))
and LEFT(d.sort,4)<>'2201';
 

-- 生成零库存表 drop table  #mdlkcsp
select a.*,ISNULL(b.CURR_STOCK,0)nsl,CONVERT(varchar(20),'') syy,
CONVERT(datetime,'') dzhyhrq into #mdlkcsp from #Base_sp a
left join  Dappsource_DW.dbo.V_D_PRICE_AND_STOCK b on  a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
where ISNULL(b.CURR_STOCK,0)<=a.nrjxl*3;
--  门店在要货数据 drop table #Tmp_yh
with x0 as (
select a.dYhrq,b.ddhrq dShrq,a. sdjlx sLx,b.sfdbh,b.sspbh,b.nsl nYhsl,b.ndhsl,b.sBzmx
from [122.147.10.200].dappsource.dbo.tmp_yhb a 
inner join [122.147.10.200].dappsource.dbo.tmp_yhmx b
on a.sdh=b.sdh and a.sFdbh=b.sFdbh
join #Tmp_fdb c on a.sfdbh=c.sfdbh
where 1=1  and a.dYhrq>=CONVERT(date,GETDATE()-180) 
and (  a.dYhrq+2<GETDATE() or b.ddhrq is not null))
,x1 as (select a.* from  x0 a
join  #base_sp c on a.sFdbh=c.sFdbh and a.sspbh=c.sSpbh
join Dappsource_DW.dbo.vendor d on c.sGys=d.code  
where  1=1 )
select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id 
into #Tmp_yh 
from x0 a ;


-- D zixun 原表 drop table #1

select CONVERT(date,b.dctime) dYhrq,a.sdh,isnull(a.sfdbh,c.sfdbh) sfdbh,
isnull(b.sspbh,c.sspbh) sspbh,ISNULL(c.nsl,b.nsl) nCgsl,b.nsl_raw ncgsl_raw,'' genstate,''smemo
into #1 from [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT a
join [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT_items b  on a.sdh=b.sdh
left join  [122.147.10.200].dappsource.dbo.delivery_receipt_zt c on b.sdh=c.sdh and b.sspbh=c.sspbh
join #Tmp_fdb d on  isnull(a.sfdbh,c.sfdbh)=d.sfdbh
where 1=1 and CONVERT(date,b.dctime)>=CONVERT(date,GETDATE()-180) and  ISNULL(c.nsl,b.nsl)>0;
 
select a.* into #dzixun_raw  from #1 a
join #base_sp d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh
join Dappsource_DW.dbo.vendor e on d.sGys=e.code 
where 1=1 and 
((d.spsfs='配送' and dateadd(day,2,a.dYhrq)<CONVERT(date,GETDATE()))
or (d.spsfs<>'配送'  and +dateadd(day,ISNULL(e.ValidDay,5),a.dYhrq)
<CONVERT(date,GETDATE())));


-- 单据汇总
select * into #BusType from [122.147.10.200].DAppSource.dbo.BusType;

with x0 as (
select sfdbh,sspbh,dyhrq,dshrq,slx,nyhsl,ndhsl,sbzmx,id,'要货' flag,
isnull(c.sname,case when a.sbzmx like '%自动生成%' or a.sbzmx like ';;%' then '自动补货'
 end ) sSource from #tmp_yh  a
left join #BusType c on 1=1 and CHARINDEX(c.sName,a.sbzmx,0)>1
)
select  ISNULL(a.sFdbh,b.sFdbh) sfdbh,ISNULL(a.sspbh,b.sSpbh) sspbh,
ISNULL(a.dYhrq,b.dYhrq) dYhrq,a.dShrq, a.nYhsl,b.nCgsl nYhsl_raw,b.ncgsl_raw ncgsl_old,
a.ndhsl nShsl,b.GenState,b.sMemo,a.sLx,sbzmx sBz,a.flag,
ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
ISNULL(a.sspbh,b.sSpbh) order by isnull(a.dyhrq,b.dyhrq) desc) npm_cal,
case when a.sFdbh is null then '系统单' end is_auto,a.sSource into #TMP_dh_cal
  from x0 a full join #dzixun_raw b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)>0 and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)<24 
where 1=1 ;
 
-- 最后的销售日期和进出

select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #2
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
join #Tmp_fdb c on a.sfdbh=c.sfdbh 
where 1=1 and a.sfdbh not like '015%' and a.dsj>CONVERT(date,GETDATE()-30)
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;



select *,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl) npm
into #jcmx0
  from #2 a   where a.nsl<0;



select * into #3 from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
join #Tmp_fdb b on a.SHOP_CODE=b.sfdbh 
 where 1=1 and  CONVERT(date,a.SALE_DATE)>CONVERT(date,getdate()-14);


--  drop  table #xsrq

select a.sfdbh,a.sspbh,CONVERT(date,b.drq) max_xs,SUM(b.nxssl_pro) nxssl,
ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by CONVERT(date,b.drq) desc) npm 
into #xsrq
from #mdlkcsp a,#3 b where a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
group by a.sfdbh,a.sspbh,CONVERT(date,b.drq);


-- 分原因
-- 暂不补货

update a  set  a.syy='暂不补货',a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliveryGysEx b 
where a.sgys=b.sgys ;

update a  set  a.syy='暂不补货',a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliverySortEx b
where a.splbh like b.sflbh+'%' and a.sfdbh=b.sfdbh ;

update a  set  a.syy='暂不补货',a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliverySpEx b
where a.sspbh=b.sspbh and b.begindate<GETDATE() and b.enddate>GETDATE()
and nflag=1 ;


update a set a.syy=b.sJcfl from #mdlkcsp a 
join #jcmx0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
where  (b.dSj>c.max_xs or c.sFdbh is null)  and b.nSl<-2 and (( a.sPsfs='配送' and b.dSj>CONVERT(date,GETDATE()-5)) 
or (a.sPsfs<>'配送' and b.dSj>CONVERT(date,GETDATE()-14)));

-- 配送商品无库位

select * into #5 from [122.147.10.200].DAppSource.dbo.t_tihi;

update a set a.syy='DC无库位' from #mdlkcsp a
left join #5 b on a.sspbh=b.SIZE_DESC
where 1=1 and LEN(a.syy)=0 and a.sPsfs='配送' and b.SIZE_DESC
 is null ;


-- 突发销售

update a set a.syy='突发销售' from #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
where len(a.syy)=0  and  (( a.sPsfs='配送' and c.max_xs>CONVERT(date,GETDATE()-5)) 
or (a.sPsfs<>'配送' and c.max_xs>CONVERT(date,GETDATE()-14))) and c.nXssl>a.nRjxl*5 and c.nXssl>2      
and   c.nXssl>=round(a.nzgsl*0.8,0) and (c.max_xs>b.dShrq or b.dShrq is null) ;


-- 起订量不足

select * into #6 from  [122.147.10.200].DAppSource.dbo.Rectification_MinSet_Ys
where drq>=CONVERT(date,GETDATE()-32);


update a set a.syy='未达起订量' from #mdlkcsp a
left join #Tmp_dh_cal  b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
join #6 c   on case when a.spsfs<>'直送' then '015901' else  a.sfdbh end=c.sfdbh and a.sspbh=c.sspbh
where c.drq>b.dyhrq or b.sfdbh is null ;


update a set  a.syy= case when  c.IntoDate>GETDATE()-5 then  '系统定额不足' 
else '新品' end   from  #mdlkcsp a 
 left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  and   b.dYhrq>=convert(date,GETDATE()-30)
 left join  [122.147.10.202].DAppresult.dbo.Index_Sp c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh 
where 1=1  and   len(a.syy)=0  
and  a.sZdbh=1   and b.sfdbh is null;

update a set  a.syy='人工未下单'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
and b.dYhrq>convert(date,GETDATE()-7)
where 1=1  and   len(a.syy)=0  and  a.sZdbh=0   and b.sfdbh is null;


-- Step 6.2 直送商品，供应商未送，采购单，供应商到货量为空
update a set a.dzhyhrq=b.dYhrq,a.syy=
case when spsfs='直送' then '直送' else '越库' end +'供应商未送货'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
where 1=1    and  len(a.syy)=0  and a.sPsfs<>'配送' and isnull(b.nShsl,0)=0 ;
 


-- Step 6.4 供应商送货不足，采购量到货量低于90%
update a set a.dzhyhrq=b.dYhrq,
a.syy=case when spsfs='直送' then '直送' else '越库' end+'供应商送货不足'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
where 1=1  and  len(a.syy)=0  and a.sPsfs<>'配送' and b.nYhsl>0  and  b.nShsl*1.0/b.nYhsl<0.9 ;

-- Step 6.5 人工订货不足，szdbh=0
update a set a.syy='人工未下单'  from  #mdlkcsp a 
left  join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)=0 ;

update a set a.dzhyhrq=b.dYhrq,a.syy='人工订货不足'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)>0  and b.nShsl*1.0/b.nYhsl>=0.9 ;


-- Step 6.6 DC未送货 或 送货不足
update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心未送货'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
where 1=1  and   len(a.syy)=0  and b.sfdbh is not null  and   isnull(b.nShsl,0)=0 and a.sPsfs<>'直送'
and b.nYhsl>0;

update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心送货不足'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
where 1=1  and   len(a.syy)=0  and b.nShsl>0 and  b.nYhsl*1.0/b.nShsl<0.9 and a.sPsfs<>'直送' ;
-- 更新物流有货未配 drop table   #dckc
select distinct a.sSpbh into #dckc from #mdlkcsp a 
join [122.147.10.200].DAppSource.dbo.T_Dckclsb b
on a.sSpbh=b.sSpbh and b.QtyAllow>0 and  a.syy='物流中心未送货' and 
DATEDIFF(day,a.dzhyhrq,CONVERT(date,b.sRq)) between 0 and 7
where  1=1; 

update a set a.syy='物流中心有货未送' from  #mdlkcsp a join #dckc b  on a.sspbh=b.sspbh
where a.syy='物流中心未送货'  ;

update a set a.syy='物流中心无货未送' from  #mdlkcsp a  
where a.syy='物流中心未送货' ;
-- Step 6.7 :系统未下单，或定额不足
-- 系统未下单 需要考虑节奏日，如果即使到节奏日出了单，那也是定额不足，后面用异常出单修正原来的原因
update a set  a.syy='系统定额不足'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
where 1=1  and   len(a.syy)=0  
and  a.sZdbh=1   and b.sfdbh is null;

-- Step 6.8:系统定额不足,但如果是手工改小的采购单 
update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
where 1=1  and   len(a.syy)=0   and b.nShsl>0   and  b.nShsl*1.0/b.nYhsl>=0.9
and  a.sZdbh=1 and b.ncgsl_old<=b.nyhsl 
and (b.sbz like '%自动%' or b.sbz like ';;%') ;

--Step 6.9: 人工改小或删单
update a set a.dzhyhrq=b.dYhrq,a.syy='人工减量或删单'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
and ((b.nShsl>0  and b.nYHsl_raw<b.ncgsl_old 
	and isnull(b.nYhsl,0)>0) or (b.ncgsl_old>0 and b.nYhsl is null ))
where 1=1  and   len(a.syy)=0   
and  a.sZdbh=1  and b.sfdbh is not null ;


--Step 6.10: 系统定额不足，人工未减量，供应商到货
update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
where 1=1  and   len(a.syy)=0   and b.nShsl>0 and  b.nShsl*1.0/b.nYhsl>=0.9
and  a.sZdbh=1  and b.nYhsl_raw=b.nYhsl  and b.nYhsl_raw>=b.ncgsl_old ;


 update a set a.syy='其他' from #mdlkcsp a    where len(a.syy)=0  ; 
 delete from dbo.TMP_MDLKCYY where drq=convert(date,GETDATE());
 -- delete from dbo.TMP_MDLKCYY where drq=convert(date,GETDATE()-90);
  
  
 delete from Dappsource_DW.dbo.TMP_MDLKCYY where drq=convert(date,GETDATE()); 
 insert into Dappsource_DW.dbo.TMP_MDLKCYY(drq,sfdbh,sspbh,sspmc,sfl,nZdsl,nZgsl,szdbh,ssfkj,spsfs,syy,dzhyhrq,nrjxl,nrjxse,nsl)
 select convert(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sSpmc,a.splbh,a.nZdsl ,a.nZgsl ,a.sZdbh,'1' sSfkj,a.sPsfs,a.syy,
  a.dzhyhrq,a.nRjxl,a.nRjxse,a.nsl   from  #mdlkcsp a ;

 
-- 第二部分 门店大库存
-- Step 2.1 ：大库存数据生成 进出按进出，要货按最后要货日期   drop table #mddkc

select sFlbh,sFlmc,nPlzzts into #tmp_flbb from   DappSource_Dw.dbo.Tmp_sort_standard
where drq = (select max(drq) from  DappSource_Dw.dbo.Tmp_sort_standard);


with x0 as (
select a.*,b.CURR_STOCK nsl, convert(numeric(15,4),case when  a.nrjxl*a.nsj=0 
then 300 else b.CURR_STOCK*a.njj*1.0/(a.nRjxl*a.nsj) end) nzzts, isnull(c.nPlzzts,55) nPlzzts
from #base_sp a 
left join Dappsource_DW.dbo.V_D_PRICE_AND_STOCK b on a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE 
left join #tmp_flbb c on LEFT(a.splbh,4)=c.sflbh 
where 1=1 and ISNULL(b.CURR_STOCK,0)>6 and ISNULL(b.CURR_STOCK,0)*a.nJj>50 
and   case when a.nRjxl*a.nsj=0 then 300 else 
   ISNULL(b.CURR_STOCK,0)*a.njj*1.0/(a.nRjxl*a.nsj) end>=isnull(c.nPlzzts,0) )
select a.sFdbh,a.sSpbh,a.sspmc ,a.sPlbh sFl,b.munit sdw,b.billto sGys,a.nJj,a.nSj
,a.szdbh,a.sPsfs,a.nRjxl,a.nRjxl*a.nsj nrjxse,a.nsl,a.nzgsl,a.nzdcl
, a.nzzts,a.nPsbzs,a.nCgbzs,convert(date,Null) dzhyhr,convert(date,Null) dzhdhr, 
convert(varchar(20),'') syy,convert(varchar(5),'') sfwqzs,convert(varchar(20),'') sfcx,
convert(money,Null) nYhsl,convert(money,Null) nDhsl,a.nzdcl_offset,
a.nZdcl_Offset_Edate,a.nZdcl_Offset_Bdate ,CONVERT(varchar(200),'') sSource,a.nPlzzts into #mddkc
  from x0  a 
join Dappsource_DW.dbo.goods b on   a.sspbh=b.code
where 1=1     ; 


--Step 2.2:最后一次进货
select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #jc1
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
join  #Tmp_fdb c on a.sfdbh=c.sfdbh
where 1=1  
and a.dsj>CONVERT(date,GETDATE()-180)
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;


-- drop table #jcmx

with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,
ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and  a.nsl>=2 )
select * into #jcmx from x0  where npm<=2;
 
-- Step 2.2.0:多点陈列和配送包装数 drop table  #de_history
select sfdbh,sspbh,spsfs,nzdcl,nZdcl_offset,max(drq) drq_max,min(drq) min_drq  into #de_history
from  DappSource_Dw.dbo.sys_deliveryset
where  drq>=convert(date,getdate()-180)
group by  sfdbh,sspbh,spsfs,nzdcl,nZdcl_offset;

--  原因划分
-- Step 2.3:遗留库存
with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and a.nsl>0  )
update a set a.syy='遗留库存'   from #mddkc  a 
left join x0 b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
where 1=1  and b.sFdbh is null;

-- 
with x1 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and a.nsl>0  )
,x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc  ) nyhpm
,a.nrjxl,a.nrjxse, a.nsl,d.sSource  from #mddkc a 
 join x1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 left join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh 
where  1=1   and len(a.syy)=0   and d.dShrq is not null
  and convert(date,d.dshrq)=CONVERT(date,b.dsj)  )
update a set a.syy=case when isnull(c.nZdcl_offset,0)>=4
 and   c.nZdcl_offset >=a.nsl*0.5 then   '多点陈列'  when ISNULL(c.nzdcl,0)>=4
 and   c.nZdcl >=a.nsl*0.5 then '最低陈列量' end ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl,
 a.nZdcl=c.nZdcl,a.nZdcl_offset=c.nZdcl_offset,a.sSource=b.sSource
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
   join #de_history c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and 
   (( c.nZdcl_offset >=a.nsl*0.5 and isnull(c.nZdcl_offset,0)>=4 )
    or (ISNULL(c.nzdcl,0)>=4 and  c.nZdcl >=a.nsl*0.5  ))
  and  (CONVERT(date,b.dYhrq)>=CONVERT(date,c.min_drq)   
and CONVERT(date,b.dYhrq)<=CONVERT(date,c.drq_max) or  (CONVERT(date,b.dYhrq)<CONVERT(date,c.min_drq)))
 where  1=1     ;


-- Step 2.7:对盘点调拨 划分：盘点，调拨量大于当前库存数量的20%
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品') 
and b.npm=1
left join #jcmx c on  a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh  and c.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
 and c.npm=2
where  1=1  and len(a.syy)=0 and ((b.nDhsl>=a.nsl*0.2) or (b.nDhsl<a.nDhsl*0.2 and c.sfdbh is not null));
/*
select * from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
and  a.sspbh='23080011'  and a.sfdbh='018329';
*/
 
 
-- Step 2.8:对最后一次到货的包装数：>5 且
 update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
  from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('配送','二步越库') 
and    a.nPsbzs>=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 and b.npm=1 ;
 

update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
  from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('直送','一步越库')
and     a.nPsbzs >=a.nsl*0.6
and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 and b.npm=1  ;
       
-- Step 2.9 :最后一次要货查是谁下的单 如果系统单，
--但是到货量大 那么就是人工原因，到货量小于系统单，系统原因，其他 手工原因
--如果是在采购里面加单的话，那么就是手工加量或加单
-- 有单据 无进出,对有正常进出无单的 划为其他
with x0 as(
select a.sFdbh,a.sSpbh,isnull(d.dShrq,b.dsj) dSj,isnull(d.nShsl,b.ndhsl) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
 join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
	 and b.sjcfl   in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
left  join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
  and d.dShrq is not null  and convert(date,d.dshrq)=CONVERT(date,b.dsj)
where  1=1   and len(a.syy)=0    )
update a set a.syy= '其他'
  ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl 
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
 where  1=1 and b.dyhrq is null     ;

with x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
-- join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
where  1=1   and len(a.syy)=0 and d.dShrq is not null
  and isnull(d.nShsl,0)>=a.nsl*0.2 
  -- and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
   )
update a set a.syy=   
case  when (b.sbz like '%自动生成%' or b.sbz like ';;%') 
        and ( b.ncgsl_old is not null and b.nyhsl_raw<=b.ncgsl_old  
        and b.nYhsl<=b.nYhsl_raw )    then '系统定额过大' 
    when   (b.sbz like '%自动生成%' or b.sbz like ';;%') 
       and ( b.ncgsl_old is   null and b.nyhsl_raw IS not null 
       and b.nYhsl<=b.nYhsl_raw )    then '人工加量或加单' 
when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like '硬配%'
           then '采购硬配' 
 when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like 'APP补货%'
           then '门店下单' 
when   b.sbz   like '%自采订单%'   then '人工下单' 
when   b.sbz   like '%DM%'   then 'DM'
when   b.sbz   like '%新品%'   then '新品'
else '人工下单' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl ,a.sSource=b.sSource
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
 ;

/*
select a.sFdbh,a.sSpbh,isnull(d.dShrq,b.dsj) dSj,isnull(d.nShsl,b.ndhsl) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  dbo.vendor c on a.sGys=c.code  
left join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
and     d.dShrq is not null  and isnull(d.nShsl,0)>=a.nsl*0.2 
 and convert(date,d.dShrq)=convert(date,b.dsj)
where  1=1  and a.sspbh='23080011'
  
*/

-- Step 2.10:往前追溯一次
update #mddkc set sfwqzs='是' where len(syy)=0;

-- 进出再生成,不设量限制 drop table #jcmx1
with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and  a.nsl>0 )
select * into #jcmx1 from x0  where npm<=2;


-- Step 2.12:对盘点调拨 划分：第二次盘点，调拨量大于当前库存数量的0.1就算
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1 and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
join   #jcmx1 c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=2 and c.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品') 
where  1=1 and len(a.syy)=0;
-- Step 2.13:对最后一次到货的包装数：库存数量小于包装数的1.2倍，最后一次到货量等于包装数
update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
 from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
where  1=1  and len(a.syy)=0 and  a.sPsfs in ('配送','二步越库')
and    a.nPsbzs >=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 ;

update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('直送','一步越库') 
and    a.nPsbzs >=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5  ;

-- Step 2.14:要货到货匹配再查一次

with x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
 -- join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
where  1=1   and len(a.syy)=0 and d.dShrq is not null
 -- and convert(date,d.dshrq)<=CONVERT(date,b.dsj) 
   )
update a set a.syy=   
case when (b.sbz like '%自动生成%' or b.sbz like ';;%') 
        and ( b.ncgsl_old is not null and b.nyhsl_raw<=b.ncgsl_old  
        and b.nYhsl<=b.nYhsl_raw )    then '系统定额过大' 
    when   (b.sbz like '%自动生成%' or b.sbz like ';;%') 
       and ( b.ncgsl_old is   null and b.nyhsl_raw IS not null 
       and b.nYhsl<=b.nYhsl_raw )    then '人工加量或加单' 
when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like '硬配%'
           then '采购硬配' 
 when   b.sbz not like '自动生成%' and b.sbz not like ';;%' and b.sbz like 'APP补货%'
           then '门店下单' 
when   b.sbz   like '%自采订单%'   then '人工下单' 
when   b.sbz   like '%DM%'   then 'DM'
when   b.sbz   like '%新品%'   then '新品'
else '人工下单' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl ,a.sSource=b.sSource
 from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1;
-- Step 2.15:   更新剩余 
update a set a.syy='其他'  from #mddkc a  where  1=1   and len(a.syy)=0 ;
-- 3 促销
select a.sFdbh,a.sspbh into #tmp_cx from [122.147.10.200].DAppSource.dbo.tmp_Promotion a 
where 1=1 and a.sZt<>'已结束'
and case when CONVERT(date,a.Bdate)>=a.Adate then CONVERT(date,a.Bdate)
else a.Adate end <GETDATE() and  case when 
CONVERT(date,a.Edate)>=a.CloseDate or a.CloseDate is null then CONVERT(date,a.Edate)
else a.CloseDate end >=GETDATE()
union
select b.sFdbh,b.sspbh
from  [122.147.10.200].DAppSource.dbo.tmp_promotionplan_items b
 where 1=1
and case when CONVERT(date,b.Bdate)>=b.DcTime then CONVERT(date,b.Bdate)
else b.DcTime end <GETDATE() and CONVERT(date,b.Bdate)>GETDATE();

update a set a.sfcx='是' from #mddkc  a
join #tmp_cx b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1;

-- drop table   #dhyq 
select a.sfdbh,a.sspbh into #dhyq from #tmp_dh_cal a
join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where  a.npm_cal=1 and b.npm_cal=2 and 
datediff(day,convert(date,a.dyhrq),convert(date,b.dshrq))>=0
and datediff(hour,b.dyhrq,a.dyhrq)>30
and a.ncgsl_old is not null 
and a.dshrq is not null 
order by a.sfdbh,a.sspbh; 

 
update a set a.syy='逾期到货' from #mddkc a
join #dhyq b on   a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 ;

update a set a.syy='人工下单' from #mddkc a
join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
	and CONVERT(date,a.dzhyhr)=CONVERT(date,b.dyhrq)
where a.syy='系统定额过大' and
  b.sbz not like ';;%'  and b.sbz not like ';;。自动生成%' 


-- Step 2.18:写入结果





-- 按嘉荣标准存的表


insert into TMP_ZZ_0331(drq,sfdbh,sspbh,sspmc,sfl,sgys,njj,nsj,szdbh,spsfs,nrjxse,nrjxl,nsl,nzzts,npsbzs,ncgbzs,dzhdhr,dzhyhr,
syy,sfwqzs,nbzzzts,sfcx,nDhsl,sSource)
select CONVERT(date,GETDATE()) drq, a.sFdbh,a.sSpbh,sSpmc,sFl,sGys,nJj,nSj,sZdbh,sPsfs,nrjxse,nRjxl,nsl,nzzts,nPsbzs,
nCgbzs,dzhdhr,dzhyhr,syy,sfwqzs,a.nPlzzts nbzzzts,a.sfcx,nDhsl,a.sSource from #mddkc a
where 1=1  ;


/*
2022-04-08

-- 自动补货商品明细
select a.sfdbh,b.sflbh into #zdbhfl
from [122.147.10.200].dappsource.dbo.sys_deliverysort a,
Dappsource_DW.dbo.tmp_spflb b where  b.sflbh like a.sflbh+'%' and LEN(b.sflbh)=8
or b.sflbh in ('1309','2103','2104');


-- 商品范围
 
select * into #dpzb from [122.147.10.202].dappresult.dbo.R_dpzb;
select sfdbh,sfdmc,smdlx,sDq,sQy into #Tmp_fdb from DappSource_Dw.dbo.tmp_fdb 
where   smdlx   in ('大店A','大店B','小店','中店A','中店B') and sJylx='连锁门店'
and dkyrq is not null and sjc not like '%取消%'; 
-- drop table #Base_sp

select a.DEPT_CODE sFdbh,a.ITEM_CODE sSpbh,b.sspmc,b.sPlbh,a.SHOP_SUPPLIER_CODE sgys,
a.SHIFT_PRICE njj,a.RETAIL_PRICE nsj,case when c.sfdbh is  not  null then 1 else 0 end szdbh,
case when a.SEND_CLASS_T='01' then '配送' when a.SEND_CLASS_T='02' then '直送'
when a.SEND_CLASS_T='03' then '一步越库' when a.SEND_CLASS_T='04' then '二步越库' end spsfs
,e.nrjxl*a.RETAIL_PRICE nrjxse,e.nsx nzgsl,e.nxx nzdsl,e.nrjxl,e.nzdcl,e.nzdcl_offset
,e.nZdcl_Offset_Bdate,e.nZdcl_Offset_Edate,e.ifPromotion,d.qpc ncgbzs,a.min_purchase_qty nPsbzs
into #Base_sp
from Dappsource_DW.dbo.P_SHOP_ITEM_OUTPUT a
join  #dpzb b on a.DEPT_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
left join #zdbhfl c on b.sfdbh=c.sfdbh and b.sPlbh=c.sflbh
join Dappsource_DW.dbo.goods d on a.ITEM_CODE=d.code
left join [122.147.10.200].dappsource.dbo.sys_deliveryset e on a.DEPT_CODE=e.sfdbh and a.ITEM_CODE=e.sspbh
join DappSource_Dw.dbo.tmp_fdb  f on  a.DEPT_CODE=f.sfdbh  and 
  f.smdlx   in ('大店A','大店B','小店','中店A','中店B') and f.sJylx='连锁门店'
and f.dkyrq is not null and f.sjc not like '%取消%'
where 1=1 and a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y' and a.CHARACTER_TYPE='N'
and b.enddate>GETDATE()-13 and
(( d.sort>'20' and d.sort<'40') or (
LEFT(d.sort,4) in ('1105','1307','1406') ))
and LEFT(d.sort,4)<>'2201';
 

-- 生成零库存表 drop table  #mdlkcsp
select a.*,ISNULL(b.CURR_STOCK,0)nsl,CONVERT(varchar(20),'') syy,
CONVERT(datetime,'') dzhyhrq into #mdlkcsp from #Base_sp a
left join  Dappsource_DW.dbo.V_D_PRICE_AND_STOCK b on  a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE
where ISNULL(b.CURR_STOCK,0)<=a.nrjxl*3;
--  门店在要货数据 drop table #Tmp_yh
with x0 as (
select a.dYhrq,b.ddhrq dShrq,a. sdjlx sLx,b.sfdbh,b.sspbh,b.nsl nYhsl,b.ndhsl,b.sBzmx
from [122.147.10.200].dappsource.dbo.tmp_yhb a 
inner join [122.147.10.200].dappsource.dbo.tmp_yhmx b
on a.sdh=b.sdh and a.sFdbh=b.sFdbh
join #Tmp_fdb c on a.sfdbh=c.sfdbh
where 1=1  and a.dYhrq>=CONVERT(date,GETDATE()-180) 
and (  a.dYhrq+2<GETDATE() or b.ddhrq is not null))
,x1 as (select a.* from  x0 a
join  #base_sp c on a.sFdbh=c.sFdbh and a.sspbh=c.sSpbh
join Dappsource_DW.dbo.vendor d on c.sGys=d.code  
where  1=1 )
select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id 
into #Tmp_yh 
from x0 a ;


-- D zixun 原表 drop table #1

select CONVERT(date,b.dctime) dYhrq,a.sdh,isnull(a.sfdbh,c.sfdbh) sfdbh,
isnull(b.sspbh,c.sspbh) sspbh,ISNULL(c.nsl,b.nsl) nCgsl,b.nsl_raw ncgsl_raw,'' genstate,''smemo
into #1 from [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT a
join [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT_items b  on a.sdh=b.sdh
left join  [122.147.10.200].dappsource.dbo.delivery_receipt_zt c on b.sdh=c.sdh and b.sspbh=c.sspbh
join #Tmp_fdb d on  isnull(a.sfdbh,c.sfdbh)=d.sfdbh
where 1=1 and CONVERT(date,b.dctime)>=CONVERT(date,GETDATE()-180) and  ISNULL(c.nsl,b.nsl)>0;
 
select a.* into #dzixun_raw  from #1 a
join #base_sp d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh
join Dappsource_DW.dbo.vendor e on d.sGys=e.code 
where 1=1 and 
((d.spsfs='配送' and dateadd(day,2,a.dYhrq)<CONVERT(date,GETDATE()))
or (d.spsfs<>'配送'  and +dateadd(day,ISNULL(e.ValidDay,5),a.dYhrq)
<CONVERT(date,GETDATE())));


-- 单据汇总
select * into #BusType from [122.147.10.200].DAppSource.dbo.BusType;

with x0 as (
select sfdbh,sspbh,dyhrq,dshrq,slx,nyhsl,ndhsl,sbzmx,id,'要货' flag,
isnull(c.sname,case when a.sbzmx like '%自动生成%' or a.sbzmx like ';;%' then '自动补货'
 end ) sSource from #tmp_yh  a
left join #BusType c on 1=1 and CHARINDEX(c.sName,a.sbzmx,0)>1
)
select  ISNULL(a.sFdbh,b.sFdbh) sfdbh,ISNULL(a.sspbh,b.sSpbh) sspbh,
ISNULL(a.dYhrq,b.dYhrq) dYhrq,a.dShrq, a.nYhsl,b.nCgsl nYhsl_raw,b.ncgsl_raw ncgsl_old,
a.ndhsl nShsl,b.GenState,b.sMemo,a.sLx,sbzmx sBz,a.flag,
ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
ISNULL(a.sspbh,b.sSpbh) order by isnull(a.dyhrq,b.dyhrq) desc) npm_cal,
case when a.sFdbh is null then '系统单' end is_auto,a.sSource into #TMP_dh_cal
  from x0 a full join #dzixun_raw b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)>0 and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)<24 
where 1=1 ;
 
-- 最后的销售日期和进出

select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #2
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
join #Tmp_fdb c on a.sfdbh=c.sfdbh 
where 1=1 and a.sfdbh not like '015%' and a.dsj>CONVERT(date,GETDATE()-30)
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;



select *,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl) npm
into #jcmx0
  from #2 a   where a.nsl<0;



select * into #3 from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
join #Tmp_fdb b on a.SHOP_CODE=b.sfdbh 
 where 1=1 and  CONVERT(date,a.SALE_DATE)>CONVERT(date,getdate()-14);


--  drop  table #xsrq

select a.sfdbh,a.sspbh,CONVERT(date,b.drq) max_xs,SUM(b.nxssl_pro) nxssl,
ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by CONVERT(date,b.drq) desc) npm 
into #xsrq
from #mdlkcsp a,#3 b where a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
group by a.sfdbh,a.sspbh,CONVERT(date,b.drq);


-- 分原因
-- 暂不补货

update a  set  a.syy='暂不补货',a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliveryGysEx b 
where a.sgys=b.sgys ;

update a  set  a.syy='暂不补货',a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliverySortEx b
where a.splbh like b.sflbh+'%' and a.sfdbh=b.sfdbh ;

update a  set  a.syy='暂不补货',a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliverySpEx b
where a.sspbh=b.sspbh and b.begindate<GETDATE() and b.enddate>GETDATE()
and nflag=1 ;


update a set a.syy=b.sJcfl from #mdlkcsp a 
join #jcmx0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
where  (b.dSj>c.max_xs or c.sFdbh is null)  and b.nSl<-2 and (( a.sPsfs='配送' and b.dSj>CONVERT(date,GETDATE()-5)) 
or (a.sPsfs<>'配送' and b.dSj>CONVERT(date,GETDATE()-14)));

-- 配送商品无库位

select * into #5 from [122.147.10.200].DAppSource.dbo.t_tihi;

update a set a.syy='DC无库位' from #mdlkcsp a
left join #5 b on a.sspbh=b.SIZE_DESC
where 1=1 and LEN(a.syy)=0 and a.sPsfs='配送' and b.SIZE_DESC
 is null ;


-- 突发销售

update a set a.syy='突发销售' from #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
where len(a.syy)=0  and  (( a.sPsfs='配送' and c.max_xs>CONVERT(date,GETDATE()-5)) 
or (a.sPsfs<>'配送' and c.max_xs>CONVERT(date,GETDATE()-14))) and c.nXssl>a.nRjxl*5 and c.nXssl>2      
and   c.nXssl>=round(a.nzgsl*0.8,0) and (c.max_xs>b.dShrq or b.dShrq is null) ;


-- 起订量不足

select * into #6 from  [122.147.10.200].DAppSource.dbo.Rectification_MinSet_Ys
where drq>=CONVERT(date,GETDATE()-32);


update a set a.syy='未达起订量' from #mdlkcsp a
left join #Tmp_dh_cal  b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
join #6 c   on case when a.spsfs<>'直送' then '015901' else  a.sfdbh end=c.sfdbh and a.sspbh=c.sspbh
where c.drq>b.dyhrq or b.sfdbh is null ;


update a set  a.syy= case when  c.IntoDate>GETDATE()-5 then  '系统定额不足' 
else '新品' end   from  #mdlkcsp a 
 left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  and   b.dYhrq>=convert(date,GETDATE()-30)
 left join  [122.147.10.202].DAppresult.dbo.Index_Sp c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh 
where 1=1  and   len(a.syy)=0  
and  a.sZdbh=1   and b.sfdbh is null;

update a set  a.syy='人工未下单'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
and b.dYhrq>convert(date,GETDATE()-7)
where 1=1  and   len(a.syy)=0  and  a.sZdbh=0   and b.sfdbh is null;


-- Step 6.2 直送商品，供应商未送，采购单，供应商到货量为空
update a set a.dzhyhrq=b.dYhrq,a.syy=
case when spsfs='直送' then '直送' else '越库' end +'供应商未送货'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
where 1=1    and  len(a.syy)=0  and a.sPsfs<>'配送' and isnull(b.nShsl,0)=0 ;
 


-- Step 6.4 供应商送货不足，采购量到货量低于90%
update a set a.dzhyhrq=b.dYhrq,
a.syy=case when spsfs='直送' then '直送' else '越库' end+'供应商送货不足'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
where 1=1  and  len(a.syy)=0  and a.sPsfs<>'配送' and b.nYhsl>0  and  b.nShsl*1.0/b.nYhsl<0.9 ;

-- Step 6.5 人工订货不足，szdbh=0
update a set a.syy='人工未下单'  from  #mdlkcsp a 
left  join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)=0 ;

update a set a.dzhyhrq=b.dYhrq,a.syy='人工订货不足'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)>0  and b.nShsl*1.0/b.nYhsl>=0.9 ;


-- Step 6.6 DC未送货 或 送货不足
update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心未送货'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
where 1=1  and   len(a.syy)=0  and b.sfdbh is not null  and   isnull(b.nShsl,0)=0 and a.sPsfs<>'直送'
and b.nYhsl>0;

update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心送货不足'  from  #mdlkcsp a 
join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
where 1=1  and   len(a.syy)=0  and b.nShsl>0 and  b.nYhsl*1.0/b.nShsl<0.9 and a.sPsfs<>'直送' ;
-- 更新物流有货未配 drop table   #dckc
select distinct a.sSpbh into #dckc from #mdlkcsp a 
join [122.147.10.200].DAppSource.dbo.T_Dckclsb b
on a.sSpbh=b.sSpbh and b.QtyAllow>0 and  a.syy='物流中心未送货' and 
DATEDIFF(day,a.dzhyhrq,CONVERT(date,b.sRq)) between 0 and 7
where  1=1; 

update a set a.syy='物流中心有货未送' from  #mdlkcsp a join #dckc b  on a.sspbh=b.sspbh
where a.syy='物流中心未送货'  ;

update a set a.syy='物流中心无货未送' from  #mdlkcsp a  
where a.syy='物流中心未送货' ;
-- Step 6.7 :系统未下单，或定额不足
-- 系统未下单 需要考虑节奏日，如果即使到节奏日出了单，那也是定额不足，后面用异常出单修正原来的原因
update a set  a.syy='系统定额不足'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
where 1=1  and   len(a.syy)=0  
and  a.sZdbh=1   and b.sfdbh is null;

-- Step 6.8:系统定额不足,但如果是手工改小的采购单 
update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
where 1=1  and   len(a.syy)=0   and b.nShsl>0   and  b.nShsl*1.0/b.nYhsl>=0.9
and  a.sZdbh=1 and b.ncgsl_old<=b.nyhsl 
and (b.sbz like '%自动%' or b.sbz like ';;%') ;

--Step 6.9: 人工改小或删单
update a set a.dzhyhrq=b.dYhrq,a.syy='人工减量或删单'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
and ((b.nShsl>0  and b.nYHsl_raw<b.ncgsl_old 
	and isnull(b.nYhsl,0)>0) or (b.ncgsl_old>0 and b.nYhsl is null ))
where 1=1  and   len(a.syy)=0   
and  a.sZdbh=1  and b.sfdbh is not null ;


--Step 6.10: 系统定额不足，人工未减量，供应商到货
update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
where 1=1  and   len(a.syy)=0   and b.nShsl>0 and  b.nShsl*1.0/b.nYhsl>=0.9
and  a.sZdbh=1  and b.nYhsl_raw=b.nYhsl  and b.nYhsl_raw>=b.ncgsl_old ;


 update a set a.syy='其他' from #mdlkcsp a    where len(a.syy)=0  ; 
 delete from dbo.TMP_MDLKCYY where drq=convert(date,GETDATE());
 -- delete from dbo.TMP_MDLKCYY where drq=convert(date,GETDATE()-90);
  
  
 delete from Dappsource_DW.dbo.TMP_MDLKCYY where drq=convert(date,GETDATE()); 
 insert into Dappsource_DW.dbo.TMP_MDLKCYY(drq,sfdbh,sspbh,sspmc,sfl,nZdsl,nZgsl,szdbh,ssfkj,spsfs,syy,dzhyhrq,nrjxl,nrjxse,nsl)
 select convert(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sSpmc,a.splbh,a.nZdsl ,a.nZgsl ,a.sZdbh,'1' sSfkj,a.sPsfs,a.syy,
  a.dzhyhrq,a.nRjxl,a.nRjxse,a.nsl   from  #mdlkcsp a ;

 
-- 第二部分 门店大库存
-- Step 2.1 ：大库存数据生成 进出按进出，要货按最后要货日期   drop table #mddkc

select sFlbh,sFlmc,nPlzzts into #tmp_flbb from   DappSource_Dw.dbo.Tmp_sort_standard
where drq = (select max(drq) from  DappSource_Dw.dbo.Tmp_sort_standard);


with x0 as (
select a.*,b.CURR_STOCK nsl, convert(numeric(15,4),case when  a.nrjxl*a.nsj=0 
then 300 else b.CURR_STOCK*a.njj*1.0/(a.nRjxl*a.nsj) end) nzzts, isnull(c.nPlzzts,55) nPlzzts
from #base_sp a 
left join Dappsource_DW.dbo.V_D_PRICE_AND_STOCK b on a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE 
left join #tmp_flbb c on LEFT(a.splbh,4)=c.sflbh 
where 1=1 and ISNULL(b.CURR_STOCK,0)>6 and ISNULL(b.CURR_STOCK,0)*a.nJj>50 
and   case when a.nRjxl*a.nsj=0 then 300 else 
   ISNULL(b.CURR_STOCK,0)*a.njj*1.0/(a.nRjxl*a.nsj) end>=isnull(c.nPlzzts,55) )
select a.sFdbh,a.sSpbh,a.sspmc ,a.sPlbh sFl,b.munit sdw,b.billto sGys,a.nJj,a.nSj
,a.szdbh,a.sPsfs,a.nRjxl,a.nRjxl*a.nsj nrjxse,a.nsl,a.nzgsl,a.nzdcl
, a.nzzts,a.nPsbzs,a.nCgbzs,convert(date,Null) dzhyhr,convert(date,Null) dzhdhr, 
convert(varchar(20),'') syy,convert(varchar(5),'') sfwqzs,convert(varchar(20),'') sfcx,
convert(money,Null) nYhsl,convert(money,Null) nDhsl,a.nzdcl_offset,
a.nZdcl_Offset_Edate,a.nZdcl_Offset_Bdate ,CONVERT(varchar(200),'') sSource,a.nPlzzts into #mddkc
  from x0  a 
join Dappsource_DW.dbo.goods b on   a.sspbh=b.code
where 1=1     ; 


--Step 2.2:最后一次进货
select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #jc1
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
join  #Tmp_fdb c on a.sfdbh=c.sfdbh
where 1=1  
and a.dsj>CONVERT(date,GETDATE()-180)
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;


-- drop table #jcmx

with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,
ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and  a.nsl>=2 )
select * into #jcmx from x0  where npm<=2;
 
-- Step 2.2.0:多点陈列和配送包装数 drop table  #de_history
select sfdbh,sspbh,spsfs,nzdcl,nZdcl_offset,max(drq) drq_max,min(drq) min_drq  into #de_history
from  DappSource_Dw.dbo.sys_deliveryset
where  drq>=convert(date,getdate()-180)
group by  sfdbh,sspbh,spsfs,nzdcl,nZdcl_offset;

--  原因划分
-- Step 2.3:遗留库存
with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and a.nsl>0  )
update a set a.syy='遗留库存'   from #mddkc  a 
left join x0 b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
where 1=1  and b.sFdbh is null;

-- 
with x1 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and a.nsl>0  )
,x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc  ) nyhpm
,a.nrjxl,a.nrjxse, a.nsl,d.sSource  from #mddkc a 
 join x1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 left join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh 
where  1=1   and len(a.syy)=0   and d.dShrq is not null
  and convert(date,d.dshrq)=CONVERT(date,b.dsj)  )
update a set a.syy=case when isnull(c.nZdcl_offset,0)>=4
 and   c.nZdcl_offset >=a.nsl*0.5 then   '多点陈列'  when ISNULL(c.nzdcl,0)>=4
 and   c.nZdcl >=a.nsl*0.5 then '最低陈列量' end ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl,
 a.nZdcl=c.nZdcl,a.nZdcl_offset=c.nZdcl_offset,a.sSource=b.sSource
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
   join #de_history c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and 
   (( c.nZdcl_offset >=a.nsl*0.5 and isnull(c.nZdcl_offset,0)>=4 )
    or (ISNULL(c.nzdcl,0)>=4 and  c.nZdcl >=a.nsl*0.5  ))
  and  (CONVERT(date,b.dYhrq)>=CONVERT(date,c.min_drq)   
and CONVERT(date,b.dYhrq)<=CONVERT(date,c.drq_max) or  (CONVERT(date,b.dYhrq)<CONVERT(date,c.min_drq)))
 where  1=1     ;


-- Step 2.7:对盘点调拨 划分：盘点，调拨量大于当前库存数量的20%
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品') 
and b.npm=1
left join #jcmx c on  a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh  and c.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
 and c.npm=2
where  1=1  and len(a.syy)=0 and ((b.nDhsl>=a.nsl*0.2) or (b.nDhsl<a.nDhsl*0.2 and c.sfdbh is not null));
/*
select * from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
and  a.sspbh='23080011'  and a.sfdbh='018329';
*/
 
 
-- Step 2.8:对最后一次到货的包装数：>5 且
 update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
  from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('配送','二步越库') 
and    a.nPsbzs>=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 and b.npm=1 ;
 

update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
  from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('直送','一步越库')
and     a.nPsbzs >=a.nsl*0.6
and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 and b.npm=1  ;
       
-- Step 2.9 :最后一次要货查是谁下的单 如果系统单，
--但是到货量大 那么就是人工原因，到货量小于系统单，系统原因，其他 手工原因
--如果是在采购里面加单的话，那么就是手工加量或加单
-- 有单据 无进出,对有正常进出无单的 划为其他
with x0 as(
select a.sFdbh,a.sSpbh,isnull(d.dShrq,b.dsj) dSj,isnull(d.nShsl,b.ndhsl) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
 join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
	 and b.sjcfl   in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
left  join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
  and d.dShrq is not null  and convert(date,d.dshrq)=CONVERT(date,b.dsj)
where  1=1   and len(a.syy)=0    )
update a set a.syy= '其他'
  ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl 
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
 where  1=1 and b.dyhrq is null     ;

with x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
-- join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
where  1=1   and len(a.syy)=0 and d.dShrq is not null
  and isnull(d.nShsl,0)>=a.nsl*0.2 
  -- and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
   )
update a set a.syy=   
case  when (b.sbz like '%自动生成%' or b.sbz like ';;%') 
        and ( b.ncgsl_old is not null and b.nyhsl_raw<=b.ncgsl_old  
        and b.nYhsl<=b.nYhsl_raw )    then '系统定额过大' 
    when   (b.sbz like '%自动生成%' or b.sbz like ';;%') 
       and ( b.ncgsl_old is   null and b.nyhsl_raw IS not null 
       and b.nYhsl<=b.nYhsl_raw )    then '人工加量或加单' 
when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like '硬配%'
           then '采购硬配' 
 when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like 'APP补货%'
           then '门店下单' 
when   b.sbz   like '%自采订单%'   then '人工下单' 
when   b.sbz   like '%DM%'   then 'DM'
when   b.sbz   like '%新品%'   then '新品'
else '人工下单' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl ,a.sSource=b.sSource
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
 ;

/*
select a.sFdbh,a.sSpbh,isnull(d.dShrq,b.dsj) dSj,isnull(d.nShsl,b.ndhsl) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  dbo.vendor c on a.sGys=c.code  
left join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
and     d.dShrq is not null  and isnull(d.nShsl,0)>=a.nsl*0.2 
 and convert(date,d.dShrq)=convert(date,b.dsj)
where  1=1  and a.sspbh='23080011'
  
*/

-- Step 2.10:往前追溯一次
update #mddkc set sfwqzs='是' where len(syy)=0;

-- 进出再生成,不设量限制 drop table #jcmx1
with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and  a.nsl>0 )
select * into #jcmx1 from x0  where npm<=2;


-- Step 2.12:对盘点调拨 划分：第二次盘点，调拨量大于当前库存数量的0.1就算
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1 and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
join   #jcmx1 c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=2 and c.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品') 
where  1=1 and len(a.syy)=0;
-- Step 2.13:对最后一次到货的包装数：库存数量小于包装数的1.2倍，最后一次到货量等于包装数
update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
 from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
where  1=1  and len(a.syy)=0 and  a.sPsfs in ('配送','二步越库')
and    a.nPsbzs >=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 ;

update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('直送','一步越库') 
and    a.nPsbzs >=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5  ;

-- Step 2.14:要货到货匹配再查一次

with x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
 -- join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
where  1=1   and len(a.syy)=0 and d.dShrq is not null
 -- and convert(date,d.dshrq)<=CONVERT(date,b.dsj) 
   )
update a set a.syy=   
case when (b.sbz like '%自动生成%' or b.sbz like ';;%') 
        and ( b.ncgsl_old is not null and b.nyhsl_raw<=b.ncgsl_old  
        and b.nYhsl<=b.nYhsl_raw )    then '系统定额过大' 
    when   (b.sbz like '%自动生成%' or b.sbz like ';;%') 
       and ( b.ncgsl_old is   null and b.nyhsl_raw IS not null 
       and b.nYhsl<=b.nYhsl_raw )    then '人工加量或加单' 
when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like '硬配%'
           then '采购硬配' 
 when   b.sbz not like '自动生成%' and b.sbz not like ';;%' and b.sbz like 'APP补货%'
           then '门店下单' 
when   b.sbz   like '%自采订单%'   then '人工下单' 
when   b.sbz   like '%DM%'   then 'DM'
when   b.sbz   like '%新品%'   then '新品'
else '人工下单' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl ,a.sSource=b.sSource
 from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1;
-- Step 2.15:   更新剩余 
update a set a.syy='其他'  from #mddkc a  where  1=1   and len(a.syy)=0 ;
-- 3 促销
select a.sFdbh,a.sspbh into #tmp_cx from [122.147.10.200].DAppSource.dbo.tmp_Promotion a 
where 1=1 and a.sZt<>'已结束'
and case when CONVERT(date,a.Bdate)>=a.Adate then CONVERT(date,a.Bdate)
else a.Adate end <GETDATE() and  case when 
CONVERT(date,a.Edate)>=a.CloseDate or a.CloseDate is null then CONVERT(date,a.Edate)
else a.CloseDate end >=GETDATE()
union
select b.sFdbh,b.sspbh
from  [122.147.10.200].DAppSource.dbo.tmp_promotionplan_items b
 where 1=1
and case when CONVERT(date,b.Bdate)>=b.DcTime then CONVERT(date,b.Bdate)
else b.DcTime end <GETDATE() and CONVERT(date,b.Bdate)>GETDATE();

update a set a.sfcx='是' from #mddkc  a
join #tmp_cx b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1;

-- drop table   #dhyq 
select a.sfdbh,a.sspbh into #dhyq from #tmp_dh_cal a
join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where  a.npm_cal=1 and b.npm_cal=2 and 
datediff(day,convert(date,a.dyhrq),convert(date,b.dshrq))>=0
and datediff(hour,b.dyhrq,a.dyhrq)>30
and a.ncgsl_old is not null 
and a.dshrq is not null 
order by a.sfdbh,a.sspbh; 

 
update a set a.syy='逾期到货' from #mddkc a
join #dhyq b on   a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 ;

update a set a.syy='人工下单' from #mddkc a
join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
	and CONVERT(date,a.dzhyhr)=CONVERT(date,b.dyhrq)
where a.syy='系统定额过大' and
  b.sbz not like ';;%'  and b.sbz not like ';;。自动生成%' 


-- 按嘉荣标准存的表
insert into TMP_ZZ_0331(drq,sfdbh,sspbh,sspmc,sfl,sgys,njj,nsj,szdbh,spsfs,nrjxse,nrjxl,nsl,nzzts,npsbzs,ncgbzs,dzhdhr,dzhyhr,
syy,sfwqzs,nbzzzts,sfcx,nDhsl,sSource)
select CONVERT(date,GETDATE()) drq, a.sFdbh,a.sSpbh,sSpmc,sFl,sGys,nJj,nSj,sZdbh,sPsfs,nrjxse,nRjxl,nsl,nzzts,nPsbzs,
nCgbzs,dzhdhr,dzhyhr,syy,sfwqzs,a.nPlzzts nbzzzts,a.sfcx,nDhsl,a.sSource from #mddkc a
where 1=1  ; 
*/

----------------  V2 
-- 自动补货商品明细
select a.sfdbh,b.sflbh into #zdbhfl
from [122.147.10.200].dappsource.dbo.sys_deliverysort a,
Dappsource_DW.dbo.tmp_spflb b where  b.sflbh like a.sflbh+'%' and LEN(b.sflbh)=8
or b.sflbh in ('1309','2103','2104');


-- 商品范围
 
select * into #dpzb from [122.147.10.202].dappresult.dbo.R_dpzb;
select sfdbh,sfdmc,smdlx,sDq,sQy into #Tmp_fdb from DappSource_Dw.dbo.tmp_fdb 
where   smdlx   in ('大店A','大店B','小店','中店A','中店B') and sJylx='连锁门店'
and dkyrq is not null and sjc not like '%取消%'; 

select distinct sfdbh from #Base_sp

select  enddate,count(distinct sfdbh) from #dpzb  group by enddate 

-- drop table #Base_sp

select a.DEPT_CODE sFdbh,a.ITEM_CODE sSpbh,d.name sspmc,d.sort sPlbh,a.SHOP_SUPPLIER_CODE sgys,
a.SHIFT_PRICE njj,a.RETAIL_PRICE nsj,case when c.sfdbh is  not  null then 1 else 0 end szdbh,
case when a.SEND_CLASS_T='01' then '配送' when a.SEND_CLASS_T='02' then '直送'
when a.SEND_CLASS_T='03' then '一步越库' when a.SEND_CLASS_T='04' then '二步越库' end spsfs
,e.nrjxl*a.RETAIL_PRICE nrjxse,e.nsx nzgsl,e.nxx nzdsl,e.nrjxl,e.nzdcl,e.nzdcl_offset
,e.nZdcl_Offset_Bdate,e.nZdcl_Offset_Edate,e.ifPromotion,d.qpc ncgbzs,a.min_purchase_qty nPsbzs,a.ITEM_ETAGERE_CODE
into #Base_sp
from Dappsource_DW.dbo.P_SHOP_ITEM_OUTPUT a
join Dappsource_DW.dbo.goods d on a.ITEM_CODE=d.code
left join #zdbhfl c on a.Dept_code=c.sfdbh and d.sort=c.sflbh
left join [122.147.10.200].dappsource.dbo.sys_deliveryset e on a.DEPT_CODE=e.sfdbh and a.ITEM_CODE=e.sspbh
join DappSource_Dw.dbo.tmp_fdb  f on  a.DEPT_CODE=f.sfdbh  and 
  f.smdlx   in ('大店A','大店B','小店','中店A','中店B') and f.sJylx='连锁门店'
and f.dkyrq is not null and f.sjc not like '%取消%'
where 1=1 and a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y' and a.CHARACTER_TYPE='N' and
(( d.sort>'20' and d.sort<'40') or (
LEFT(d.sort,4) in ('1105','1307','1406') ))
and LEFT(d.sort,4)<>'2201';
 
  
--  门店在要货数据 drop table #Tmp_yh
with x0 as (
select a.dYhrq,b.ddhrq dShrq,a. sdjlx sLx,b.sfdbh,b.sspbh,b.nsl nYhsl,b.ndhsl,b.sBzmx
from [122.147.10.200].dappsource.dbo.tmp_yhb a 
inner join [122.147.10.200].dappsource.dbo.tmp_yhmx b
on a.sdh=b.sdh and a.sFdbh=b.sFdbh
join #Tmp_fdb c on a.sfdbh=c.sfdbh
where 1=1  and a.dYhrq>=CONVERT(date,GETDATE()-180) 
and (  a.dYhrq+2<GETDATE() or b.ddhrq is not null))
,x1 as (select a.* from  x0 a
join  #base_sp c on a.sFdbh=c.sFdbh and a.sspbh=c.sSpbh
join Dappsource_DW.dbo.vendor d on c.sGys=d.code  
where  1=1 )
select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id 
into #Tmp_yh 
from x0 a ;


-- D zixun 原表 drop table #1

select CONVERT(date,b.dctime) dYhrq,a.sdh,isnull(a.sfdbh,c.sfdbh) sfdbh,
isnull(b.sspbh,c.sspbh) sspbh,ISNULL(c.nsl,b.nsl) nCgsl,b.nsl_raw ncgsl_raw,'' genstate,''smemo
into #1 from [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT a
join [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT_items b  on a.sdh=b.sdh
left join  [122.147.10.200].dappsource.dbo.delivery_receipt_zt c on b.sdh=c.sdh and b.sspbh=c.sspbh
join #Tmp_fdb d on  isnull(a.sfdbh,c.sfdbh)=d.sfdbh
where 1=1 and CONVERT(date,b.dctime)>=CONVERT(date,GETDATE()-180) and  ISNULL(c.nsl,b.nsl)>0;
 
select a.* into #dzixun_raw  from #1 a
join #base_sp d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh
join Dappsource_DW.dbo.vendor e on d.sGys=e.code 
where 1=1 and 
((d.spsfs='配送' and dateadd(day,2,a.dYhrq)<CONVERT(date,GETDATE()))
or (d.spsfs<>'配送'  and +dateadd(day,ISNULL(e.ValidDay,5),a.dYhrq)
<CONVERT(date,GETDATE())));


-- 单据汇总
select * into #BusType from [122.147.10.200].DAppSource.dbo.BusType;

with x0 as (
select sfdbh,sspbh,dyhrq,dshrq,slx,nyhsl,ndhsl,sbzmx,id,'要货' flag,
isnull(c.sname,case when a.sbzmx like '%自动生成%' or a.sbzmx like ';;%' then '自动补货'
 end ) sSource from #tmp_yh  a
left join #BusType c on 1=1 and CHARINDEX(c.sName,a.sbzmx,0)>1
)
select  ISNULL(a.sFdbh,b.sFdbh) sfdbh,ISNULL(a.sspbh,b.sSpbh) sspbh,
ISNULL(a.dYhrq,b.dYhrq) dYhrq,a.dShrq, a.nYhsl,b.nCgsl nYhsl_raw,b.ncgsl_raw ncgsl_old,
a.ndhsl nShsl,b.GenState,b.sMemo,a.sLx,sbzmx sBz,a.flag,
ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
ISNULL(a.sspbh,b.sSpbh) order by isnull(a.dyhrq,b.dyhrq) desc) npm_cal,
case when a.sFdbh is null then '系统单' end is_auto,a.sSource into #TMP_dh_cal
  from x0 a full join #dzixun_raw b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)>0 and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)<24 
where 1=1 ;
 

 
-- 第二部分 门店大库存
-- Step 2.1 ：大库存数据生成 进出按进出，要货按最后要货日期   drop table #mddkc

select sFlbh,sFlmc,nPlzzts into #tmp_flbb from   DappSource_Dw.dbo.Tmp_sort_standard
where drq = (select max(drq) from  DappSource_Dw.dbo.Tmp_sort_standard);

-- 2.1.1  xs
select a.SHOP_CODE sfdbh,a.ITEM_CODE sspbh,sum(a.SALE_QTY) nxssl into #Tmp_xs from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
		join #Base_sp b on a.ITEM_CODE=b.sSpbh and a.SHOP_CODE=b.sFdbh
		where    CONVERT(date,a.SALE_DATE)>=convert(date,getdate()-30)    and  CONVERT(date,a.SALE_DATE)<CONVERT(date,GETDATE())
		  group by  a.SHOP_CODE,a.ITEM_CODE;

-- drop table  #mddkc
with x0 as (
select a.*,b.CURR_STOCK nsl, convert(numeric(12,2),case when ISNULL(d.nxssl,0)=0 
then 300 else b.CURR_STOCK*30.0/d.nxssl end) nzzts, isnull(c.nPlzzts,55) nPlzzts, ISNULL(d.nxssl,0)/30.0 nxsrj
from #base_sp a 
left join Dappsource_DW.dbo.V_D_PRICE_AND_STOCK b on a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE 
left join #tmp_flbb c on LEFT(a.splbh,4)=c.sflbh 
left join #Tmp_xs d on a.sFdbh=d.sfdbh and a.sSpbh=d.sspbh
where 1=1 and ISNULL(b.CURR_STOCK,0)>6 and ISNULL(b.CURR_STOCK,0)*a.nJj>50 
and  convert(numeric(10,2),case when ISNULL(d.nxssl,0)=0 
then 300 else b.CURR_STOCK*30.0/d.nxssl end)>=isnull(c.nPlzzts,55) )
select a.sFdbh,a.sSpbh,a.sspmc ,a.sPlbh sFl,b.munit sdw,b.billto sGys,a.nJj,a.nSj
,a.szdbh,a.sPsfs,a.nxsrj nRjxl,a.nxsrj*a.nsj nrjxse,a.nsl,a.nzgsl,a.nzdcl
, a.nzzts,a.nPsbzs,a.nCgbzs,convert(date,Null) dzhyhr,convert(date,Null) dzhdhr, 
convert(varchar(20),'') syy,convert(varchar(5),'') sfwqzs,convert(varchar(20),'') sfcx,
convert(money,Null) nYhsl,convert(money,Null) nDhsl,a.nzdcl_offset,
a.nZdcl_Offset_Edate,a.nZdcl_Offset_Bdate ,CONVERT(varchar(200),'') sSource,a.nPlzzts,a.ITEM_ETAGERE_CODE into #mddkc
from x0  a 
join Dappsource_DW.dbo.goods b on   a.sspbh=b.code
where 1=1      ; 


--Step 2.2:最后一次进货
select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #jc1
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
join  #Tmp_fdb c on a.sfdbh=c.sfdbh
where 1=1  
and a.dsj>CONVERT(date,GETDATE()-180)
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;


-- drop table #jcmx

with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,
ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and  a.nsl>=2 )
select * into #jcmx from x0  where npm<=2;
 
-- Step 2.2.0:多点陈列和配送包装数 drop table  #de_history
select sfdbh,sspbh,spsfs,nzdcl,nZdcl_offset,max(drq) drq_max,min(drq) min_drq  into #de_history
from  DappSource_Dw.dbo.sys_deliveryset
where  drq>=convert(date,getdate()-180)
group by  sfdbh,sspbh,spsfs,nzdcl,nZdcl_offset;

--  原因划分
-- Step 2.3:遗留库存
with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and a.nsl>0  )
update a set a.syy='遗留库存'   from #mddkc  a 
left join x0 b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
where 1=1  and b.sFdbh is null;

update a set a.syy='新品'  from #mddkc a  where 1=1 
and  len(syy)=0  and  convert(date,a.ITEM_ETAGERE_CODE)>CONVERT(date,GETDATE()-90) and   a.ITEM_ETAGERE_CODE is  not null;

-- 
with x1 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and a.nsl>0  )
,x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc  ) nyhpm
,a.nrjxl,a.nrjxse, a.nsl,d.sSource  from #mddkc a 
 join x1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 left join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh 
where  1=1   and len(a.syy)=0   and d.dShrq is not null
  and convert(date,d.dshrq)=CONVERT(date,b.dsj)  )
update a set a.syy=case when isnull(c.nZdcl_offset,0)>=4
 and   c.nZdcl_offset >=a.nsl*0.5 then   '多点陈列'  when ISNULL(c.nzdcl,0)>=4
 and   c.nZdcl >=a.nsl*0.5 then '最低陈列量' end ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl,
 a.nZdcl=c.nZdcl,a.nZdcl_offset=c.nZdcl_offset,a.sSource=b.sSource
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
   join #de_history c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and 
   (( c.nZdcl_offset >=a.nsl*0.5 and isnull(c.nZdcl_offset,0)>=4 )
    or (ISNULL(c.nzdcl,0)>=4 and  c.nZdcl >=a.nsl*0.5  ))
  and  (CONVERT(date,b.dYhrq)>=CONVERT(date,c.min_drq)   
and CONVERT(date,b.dYhrq)<=CONVERT(date,c.drq_max) or  (CONVERT(date,b.dYhrq)<CONVERT(date,c.min_drq)))
 where  1=1     ; 


-- Step 2.7:对盘点调拨 划分：盘点，调拨量大于当前库存数量的20%
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品') 
and b.npm=1
 
where  1=1  and len(a.syy)=0 and  b.nDhsl>=a.nsl*0.2;
/*
select * from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
and  a.sspbh='23080011'  and a.sfdbh='018329';
*/
 
 
-- Step 2.8:对最后一次到货的包装数：>5 且
 update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
  from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('配送','二步越库') 
and    a.nPsbzs>=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 and b.npm=1 ;
 

update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
  from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('直送','一步越库')
and     a.nPsbzs >=a.nsl*0.6
and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 and b.npm=1  ;
       
-- Step 2.9 :最后一次要货查是谁下的单 如果系统单，
--但是到货量大 那么就是人工原因，到货量小于系统单，系统原因，其他 手工原因
--如果是在采购里面加单的话，那么就是手工加量或加单
-- 有单据 无进出,对有正常进出无单的 划为其他
with x0 as(
select a.sFdbh,a.sSpbh,isnull(d.dShrq,b.dsj) dSj,isnull(d.nShsl,b.ndhsl) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
 join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
	 and b.sjcfl   in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
left  join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
  and d.dShrq is not null  and convert(date,d.dshrq)=CONVERT(date,b.dsj)
where  1=1   and len(a.syy)=0    )
update a set a.syy= '其他'
  ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl 
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
 where  1=1 and b.dyhrq is null     ;

with x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
-- join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
where  1=1   and len(a.syy)=0 and d.dShrq is not null
  and isnull(d.nShsl,0)>=a.nsl*0.2 
  -- and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
   )
update a set a.syy=   
case  when (b.sbz like '%自动生成%' or b.sbz like ';;%') 
        and ( b.ncgsl_old is not null and b.nyhsl_raw<=b.ncgsl_old  
        and b.nYhsl<=b.nYhsl_raw )    then '系统定额过大' 
    when   (b.sbz like '%自动生成%' or b.sbz like ';;%') 
       and ( b.ncgsl_old is   null and b.nyhsl_raw IS not null 
       and b.nYhsl<=b.nYhsl_raw )    then '人工加量或加单' 
when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like '硬配%'
           then '采购硬配' 
 when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like 'APP补货%'
           then '门店下单' 
when   b.sbz   like '%自采订单%'   then '人工下单' 
when   b.sbz   like '%DM%'   then 'DM'
when   b.sbz   like '%新品%'   then '新品'
else '人工下单' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl ,a.sSource=b.sSource
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
 ;

/*
select a.sFdbh,a.sSpbh,isnull(d.dShrq,b.dsj) dSj,isnull(d.nShsl,b.ndhsl) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  dbo.vendor c on a.sGys=c.code  
left join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
and     d.dShrq is not null  and isnull(d.nShsl,0)>=a.nsl*0.2 
 and convert(date,d.dShrq)=convert(date,b.dsj)
where  1=1  and a.sspbh='23080011'
  
*/

-- Step 2.10:往前追溯一次
update #mddkc set sfwqzs='是' where len(syy)=0;

-- 进出再生成,不设量限制 drop table #jcmx1
with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and  a.nsl>0 )
select * into #jcmx1 from x0  where npm<=2;


-- Step 2.12:对盘点调拨 划分：第二次盘点，调拨量大于当前库存数量的0.1就算
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1 and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
join   #jcmx1 c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=2 and c.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品') 
where  1=1 and len(a.syy)=0 ;
-- Step 2.13:对最后一次到货的包装数：库存数量小于包装数的1.2倍，最后一次到货量等于包装数
update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
 from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
where  1=1  and len(a.syy)=0 and  a.sPsfs in ('配送','二步越库')
and    a.nPsbzs >=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 ;

update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('直送','一步越库') 
and    a.nPsbzs >=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5  ;

-- Step 2.14:要货到货匹配再查一次

with x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
 -- join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
where  1=1   and len(a.syy)=0 and d.dShrq is not null
 -- and convert(date,d.dshrq)<=CONVERT(date,b.dsj) 
   )
update a set a.syy=   
case when (b.sbz like '%自动生成%' or b.sbz like ';;%') 
        and ( b.ncgsl_old is not null and b.nyhsl_raw<=b.ncgsl_old  
        and b.nYhsl<=b.nYhsl_raw )    then '系统定额过大' 
    when   (b.sbz like '%自动生成%' or b.sbz like ';;%') 
       and ( b.ncgsl_old is   null and b.nyhsl_raw IS not null 
       and b.nYhsl<=b.nYhsl_raw )    then '人工加量或加单' 
when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like '硬配%'
           then '采购硬配' 
 when   b.sbz not like '自动生成%' and b.sbz not like ';;%' and b.sbz like 'APP补货%'
           then '门店下单' 
when   b.sbz   like '%自采订单%'   then '人工下单' 
when   b.sbz   like '%DM%'   then 'DM'
when   b.sbz   like '%新品%'   then '新品'
else '人工下单' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl ,a.sSource=b.sSource
 from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1;
-- Step 2.15:   更新剩余 
update a set a.syy='其他'  from #mddkc a  where  1=1   and len(a.syy)=0 ;
-- 3 促销
select a.sFdbh,a.sspbh into #tmp_cx from [122.147.10.200].DAppSource.dbo.tmp_Promotion a 
where 1=1 and a.sZt<>'已结束'
and case when CONVERT(date,a.Bdate)>=a.Adate then CONVERT(date,a.Bdate)
else a.Adate end <GETDATE() and  case when 
CONVERT(date,a.Edate)>=a.CloseDate or a.CloseDate is null then CONVERT(date,a.Edate)
else a.CloseDate end >=GETDATE()
union
select b.sFdbh,b.sspbh
from  [122.147.10.200].DAppSource.dbo.tmp_promotionplan_items b
 where 1=1
and case when CONVERT(date,b.Bdate)>=b.DcTime then CONVERT(date,b.Bdate)
else b.DcTime end <GETDATE() and CONVERT(date,b.Bdate)>GETDATE();

update a set a.sfcx='是' from #mddkc  a
join #tmp_cx b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1;

-- drop table   #dhyq 
select a.sfdbh,a.sspbh into #dhyq from #tmp_dh_cal a
join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where  a.npm_cal=1 and b.npm_cal=2 and 
datediff(day,convert(date,a.dyhrq),convert(date,b.dshrq))>=0
and datediff(hour,b.dyhrq,a.dyhrq)>30
and a.ncgsl_old is not null 
and a.dshrq is not null 
order by a.sfdbh,a.sspbh; 

 
update a set a.syy='逾期到货' from #mddkc a
join #dhyq b on   a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 ;

update a set a.syy='人工下单' from #mddkc a
join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
	and CONVERT(date,a.dzhyhr)=CONVERT(date,b.dyhrq)
where a.syy='系统定额过大' and
  b.sbz not like ';;%'  and b.sbz not like ';;。自动生成%' 


-- 按嘉荣标准存的表
delete from TMP_ZZ_0331 where drq=CONVERT(date,getdate());
insert into TMP_ZZ_0331(drq,sfdbh,sspbh,sspmc,sfl,sgys,njj,nsj,szdbh,spsfs,nrjxse,nrjxl,nsl,nzzts,npsbzs,ncgbzs,dzhdhr,dzhyhr,
syy,sfwqzs,nbzzzts,sfcx,nDhsl,sSource)
select CONVERT(date,GETDATE()) drq, a.sFdbh,a.sSpbh,sSpmc,sFl,sGys,nJj,nSj,sZdbh,sPsfs,nrjxse,nRjxl,nsl,nzzts,nPsbzs,
nCgbzs,dzhdhr,dzhyhr,syy,sfwqzs,a.nPlzzts nbzzzts,a.sfcx,nDhsl,a.sSource from #mddkc a
where 1=1  ; 












-------------V3 
-- 自动补货商品明细
select a.sfdbh,b.sflbh into #zdbhfl
from [122.147.10.200].dappsource.dbo.sys_deliverysort a,
Dappsource_DW.dbo.tmp_spflb b where  b.sflbh like a.sflbh+'%' and LEN(b.sflbh)=8
or b.sflbh in ('1309','2103','2104');


-- 商品范围
 
-- select * into #dpzb from [122.147.10.202].dappresult.dbo.R_dpzb;
-- select sfdbh,sfdmc,smdlx,sDq,sQy into #Tmp_fdb from DappSource_Dw.dbo.tmp_fdb 
-- where   smdlx   in ('大店A','大店B','小店','中店A','中店B') and sJylx='连锁门店'
-- and dkyrq is not null and sjc not like '%取消%'; 

-- select distinct sfdbh from #Base_sp

-- select  enddate,count(distinct sfdbh) from #dpzb  group by enddate 

-- drop table #Base_sp

select a.DEPT_CODE sFdbh,a.ITEM_CODE sSpbh,d.name sspmc,d.sort sPlbh,a.SHOP_SUPPLIER_CODE sgys,
a.SHIFT_PRICE njj,a.RETAIL_PRICE nsj,case when c.sfdbh is  not  null then 1 else 0 end szdbh,
case when a.SEND_CLASS_T='01' then '配送' when a.SEND_CLASS_T='02' then '直送'
when a.SEND_CLASS_T='03' then '一步越库' when a.SEND_CLASS_T='04' then '二步越库' end spsfs
,e.nrjxl*a.RETAIL_PRICE nrjxse,e.nsx nzgsl,e.nxx nzdsl,e.nrjxl,e.nzdcl,e.nzdcl_offset
,e.nZdcl_Offset_Bdate,e.nZdcl_Offset_Edate,e.ifPromotion,d.qpc ncgbzs,a.min_purchase_qty nPsbzs,a.ITEM_ETAGERE_CODE
into #Base_sp
from Dappsource_DW.dbo.P_SHOP_ITEM_OUTPUT a
join Dappsource_DW.dbo.goods d on a.ITEM_CODE=d.code
left join #zdbhfl c on a.Dept_code=c.sfdbh and d.sort=c.sflbh
left join [122.147.10.200].dappsource.dbo.sys_deliveryset e on a.DEPT_CODE=e.sfdbh and a.ITEM_CODE=e.sspbh
join DappSource_Dw.dbo.tmp_fdb  f on  a.DEPT_CODE=f.sfdbh  and 
  f.smdlx   in ('大店A','大店B','小店','中店A','中店B') and f.sJylx='连锁门店'
and f.dkyrq is not null and f.sjc not like '%取消%'
where 1=1 and a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y' and a.CHARACTER_TYPE='N' and
(( d.sort>'20' and d.sort<'40') or (
LEFT(d.sort,4) in ('1105','1307','1406') ))
and LEFT(d.sort,4)<>'2201';
 
  
--  门店在要货数据 drop table #Tmp_yh
select distinct sfdbh into #tmp_fdb from #Base_sp
with x0 as (
select a.dYhrq,b.ddhrq dShrq,a. sdjlx sLx,b.sfdbh,b.sspbh,b.nsl nYhsl,b.ndhsl,b.sBzmx
from [122.147.10.200].dappsource.dbo.tmp_yhb a 
inner join [122.147.10.200].dappsource.dbo.tmp_yhmx b
on a.sdh=b.sdh and a.sFdbh=b.sFdbh
join #Tmp_fdb c on a.sfdbh=c.sfdbh
where 1=1  and a.dYhrq>=CONVERT(date,GETDATE()-180) 
and (  a.dYhrq+2<GETDATE() or b.ddhrq is not null))
,x1 as (select a.* from  x0 a
join  #base_sp c on a.sFdbh=c.sFdbh and a.sspbh=c.sSpbh
join Dappsource_DW.dbo.vendor d on c.sGys=d.code  
where  1=1 )
select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id 
into #Tmp_yh 
from x0 a ;


-- D zixun 原表 drop table #1

select CONVERT(date,b.dctime) dYhrq,a.sdh,isnull(a.sfdbh,c.sfdbh) sfdbh,
isnull(b.sspbh,c.sspbh) sspbh,ISNULL(c.nsl,b.nsl) nCgsl,b.nsl_raw ncgsl_raw,'' genstate,''smemo
into #1 from [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT a
join [122.147.10.200].dappsource.dbo.DELIVERY_RECEIPT_items b  on a.sdh=b.sdh
left join  [122.147.10.200].dappsource.dbo.delivery_receipt_zt c on b.sdh=c.sdh and b.sspbh=c.sspbh
join #Tmp_fdb d on  isnull(a.sfdbh,c.sfdbh)=d.sfdbh
where 1=1 and CONVERT(date,b.dctime)>=CONVERT(date,GETDATE()-180) and  ISNULL(c.nsl,b.nsl)>0;
 
select a.* into #dzixun_raw  from #1 a
join #base_sp d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh
join Dappsource_DW.dbo.vendor e on d.sGys=e.code 
where 1=1 and 
((d.spsfs='配送' and dateadd(day,2,a.dYhrq)<CONVERT(date,GETDATE()))
or (d.spsfs<>'配送'  and +dateadd(day,ISNULL(e.ValidDay,5),a.dYhrq)
<CONVERT(date,GETDATE())));


-- 单据汇总
select * into #BusType from [122.147.10.200].DAppSource.dbo.BusType;

with x0 as (
select sfdbh,sspbh,dyhrq,dshrq,slx,nyhsl,ndhsl,sbzmx,id,'要货' flag,
isnull(c.sName,case when a.sbzmx like '%自动生成%' or a.sbzmx like ';;%' then '自动补货'
 end ) sSource from #tmp_yh  a
left join #BusType c on 1=1 and CHARINDEX(c.sName,a.sbzmx,0)>1 and sType='delivery' and sParentseName<>''
)
select  ISNULL(a.sFdbh,b.sFdbh) sfdbh,ISNULL(a.sspbh,b.sSpbh) sspbh,
ISNULL(a.dYhrq,b.dYhrq) dYhrq,a.dShrq, a.nYhsl,b.nCgsl nYhsl_raw,b.ncgsl_raw ncgsl_old,
a.ndhsl nShsl,b.GenState,b.sMemo,a.sLx,sbzmx sBz,a.flag,
ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
ISNULL(a.sspbh,b.sSpbh) order by isnull(a.dyhrq,b.dyhrq) desc) npm_cal,
case when a.sFdbh is null then '系统单' end is_auto,a.sSource into #TMP_dh_cal
  from x0 a full join #dzixun_raw b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)>0 and DATEDIFF(HOUR,b.dyhrq,a.dyhrq)<24 
where 1=1 ;
 

 
-- 第二部分 门店大库存
-- Step 2.1 ：大库存数据生成 进出按进出，要货按最后要货日期   drop table #mddkc

select sFlbh,sFlmc,nPlzzts into #tmp_flbb from   DappSource_Dw.dbo.Tmp_sort_standard
where drq = (select max(drq) from  DappSource_Dw.dbo.Tmp_sort_standard);


  -- Step 2.1.0 :取 日结的库存
        select c_store_id sfdbh,c_gcode sspbh,c_number nkcsl,c_A nKcje into #Tmp_mdkc_sl   from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date=trunc(sysdate-1)');

-- 2.1.1  xs
select a.SHOP_CODE sfdbh,a.ITEM_CODE sspbh,sum(a.SALE_QTY) nxssl into #Tmp_xs from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
		join #Base_sp b on a.ITEM_CODE=b.sSpbh and a.SHOP_CODE=b.sFdbh
		where    CONVERT(date,a.SALE_DATE)>=convert(date,getdate()-30)    and  CONVERT(date,a.SALE_DATE)<CONVERT(date,GETDATE())
		  group by  a.SHOP_CODE,a.ITEM_CODE;

-- drop table  #mddkc
with x0 as (
select a.*,b.nkcsl nsl, convert(numeric(12,2),case when ISNULL(d.nxssl,0)=0 
then 300 else b.nkcsl*30.0/d.nxssl end) nzzts, isnull(c.nPlzzts,55) nPlzzts, ISNULL(d.nxssl,0)/30.0 nxsrj
from #base_sp a 
left join #Tmp_mdkc_sl b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh 
left join #tmp_flbb c on LEFT(a.splbh,4)=c.sflbh 
left join #Tmp_xs d on a.sFdbh=d.sfdbh and a.sSpbh=d.sspbh
where 1=1 and ISNULL(b.nkcsl,0)>6 and ISNULL(b.nKcje,0)>50 
and  convert(numeric(10,2),case when ISNULL(d.nxssl,0)=0 
then 300 else b.nKcsl*30.0/d.nxssl end)>=isnull(c.nPlzzts,55) )
select a.sFdbh,a.sSpbh,a.sspmc ,a.sPlbh sFl,b.munit sdw,b.billto sGys,a.nJj,a.nSj
,a.szdbh,a.sPsfs,a.nxsrj nRjxl,a.nxsrj*a.nsj nrjxse,a.nsl,a.nzgsl,a.nzdcl
, a.nzzts,a.nPsbzs,a.nCgbzs,convert(date,Null) dzhyhr,convert(date,Null) dzhdhr, 
convert(varchar(20),'') syy,convert(varchar(5),'') sfwqzs,convert(varchar(20),'') sfcx,
convert(money,Null) nYhsl,convert(money,Null) nDhsl,a.nzdcl_offset,
a.nZdcl_Offset_Edate,a.nZdcl_Offset_Bdate ,CONVERT(varchar(200),'') sSource,a.nPlzzts,a.ITEM_ETAGERE_CODE into #mddkc
from x0  a 
join Dappsource_DW.dbo.goods b on   a.sspbh=b.code
where 1=1      ; 


--Step 2.2:最后一次进货
select CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #jc1
from [122.147.10.202].DAppStore.dbo.tmp_jcb a 
join [122.147.10.202].DAppStore.dbo.tmp_jcmxb b 
on  a.sjcbh=b.sjcbh and  a.sfdbh=b.sfdbh
join  #Tmp_fdb c on a.sfdbh=c.sfdbh
where 1=1  
and a.dsj>CONVERT(date,GETDATE()-180)
group by CONVERT(date,a.dsj),a.sfdbh,a.sjcfl,b.sspbh;


-- drop table #jcmx

with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,
ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and  a.nsl>=2 )
select * into #jcmx from x0  where npm<=2;
 
-- Step 2.2.0:多点陈列和配送包装数 drop table  #de_history
select sfdbh,sspbh,spsfs,nzdcl,nZdcl_offset,max(drq) drq_max,min(drq) min_drq  into #de_history
from  DappSource_Dw.dbo.sys_deliveryset
where  drq>=convert(date,getdate()-180)
group by  sfdbh,sspbh,spsfs,nzdcl,nZdcl_offset;

--  原因划分
update a set a.syy='新品'  from #mddkc a  where 1=1 
   and  convert(date,a.ITEM_ETAGERE_CODE)>CONVERT(date,GETDATE()-90) and   a.ITEM_ETAGERE_CODE is  not null;


-- Step 2.3:遗留库存
with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and a.nsl>0  )
update a set a.syy='遗留库存'   from #mddkc  a 
left join x0 b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
where 1=1  and len(a.syy)=0 and b.sFdbh is null;


-- 
with x1 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and a.nsl>0  )
,x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc  ) nyhpm
,a.nrjxl,a.nrjxse, a.nsl,d.sSource  from #mddkc a 
 join x1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 left join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh 
where  1=1   and len(a.syy)=0   and d.dShrq is not null
  and convert(date,d.dshrq)=CONVERT(date,b.dsj)  )
update a set a.syy=case when isnull(c.nZdcl_offset,0)>=4
 and   c.nZdcl_offset >=a.nsl*0.5 then   '多点陈列'  when ISNULL(c.nzdcl,0)>=4
 and   c.nZdcl >=a.nsl*0.5 then '最低陈列量' end ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl,
 a.nZdcl=c.nZdcl,a.nZdcl_offset=c.nZdcl_offset,a.sSource=b.sSource
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
   join #de_history c on a.sfdbh=c.sfdbh and a.sspbh=c.sspbh and 
   (( c.nZdcl_offset >=a.nsl*0.5 and isnull(c.nZdcl_offset,0)>=4 )
    or (ISNULL(c.nzdcl,0)>=4 and  c.nZdcl >=a.nsl*0.5  ))
  and  (CONVERT(date,b.dYhrq)>=CONVERT(date,c.min_drq)   
and CONVERT(date,b.dYhrq)<=CONVERT(date,c.drq_max) or  (CONVERT(date,b.dYhrq)<CONVERT(date,c.min_drq)))
 where  1=1     ; 


-- Step 2.7:对盘点调拨 划分：盘点，调拨量大于当前库存数量的20%
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品') 
and b.npm=1
 
where  1=1  and len(a.syy)=0 and  b.nDhsl>=a.nsl*0.2;
/*
select * from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
and  a.sspbh='23080011'  and a.sfdbh='018329';
*/
 
 
-- Step 2.8:对最后一次到货的包装数：>5 且
 update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
  from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('配送','二步越库') 
and    a.nPsbzs>=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 and b.npm=1 ;
 

update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
  from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('直送','一步越库')
and     a.nPsbzs >=a.nsl*0.6
and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 and b.npm=1  ;
       
-- Step 2.9 :最后一次要货查是谁下的单 如果系统单，
--但是到货量大 那么就是人工原因，到货量小于系统单，系统原因，其他 手工原因
--如果是在采购里面加单的话，那么就是手工加量或加单
-- 有单据 无进出,对有正常进出无单的 划为其他
with x0 as(
select a.sFdbh,a.sSpbh,isnull(d.dShrq,b.dsj) dSj,isnull(d.nShsl,b.ndhsl) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
 join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
	 and b.sjcfl   in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
left  join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
  and d.dShrq is not null  and convert(date,d.dshrq)=CONVERT(date,b.dsj)
where  1=1   and len(a.syy)=0    )
update a set a.syy= '其他'
  ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl 
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
 where  1=1 and b.dyhrq is null     ;

with x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
-- join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
where  1=1   and len(a.syy)=0 and d.dShrq is not null
  and isnull(d.nShsl,0)>=a.nsl*0.2 
  -- and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
   )
update a set a.syy=   
case  when (b.sbz like '%自动生成%' or b.sbz like ';;%') 
        and ( b.ncgsl_old is not null and b.nyhsl_raw<=b.ncgsl_old  
        and b.nYhsl<=b.nYhsl_raw )    then '系统定额过大' 
    when   (b.sbz like '%自动生成%' or b.sbz like ';;%') 
       and ( b.ncgsl_old is   null and b.nyhsl_raw IS not null 
       and b.nYhsl<=b.nYhsl_raw )    then '人工加量或加单' 
when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like '硬配%'
           then '采购硬配' 
 when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like 'APP补货%'
           then '门店下单' 
when   b.sbz   like '%自采订单%'   then '人工下单' 
when   b.sbz   like '%DM%'   then 'DM'
when   b.sbz   like '%新品%'   then '新品'
else '人工下单' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl ,a.sSource=b.sSource
  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
 ;

/*
select a.sFdbh,a.sSpbh,isnull(d.dShrq,b.dsj) dSj,isnull(d.nShsl,b.ndhsl) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  dbo.vendor c on a.sGys=c.code  
left join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
and     d.dShrq is not null  and isnull(d.nShsl,0)>=a.nsl*0.2 
 and convert(date,d.dShrq)=convert(date,b.dsj)
where  1=1  and a.sspbh='23080011'
  
*/

-- Step 2.10:往前追溯一次
update #mddkc set sfwqzs='是' where len(syy)=0;

-- 进出再生成,不设量限制 drop table #jcmx1
with x0 as (
select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
,a.nsl   from #jc1 a  
join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 and  a.nsl>0 )
select * into #jcmx1 from x0  where npm<=2;


-- Step 2.12:对盘点调拨 划分：第二次盘点，调拨量大于当前库存数量的0.1就算
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1 and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
join   #jcmx1 c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=2 and c.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品') 
where  1=1 and len(a.syy)=0 ;
-- Step 2.13:对最后一次到货的包装数：库存数量小于包装数的1.2倍，最后一次到货量等于包装数
update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
 from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
where  1=1  and len(a.syy)=0 and  a.sPsfs in ('配送','二步越库')
and    a.nPsbzs >=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5 ;

update a set a.syy='配送包装数过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl
from #mddkc a  join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
where  1=1   and len(a.syy)=0 and  a.sPsfs in ('直送','一步越库') 
and    a.nPsbzs >=a.nsl*0.6  and b.nDhsl=a.nPsbzs and a.nPsbzs>=5  ;

-- Step 2.14:要货到货匹配再查一次

with x0 as(
select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
d.ncgsl_old,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm
,a.nrjxl,a.nrjxse,a.nzdcl,a.nsl,a.nPsbzs,a.nCgbzs,d.sSource from #mddkc a 
 -- join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
left join  Dappsource_DW.dbo.vendor c on a.sGys=c.code  
 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
where  1=1   and len(a.syy)=0 and d.dShrq is not null
 -- and convert(date,d.dshrq)<=CONVERT(date,b.dsj) 
   )
update a set a.syy=   
case when (b.sbz like '%自动生成%' or b.sbz like ';;%') 
        and ( b.ncgsl_old is not null and b.nyhsl_raw<=b.ncgsl_old  
        and b.nYhsl<=b.nYhsl_raw )    then '系统定额过大' 
    when   (b.sbz like '%自动生成%' or b.sbz like ';;%') 
       and ( b.ncgsl_old is   null and b.nyhsl_raw IS not null 
       and b.nYhsl<=b.nYhsl_raw )    then '人工加量或加单' 
when   b.sbz not like '%自动生成%' and b.sbz not like ';;%' and b.sbz like '硬配%'
           then '采购硬配' 
 when   b.sbz not like '自动生成%' and b.sbz not like ';;%' and b.sbz like 'APP补货%'
           then '门店下单' 
when   b.sbz   like '%自采订单%'   then '人工下单' 
when   b.sbz   like '%DM%'   then 'DM'
when   b.sbz   like '%新品%'   then '新品'
else '人工下单' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl ,a.sSource=b.sSource
 from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1;
-- Step 2.15:   更新剩余 
update a set a.syy='其他'  from #mddkc a  where  1=1   and len(a.syy)=0 ;
-- 3 促销
select a.sFdbh,a.sspbh into #tmp_cx from [122.147.10.200].DAppSource.dbo.tmp_Promotion a 
where 1=1 and a.sZt<>'已结束'
and case when CONVERT(date,a.Bdate)>=a.Adate then CONVERT(date,a.Bdate)
else a.Adate end <GETDATE() and  case when 
CONVERT(date,a.Edate)>=a.CloseDate or a.CloseDate is null then CONVERT(date,a.Edate)
else a.CloseDate end >=GETDATE()
union
select b.sFdbh,b.sspbh
from  [122.147.10.200].DAppSource.dbo.tmp_promotionplan_items b
 where 1=1
and case when CONVERT(date,b.Bdate)>=b.DcTime then CONVERT(date,b.Bdate)
else b.DcTime end <GETDATE() and CONVERT(date,b.Bdate)>GETDATE();

update a set a.sfcx='是' from #mddkc  a
join #tmp_cx b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1;

-- drop table   #dhyq 
select distinct a.sfdbh,a.sspbh into #dhyq from #tmp_dh_cal a
join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where  a.npm_cal=1 and b.npm_cal>=2 and 
datediff(day,convert(date,a.dyhrq),convert(date,b.dshrq))>=0
and datediff(hour,b.dyhrq,a.dyhrq)>30
and a.ncgsl_old is not null 
and a.dshrq is not null 
order by a.sfdbh,a.sspbh; 

 
update a set a.syy='逾期到货' from #mddkc a
join #dhyq b on   a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where 1=1 ;

update a set a.syy='人工下单' from #mddkc a
join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
	and CONVERT(date,a.dzhyhr)=CONVERT(date,b.dyhrq)
where a.syy='系统定额过大' and
  b.sbz not like ';;%'  and b.sbz not like ';;。自动生成%' 


-- 按嘉荣标准存的表
delete from TMP_ZZ_0331 where drq=CONVERT(date,getdate());
insert into TMP_ZZ_0331(drq,sfdbh,sspbh,sspmc,sfl,sgys,njj,nsj,szdbh,spsfs,nrjxse,nrjxl,nsl,nzzts,npsbzs,ncgbzs,dzhdhr,dzhyhr,
syy,sfwqzs,nbzzzts,sfcx,nDhsl,sSource)
select CONVERT(date,GETDATE()) drq, a.sFdbh,a.sSpbh,sSpmc,sFl,sGys,nJj,nSj,sZdbh,sPsfs,nrjxse,nRjxl,nsl,nzzts,nPsbzs,
nCgbzs,dzhdhr,dzhyhr,syy,sfwqzs,a.nPlzzts nbzzzts,a.sfcx,nDhsl,a.sSource from #mddkc a
where 1=1  ; 