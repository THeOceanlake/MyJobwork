-- 定额变化
select  a.Drq,sum(a.nXx),sum(a.nSx),sum(a.nZdcl),sum(a.nXx*b.SHIFT_PRICE) nxxje  from DappSource_Dw.dbo.SYS_DELIVERYSET a
join DappSource_Dw.dbo.goods c on a.sSpbh=c.code 
join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on a.sFdbh=b.DEPT_CODE and a.sSpbh=b.ITEM_CODE
where 1=1 and   (( c.sort>'20' and c.sort<'40') or (
LEFT(c.sort,4) in ('1105','1307','1309','1406') ))
and LEFT(c.sort,4)<>'2201' and a.sFdbh in   ('012006','012007','018329','018389')
and a.Drq>CONVERT(date,'2022-04-15')
group by a.Drq  order by a.Drq

-- 库存变化
select a.drq,sum(a.nkcje) nkcje  from  DappSource_Dw.dbo.tmp_kclsb a 
join DappSource_Dw.dbo.goods c on a.sSpbh=c.code 
join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on a.sFdbh=b.DEPT_CODE and a.sSpbh=b.ITEM_CODE
where 1=1 and   (( c.sort>'20' and c.sort<'40') or (
LEFT(c.sort,4) in ('1105','1307','1309','1406') ))
and LEFT(c.sort,4)<>'2201' and a.sFdbh in   ('012006','012007','018329','018389')
and a.Drq>CONVERT(date,'2022-04-15') group by a.drq  order by 1 ;

-- 90 天评估
/*
  1 目前处理进度
  2 2个阶段的销售表现
  3 定价过低
*/


-- 周转趋势-如果没有大变化则不贴

select a.drq,sum(a.nkc*a.njj) from DappSource_Dw.dbo.tmp_mdspzzyy a 
-- join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on a.sfdbh=b.DEPT_CODE and a.sspbh=b.ITEM_CODE
where a.drq>=CONVERT(date,'2022-04-10') 
and a.sfdbh in ('012006','012007','018329','018389')
group by a.drq  order by 1 

-- 超出标准库存
-- 周转过大 超出库存金额

--Step 0 :-- 商品范围

select a.DEPT_CODE sFdbh,a.ITEM_CODE sSpbh,b.sspmc,b.sPlbh,a.SHOP_SUPPLIER_CODE sgys,
a.SHIFT_PRICE njj,a.RETAIL_PRICE nsj, a.Stop_into,
case when a.SEND_CLASS_T='01' then '配送' when a.SEND_CLASS_T='02' then '直送'
when a.SEND_CLASS_T='03' then '一步越库' when a.SEND_CLASS_T='04' then '二步越库' end spsfs
,e.nrjxl*a.RETAIL_PRICE nrjxse,e.nsx nzgsl,e.nxx nzdsl,e.nrjxl,e.nzdcl,e.nzdcl_offset
,e.nZdcl_Offset_Bdate,e.nZdcl_Offset_Edate,e.ifPromotion,d.qpc ncgbzs,a.min_purchase_qty nPsbzs
into #Base_sp
from [122.147.160.32].DApplicationBI.dbo.P_SHOP_ITEM_OUTPUT a
join [122.147.10.202].dappresult.dbo.R_dpzb b 
on a.DEPT_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
join [122.147.160.32].DApplicationBI.dbo.goods d on a.ITEM_CODE=d.code
left join [122.147.10.200].dappsource.dbo.sys_deliveryset e on a.DEPT_CODE=e.sfdbh and a.ITEM_CODE=e.sspbh
where 1=1 and   a.DEPT_CODE in ('018329','012006','012007','018389','018418','018336','018425')
 and a.character_type='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y'
and b.enddate>GETDATE()-13 and
(( d.sort>'20' and d.sort<'40') or (
LEFT(d.sort,4) in ('1105','1307','1309','1406') ))
and LEFT(d.sort,4)<>'2201';



-- Step 2 kucu
select * into #tmp_kc from  [122.147.160.32].DApplicationBI.dbo.V_D_PRICE_AND_STOCK b
where  STORE_CODE in ('018329','012006','012007','018389','018418','018336','018425')

-- 总库存金额
select a.*,ISNULL(b.CURR_STOCK,0) nkcsl into #zkc from #Base_sp a 
left join #tmp_kc b on a.sfdbh=b.STORE_CODE and a.sspbh=b.item_code

-- 大库存

select *,nkc*njj nkcje,nkc*njj-njj*case when nbzzzts*nrjxl>5 then nbzzzts*nrjxl
else 5 end nccje ,case when nbzzzts*nrjxl>5 then  nbzzzts*nrjxl
else  5 end nblkc into #2 from  dappsource_DW.dbo.Tmp_mdspzzyy 
where drq=convert(date,getdate())  
and sfdbh in ('018329','012006','012007','018389','018425')

with x0 as (
select sfdbh,count(1) nsps,sum(isnull(nkcsl*njj,0)) nzkcje,
sum(case when  stop_into<>'N' then isnull(nkcsl*njj,0) else 0 end  ) ntgkc from #zkc 
where sfdbh in ('018329','012006','012007','018389','018425') group by sfdbh)
,x1 as (select sfdbh,count(1) nsps,sum(nkcje) ndkje,sum(nccje)nccje  from #2 group by sfdbh)
select a.sfdbh,c.sfdmc,a.nsps,b.nsps,a.nzkcje,a.ntgkc,b.ndkje,b.nccje from x0 a 
left join x1 b on a.sfdbh=b.sfdbh
left join [122.147.160.32].DApplicationBI.dbo.Tmp_fdb c on a.sfdbh=c.sfdbh
order by 1;


------- 系统干预情况
-- 1 按进度执行情况
-- 5月份 目前是5折，6月份 目前是7折以上

select a.sMonth,case  when b.sFdbh is not null and  b.nxsje*1.0/b.nyqxse>=0.45 then 'y' 
when  b.sFdbh is not null and  b.nxsje*1.0/b.nyqxse<0.45  then   'N' 
when b.sFdbh is null  then 'bdx'  end ,
COUNT(1),sum(case when ISNULL(a.nKcsl,0)<=0 then 1 else 0 end ) nqtsl,
sum(case when  ISNULL(a.nKcsl,0)>0 then 1 else 0 end) nwwcsl,sum(b.nxsje) ,sum(b.nyqxse),sum(b.nxscb)
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