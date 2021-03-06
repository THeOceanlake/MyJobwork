/*
 31 库执行
按日结销量和进价设置最低陈列，销量很大的陈列按货架数，中等的如果陈列数过大则 减陈列量，高价格的减陈列

-- 修改版
1、进价大于70元以上的 只给面位数 
2、进价低于70元的，且日均大于等于0.05 单品，给面位*层数*深度，深度超过2 的只给2，
 
3、进价低于70元的，且日均大于等于0且小于0.05的单品，给面位*层数
4、散货，单位是KG的，取 货架最低陈列值

*/
--Step 0 :Data Prepare

select a.sFdbh,a.sHjbh,c.sHjmc,b.sSpbh,b.nM,b.nC,b.nS,b.nMinS into #1 from [122.147.10.202].DAppResult.dbo.ShelfCollection_Zd  a
left join [122.147.10.202].DAppResult.dbo.ShelfCollection_Mx b on a.sFdbh=b.sFdbh and a.sHjbh=b.sHjbh
left join [122.147.10.202].DAppResult.dbo.Shelf_Info c on a.sFdbh=c.sFdbh and a.sHjbh=c.sHjbh
where 1=1 and a.sFdbh in ('012006','012007','018329','018389') ;

-- Step 1:De
select * into #2  from [122.147.10.200].dappsource.dbo.sys_deliveryset where sFdbh in ('012006','012007','018329','018389') ;

-- Stwp 2 :contract drop table #5
select a.sFdbh,a.sHjbh,a.sHjmc,a.sSpbh,a.nM,a.nC,a.nS,isnull(a.nM*a.nC*a.nMinS,0) nhjzdcl,
isnull(a.nM*a.nC*a.nS,0) nmhjs,
b.spsfs,b.FlagLevel,b.nRjxl,b.nSx,b.nXx,b.nKzts,b.nYlxs,b.zcts,a.nMinS,
case when isnull(b.nZdcl,0)>=isnull(b.nZdcl_Offset,0) then ISNULL(b.nZdcl,0) else ISNULL(b.nZdcl_Offset,0) end nzdcl_cal
,b.nMws,b.nPls,4 nzdcl_raw into #5 from  #1 a 
left join #2  b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where 1=1;

-- Step 3:mdsp
 
 select * into #t_sdmdtable
 from [122.147.10.200].Dappsource.dbo.t_sdmdtable where sfdbh in  ('018320','012006','012007','018389','018329');


 -- 自动补货商品明细
select a.sfdbh,b.sflbh into #zdbhfl
from [122.147.10.200].dappsource.dbo.sys_deliverysort a,
[122.147.10.200].dappsource.dbo.tmp_spflb b where  b.sflbh like a.sflbh+'%' and LEN(b.sflbh)=8
or b.sflbh in ('1309','2103','2104');

--

-- drop table #6
select a.sFdbh,b.sFDMC,a.sHjbh,a.sHjmc,a.sSpbh,c.name sspmc,c.sort,d.shift_price njj,d.retail_price nsj,a.spsfs,
  case h.slx when '畅销品'then 'A' when '快销品' then 'B' 
  when '正常品' then 'C' when '低周转' then 'D' when '滞销品' then 'E' end FlagLevel,c.isnormal,c.alcqty,
d.min_purchase_qty,a.nM,a.nC,a.nS,a.nMinS,a.nhjzdcl,a.nmhjs,
d.SHOP_SUPPLIER_CODE sgys,f.name sgysmc,case when a.spsfs = '配送' then 2 else   f.days end days,f.ValidDay ,case when c.isnormal='冷藏商品' then  CONVERT(money,'') else  a.nRjxl end nRjxsl,a.nSx,a.nXx,a.nzdcl_cal
,a.nMws,a.nPls,a.nzdcl_raw,case when e.sFdbh is not null  then '1' else '0' end  szdbh,c.munit sdw
,g.CURR_STOCK ndqkc,h.slx
into #6  from #5 a 
left join DappSource_Dw.dbo.Tmp_FDB b on a.sFdbh=b.sFDBH
left join DappSource_Dw.dbo.goods c on a.sSpbh=c.code
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT d on a.sFdbh=d.dept_code and a.sSpbh=d.item_code
left join #zdbhfl e on a.sFdbh=e.sFdbh and c.sort=e.sflbh
left join DappSource_Dw.dbo.vendor f on d.SHOP_SUPPLIER_CODE=f.code
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK g on a.sFdbh=g.STORE_CODE and a.sspbh=g.ITEM_CODE 
left join #t_sdmdtable h on a.sFdbh=h.sfdbh and a.sspbh=h.sspbh
where 1=1 and a.sSpbh is not null order by a.sFdbh,c.sort,a.sSpbh ;
 

update a  set  a.szdbh='0' from #6  a,[122.147.10.200].DAppSource.dbo.Sys_DeliveryGysEx b 
where a.sgys=b.sgys ;

update a  set  a.szdbh='0' from #6 a,[122.147.10.200].DAppSource.dbo.Sys_DeliverySortEx b
where a.sort like b.sflbh+'%' and a.sfdbh=b.sfdbh ;


update a  set  a.szdbh='0' from #6  a,[122.147.10.200].DAppSource.dbo.Sys_DeliverySpEx b
where a.sspbh=b.sspbh and b.begindate<GETDATE() and b.enddate>GETDATE()  and nFlag=1;


/*
    需要注意的点
    1、部分商品的面位数或者层数设置很不合理，解决方案两种：修改货架，给最低陈列限定一个大值
*/
-- drop table #7  0425 修改
select a.sFdbh,a.sFDMC,a.sSpbh,a.sspmc,a.njj,a.sdw,a.sort,a.spsfs,a.FlagLevel,a.isnormal,a.alcqty,a.min_purchase_qty,
sum(a.nM) nm ,max(a.nC) nc,max(a.nS) ns,max(a.nMinS) nmins,sum(a.nm*a.nc) nhjdw,
sum(nhjzdcl) nhjzdcl,sum(a.nmhjs) nmhjs,a.sgys,a.sgysmc,a.days,a.ValidDay,a.nRjxsl,a.nSx,a.nXx,
case when a.nzdcl_cal>0 then a.nzdcl_cal else 4 end nzdcl_cal,a.nMws,a.nPls,
case when a.szdbh='1' then '自动补货' else '非自动补货' end szdbh,a.ndqkc,a.sLx,
sum(case 
    when upper(a.sdw)='KG' then  a.nhjzdcl 
    when a.njj>=70 and   upper(isnull(a.sdw,''))<>'KG'  then  a.nm    
	 when a.njj<70  and upper(isnull(a.sdw,''))<>'KG' and  a.nRjxsl>=0.05 
        then ceiling(a.nm*a.nc*case when a.nMinS<=2 then a.nMinS else 2  end) 
	 when a.njj<70  and upper(isnull(a.sdw,''))<>'KG' and  a.nRjxsl>=0 and a.nRjxsl<0.05 then  a.nm*a.nc
end) nt1
 into #7 from #6 a  where 1=1 and a.spsfs is not null 
group by 
 a.sFdbh,a.sFDMC,a.sSpbh,a.sspmc,a.sort,a.spsfs,a.FlagLevel,a.isnormal,a.alcqty,a.min_purchase_qty,
 a.sgys,a.sgysmc,a.days,a.ValidDay,a.nRjxsl,a.nSx,a.nXx,
case when a.nzdcl_cal>0 then a.nzdcl_cal else 4 end  ,a.nMws,a.nPls,a.szdbh,a.njj,a.sdw,a.ndqkc,a.slx
order by  sfdbh,sort,sSpbh;

  select  a.sfdbh,a.sfdmc,a.sspbh,a.sSpmc,a.njj,a.szdbh,a.sdw,a.sort,a.spsfs,a.isnormal,a.FlagLevel,a.MIN_PURCHASE_QTY,
a.alcqty,a.nc,a.ns,a.nmins,a.nmhjs,a.nRjxsl,
a.nm,floor(case when nm=0 then 0 else nt1*1.0/nm end) npls,floor(case when nm=0 then 0 else nt1*1.0/nm end)*nm nres
  from #7  order by sfdbh,sspbh

