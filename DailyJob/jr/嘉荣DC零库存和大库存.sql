----  DC 报表数据源
/*
    DC 商品范围限定在T_Tihi 中，
    销售使用所有门店的30天实际销售求日均
    库存数据使用日结数据
*/
-- drop table #Base_Dcsp
select *  into #T_tihi from  [122.147.10.200].DAppSource.dbo.T_TiHi ;

select a.code sSpbh,a.name sSpmc,a.sort sFlbh,a.alc spsfs,
a.inprc njj,a.rtlprc nsj,a.qpc nCgbzs,a.alcqty nPsbzs,a.billto sGys,a.isnormal,a.scgqy
,'1' sZdbh into #Base_Dcsp  from DappSource_Dw.dbo.goods a
join #T_tihi b on a.code=b.SIZE_DESC
where a.alc='配送' and   (( a.sort>'20' and a.sort<'40') or (
 LEFT(a.sort,4) in ('1105','1307','1406') )) and LEFT(a.sort,4)<>'2201'  ;

select distinct sspbh into #Tmp_NoPlace from [122.147.10.200].DAppSource.dbo.NoPlaceOrder  
where  CONVERT(date,GETDATE())>=case when  dBeginDate>dShDate then dBeginDate
else dShDate end and CONVERT(date,GETDATE())<=
case  when dCsDate IS null then dEndDate
 when  dCsDate is not null and dEndDate>=dCsDate then dCsDate
 when dCsDate IS not null and dEndDate<dCsDate then dEndDate  end 
 and nFlag=1;
 
update a set a.szdbh='0' from #Base_Dcsp a join #Tmp_NoPlace b on a.sspbh=b.sspbh;

-- 库存
select c_store_id sfdbh,c_gcode sspbh,c_number nkcsl,c_A nkcje into #Tmp_dckc   
from openquery( [122.147.160.20],
    'select * from tbs_day_inventory where c_store_id=''015901''
    and c_day_date=trunc(sysdate-1)');

-- 销售和日均 drop table #Tmp_xs
select a.ITEM_CODE sSpbh,SUM(a.SALE_QTY) nxssl,sum(a.SALE_AMOUNT) nxsje,SUM(a.SALE_QTY)/30.0 nrjxl ,sum(SALE_COST) nxscb
into #Tmp_xs from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
join DappSource_Dw.dbo.Tmp_FDB b on a.SHOP_CODE=b.sfdbh
join #Base_Dcsp c on a.ITEM_CODE=c.sSpbh and c.spsfs='配送'
where 1=1 and b.sJylx='连锁门店' and b.dkyrq is not null and b.sjc not like '%取消%'
and convert(date,a.SALE_DATE)>=CONVERT(date,GETDATE()-30) and  convert(date,a.SALE_DATE)<CONVERT(date,GETDATE())
group by a.ITEM_CODE;

-- 进出表
select a.dsj,a.sfdbh,a.sjcfl,b.sspbh,b.nsl,b.njj,b.nsl*b.njj nje into #jcb
from [122.147.10.200].DAppSource.dbo.tmp_jcb a,
    [122.147.10.200].DAppSource.dbo.tmp_jcmxb b  where a.sjcbh=b.sjcbh 
and  a.sfdbh=b.sfdbh  and  a.dsj>CONVERT(date,GETDATE()-180)
and a.dsj<CONVERT(date,GETDATE()) and a.sjcfl<>'配送';

-- 单据表
select a.sfdbh,a.ddhrq,a.sshrq,a.sgys,b.sspbh,b.nsl,b.ndhsl,b.njj,b.sbzmx
into #tmp_cgd from [122.147.10.200].DAppSource.dbo.tmp_cgdd a
,[122.147.10.200].dappsource.dbo.tmp_cgddmx b where a.sdh=b.sdh
 and a.sfdbh='015901' and a.ddhrq>=CONVERT(date,GETDATE()-180)
 and a.ddhrq<=CONVERT(date,GETDATE() )  ;
 
 
-- D咨询原单
select b.DcTime ddhrq,a.sdh,a.sfdbh,b.sspbh,b.sgys,b.nsl_last nsl_raw,b.nsl
,a.zdlx,a.BusType into #tmp_Dzixun from [122.147.10.200].DAppSource.dbo.Purchase_Receipt a
join [122.147.10.200].DAppSource.dbo.Purchase_Receipt_Items b on a.sdh=b.sdh
where 1=1 and b.DcTime>CONVERT(date,GETDATE()-182) 
and  b.DcTime<CONVERT(date,GETDATE()) and a.slx='配送';

-- 单据汇总
	
select ISNULL(a.sfdbh,b.sfdbh) sfdbh,ISNULL(a.ddhrq,b.ddhrq) ddhrq,
a.sshrq,ISNULL(a.sspbh,b.sspbh) sspbh,ISNULL(a.sgys,b.sgys) sgys,a.nsl,a.ndhsl
 ,b.nsl_raw,b.zdlx,b.BusType,a.sbzmx,ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
	ISNULL(a.sspbh,b.sSpbh) order by isnull(a.ddhrq,b.ddhrq) desc,isnull(a.nsl,b.nsl) desc) npm_cal,
	case when a.sFdbh is null then '系统单' end is_auto
	 into #Tmp_cgdd_result  from  #tmp_cgd  a
full join #tmp_Dzixun  b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		and DATEDIFF(HOUR,b.ddhrq,a.ddhrq)>0 and DATEDIFF(HOUR,b.ddhrq,a.ddhrq)<24
where 1=1 ;


-- 一 DC零库存商品 drop  table #dclkcyy

-- 定额和日均
select a.sspbh,b.nJysx,b.njyxx,b.nYcrjxl_De ,b.nSx,b.nXx into #dcde   
    from #Base_Dcsp a
        join [122.147.10.200].dappsource.dbo.Sys_PurchaseSet b on a.sspbh=b.sSpbh
    where 1=1;

select a.sSpbh, a.sSpmc,a.sFlbh,a.njj,a.nsj,a.sgys,c.nrjxl,d.nSx,d.nXx
,a.sZdbh,a.nCgbzs,a.isnormal,a.scgqy,ISNULL(b.nkcsl,0) nkcsl,CONVERT(varchar(20),'') syy,
CONVERT(date,NULl) dzhcgrq,CONVERT(money,Null) nCgsl,CONVERT(money,Null) nDhsl
 into #dclkcyy  from #Base_Dcsp a
left join #tmp_dckc b on a.sspbh=b.sspbh
left join #Tmp_xs c on a.sspbh=c.sspbh
LEFT join #dcde d on a.sSpbh=d.sSpbh
where 1=1 and ISNULL(b.nkcsl,0)<=ISNULL(c.nrjxl,0)*3;

--Step 1.1:进出原因——最后一次扣减库存是非配送,但是日期要在有效期内
  -- drop table #tmp_jc
   with x0 as (
  select CONVERT(date,a.dsj) drq,a.sfdbh,a.sspbh,a.sjcfl,SUM(a.nsl) nsl 
    from #jcb a  group by CONVERT(date,a.dsj),a.sfdbh,a.sspbh,a.sjcfl
  )  
  select a.*,ROW_NUMBER()over(partition by a.sspbh order by a.drq desc,nsl) npm 
  into #tmp_jc from x0 a  where  1=1 and nsl<0 ;
  
  update a set a.syy=b.sJcfl from #dclkcyy a 
  join #tmp_jc b on a.sSpbh=b.sSpbh and b.npm=1   and DATEDIFF(day,b.drq,CONVERT(date,getdate()))<7
  where 1=1 and b.sjcfl  not in ('调出','调出赠品');
  
   
--Step 1.2:供应商未送货或供应商送货不足
 update a set a.syy=case when b.nDhsl is null then '供应商未送货' 
 when b.nDhsl*1.0/b.nsl<0.9 then '供应商送货不足' end,
	a.dzhcgrq=b.ddhrq,a.nCgsl=b.nsl,a.nDhsl=b.nDhsl from #dclkcyy a  
 join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm_cal=1 
 where 1=1 and b.nsl is not null and b.nsl>=ISNULL(b.nsl_raw,0) 
   and ISNULL(b.nDhsl,0)<b.nsl*0.9 and len(a.syy)=0 ;
  -- Step 7:删单或减量：系统出单，但是没有实际单或量少了
	update a set a.syy=case when b.nsl is null then '人工删单/减量' 
	 when b.nsl<b.nsl_raw*0.9 then '人工删单/减量' end,
		 a.dzhcgrq=b.ddhrq, a.nCgsl=b.nsl,a.nDhsl=b.nDhsl from #dclkcyy a  
	  join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm_cal=1 
	where 1=1 and isnull(b.nsl,0)<b.nsl_raw*0.9 and b.nsl_raw is not null 
	and len(a.syy)=0  ;

   update a set a.syy='人工订货不足', a.dzhcgrq=b.ddhrq,a.nCgsl=b.nsl,a.nDhsl=b.nDhsl 
    from #dclkcyy a  
	left join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm_cal=1  
	where   len(a.syy)=0  and a.szdbh='0' and b.ddhrq is not null 
	and b.nDhsl>=b.nsl and b.nsl is not null;

	  update a set a.syy='人工未下单', a.dzhcgrq=b.ddhrq,a.nCgsl=b.nsl,a.nDhsl=b.nDhsl 
	  from #dclkcyy a  
	 left join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm_cal=1  
	 where   len(a.syy)=0 and a.szdbh='0'  and b.nsl is  null;

	 update a set a.syy='系统定额不足', a.dzhcgrq=b.ddhrq,a.nCgsl=b.nsl,a.nDhsl=b.nDhsl
	  from #dclkcyy a  
	 left join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm_cal=1  
	 where   len(a.syy)=0 and a.szdbh='1'and b.ddhrq is not null
	   and b.nDhsl>=b.nsl and b.nsl_raw is not null;
	   
	 

	 /*DC  系统定额和出单分两块,如果是没有单据,则归属与ERP未出单*/
	 update a set a.syy='ERP未出单', a.dzhcgrq=b.ddhrq,a.nCgsl=b.nsl,a.nDhsl=b.nDhsl
	   from #dclkcyy a  
	 left join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm_cal=1  
	 where   len(a.syy)=0  and a.szdbh='1' and b.nsl is  null 
	 and b.nsl_raw is not null;
  
     update a set a.syy='其他' from #dclkcyy a   where   len(a.syy)=0 ;
     
    -- 结果存储 
    delete  DappSource_Dw.dbo.Tmp_Dclkcyy where drq= convert(date,getdate());
	insert into   DappSource_Dw.dbo.Tmp_Dclkcyy(drq,sSpbh,sSpmc,sFl,sFlmc,nJj,nSj,nZdsl,nZgsl,nRjxl,dZhyhr,nCgsl,nDhsl,syy,nkcsl)
	select convert(date,getdate()) drq, a.sSpbh,a.sSpmc,a.sFlbh,d.sFlmc,a.nJj,a.nSj,
	a.nxx,a.nsx,a.nRjxl,a.dzhcgrq,a.nCgsl,a.nDhsl,a.syy,a.nkcsl
	from #dclkcyy a 
	left join  DappSource_Dw.dbo.tmp_spflb d on a.sFlbh=d.sFlbh
	where 1=1;
	 
  -- 二、DC大库存 drop table #tmp_dcspzzyy 
  -- 食品30天，非食 45天
 
 select a.sSpbh, a.sSpmc,a.sFlbh,a.njj,a.nsj,a.sgys,d.nrjxl,e.nSx nZgsl
  ,e.nXx nZdsl,a.spsfs
,a.sZdbh,a.nCgbzs,a.isnormal,a.scgqy,ISNULL(b.nkcsl,0) nsl,convert(date,null) dYhrq ,
 convert(date,null) dDhrq,convert(money,null) nCgsl,convert(money,null) nDhsl,
 CEILING(case when isnull(d.nrjxl,0)<=0  then 300 
 when isnull(d.nrjxl,0)>0 then ISNULL(b.nkcsl,0)*1.0/ISNULL(d.nrjxl,0)  end  ) nzzts,
   convert(varchar(50),'') syy  into #tmp_dcspzzyy 
from #Base_Dcsp a
left join #tmp_dckc b on a.sspbh=b.sspbh
left join #Tmp_xs d on a.sSpbh=d.sSpbh
left join DappSource_Dw.dbo.goods c on a.sSpbh=c.code
left join #dcde e on a.sSpbh=e.sSpbh
where 1=1 and a.scgqy<>'生鲜部' and ISNULL(b.nkcsl,0)>10 and  CEILING(case when isnull(d.nrjxl,0)<=0  then 300 
 when isnull(d.nrjxl,0)>0 then ISNULL(b.nkcsl,0)*1.0/ISNULL(d.nrjxl,0)  end)>=case when a.scgqy='非食品部' then 45 else 30 end  ; 


 
 -- 2.1 DC进出
    with x0 as (
  select CONVERT(date,a.dsj) drq,a.sfdbh,a.sspbh,a.sjcfl,SUM(a.nsl) nsl 
    from #jcb a  group by CONVERT(date,a.dsj),a.sfdbh,a.sspbh,a.sjcfl
  )  
  select a.*,ROW_NUMBER()over(partition by a.sspbh order by a.drq desc,nsl desc) npm 
  into #tmp_jc1 from x0 a  where  1=1 and nsl>0 ;
  
-- 2.2 遗留库存
 update a set a.syy='遗留库存' from #tmp_dcspzzyy a 
	join #tmp_jc1 b on a.sSpbh=b.sSpbh  where b.drq is null;
-- 2.3 进出类型
  update a set a.syy= b.sJcfl   
   ,a.dDhrq=b.drq,a.nDhsl=b.nSl
  from #tmp_dcspzzyy a join  #tmp_jc1 b on a.sSpbh=b.sSpbh  
   where b.sjcfl not in ('入库','入库赠品')  and abs(b.nSl)>=a.nsl*0.2 
   and b.npm=1 ;
-- 2.4 商品匹配采购单，验收类型
   with x0 as (
   select a.*,ROW_NUMBER()over(partition by a.sspbh order by a.ddhrq desc,a.nsl desc) ncgpm
   from #Tmp_cgdd_result a where nDhsl>0 )
   update a set a.syy=case 
   when b.sspbh is null then '遗留库存'
   when a.nsl>=a.nCgbzs*0.5 and b.nDhsl=a.nCgbzs then '采购包装数过大'
   when b.nsl_raw is null then '人工下单' 
   when b.nsl_raw is not null and b.nsl>b.nsl_raw  then '人工加量或加单'
   when b.nsl_raw is not null and b.nsl<=b.nsl_raw and b.sbzmx like '%自动生成%'
   then '系统定额过大'
   when b.nsl_raw is not null and b.nsl<=b.nsl_raw and b.sbzmx like '%自采订单%'
   then '自采' end,a.dYhrq=b.ddhrq,a.dDhrq=b.sshrq,a.nCgsl=b.nsl,
		 a.nDhsl=b.nDhsl from #tmp_dcspzzyy a 
   left join x0 b on a.sSpbh=b.sspbh and b.ncgpm=1
   where 1=1  and len(syy)=0;
   
   -- 逾期到货  drop table #dhyq_dc
select a.sfdbh,a.sspbh into #dhyq_dc from #Tmp_cgdd_result  a
join #Tmp_cgdd_result  b on a.sspbh=b.sspbh
where  a.npm_cal=1 and b.npm_cal=2 and 
datediff(hour,a.ddhrq,b.sshrq)>1
and datediff(hour,b.ddhrq,a.ddhrq)>30
and a.nsl is not null  and a.sshrq is not null 
order by   a.sspbh;

update a set a.syy='逾期到货' from #tmp_dcspzzyy  a
join #dhyq_dc b on    a.sspbh=b.sspbh
where 1=1 ;
   
    update a set a.syy= b.sJcfl   
   ,a.dDhrq=b.drq,a.nDhsl=b.nSl
  from #tmp_dcspzzyy a join  #tmp_jc1 b on a.sSpbh=b.sSpbh  
   where b.sjcfl not in ('入库','入库赠品')  and abs(b.nSl*1.0/a.nsl)>=0.4 
   and b.npm=2 ;
   
   update  #tmp_dcspzzyy set syy='其他' where len(syy)=0 or  syy is null;

  delete DappSource_Dw.dbo.Tmp_dczzyy where  drq=CONVERT(date,GETDATE());
  insert into DappSource_Dw.dbo.Tmp_dczzyy(drq,sSpbh,sSpmc,sFl,sGys,nZdsl,nZgsl,nCgbzs,sPsfs,sZdbh,nkcsl,dYhrq,dDhrq,nCgsl,nDhsl,nzzts,syy,nrjxl)
  select CONVERT(date,getdate()),a.sSpbh,a.sSpmc,a.sFlbh,a.sGys,a.nZdsl,a.nZgsl,a.nCgbzs,a.sPsfs,a.sZdbh,a.nSl,a.dYhrq,a.dDhrq,a.nCgsl,
  a.nDhsl,a.nzzts,a.syy,a.nrjxl from #tmp_dcspzzyy a;



 -- 零库存页面
 select  #result

SELECT convert(varchar,drq) 日期 ,
  max( case when syy='物流中心无货未送	' then nzb else 0 end) as '物流中心无货未送	',
	max( case when syy='越库供应商未送货' then nzb else 0 end) as '越库供应商未送货',
	max( case when syy='人工未下单' then nzb else 0 end) as '人工未下单',
	max( case when syy='暂不补货' then nzb else 0 end) as '暂不补货',
	max( case when syy='直送供应商未送货' then nzb else 0 end) as '直送供应商未送货',
	max( case when syy='新品' then nzb else 0 end) as '新品',
	max( case when syy='物流中心有货未送' then nzb else 0 end) as '物流中心有货未送',
	max( case when syy='系统定额不足' then nzb else 0 end) as '系统定额不足',
	max( case when syy='未达起订量' then nzb else 0 end) as '未达起订量',
	max( case when syy='退配' then nzb else 0 end) as '退配',
	max( case when syy='调出' then nzb else 0 end) as '调出',
  max( case when syy='DC无库位' then nzb else 0 end) as 'DC无库位',
  max( case when syy='突发销售' then nzb else 0 end) as '突发销售',
  max( case when syy='人工订货不足' then nzb else 0 end) as '人工订货不足',
  max( case when syy='人工减量或删单' then nzb else 0 end) as '人工减量或删单',
  max( case when syy='损溢' then nzb else 0 end) as '损溢',
  max( case when syy='越库供应商送货不足' then nzb else 0 end) as '越库供应商送货不足',
  sum(商品数或金额) 总数
	FROM #result 
	group by  drq
	order by drq 

   
	 
  select '','全部' union
select syy,syy from TMP_MDLKCYY_QUERY_SYY#IP# 
where syy in (物流中心无货未送	,越库供应商未送货	,暂不补货	,新品,直送供应商未送货,人工未下单	,物流中心有货未送,DC无库位,未达起订量,
系统定额不足,退配	,突发销售,其他,人工订货不足,人工减量或删单,调出,损溢,越库供应商送货不足)
物流中心无货未送	,越库供应商未送货	,暂不补货	,新品,直送供应商未送货,人工未下单	,物流中心有货未送,DC无库位,未达起订量,
系统定额不足,退配	,突发销售,其他,人工订货不足,人工减量或删单,调出,损溢,越库供应商送货不足

		  
