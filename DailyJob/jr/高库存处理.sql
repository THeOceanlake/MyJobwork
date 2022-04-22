/*
   高库存清单
   Author:Dxp


*/
-- Step 1 : Data Prepare
-- drop table #tmp_mdspzz
select * into #tmp_mdspzz from  master.dbo.TMP_ZZ_0331 where drq=CONVERT(date,GETDATE())
and syy<>'新品';

select * into #Tmp_cx from [122.147.10.200].DAppSource.dbo.tmp_Promotion 
where   edate>=GETDATE()-1 AND bdate<GETDATE()+30 AND edate>=bdate ;


select * into #Tmp_de from [122.147.10.200].DAppSource.dbo.sys_deliveryset; 

--  Step 2 :按条件筛选数据
/*
	1 常温非新品
	2 可退量大于0
	3 t_sdmdtable 表里  ( '正常品','低周转','滞销品')且nday<0.05-- 018425 use
	4  最近无促销 
  5 保留库存为  日均销量*标准天数与 下限-1+配送包装数的最大值
    日均销量为近30天实际销售平均
*/
-- drop table  #data_result
   select a.drq,a.sFdbh,a.sSpbh,a.sSpmc,a.sFl,a.sGys,a.sPsfs,a.nJj,a.nSj,a.nRjxl,a.nrjxse,a.nsl,a.nCgbzs,a.nPsbzs,a.nzzts,a.nbzzzts,
   b.STOP_INTO,b.STOP_SALE,b.DISPLAY_MODE,b.c_introduce_date,b.ITEM_ETAGERE_CODE,e.isnormal,e.scgqy,d.nsx,d.nxx
   , case  when d.nxx is null and  CEILING(a.nRjxl*a.nbzzzts)>=a.nPsbzs then  CEILING(a.nRjxl*a.nbzzzts)
		   when d.nxx is null and  CEILING(a.nRjxl*a.nbzzzts)<a.nPsbzs then a.nPsbzs
           when d.nxx is not null and  CEILING(a.nRjxl*a.nbzzzts)>=a.nPsbzs+d.nxx-1  then CEILING(a.nRjxl*a.nbzzzts)
          when  d.nxx is not null and  CEILING(a.nRjxl*a.nbzzzts)<a.nPsbzs+d.nxx-1  then a.nPsbzs+d.nxx-1 end  nbzkc
   into #data_result
    from  #tmp_mdspzz a 
   join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on a.sFdbh=b.DEPT_CODE and a.sSpbh=b.ITEM_CODE
   left join DappSource_Dw.dbo.t_sdmdtable c on a.sFdbh=c.sfdbh and a.sSpbh=c.sspbh
   left join #Tmp_de d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh
     join DappSource_Dw.dbo.goods e on a.sSpbh=e.code
   left join #Tmp_cx f on a.sFdbh=f.sfdbh and a.sSpbh=f.sspbh
   where 1=1   and ( b.ITEM_ETAGERE_CODE<CONVERT(date,GETDATE()-90) or b.ITEM_ETAGERE_CODE is null)
   and b.STOP_INTO='N' and b.STOP_SALE='N' and b.VALIDATE_FLAG='Y' and b.CHARACTER_TYPE='N' and b.c_introduce_date<GETDATE()-60
   and e.isnormal='常温商品'   and  left(e.sort,4) not in ('2106','2208','3102','3903')
    AND left(e.sort,6) not in ('210506','230402','250201','370125')
    AND e.sort not in ('23060302','33021201','33021202','33021204','33021205','33021206','33021207','33021208')
	  and f.sspbh is null 
    and a.nsl>a.nPsbzs   ;


-- Step 3 
select distinct  a.drq,a.sFdbh,b.sfdmc,a.sSpbh,a.sSpmc,a.sFl ,c.sflmc , a.sPsfs,a.nJj,a.nSj,a.c_introduce_date,a.ITEM_ETAGERE_CODE,a.isnormal,a.scgqy
,a.nCgbzs,a.nPsbzs,a.nbzzzts,a.nsl,a.nzzts,a.nRjxl,a.nrjxse,a.nsx,a.nxx,a.nbzkc,floor(a.nsl-a.nbzkc) nclkc into #r1  from   #data_result a 
left join DappSource_Dw.dbo.tmp_fdb b on a.sFdbh=b.sfdbh
left join DappSource_Dw.dbo.tmp_spflb  c on a.sFl=c.sflbh
where a.nsl>a.nbzkc and floor(a.nsl-a.nbzkc)>0 and a.nsl>10 and a.nsj*a.nsl>500  order by a.sFdbh,a.sSpbh

select a.drq,a.sFdbh,b.sfdmc,a.sSpbh,a.sSpmc,a.sFl ,c.sflmc , a.sPsfs,a.nJj,a.nSj,a.c_introduce_date,a.ITEM_ETAGERE_CODE,a.isnormal,a.scgqy
,a.nCgbzs,a.nPsbzs,a.nbzzzts,a.nsl,a.nzzts,a.nRjxl,a.nrjxse,a.nsx,a.nxx,a.nbzkc,floor(a.nsl-a.nbzkc) nclkc  from   #data_result a 
left join DappSource_Dw.dbo.tmp_fdb b on a.sFdbh=b.sfdbh
left join DappSource_Dw.dbo.tmp_spflb  c on a.sFl=c.sflbh
where a.nsl>a.nbzkc and floor(a.nsl-a.nbzkc)>0 and a.nsl>10 and a.nsj*a.nsl>500  order by a.sFdbh,a.sSpbh

-- 写入 200 不良库存商品池
insert into DAppSource.dbo.BadStock_Goods(CalDate,sFdbh,sSpbh,nKc,nRjxl,nJj,stop_into,stop_sale,nZzts,nZzbzts,nDykc,sSfkt,nSx,nZdcl,nZdcl_Offset,
sPsfs,sReason,IsProcessed,sGysbh,sGysdhr,sMdthr,nCgbzs,sGenNotice,IsProcessed_Test)


insert into  [122.147.10.200].DAppSource.dbo.BadStock_Goods(CalDate,sFdbh,sSpbh,nKc,nRjxl,nJj,stop_into,stop_sale,nZzts,nZzbzts,nDykc,sSfkt,nSx,nZdcl
,nZdcl_Offset,
sPsfs,sReason,IsProcessed,sGysbh,sGysdhr,sMdthr,nCgbzs,sGenNotice,IsProcessed_Test)
select   CONVERT(date,convert(date,GETDATE())) drq,a.sFdbh,ltrim(a.sSpbh) sSpbh,a.nsl,a.nRjxl,a.nJj,b.STOP_INTO,b.STOP_SALE,convert(int,a.nzzts),a.nbzzzts,a.nclkc,
case when b.RETURN_ATTRIBUTE='可退换' then 1 else 0 end,a.nsx,c.nzdcl,c.nZdcl_offset,a.sPsfs,'高库存',null IsProcessed,rtrim(b.SHOP_SUPPLIER_CODE),
case when d.type is null then '' else '(' + d.type + ')' + isnull(d.wwwadr,'') end,isnull(rtrim(d.shop_return_date),''),a.nCgbzs,1,null from #r1 a 
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on a.sFdbh=b.DEPT_CODE and a.sSpbh=b.ITEM_CODE
left join #Tmp_de c on a.sFdbh=c.sfdbh and a.sSpbh=c.sspbh
left join DappSource_Dw.dbo.vendor d on b.SHOP_SUPPLIER_CODE=d.code 
where 1=1  order by a.sFdbh,a.sSpbh ;