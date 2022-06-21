/*万佳利常用语句*/
 Use DAppSource_WJL;
  -- Step 1 :商品资料
    select * from  DAppSource_WJL.dbo.tmp_spb  
   where  sSpbh='6971092445724' and sFdbh='002' and 1=1

   -- 单品指标上下限和库存对比
   select a.sFdbh,a.sSpbh,a.sSpmc,a.sPlbh,a.nJhj,a.nLsj,a.sDw,a.nRjxl,a.nRjxl_De
   ,b.nPms,a.nJyxx,a.nJysx,c.nSl,a.nZdsl,a.nZgsl,a.sZdbh,abs(a.nJyxx-c.nSl) from  DAppSource_WJL.dbo.R_Dpzb a 
   join DAppSource_WJL.dbo.tmp_spb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
   join DAppSource_WJL.dbo.Tmp_Kclsb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and CONVERT(date,c.dRq)=CONVERT(date,GETDATE()-1)
   where 1=1 and a.sFdbh='012' and a.sZdbh=1 and a.nJyxx>c.nSl
   order by abs(a.nJyxx-c.nSl) desc

    
   --update a set a.nzdsl=b.njyxx,a.nzgsl=b.njysx from  DAppSource_WJL.dbo.Tmp_spb a,
   --DAppSource_WJL.dbo.R_Dpzb b 
   --where 1=1 and  a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and a.sFdbh='012'


   -- Step 1: 青云配送单
   select * from DAppSource_WJL.dbo.Purchase_DeliveryReceipt a,
	DAppSource_WJL.dbo.Purchase_DeliveryReceipt_Items b
	where a.sDh=b.sDh  and a.dDhrq='2021-06-02'
	and a.sMemo='自动订单(配送)' and b.sSpbh='6902088312812' 
	--and a.sFdbh='012'

  --Step 2: 天牧 POS实际配送单 nsqsl 申请数量，就是要货量，npssl,就是最终审核后的收货量
	select   * from wjlck.pos_2008.pos_2008.t_sppsd  a,
	 wjlck.pos_2008.pos_2008.t_psdmx  b
	where a.sPsdbh=b.sPsdbh    
	 and  b.sspbh like '%6902083880781' and a.spsdbh>'20210820'  and srkfd='010'

	  -- 验收单
   select  *
    from Wjlck.pos_2008.Pos_2008.t_spysd a, Wjlck.pos_2008.Pos_2008.t_ysdmx b
    where a.sysdbh>='20210628'  
	 and a.sysdbh=b.sysdbh  and  (a.ssFcd is null or a.sSfcd='补')
	and b.sspbh='6902088605259'

  --Step 3:天牧POS实际要货单 
    SELECT a.sYhjhbh,a.sZy,a.sfdbh,a.dYhrq,b.sspbh,b.nYhsl,b.nYpsl,b.nYcgsl  
    FROM   Wjl.pos_2008.Pos_2008.T_mdyhjh a,
	Wjl.pos_2008.Pos_2008.[T_yhjhmx]  b where a.sYhjhbh=b.sYhjhbh
	and a.dYhrq>'2021-06-02' and b.sspbh like '%6926756560091'
     
-- 订货金额的量
select convert(date,a.dDhrq) drq,sum(b.njhsl*c.nJj) nje,count(distinct b.sspbh) npzs  from wjl.pos_2008.pos_2008.t_cgdd a
,wjl.pos_2008.pos_2008.t_cgddmx b ,DAppSource_WJL.dbo.Tmp_spb_All c
where a.scgddbh=b.scgddbh  and a.dDhrq>='2021-05-20'
and b.sspbh=c.sSpbh and LEFT(c.sFl,4) in ('0101','0102','0103','0201','0202','0203','0205','0301','0302','0304','0305','0401','0402',
 '0403','0406','0501','0502','0504','0604','0605','0701','0702','0706','0707','0708','0709',
 '0710','0711','0712','0713','0714','0802','0804','0805','0806','0807','0808','0809',
 '0810','0901','0902','0903','0904','0905','1001','1002','1003','1004','1005','1006',
 '1007','1101','1102','1103','1104','1201','1202','1203','1204','1205','1206','1207',
 '1208','1209','1210','1211','1301','1302','1303','1304','1305','3401','3402','3403',
 '3601','3801','3802','3901','4101','4102','4103') group by convert(date,a.dDhrq) order by 1

 select  CONVERT(date,a.dDhrq) drq,sum(b.nsl*c.nJj) njjje  from DAppSource_WJL.dbo.Purchase_DeliveryReceipt a ,
DAppSource_WJL.dbo.Purchase_DeliveryReceipt_Items b,DAppSource_WJL.dbo.Tmp_spb_All c
where a.sDh=b.sDh   and a.dDhrq>'2021-05-20'
and a.sMemo not in ('自动订单(配送)','紧急订单(越库)','紧急订单(直送)')
and b.sSpbh=c.sSpbh
group by CONVERT(date,a.dDhrq)  order by 1;

-- DC应该采购未出单商品
  select * into #dccg from dbo.Purchase_Receipt_Items a where a.sDh>CONVERT(varchar,GETDATE(),112);

select a.sSpbh,b.sSpmc,b.sFl,a.sGys,e.sGysmc,c.nSl,CEILING(ISNULL(a.nrjxl_De,a.nrjxl)*a.nZdkcts_jy) nxx,
CEILING(ISNULL(a.nrjxl_De,a.nrjxl)*a.nZgkcts_jy) nsx,e.sDays,e.nZddhsl,e.nZddhje  from DAppSource_WJL.dbo.Purchase_Spb a 
left join DAppSource_WJL.dbo.Tmp_spb_All b on a.sspbh=b.sSpbh
left join DAppSource_WJL.dbo.Tmp_dckcb c on a.sspbh=c.sSpbh and c.sRq='20210608' 
left join DAppSource_WJL.dbo.Tmp_Gys e on a.sGys=e.sGysbh and e.sFDBH='0000'
left join (select   sspbh,sum(nztsl) nsl from [wjlck].pos_2008.pos_2008.v_dc_ztdd
 where  sfdbh='088'   group by  sspbh having sum(nztsl)>0 ) f on a.sspbh=f.sspbh
 left join #dccg  g on a.sspbh=g.sspbh 
where   CEILING(ISNULL(a.nrjxl_De,a.nrjxl)*a.nZdkcts_jy)>=isnull(c.nSl,0)
and CEILING(ISNULL(a.nrjxl_De,a.nrjxl)*a.nZdkcts_jy)>0
and substring(e.sDays,3,1)='1' and f.sspbh is null and g.sspbh is null 

select * from dbo.Purchase_DeliveryReceipt_Items_History 
where sspbh='6903148048962'



-- 未达起订量
select  a.srq,a.sspbh,a.ncgsl*a.njj,a.nzddhje from DAppSource_WJL.dbo.Purchase_Receipt_Items_History  a
where sSpbh in ('6906303004254','6906303003912','6906303001857','6906303001482')
and a.srq>'2021-06-02'

select  a.srq,a.sspbh,a.ncgsl*a.njj,a.nzddhje from DAppSource_WJL.dbo.Purchase_DeliveryReceipt_Items_History  a
where sSpbh in ('6906303004254','6906303003912','6906303001857','6906303001482')
and a.srq>'2021-06-02'

--  代表、调价 没有实际进出
select distinct a.sJcfl from DAppSource_WJL.dbo.Tmp_Jcb a ,
DAppSource_WJL.dbo.Tmp_Jcmxb b
where a.sJcbh=b.sJcbh ;

-- 青云的直采单
select * from DAppSource_WJL.dbo.Purchase_DeliveryReceipt a ,DAppSource_WJL.dbo.Purchase_DeliveryReceipt_Items 
b  , dbo.tmp_spb c where a.sDh=b.sDh and   a.sFdbh=c.sFdbh and b.sSpbh=c.sSpbh 
and b.sSpbh='1477771'
and c.sGys='001196' and a.sDh>'20210607';

select * from  DAppSource_WJL.dbo.Purchase_DeliveryReceipt_Items_History 
b  , dbo.tmp_spb c where b.sFdbh=c.sFdbh and b.sSpbh=c.sSpbh 
and b.sSpbh='1477771'
and c.sGys='001196' and b.sbh>'20210607'

-- 青云的DC采购单
select * from DAppSource_WJL.dbo.Purchase_Receipt a ,DAppSource_WJL.dbo.Purchase_Receipt_Items 
b where a.sDh=b.sDh and b.sspbh='1477771'

-- Step 10 :供应商多次要货不到

-- 11 实际采购单
select  *  from Wjlck.pos_2008.Pos_2008.t_cgdd a,
   Wjlck.pos_2008.Pos_2008.t_cgddmx b , 
   dbo.Tmp_spb_All c  where a.scgddbh=b.scgddbh
   and  a.scgddbh>'20210601'
   and b.sspbh=c.sspbh  
   --and c.sGys='001284'
   and c.sSpbh='6926756560091'
 
 -- 
 select * from Wjl.pos_2008.Pos_2008.t_spzttzd a,
 Wjl.pos_2008.Pos_2008.t_zttzdmx  b
 where b.sSpbh='6971835750382' and a.sZttzdbh=b.sZttzdbh;
 
 -- 商品定位表
 select *  from wjl.pos_2008.pos_2008.t_spdwb
 where sfdbh='001' and sspbh='026102983867'

 --  DC日均
 select * from dbo.Purchase_Spb  where sSpbh in ('2795984','2795991');

 -- 库存
 -- 门店库存
 select * from dbo.Tmp_Kclsb  where  sSpbh='6925909980526'
 and drq='2021-06-06 23:59:59.000'
 -- DC库存
 select * from dbo.Tmp_dckcb  where  sSpbh='6934268800123' and srq='20210606'

 --
 select sum(npssl)*1.0/30 from wjl.pos_2008.pos_2008.t_psdmx 
 where sspbh='2795984' and spsdbh>'20210501'

 select * from dbo.Tmp_Gys where sGysbh='001196'

 --  停购商品DC出单
 select * from dbo.Purchase_Receipt_Items a ,
 dbo.Tmp_spb_dc b where a.sSpbh=b.sSpbh and b.sSfkj=0 and a.sDh>'20210605'
 and 1=1 ;

 --  门店未出单
 drop table #mddd;
 select a.sFdbh,a.sSpbh,a.sGys,a.nsl,a.nKc,a.spsfs into #mddd from dbo.Purchase_DeliveryReceipt_Items a  where a.sDh>CONVERT(varchar,GETDATE(),112);
  select * into #kc from wjl.pos_2008.pos_2008.t_kc  where 1=1;

 select a.sFdbh,a.sSpbh,a.sSpmc,a.nRjxl,a.nRjxl_De,a.nZxcl,a.nJyxx,b.nSl,a.sSfkj,a.sZdbh,c.sPsfs,d.nsl,d.dupdateDate
 ,c.nzdcl,c.sSfks,f.sDays  from dbo.R_Dpzb a 
  left join dbo.Tmp_Kclsb b  on  a.sSpbh=b.sspbh and a.sFdbh=b.sfdbh and b.dRq=CONVERT(varchar,GETDATE()-1,23)+' 23:59:59.000'
 join dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
 left join DAppSource_WJL.dbo.tmp_Cgzt_Md d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh and d.drq>getdate()-6
 left join #mddd e on a.sFdbh=e.sFdbh and a.sSpbh=e.sSpbh
 left join dbo.Tmp_Gys f on c.sGys=f.sGysbh  and c.sFdbh=f.sFdbh 
 --left join #kc g on a.sFdbh=g.sfdbh and a.sSpbh=g.sspbh
 where  b.nSl<a.nJyxx and c.ssfkj=1 and c.sZdbh=1   and isnull(e.nsl,0)=0 and d.nSl is null
 and  LEFT(c.sFl,4) in ('0101','0102','0103','0201','0202','0203','0205','0301','0302','0304','0305','0401','0402',
 '0403','0406','0501','0502','0504','0604','0605','0701','0702','0706','0707','0708','0709',
 '0710','0711','0712','0713','0714','0802','0804','0805','0806','0807','0808','0809',
 '0810','0901','0902','0903','0904','0905','1001','1002','1003','1004','1005','1006',
 '1007','1101','1102','1103','1104','1201','1202','1203','1204','1205','1206','1207',
 '1208','1209','1210','1211','1301','1302','1303','1304','1305','3401','3402','3403',
 '3601','3801','3802','3901','4101','4102','4103') 
 and (c.sPsfs='配送' or (c.sPsfs<>'配送' and  substring(f.sDays,5,1)='1'));
 -- and c.sPsfs<>'配送' and  substring(f.sDays,2,1)='1';

 select * from dbo.Purchase_DeliveryReceipt_Items_History where sSpbh='6902422011500'

 select * from DAppSource_WJL.dbo.tmp_Cgzt_Md  where 
 select CONVERT(varchar,GETDATE()-1,23)+' 23:59:59.000'
 -- 历史单品指标
 select * from dbo.H_Dpzb
 where right(TaskID,8)='20210528' and sFdbh='002' and sSpbh='6931273213023'

 -- 供应商未出单情况
 select * from dbo.R_Dpzb a
 ,  Tmp_Gys b,tmp_spb c    where 
a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.sGys='001284' and b.sFDBH=c.sFdbh and b.sGysbh=c.sGys


-- 配送包装数差异查询
 select  a.sPsdbh,a.sZy,a.sCkfd,a.sRkfd,a.dPssj,a.dShsj,b.sspbh,b.nPssl nDhsl,b.nSqsl nYhsl
   into #tmp_psd
   from wjl.pos_2008.pos_2008.t_sppsd  a with(nolock),
	wjl.pos_2008.pos_2008.t_psdmx  b with(nolock)  where a.sPsdbh=b.sPsdbh    
	 and a.spsdbh>='20210501';

   with x0 as(
   select a.srkfd,a.sspbh, min (a.ndhsl) ndhsl,count(a.spsdbh) ncs from #tmp_psd a  where ndhsl>0
    and sckfd='088'  group by a.srkfd,a.sspbh )
	,x1 as (
   select a.*,b.sspmc,b.sdw,b.npsbzs,b.njj  from  x0 a
   left join dbo.tmp_spb b on a.srkfd=b.sfdbh and a.sspbh=b.sspbh
   where 1=1 and a.ndhsl<b.npsbzs  and  left(sfl,4) in ('0101','0102','0103','0201','0202','0203','0205','0301','0302','0304','0305','0401','0402','0403','0406','0501','0502','0504','0604','0605','0701','0702','0706','0707','0708','0709','0710','0711','0712','0713','0714','0802','0804','0805','0806','0807','0808','0809','0810','0901','0902','0903','0904','0905','1001','1002','1003','1004','1005','1006','1007','1101','1102','1103','1104','1201','1202','1203','1204','1205','1206','1207','1208','1209','1210','1211','1301','1302','1303','1304','1305','3401','3402','3403','3601','3801','3802','3901','4101','4102','4103')
   and b.ssfkj=1 and b.szdbh=1)
   select a.sspbh,a.sspmc,a.sdw,max(a.njj) njj, a.ndhsl  ndhsl, a.npsbzs  npsbzs,sum(a.ncs),max(b.nxssl),max(b.nrjxl) from x1 a 
   left join (select sspbh,sum(nxssl) nxssl,sum(nrjxl) nrjxl from R_Dpzb group by sspbh) b on a.sspbh=b.sspbh
   group by a.sspbh,a.sspmc,a.sdw,a.ndhsl,a.npsbzs  having sum(a.ncs)>3 and nPsbzs-ndhsl>3 order by  a.npsbzs - a.ndhsl  desc
    
	


	select c.sPsfs,sum(b.nsl*c.nJj)  from DAppSource_WJL.dbo.Purchase_DeliveryReceipt a ,DAppSource_WJL.dbo.Purchase_DeliveryReceipt_Items 
b  , DAppSource_WJL.dbo.tmp_spb c where a.sDh=b.sDh and   a.sFdbh=c.sFdbh and b.sSpbh=c.sSpbh 
  and a.sDh>'20210611' group by c.sPsfs with rollup(c.spsfs);


  select  sum(b.nsl*c.nJj)    from DAppSource_WJL.dbo.Purchase_Receipt a ,DAppSource_WJL.dbo.Purchase_Receipt_Items 
b  , DAppSource_WJL.dbo.Tmp_spb_dc c where a.sDh=b.sDh   and b.sSpbh=c.sSpbh 
  and a.sDh>'20210611' group by c.sPsfs with rollup(c.spsfs);

  select   sum(b.nSl*b.nJj)   from DAppSource_WJL.dbo.Purchase_Receipt a ,DAppSource_WJL.dbo.Purchase_Receipt_Items 
b    where a.sDh=b.sDh  
  and a.sDh>'20210611' 

  select sum(nCgsl*nJj) from DAppSource_WJL.dbo.tmp_purchase_receipt


  drop table #1;
  select b.sSpbh, CEILING(b.nRjxl_De*b.nZdkcts_jy) nxx into #1  from DAppSource_WJL.dbo.Tmp_Gys a ,DAppSource_WJL.dbo.Purchase_Spb b
  where a.sGysbh=b.sGys and SUBSTRING(a.sDays,6,1)='1' and a.sFDBH='0000'

  select a.sfdbh,a.sspbh,a.nXysl into #kc from wjl.pos_2008.pos_2008.t_kc a 
where a.sfdbh='088';
select * from  #1 a  left join #kc b on a.sspbh=b.sspbh
where  1=1 


select * from DAppSource_WJL.dbo.Purchase_DeliveryReceipt_Items where sSpbh='6935351200561' and sFdbh='001'


-- 查询近一周


-- 缺货商品
select  a.sFdbh,b.sSpbh,b.sSpmc,b.nRjxl_De,b.nJyxx,b.nJysx,a.nDhts from R_Qhsp a 
left join R_Dpzb b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh 
where a.sFdbh='012'
order by  a.nDhts*b.nRjxse desc

-- 库存为 1  2 的单品和分布   -- drop table #kcfb
select a.sFdbh,a.sSpbh,a.sSpmc,c.sFl,d.nxysl,a.nJyxx,a.nJysx,a.nRjxl_De into #kcfb  from dbo.R_Dpzb a 
 --  left join dbo.Tmp_Kclsb b  on  a.sSpbh=b.sspbh and a.sFdbh=b.sfdbh and b.dRq=CONVERT(varchar,GETDATE()-1,23)+' 23:59:59.000'
 join dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh 
and LEFT(c.sFl,4) in ('0101','0102','0103','0201','0202','0203','0205','0301','0302','0304','0305','0401','0402',
 '0403','0406','0501','0502','0504','0604','0605','0701','0702','0706','0707','0708','0709',
 '0710','0711','0712','0713','0714','0802','0804','0805','0806','0807','0808','0809',
 '0810','0901','0902','0903','0904','0905','1001','1002','1003','1004','1005','1006',
 '1007','1101','1102','1103','1104','1201','1202','1203','1204','1205','1206','1207',
 '1208','1209','1210','1211','1301','1302','1303','1304','1305','3401','3402','3403',
 '3601','3801','3802','3901','4101','4102','4103')
 left join #kc d on a.sFdbh=d.sfdbh and a.sSpbh=d.sSpbh;


 select a.nxysl,COUNT(1) nsps   from #kcfb  a where a.nxysl in (1,2)
 group by a.nxysl


  select a.nxysl,b.sflbh,max(b.sFlmc) sflmc,count(1) zsps   from #kcfb  a
  left join  dbo.tmp_spflb b on left(a.sFl,2)=b.sFlbh where a.nxysl in (1,2)
 group by a.nxysl,b.sFlbh  order by 4 desc;

 -- 现有食品的单品
  select  a.sFdbh,c.sFDMC,a.sSpbh,a.sSpmc,b.sFlbh,b.sFlmc,d.sPsfs,d.sZdbh,a.nRjxl_De,a.nJyxx,a.nJysx,a.nxysl  from #kcfb  a
  left join  dbo.tmp_spflb b on  a.sFl=b.sFlbh 
  left join dbo.tmp_fdb c on a.sfdbh=c.sfdbh
  left join dbo.tmp_spb d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh 
  where a.nxysl in (1,2) and d.sPsfs='直送'
   and left(a.sFl,2)='03'  order by a.nJyxx-a.nxysl desc
  
  -- 
  select * from dbo.Purchase_CJYPB  a 
  ,dbo.Tmp_spb_All b 
  where 日期='2021-06-15 00:00:00.000' and a.商品代码=b.sSpbh and b.spsfs=;

  -- 销售较好的散货
    -- 单品指标上下限和库存对比
   select a.sFdbh,a.sSpbh,a.sSpmc,a.sPlbh,a.nJhj,a.nLsj,a.sDw,a.nRjxl,a.nRjxl_De
   ,b.nPms,a.nJyxx,a.nJysx,c.nSl,a.nZdsl,a.nZgsl,a.sZdbh,a.nZxcl from  DAppSource_WJL.dbo.R_Dpzb a 
   join DAppSource_WJL.dbo.tmp_spb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
   join DAppSource_WJL.dbo.Tmp_Kclsb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and CONVERT(date,c.dRq)=CONVERT(date,GETDATE()-1)
   where 1=1 and  a.nRjxl_De>0.5 and b.nPms is null  and  b.sZdbh=1 and b.sSfkj=1
   order by  a.nRjxl_De desc

   -- 当前散货
   select a.sFdbh,d.sFDMC,a.sSpbh,a.sSpmc,b.sFl,c.sFlmc,b.sDw, from R_Dpzb a
   left join dbo.tmp_spb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
   left join dbo.tmp_spflb c on b.sFl=c.sFlbh
   join  dbo.Tmp_FDB d on a.sFdbh=d.sFDBH
   where 1=1 and b.sSfkj=1 and b.sZdbh=1  and b.sSpbh like '2%'  and len(b.sSpbh)=7;


   /*商品上架*/
Use DAppSource_WJL;

select * from T_Spsj_zd
select * from T_Spsj_Mx
select * from T_Spsj_result_in
select * from T_Spsj_result_out

select a.sSjfd,d.sFDMC,a.sSpbh,c.sSpmc,c.sDw,c.nJj,c.nSj,e.sFlbh,e.sFlmc,b.nDjxl,b.nJyds,b.nDqsjl,c.sSfkj,c.sZdbh,
case when c.sjjx='1' then '季节性清零' else '正常经营' end sjjx,f.nSl from dbo.T_Spsj_result_in a 
left join dbo.T_Spsj_Mx b on a.sSjdh=b.sSjdh and a.sSpbh=b.sSjsp
left join dbo.tmp_spb c on a.sSjfd=c.sFdbh and a.sSpbh=c.sSpbh
join  dbo.Tmp_FDB d on a.sSjfd=d.sFDBH
join dbo.tmp_spflb e on c.sFl=e.sFlbh
left join dbo.Tmp_Kclsb f on a.sSjfd=f.sFdbh and a.sSpbh=f.sSpbh and f.dRq=CONVERT(varchar,GETDATE()-1,23)+' 23:59:59.000'
where 1=1;


--- 万佳利代表商品
select * from wjl.pos_2008.pos_2008.t_spdbgx where sbdbspbh='6935547300181'
select * from wjl.pos_2008.pos_2008.t_xsmx where sSpbh='6901035612586' and sxsdbh>'20210101' and sfdbh='014';
select * from DAppSource_WJL.dbo.Tmp_Xsnrb where sSpbh='6901035610551'


--- 库龄查询
-----0802白酒和红酒、12家居、34散货
select splbh 分类,a.sspbh 商品编号,sspmc 商品名称,a.sfdbh 分店编号,nbdxts 不动销天数,b.nsl 库存,nbzt,(case when ssfkt=0 then '不可退货' else '退货' end) ssfkt,nzgsl,nzdsl,case when a.nRjxl=0 then 365 else b.nSl/a.nRjxl end nzzts,'' 库龄 into #1
from r_dpzb a,tmp_kclsb b where a.sspbh=b.sspbh and a.sfdbh=b.sfdbh and b.drq='2021-06-27 23:59:59.000'
and  a.nbdxts>100 and left(splbh,4)<>'0802' and left(splbh,2)<>'12' and  left(splbh,2)<>'34' and b.nsl>1
and a.nBzt<=270 and a.nBzt>1 
union
select a.sfl,a.sspbh,a.sspmc,a.sfdbh,c.nBdxts,b.nSl,c.nBzt,(case when ssfkt=0 then '不可退货' else '退货' end) ssfkt,nzgsl,nzdsl,a.nzzts,'半年未进货'  from dbo.tmp_mdspzzyy a
 join tmp_kclsb b on   a.sspbh=b.sspbh and a.sfdbh=b.sfdbh and b.drq='2021-06-27 23:59:59.000'
 join R_Dpzb  c on a.sfdbh=c.sFdbh and a.sspbh=c.sSpbh
 where a.drq=convert(date,GETDATE()) and syy='遗留库存' and a.nzzts>60 
 and left(a.sfl,4)<>'0802' and left(a.sfl,2)<>'12' and  left(a.sfl,2)<>'34' and b.nSl>1 and c.nBzt<=270
 and c.nBzt>1  
 ;

 select * from #1 
 select a.sFdbh,b.sSpbh,max(a.sJcbh) sjcbh into #jc from Tmp_Jcb a,dbo.Tmp_Jcmxb b where a.sJcbh=b.sJcbh and a.sFdbh=b.sFdbh and b.nSl>0
 group by a.sFdbh,b.sSpbh;


 with x0 as (
  select a.sFdbh,b.sSpbh,a.sJcbh,a.sJcfl,a.dSj,b.nSl from Tmp_Jcb a,dbo.Tmp_Jcmxb b,#jc c where a.sJcbh=b.sJcbh and a.sFdbh=b.sFdbh 
   and a.sfdbh=c.sfdbh and a.sJcbh=c.sjcbh and b.sspbh=c.sSpbh 
   )
 select  * from #1 a 
 left join x0 b on a.分店编号=b.sFdbh and a.商品编号=b.sSpbh

 -- Step 25 :查最小销量和采购配送包装数不一致的单品：最小配送包装数错误
 /*单品的最小销售单位的特点是 总销售量肯定是这个数量的倍数*/
 select * into #xs from DAppSource_WJL.dbo.Tmp_Xsnrb a where a.sXsdh>'20210501' and a.nXssl>1;

 select a.sSpbh,a.nXssl,sum(a.nXssl) nzxssl,count(1) nkds,count(distinct a.sFdbh) nfds into #spxsmx from #xs a  group by a.sSpbh,a.nXssl;

 with x0 as(
 select a.sSpbh,sum(nxssl) nzxssl from #spxsmx a group by a.sspbh)
 ,x1 as(select a.*,ROW_NUMBER()over(partition by a.sspbh order by a.nxssl) npm from #spxsmx a
 where len(a.sSpbh)>5  )
 select a.*,c.sFdbh,c.sSpmc,c.sPsfs,c.nCgbzs,c.nPsbzs into #bzs2 from x1 a 
 join x0 b on a.sSpbh=b.sSpbh 
 left join DAppSource_WJL.dbo.Tmp_spb  c on a.sSpbh=c.sSpbh
 where a.npm=1 and b.nzxssl%a.nXssl=0 and b.nzxssl>a.nXssl
 and  a.nXssl>( case when c.sPsfs='直送' then c.nCgbzs else c.npsbzs end)*1.2
 and  LEFT(c.sFl,4) in ('0101','0102','0103','0201','0202','0203','0205','0301','0302','0304','0305','0401','0402',
 '0403','0406','0501','0502','0504','0604','0605','0701','0702','0706','0707','0708','0709',
 '0710','0711','0712','0713','0714','0802','0804','0805','0806','0807','0808','0809',
 '0810','0901','0902','0903','0904','0905','1001','1002','1003','1004','1005','1006',
 '1007','1101','1102','1103','1104','1201','1202','1203','1204','1205','1206','1207',
 '1208','1209','1210','1211','1301','1302','1303','1304','1305','3401','3402','3403',
 '3601','3801','3802','3901','4101','4102','4103') and c.sFdbh in (select distinct sfdbh from R_kpi where EndDate>GETDATE()-6) ;

 select distinct sSpbh,sSpmc,nXssl,sPsfs,nCgbzs,nPsbzs  from  #bzs2  a 
 where  nXssl>5

 select a.*,c.nJj,c.nSj from  #bzs2 a 
 left join DAppSource_WJL.dbo.Tmp_spb  c on a.sSpbh=c.sSpbh
 where  nXssl=2 

 --Step 26 进出
 select * from dbo.Tmp_Jcmxb  where sspbh='6921311105168' and sFdbh='012' order by sJcbh desc


select * from dbo.Tmp_Jcb  where sJcbh='202106210880001' and sFdbh='012' order by sJcbh desc


-- Step 27：推进新品存档
-- 每档excel 存档，然后
select  a.sSpbh,a.sSpmc into #new_sp from  dbo.Tmp_spb_All a  where a.sspbh in (
'6953442900046','6958051600035','6953442900060','6971474880037','6954626900074','6926475201367','6902878121136','6973043880318','6922804600016','6932960409590','6948469466675','6926372510456','6902890111306','6902890239444','6902890259541','6902890226765','6902890259589','6902890259749','6902890252764','4891028164395','4891028164456','4891028167747','4891028165279','6921718066802','6931754806058','6931754806096','6931754806430','6931754806065','6911988013569','6949352200055','6900082020450','6956416200074','6902987202054','6933125688881' );

-- 2021-07-07 外围商品数据
select '06907992513607' sspbh into #waisp  union  select '6923644272159' union  select '6907992518473' union  select '6902083810795' union  select '6923644232559' union  select '6916196424268' union  select '6916196410414' union  select '6916196422547' union  select '4100290077570' union  select '6921168596614' union  select '6934558003050' union  select '6921168502127' union  select '6921168595730' union  select '6921168595006' union  select '6902083918101' union  select '6921168594993' union  select '6972549660493' union  select '6901285993282' union  select '6922858201177' union  select '6940159414003' union  select '6908946286943' union  select '6940159413006' union  select '6940159411019' union  select '6940159414010' union  select '6973853180097' union  select '6954767430836' union  select '6949133700521' union  select '6940159410142' union  select '6940159413075' union  select '6901347884138' union  select '6921311143320' union  select '6921311105496' union  select '6936551602407' union  select '6920458835488' union  select '6921294389371' union  select '6928377504379' union  select '6921294389906' union  select '6921294358674' union  select '6921294358698' union  select '6902083907150' union  select '4891028164398' union  select '6921294342970' union  select '6972549660097' union  select '6920459905012' union  select '6921168596348' union  select '6973870130006' union  select '6925303756741' union  select '4891028720232' union  select '6921294393798' union  select '6926892575041' union  select '6972549660677' union  select '6921294305166' union  select '6921294344325' union  select '6921294396508' union  select '6921294391985' union  select '6920202866737' union  select '6927573123513' union  select '8850228005873' union  select '6927573119219' union  select '6934024590169' union  select '6934024590367' union  select '6921168596157' union  select '6902538007367' union  select '6902538007381' union  select '6902538006261' union  select '6921168550142' union  select '6920458835341' union  select '6937761805015' union  select '6970870270947' union  select '6921168594733' union  select '6922456848392' union  select '6920458835372' union  select '6970870270961' union  select '6972549660196' union  select '6922456850142' union  select '6957993400093' union  select '8855790000141' union  select '4710111901535' union  select '4710111901719' union  select '8850389100769' union  select '8850389100691' union  select '8850389106280' union  select '8850267112624' union  select '8850389101391' union  select '6909306010956' union  select '6949352201403' union  select '6921336821258' union  select '6948960106629' union  select '6901672500086' union  select '6948960109347' union  select '6949352232797' union  select '6901672913206' union  select '6948960102751' union  select '6915878219093' union  select '6973060560163' union  select '6973060560187' union  select '6948960110145' union  select '6909306010819' union  select '6901672500017' union  select '6948960107671' union  select '016938514100715' union  select '6951329303843' union  select '6906151617279' union  select '6903622798932' union  select '6906151638076' union  select '6928083900007' union  select '6930174800110' union  select '6901160910106' union  select '6973656640248' union  select '6973656640033' union  select '6935145343085' union  select '6935145343030' union  select '6935145343061' union  select '6935145343047' union  select '6935145343092' union  select '6935145343054' union  select '6935145301078' union  select '4251402303008' union  select '4251402303015' union  select '6956064018601' union  select '6921317600315' union  select '6932850200450' union  select '6927334800264' union  select '6927334800967' union  select '6927334800301' union  select '6926578016899' union  select '6926756590418' union  select '6923557911169' union  select '6933848786970' union  select '2400016' union  select '6973916050053' union  select '6957471701285' union  select '6923557959307' union  select '6918962005862' union  select '6922507806517' union  select '6937412220258' union  select '6931278888202' union  select '6900873714070' union  select '6903252097023' union  select '6937962103088' union  select '6903252085051' union  select '6920238083023' union  select '6920208993314' union  select '6920208900770' union  select '6920208923069' union  select '6925303795214' union  select '6937962107581' union  select '6937962103736' union  select '6937962102876' union  select '6920208992386' union  select '6920734714773' union  select '6920238011118' union  select '6925303710897' union  select '6925303710880' union  select '6901715296648' union  select '6901715296662' union  select '6921774260060' union  select '6920734713080' union  select '6937962103163' union  select '6903252714135' union  select '6920238082019' union  select '6904417011274' union  select '6901715296686' union  select '6938618412837' union  select '6900873084012' union  select '6917935002297' union  select '6917935002181' union  select '6937962104115' union  select '6937962104948' union  select '6917935002280' union  select '6917536014149' union  select '6920238081050' union  select '6937962106195' union  select '6917935002150' union  select '6971807591081' union  select '6942628020258' union  select '6942628020241' union  select '6971284201244' union  select '6970209860191' union  select '6926410321501' union  select '6926410321617' union  select '6925303794712' union  select '6958770000970' union  select '6971415832279' union  select '6902890249306' union  select '6901447007765' union  select '6901447007772' union  select '6917878044729' union  select '6923986040164' union  select '9349479000625' union  select '8801073210363' union  select '8801073101524' union  select '8801073210776' union  select '8803556815706' union  select '6924955406615' union  select '6924160712389' union  select '6924160712747' union  select '6924160713522' union  select '6924160713546' union  select '6924955406622' union  select '6933364808019' union  select '6933364808026' union  select '6933364808057' union  select '6939978706130' union  select '6972636670244' union  select '6936285700356' union  select '6921803400283' union  select '6939978706123' union  select '6939978706147' union  select '6972636670237' union  select '6924773536006' union  select '6945018700259' union  select '6933364800051' union  select '6948038100634' union  select '6939978706192' union  select '6924160715441' union  select '6921803403024' union  select '6972322280061' union  select '6930946900116' union  select '6930946900246' union  select '6951315037899' union  select '6956558913191' union  select '6972322280009' union  select '6972322280023' union  select '6972322280092' union  select '6952889402267' union  select '6972322280122' union  select '6952096711275' union  select '6941179564044' union  select '6972578221238' union  select '6928235295142' union  select '6972578221139' union  select '6970662880538' union  select '6972578221108' union  select '6933441800141' union  select '6933441800134' union  select '026946296590051' union  select '6933441800189' union  select '6924903502017' union  select '6924903500051' union  select '6936869220003' union  select '6936869216075' union  select '6941179563887' union  select '6930946900949' union  select '6972322280382' union  select '6931502003067' union  select '6936869220034' union  select '6973161290051' union  select '016946296590051' union  select '6936869215382' union  select '6924903500761' union  select '6952675321611' union  select '6936869215603' union  select '6923228405089' union  select '6927525900117' union  select '6928497800047' union  select '6957172790052' union  select '6935490202266' union  select '6923228400183' union  select '6970662880668' union  select '6924160714710' union  select '6928528000163' union  select '6928528000934' union  select '6952265300040' union  select '6956511907915' union  select '6952096711411' union  select '6952096710926' union  select '6935284415308' union  select '6930487920802' union  select '6970903440057' union  select '6972729920058' union  select '6935284455595' union  select '6935284488883' union  select '6951027300014' union  select '6972016790128' union  select '6925668475608' union  select '6951027300076' union  select '6935284412079' union  select '6937221716172' union  select '6970655717964' union  select '6953513210074' union  select '6953513295330' union  select '6972729920027' union  select '6930487901795' union  select '6953513295347' union  select '6951027300106' union  select '036939650400059' union  select '6970395400195' union  select '6923841900015' union  select '6935814600112' union  select '016939650400059' union  select '046939650400059' union  select '6935284412918' union  select '6935284455588' union  select '6933595616162' union  select '6951027300830' union  select '6948406015089' union  select '6951027302506' union  select '6951027300779' union  select '6972377900105' union  select '6972752250108' union  select '6927509821803' union  select '6930946900802' union  select '6971376020869' union  select '6925678103133' union  select '6951027300519' union  select '6928539800097' union  select '6951027301981' union  select '6948406000030' union  select '6948406000023' union  select '6951027300182' union  select '6948406017021' union  select '6930946901151' union  select '6936158287243' union  select '6936158287236' union  select '6970903440040' union  select '6951592317011' union  select '6951027300694' union  select '6971847420006' union  select '6958951100536' union  select '6954283000032' union  select '6970463600298' union  select '6972322280337' union  select '6935284470031' union  select '6972322280580' union  select '6935284415933' union  select '6938956700276' union  select '6952395700895' union  select '6944737300863' union  select '6952395700451' union  select '6939418902313' union  select '6954446303505' union  select '6901180351880' union  select '6919892633101' union  select '6901180973785' union  select '6901180973686' union  select '6919892641106' union  select '6901668927873' union  select '6901668927811' union  select '6901668005748' union  select '6901668931740' union  select '6901668931726' union  select '6901668006103' union  select '6901668005762' union  select '6901668062499' union  select '6901180339383' union  select '6901668003409' union  select '6917878131504' union  select '6901180591989' union  select '6901180681185' union  select '6901668200013' union  select '6901668200235' union  select '6901668200303' union  select '6924546002158' union  select '6970417724285' union  select '6942886307108' union  select '6942886302134' union  select '6920907800944' union  select '6970417725350' union  select '6937007116790' union  select '6970417725428' union  select '6970417723257' union  select '6970417723172' union  select '6937007117063' union  select '6937007117025' union  select '6970417721420' union  select '6946932967971' union  select '6949618301038' union  select '6926970100066' union  select '6958620703907' union  select '6955878200066' union  select '6958620700319' union  select '6911173279121' union  select '6924743926011' union  select '6924187839274' union  select '6930799503618' union  select '6924743925618' union  select '6930799503533' union  select '6930799503564' union  select '6924743915770' union  select '6926265313126' union  select '6924743926660' union  select '6924743926653' union  select '6924743925625' union  select '6924743914704' union  select '6924743925991' union  select '6924743926387' union  select '6924743913387' union  select '6924743926349' union  select '6924743926615' union  select '6924187839236' union  select '6970603450783' union  select '6970113720055' union  select '6931286064315' union  select '6923985700038' union  select '6931286064285' union  select '6905734301468' union  select '6909409012802' union  select '6926215372890' union  select '6924743925502' union  select '6931552204384' union  select '6970541410214' union  select '6924743926264' union  select '6970541410207' union  select '6924743926257' union  select '6923567880219' union  select '4897098800331' union  select '4710199110775' union  select '8858702431590' union  select '8993175537384' union  select '8934893010049' union  select '4897082057185' union  select '8934893010032' union  select '9556121027286' union  select '4897105430001' union  select '6954432711321' union  select '6923450669488' union  select '6923450669600' union  select '6923450669570' union  select '6954432711437' union  select '6911316223202' union  select '6924960961123' union  select '6930639273534' union  select '6937451811531' union  select '6930639260282' union  select '036911316540309' union  select '6911316660311' union  select '046911316540309' union  select '6939501805958' union  select '6937451811449' union  select '6937451813542' union  select '6911316372733' union  select '6924546001151' union  select '6931925828032' union  select '026911316540309' union  select '016911316540309' union  select '6924513905598' union  select '6911316530300' union  select '6911316375307' union  select '6941308821642' union  select '6911316582415' union  select '6911316375314' union  select '6920952712254' union  select '6911316582231' union  select '6921299762032' union  select '6920907817829' union  select '6930639260640' union  select '6930639260718' union  select '6911316370678' union  select '6930639260602' union  select '6920907817799' union  select '6921211101154' union  select '6901424335904' union  select '6952480090870' union  select '6970409940938' union  select '6936664810461' union  select '6936664810485' union  select '6936664811024' union  select '6924546006279' union  select '6939501802483' union  select '6939501804685' union  select '6924546006262' union  select '690248942' union  select '6942836700409' union  select '6914973610583' union  select '45129131' union  select '6926832401928' union  select '6914973611993' union  select '80310891' union  select '8809260944411' union  select '4605504515188' union  select '80176732' union  select '4897055394095' union  select '4714883741818' union  select '4005292123501' union  select '4897055393746' union  select '4897055392312' union  select '4005292652384' union  select '8410525173950' union  select '6920130961078' union  select '6952480080536' union  select '6901097622004' union  select '6952096703652' union  select '6901097622028' union  select '6937638100045' union  select '6948004701339' union  select '6952096711084' union  select '6952096711251' union  select '6937638102797' union  select '6937621900010' union  select '6930044165219' union  select '6954627200227' union  select '6920130971992' union  select '6933040203404' union  select '6924187821989' union  select '6920771610809' union  select '6924187828759' union  select '6924187872288' union  select '6924187828537' union  select '6924187828544' union  select '6924187828964' union  select '6936324888816' union  select '6936324888823' union  select '6920584452221' union  select '6920470110044' union  select '6920470111140' union  select '6920470123839' union  select '6938014081873' union  select '6920470110228' union  select '6922332116546' union  select '6928308600224' union  select '6936324888632' union  select '6920771610090' union  select '6924187858084' union  select '6957104100058' union  select '6952096711046' union  select '6936816212044' union  select '6951440029004' union  select '6936158281678' union  select '6936158287205' union  select '6936158281685' union  select '6931630080589' union  select '6943517100075' union  select '6943517119589' union  select '6943517118681' union  select '6933585961289' union  select '6943517166668' union  select '6943517128116' union  select '6930655000237' union  select '6957097401569' union  select '6970303530884' union  select '6970909900562' union  select '6957097400104' union  select '6959005500821' union  select '6931630002000' union  select '6934660559216' union  select '6934660554150' union  select '6923589462448' union  select '6903148138182' union  select '6923589463582' union  select '6934660524511' union  select '6934660511917' union  select '6903244376273' union  select '6901236378809' union  select '6914068020655' union  select '6922266450365' union  select '6914068024356' union  select '6914068015293' union  select '6903244675338' union  select '6933684000520' union  select '6922868285730' union  select '6933684005037' union  select '6914068018171' union  select '6922266448843' union  select '6914068019529' union  select '6901236340288' union  select '6922266439575' union  select '6901236373965' union  select '6940953100331' union  select '6922868286959' union  select '6922266437342' union  select '6922868283101' union  select '6914068018775' union  select '6922266450310' union  select '6914068026312' union  select '6922266462863' union  select '6914068020457' union  select '6901236300343' union  select '6903244680929' union  select '6944125680041' union  select '6944125680232' union  select '6944125680225' union  select '4547691689719' union  select '4547691239082' union  select '4547691770929' union  select '4547691439628' union  select '4547691239129' union  select '6931060710018' union  select '6937432406909' union  select '6954967602842' union  select '6954967602859' union  select '6938902618020' union  select '6903148048948' union  select '6938902619331' union  select '6903148018194' union  select '6920354818592' union  select '6903148054215' union  select '6908011911725' union  select '6926160720104' union  select '6933179210038' union  select '6930387571098' union  select '6930387571081' union  select '6923476109081' union  select '6923476106356' union  select '6933179260118' union  select '6926160720050' union  select '6926160723433' union  select '6970983297053' union  select '6902088720839' union  select '6902022134333' union  select '6902022134319' union  select '6910019007614' union  select '6903148078921' union  select '6903148070949' union  select '6971023270685' union  select '6910019017507' union  select '6910019405007' union  select '6971068290013' union  select '6922577766209' union  select '6901209258169' union  select '6923800535180' union  select '6934665086250' union  select '6923800534954' union  select '6923644295264' union  select '6923644230111' union  select '6907992105772' union  select '6922577766124' union  select '6941704425895' union  select '6922577766117' union  select '6901209253805' union  select '6901209256134' union  select '6922577727446' union  select '6941704425796' union  select '6941704425802' union  select '6907992105147' union  select '6941704425079' union  select '6907992105055' union  select '6907992103877' union  select '6907992105147' union  select '6941704424270' union  select '6922577722717' union  select '6922577722090' union  select '6922577733706' union  select '6901209263606' union  select '6901209263620' union  select '6907992105161' union  select '6907992101330' union  select '6924810810007' union  select '6907992102764' union  select '6923800570075' union  select '6907992105574' union  select '6932571032132' union  select '6932571040908' union  select '6973035110058' union  select '6921168594535' union  select '6932571041004' union  select '6932571040915' union  select '6921168594498' union  select '6921168594474' union  select '6932571040168' union  select '6932571040281' union  select '6901209257216' union  select '6901209261800' union  select '6923644234669' union  select '6923644234638' union  select '6932571080522' union  select '6901209264603' union  select '6901209262623' union  select '6941704414189' union  select '6925303780210' union  select '6932571080478' union  select '6972960570128' union  select '6932571080195' union  select '6941704419436' union  select '6932571040182' union  select '6970605360097' union  select '6970605360578' union  select '6970605367263' union  select '6970605360103' union  select '6932571061316' union  select '6932571061569' union  select '6932571061361' union  select '6932571061057' union  select '6932571061293' union  select '6932571061767' union  select '6932571061798' union  select '6932571061453' union  select '6972491871251' union  select '6972491871237' union  select '6922477410530' union  select '6922477410523' union  select '6923644299446' union  select '6923644299453' union  select '8805584111904' union  select '6957690901794' union  select '4897115720000' union  select '6909493100317' union  select '6907992824703' union  select '6918551811423' union  select '6923644251697' union  select '6923644250751' union  select '6909493200239' union  select '6932002062776' union  select '6923644282264' union  select '6932002061045' union  select '6907992821566' union  select '6923644285814' union  select '4897115720017' union  select '6927119002913' union  select '6909493100720' union  select '6923644275198' union  select '6923644266257' union  select '6909493100232' union  select '6918551814356' union  select '6909493200741' union  select '6932002060697' union  select '6909493200208' union  select '6909493200277' union  select '6907868581389' union  select '6972853630069' union  select '6972853630199' union  select '6909493100577' union  select '074570002023' union  select '6907868580214' union  select '6907868580191' union  select '6907868581181' union  select '6923469320080' union  select '6907868581686' union  select '6925704218930' union  select '6909493100584' union  select '074570052028' union  select '074570022021' union  select '6909493100607' union  select '6909493100911' union  select '6932002061809' union  select '6909493401360' union  select '6932002080053' union  select '6918551807884' union  select '6907868518880' union  select '6922214714013' union  select '6923644274344' union  select '6918551804593' union  select '6932002020431' union  select '6972885740019' union  select '4891353312218' union  select '6954065405642' union  select '6954065407998' union  select '6973320340016' union  select '046908791103167' union  select '6925909961396' union  select '6958214659788' union  select '6925909980236' union  select '6958214619072' union  select '6973485990118' union  select '6936378310301' union  select '6936378310318'    
 -- 商品写入
 insert into DAppSource_WJL.dbo.R_recommond_sp(sSpbh,dcreate_date,sResource)
 select distinct  case when LEN(a.sspbh)<=13 then a.sspbh 
 when len(a.sspbh)>13 then right(a.sspbh,13) end,CONVERT(date,'2021-07-07'),'外围市面商品'   from #waisp a 

  -- 客户实际引进新品表
  select * into #xp_sj from    wjl.pos_2008.pos_2008.v_xpb where dsj>'2021-06-25'

  select * from #new_sp a,#xp_sj b where a.sSpbh=b.sspbh and b.sfdbh<>'088';
  
 --  create table R_recommond_sp(sSpbh varchar(50) not null,dcreate_date date);
 --  create table R_recommond_spmx(sSpbh varchar(50) not null,sFdbh varchar(20),d_into_date date);
 -- alter table DAppSource_WJL.dbo.R_recommond_sp  add sResource varchar(50)  
 -- drop table DAppSource_WJL.dbo.R_recommond_sp;
 insert into DAppSource_WJL.dbo.R_recommond_sp(sSpbh,dcreate_date)
 select sspbh,CONVERT(date,GETDATE()) from #new_sp;

 insert into DAppSource_WJL.dbo.R_recommond_spmx(sSpbh,sfdbh,d_into_date) 
 select a.sSpbh,a.sfdbh,a.dsj  from (select a.sSpbh,b.sfdbh,b.dsj,a.sResource from  R_recommond_sp a,#xp_sj b where a.sSpbh=b.sspbh) a
 left join DAppSource_WJL.dbo.R_recommond_spmx b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
 where b.sfdbh is null;

 -- 用 index_sp 表匹配
  insert into DAppSource_WJL.dbo.R_recommond_spmx(sSpbh,sfdbh,d_into_date) 
  select a.sSpbh,a.sfdbh,a.IntoDate  from 
  (select a.sSpbh,b.sfdbh,b.IntoDate,a.sResource,b.OutDate  
  from  R_recommond_sp a,DAppSource_WJL.dbo.Index_Sp b where a.sSpbh=b.sspbh  and (b.IntoDate
  >a.dcreate_date   )) a
 left join DAppSource_WJL.dbo.R_recommond_spmx b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
 where b.sfdbh is null;


   select a.sSpbh,a.sfdbh,a.IntoDate,b.sResult  from (select a.sSpbh,b.sfdbh,b.IntoDate,a.sResource,b.OutDate  from  R_recommond_sp a,DAppSource_WJL.dbo.Index_Sp b where a.sSpbh=b.sspbh  and (b.IntoDate
  >a.dcreate_date   )) a
 left join DAppSource_WJL.dbo.R_recommond_spmx b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
 where b.sfdbh is not null and b.sResult is not null;
  
 


 -- Step 28:品类排名前3 drop table #plpm1;
 select a.sFdbh,a.sSpbh,a.sSpmc,a.sPlbh,a.nRjxl,a.sZdbh,a.sSfkj,a.nJhj into #plpm1 from R_Dpzb a
 join  dbo.tmp_spb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and ISNULL(b.sjjx,0)<>1  and a.sSfkj='1' where a.EndDate>GETDATE()-7;
 -- select * from #plpm1 where sSpbh='6907992636191';

 with x0 as (
 select a.sSpbh,a.sSpmc,a.sPlbh,AVG(a.nRjxl) nrjxl,count(a.sFdbh) nfds,AVG(a.nRjxl*a.nJhj) nrjxse from #plpm1 a group by a.sSpbh,a.sSpmc,a.sPlbh)
 ,x1 as (select a.*,ROW_NUMBER()over(partition by a.splbh order by a.nrjxl desc) npm from x0 a )
 ,x2 as (select distinct sspbh,sspmc,splbh,nrjxl,nfds,npm from x1 where npm<=3)
 select a.* from (select  b.sFdbh,b.sFdmc,a.sSpbh,a.sSpmc,a.sPlbh,a.nrjxl,a.nfds,npm from x2 a,dbo.R_Kpi b where b.EndDate>GETDATE()-6) a
 left join dbo.R_Dpzb b on a.sfdbh=b.sFdbh and a.sspbh=b.sSpbh and b.EndDate>GETDATE()-6
where 1=1  and b.sFdbh is null and a.nrjxl>0.5 order by splbh;


-- Step 29: 新品追踪
/* 引进的新品 追踪其销售*/
   select a.sSpbh,a.dcreate_date,a.sResource,b.sFdbh,b.d_into_date into #into_sp from DAppSource_WJL.dbo.R_recommond_sp a,DAppSource_WJL.dbo.R_recommond_spmx b 
   where a.sSpbh=b.sSpbh ;
   -- Step 29.1:总引进数,总推荐数
   select COUNT(1) ntjsps into #xpyj_1 from DAppSource_WJL.dbo.R_recommond_sp a ;
   select count(distinct sSpbh) nyjsps into #xpyj_2 from #into_sp ;

   --Step 29.2:销售数量
   select a.sSpbh,a.sResource,max(d.sspmc) sspmc,max(d.sFl) sfl,COUNT(distinct a.sFdbh) nyjfds,count(distinct b.sFdbh) nfds,sum(b.nXssl) nxssl,sum(isnull(b.nXsdj*b.nXssl,0)) nxsje into #xsmx from #into_sp a 
   left join  dbo.Tmp_Xsnrb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and CONVERT(date,left(b.sxsdh,8))>a.d_into_date 
	join  dbo.tmp_spb d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh
   where 1=1 group by a.sSpbh,a.sResource;

   with x0 as (
   select COUNT(1)nzsps,sum(case when a.nfds>0 then 1 else 0 end) ndxsps,sum(nxsje) nxsje,sum(case when a.nfds>0 then 1 else 0 end)*1.0/count(1) ndxl from #xsmx a)
   ,x1 as (select b.nyjsps,a.ntjsps, b.nyjsps*1.0/a.ntjsps nyjl from #xpyj_1 a,#xpyj_2 b)
   select b.ntjsps,b.nyjsps,b.nyjl,a.ndxsps,a.ndxl,a.nxsje from x0 a,x1 b 




      select  *  from #into_sp a 
   join DAppSource_WJL.dbo.Tmp_Xsnrb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and CONVERT(date,left(b.sxsdh,8))>a.d_into_date
     and b.nXssl>0
   join DAppSource_WJL.dbo.Index_Sp c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and CONVERT(date,left(b.sxsdh,8))>c.IntoDate
      and a.dcreate_date<c.IntoDate  
	join DAppSource_WJL.dbo.tmp_spb d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh
   where 1=1 group by a.sSpbh,a.sResource




-- Step 30 :单据对比计划
/*天牧出单 和 最后的 实际采购单 对比，查看人工修改的单据的问题，配送不允许改，不存在比对需求
drop table #receipt_raw;
*/
select a.sDh,CONVERT(date,left(a.sdh,8),23) dDhrq,a.sFdbh,a.sSpbh,a.sGys,a.spsfs,a.nsl,'门店采购' flag into #receipt_raw from dbo.Purchase_DeliveryReceipt_Items a 
where a.sdh>=CONVERT(varchar,GETDATE()-15,23) and a.spsfs<>'配送'
union 
select a.sdh,CONVERT(date,left(a.sdh,8),23) dDhrq,'088',a.sSpbh,'' sGys,'',a.nSl,'DC采购'  from dbo.Purchase_Receipt_Items a where a.sdh>=CONVERT(varchar,GETDATE()-15,23);
-- 配送单
  --Step 30.1: 要货表 drop table #Tmp_yhb T_mdyhjh 跟青云单是一模一样的  配送单要排除当天到的情况，因为取的库存是凌晨的
  SELECT  a.sYhjhbh,a.sZy,a.sfdbh, ISNULL(a.dShsj,a.dYhrq) dYhrq,b.sspbh,b.nYhsl,b.nYpsl,b.nYcgsl,a.sbz into #Tmp_yhb 
    FROM   Wjl.pos_2008.Pos_2008.T_mdyhjh a,
	Wjl.pos_2008.Pos_2008.[T_yhjhmx]  b where a.sYhjhbh=b.sYhjhbh
	and a.sYhjhbh>=CONVERT(varchar,GETDATE()-15,23) and a.sBz='dzixun要货'  and a.sYhjhbh<CONVERT(varchar,GETDATE()+1,23);

	select * from #Tmp_yhb;
 -- Step 2: 导实际采购单  drop table #cgdd;
   	with x0 as (select a.scgddbh,a.sZy,ISNULL(a.dShsj,a.dDhrq) dDhsj,a.sgysbh,a.sDhd,b.sspbh,b.nJhsl, b.sjhmx,a.sddzt,
	ROW_NUMBER()over(partition by a.sDhd,b.sspbh,convert(date,ISNULL(a.dShsj,a.dDhrq)) order by ISNULL(a.dShsj,a.dDhrq) desc) npm 
	from Wjlck.pos_2008.Pos_2008.t_cgdd a,Wjlck.pos_2008.Pos_2008.t_cgddmx b
	where a.scgddbh=b.scgddbh and a.szy like '%dzixun%'  and a.scgddbh>=CONVERT(varchar,GETDATE()-15,112)  and  a.sddzt<>'0' )
	,x1 as (select a.*,c.value('.', 'varchar(50)') sJhFdmx  
    from x0 a cross apply (select cast('<row>' + replace(substring(replace(a.sJhmx,'*',''),2,len(replace(a.sJhmx,'*',''))), '\','</row><row>')+ '</row>' as xml) as xmlcode) b
   cross apply xmlcode.nodes('*') t1 (c) where 1=1 and a.sJhmx <> '' )
	select  *,left(sJhfdmx,3) sJhfd,case when sJhFdmx like '%f%' then substring(sJhFdmx,4,CHARINDEX('f',sJhFdmx)-4) else substring(sJhfdmx,4,len(sJhfdmx)) end nSl into #cgdd from x1 ;
   -- 删除当天有要货的门店商品 
    
   delete a  from #cgdd  a 
  join #Tmp_yhb b on CONVERT(date,a.dDhsj)=CONVERT(date,b.dYhrq) and a.sSpbh=b.sspbh  and a.sJhfd=b.sfdbh ;

    delete a  from #receipt_raw  a 
  join #Tmp_yhb b on CONVERT(date,a.dDhrq)=CONVERT(date,b.dYhrq) and a.sSpbh=b.sspbh  and a.sFdbh=b.sfdbh ;

  -- Step 30.3  单据对比 加单 删单  加量 减量
  select ISNULL(a.dDhrq,b.dDhsj) drq,isnull(a.sFdbh,b.sJhfd) sfdbh,isnull(a.sSpbh,b.sspbh) sSpbh,
   a.spsfs,a.flag,a.nsl,b.nSl nsjsl ,case when b.sJhfd is null then '采购删单'  when a.sFdbh is null then '采购加单'
   when a.sDh is not null and b.sJhfd is not null and a.nsl<b.nsl then '采购加量'
   when a.sDh is not null and b.sJhfd is not null and a.nsl>b.nsl then '采购减量' else '转单正常' end resu into #receipt_resu
   from #receipt_raw a 
  full join #cgdd b on a.dDhrq=CONVERT(date,b.dDhsj) and a.sSpbh=b.sspbh and a.sFdbh=b.sJhfd  
  where 1=1 ;

  select a.drq 订货日期	,a.sfdbh 分店,a.sSpbh 商品,b.sSpmc 商品名称,b.sFl 分类,b.sDw 单位,b.nJj 进价 ,b.spsfs 配送方式,a.flag 单据类型,a.nsl 青云出单数量,a.nsjsl 实际单据数量,a.resu  from #receipt_resu a 
  left join dbo.tmp_spb b on a.sfdbh=b.sfdbh and a.sSpbh=b.sSpbh
  where 1=1 and b.sZdbh='1' and b.sSfkj='1'   and resu in ('采购加量','采购加单')
  order by nsjsl-ISNULL(nsl,0) desc;

   select count(1)  from #receipt_resu a 
  left join dbo.tmp_spb b on a.sfdbh=b.sfdbh and a.sSpbh=b.sSpbh
  where 1=1 and b.sZdbh='1' and b.sSfkj='1'  

  select count(1)  from #receipt_resu a 
  left join dbo.tmp_spb b on a.sfdbh=b.sfdbh and a.sSpbh=b.sSpbh
  where 1=1 and b.sZdbh='1' and b.sSfkj='1'   and resu in ('采购加量','采购加单')
  
  
   select distinct a.sSpbh,b.sSpmc,b.sPsfs,b.sFl,c.sFlmc  from #receipt_resu a 
  left join dbo.tmp_spb b on a.sfdbh=b.sfdbh and a.sSpbh=b.sSpbh
  left join dbo.tmp_spflb c on b.sFl=c.sFlbh
  where 1=1 and b.sZdbh='1' and b.sSfkj='1'   and resu in ('采购加量','采购加单')
   order by b.sfl;

   select distinct sSpbh,sSpmc from dbo.r_dpzb  where sSfkj='1' and sZdbh='1' and nJyxx>0 ;
  -- 门店 DC 库存
  select drq,sum(nJjje) from DAppSource_WJL.dbo.Dxp_tmp_mdkcls group by  drq


  -- 两期缺货对比
  select a.sFdbh,a.sSpbh,a.nDhts,TaskID,CONVERT(date,right(a.TaskId,8)) drq  into #1
   from dbo.H_Qhsp a  
  where a.sFdbh='008' and CONVERT(date,right(a.TaskId,8))>getdate()-15;

  -- drop table #2;
   select a.sFdbh,a.sSpbh,a.sSpmc,a.nRjxl,a.nRjxse,a.nRjml,TaskID,CONVERT(date,right(a.TaskId,8)) drq  into #2
   from dbo.H_Dpzb a  
  where a.sFdbh='008' and CONVERT(date,right(a.TaskId,8))>getdate()-15;

   with x0 as(
  select a.sfdbh,a.sSpbh,b.sspmc,a.nDhts,b.nRjxse,b.nRjxl,b.nRjml,a.drq,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.drq desc) npm
  from #1 a  join #2 b on a.TaskID=b.TaskID and a.sfdbh=b.sFdbh and a.sSpbh=b.sSpbh
  where 1=1)
  select a.drq, a.sFdbh,a.sSpbh,a.ssPmc,a.nRjxse,a.nDhts,b.nDhts,b.nRjxse,a.nRjml*a.nDhts,b.nRjml*b.nDhts from x0 a 
  left join x0 b on a.sfdbh=b.sfdbh and a.sspbh=b.sSpbh and b.drq='2021-07-04'
  where a.drq='2021-07-11' order by a.nRjml*a.nDhts-isnull(b.nRjml,0)*isnull(b.nDhts,0) desc

  select * from #1 where sfdbh='008' and sSpbh='6907619688398'

  
  select * from dbo.tmp_spb where sfdbh='008' and sSpbh='6907619688398'


  -- 供应商到货节奏查询
  select convert(date,a.dDhrq) 日期,max( DATENAME(DW,convert(date,a.dDhrq))) xq,COUNT(distinct a.sGys) 供应商个数,count(1) 品次数
into #1 from DAppSource_WJL.dbo.Tmp_Cgddmx_dc a
where  a.dDhrq>GETDATE()-29 and ISNULL(nDhsl,0)>0 group by  convert(date,a.dDhrq)

select convert(date,a.dYsrq) 日期,max( DATENAME(DW,convert(date,a.dYsrq))) xq,COUNT(distinct a.sGysbh) 供应商个数,count(1) 品次数
into #2 from wjl.pos_2008.pos_2008.t_spysd a,wjl.pos_2008.pos_2008.t_ysdmx b
where a.sYsdbh=b.sYsdbh and  a.sfdbh='088' and  isnull(b.nYssl,0)>0 and  a.dYsrq >GETDATE()-29
group by convert(date,a.dYsrq) 


select a.日期,SUM(b.品次数),avg(b.品次数) from #1 a 
join #1 b on DATEDIFF(day,b.日期,a.日期) between 0 and  6
where a.xq='星期日' group by a.日期

 
-- select a.xq 星期,AVG(a.品次数) 平均品次数 from #1  a group by a.xq  order by 1

select a.xq 星期,AVG(a.品次数) 平均品次数 from #1  a group by a.xq 
order by charindex(xq,'星期一星期二星期三星期四星期五星期六星期日')

-- Step 33 : 采购包装数或配送包装数比上限大太多的
with x0 as(
select a.sFdbh,a.sSpbh,a.sSpmc,b.sFl,a.sSfkj,a.sZdbh,a.nRjxl,a.nRjxl_De,b.nCgbzs,b.nPsbzs
,b.sPsfs,a.nJysx,case when b.spsfs='直送' then '采购包装数过大'  when b.sPsfs<>'直送' then '配送包装数过大'  end  f
from DAppSource_WJL.dbo.R_Dpzb a 
join DAppSource_WJL.dbo.tmp_spb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where b.sZdbh='1' and b.sSfkj='1' and (( b.sPsfs='直送'  and  b.nCgbzs*1.0>a.nJysx*2) or (
b.sPsfs='越库'  and  b.nPsbzs*1.0>a.nJysx*2) or  (b.sPsfs='配送'  and  b.nPsbzs*1.0>a.nJysx*2))
  and b.nPsbzs>10 and b.nCgbzs>10  )
  select   sspbh,sspmc,sFl,nCgbzs,nPsbzs,sPsfs, f,count(sFdbh) from x0 
  group by sspbh,sspmc,sFl,nCgbzs,nPsbzs,sPsfs, f  having COUNT(sFdbh)>3 order by nPsbzs desc

-- Step 34 : 人工下单商品，有销售，建议转自动下单
   -- Step 34 0 : 统计销售次数

   select a.sFdbh,a.sSpbh,a.sSpmc,b.sFl,a.sSfkj, a.nRjxl, b.nCgbzs,b.nPsbzs
,b.sPsfs, a.nJysx_Raw,case when  isnull(b.sjjx,0)<>1 then '非季节性'else '季节性' end  from DAppSource_WJL.dbo.R_Dpzb a 
   join DAppSource_WJL.dbo.tmp_spb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
   where b.sSfkj='1' and b.sZdbh='0' and a.nPxs>3
   and LEFT(a.sPlbh,2)<>'07' and LEFT(a.sPlbh,6)<>'250703' and LEFT(a.sPlbh,2)<>'34' and nRjxl>0.5
   and a.sFdbh<>'002' and  ISNULL(b.sjjx,0)<>'1';
   
   -- Step 35 :有定额没单品指标的
   select * from DAppSource_WJL.dbo.tmp_spb a 
left join DAppSource_WJL.dbo.R_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.EndDate>GETDATE()-15
where a.sSfkj='1'and isnull(a.nZdsl,0)>0 and b.sFdbh is null 
and LEFT(a.sFl,4) in ('0101','0102','0103','0201','0202','0203','0205','0301','0302','0304','0305','0401','0402',
 '0403','0406','0501','0502','0504','0604','0605','0701','0702','0706','0707','0708','0709',
 '0710','0711','0712','0713','0714','0802','0804','0805','0806','0807','0808','0809',
 '0810','0901','0902','0903','0904','0905','1001','1002','1003','1004','1005','1006',
 '1007','1101','1102','1103','1104','1201','1202','1203','1204','1205','1206','1207',
 '1208','1209','1210','1211','1301','1302','1303','1304','1305','3401','3402','3403',
 '3601','3801','3802','3901','4101','4102','4103') 

 --Step 36 : 周转天数标准版
   -- Step 36.1: DC 配送商品周转天数，DC每日的库存和门店的日均销量?去计算
    -- drop table #dczz_1  drop table #dczz_2
  select convert(date,a.sRq) drq,a.sSpbh,a.nSl,b.sFl,a.nsl*b.nJj nkcje into #dczz_1    from dbo.Tmp_dckcb  a 
 join DAppSource_WJL.dbo.Tmp_spb_dc b on a.sSpbh=b.sSpbh and b.sPsfs='配送'
 where a.sRq>'20210501'  and a.nSl>0 
 and LEFT(b.sFl,4) in ('0101','0102','0103','0201','0202','0203','0205','0301','0302','0304','0305','0401','0402',
 '0403','0406','0501','0502','0504','0604','0605','0701','0702','0706','0707','0708','0709',
 '0710','0711','0712','0713','0714','0802','0804','0805','0806','0807','0808','0809',
 '0810','0901','0902','0903','0904','0905','1001','1002','1003','1004','1005','1006',
 '1007','1101','1102','1103','1104','1201','1202','1203','1204','1205','1206','1207',
 '1208','1209','1210','1211','1301','1302','1303','1304','1305','3401','3402','3403',
 '3601','3801','3802','3901','4101','4102','4103') ;
  
 select convert(date,a.dSj) drq,a.sSpbh,a.nSl,b.sFl,-a.nsl*b.nJj nchje into #dczz_2 from dbo.Tmp_jcmxb_dc  a 
 join DAppSource_WJL.dbo.Tmp_spb_dc b on a.sSpbh=b.sSpbh and b.sPsfs='配送'
 where a.dSj>'2021-05-01' and a.sJcfl='出配(配送)' and a.nSl<0 and
 LEFT(b.sFl,4) in ('0101','0102','0103','0201','0202','0203','0205','0301','0302','0304','0305','0401','0402',
 '0403','0406','0501','0502','0504','0604','0605','0701','0702','0706','0707','0708','0709',
 '0710','0711','0712','0713','0714','0802','0804','0805','0806','0807','0808','0809',
 '0810','0901','0902','0903','0904','0905','1001','1002','1003','1004','1005','1006',
 '1007','1101','1102','1103','1104','1201','1202','1203','1204','1205','1206','1207',
 '1208','1209','1210','1211','1301','1302','1303','1304','1305','3401','3402','3403',
 '3601','3801','3802','3901','4101','4102','4103')  ;

 -- 生成日期
  declare @begindate date
 declare @enddate date
 select @begindate=CONVERT(date,'2021-06-02'), @enddate=CONVERT(date,GETDATE())
 create table #tmp_date(drq date not null);
 while @begindate<@enddate
   begin
		insert into #tmp_date(drq) select @begindate
		set @begindate=dateadd(day,1,@begindate)
   end 

 with x0 as (
 select a.drq,sum(a.nkcje) nkcje from #dczz_1 a  group by a.drq)
 ,x1 as (select a.drq,sum(isnull(a.nchje,0)) nchje from #dczz_2 a group by a.drq )
 ,x2 as (select a.drq,AVG(isnull(b.nkcje,0)) nkcje from #tmp_date a 
 join x0 b on DATEDIFF(day,b.drq,a.drq) between 0 and 29  where a.drq>'2021-06-01' group by a.drq)
  ,x3 as (select a.drq,AVG(isnull(b.nchje,0)) nchje from #tmp_date a 
 join x1 b on DATEDIFF(day,b.drq,a.drq) between 0 and 29 where a.drq>'2021-06-01' group by a.drq )
  
 select a.drq,a.nkcje,b.nchje,case when isnull(b.nchje,0)>0 then a.nkcje*1.0/b.nchje end from x2 a 
 left join x3 b on a.drq=b.drq
 order by  a.drq 



-- Step 37: 经常性的库存数低于最低陈列的单品
    --获取历史建议定额与历史日均"
     declare @Mdjxc_PY money
     if exists (select sParamsVal from purchase_params where sParamsName = 'Mdjxc_PY'
     begin
            select @Mdjxc_PY=sParamsVal from purchase_params where sParamsName = 'Mdjxc_PY'
             End
            else
           begin 
             set @Mdjxc_PY=1
            End
      select convert(varchar(8),dateadd(day,@Mdjxc_PY,convert(datetime,substring(Taskid,len(sFdbh)+9,8))),112) dxgRq, nJysx,nJyxx,nRjxl_de nRjxl
          into #detmp from H_Dpzb where 1=1 and sFdbh = @sfdbh and sSpbh = @sspbh and substring(Taskid,len(sFdbh)+9,8)>=@begintime-7
          and substring(Taskid,len(sFdbh)+1,8)<=@endtime
        insert into #detmp
            select convert(varchar(8),dateadd(day,@Mdjxc_PY,convert(datetime,substring(Taskid,len(sFdbh)+9,8))),112) dxgRq, nJysx,nJyxx,nRjxl_de nRjxl from H_Dpzb_X 
           where 1=1 and sFdbh = @sfdbh and sSpbh = @sspbh and substring(Taskid,len(sFdbh)+9,8)>=@begintime-7
           and substring(Taskid,len(sFdbh)+1,8)<=@endtime
            select *,row_number() over(order by dxgRq asc) npx into #de from #detmp 
          
           declare @j int
           declare @deall int
           set @j = 1
            select @deall=Max(npx) from #de
            while @j <= @deall
              begin
			  declare @sx money
            declare @xx money
            declare @rj money
            declare @xgrq datetime
           select @sx=nJysx,@xx=nJyxx,@xgrq=dxgRq,@rj=nRjxl from #de where nPx = @j
            update #Date set nJysx = @sx,nJyxx = @xx,nRjxl = @rj where dRq>=@xgrq
           set @j = @j + 1
           End
	-- 方法二 简单法 当前定额和库存	   
	-- 问题是  当前的最低陈列会变大，那么最终只能后查，而不能先查出来
select * into #tmpkc from dappsource_wjl.dbo.tmp_kclsb a where a.drq=CONVERT(varchar,GETDATE()-1,112)+' 23:59:59.000'
select a.sfdbh,a.sspbh,a.sspmc,a.njyxx,a.nzxcl,b.nsl from DAppSource_WJL.dbo.R_dpzb a 
left join #tmpkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where a.szdbh=1 and a.ssfkj=1 and a.nzxcl>isnull(b.nsl,0) and a.sfdbh='012'


select a.sfdbh,sum(a.ndhts*b.nrjml),sum(case when b.szdbh=1 then 0 else a.ndhts*b.nrjml end) nqhml,
  sum(case when b.szdbh=1 then 0 else a.ndhts*b.nrjml end) / sum(a.ndhts*b.nrjml)  from DAppSource_WJL.dbo.r_qhsp a
left join DAppSource_WJL.dbo.R_dpzb b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh 
group by a.sfdbh  order by 4 desc

--Step 38:
with x0 as (
   select a.scgddbh,a.sZy,ISNULL(a.dShsj,a.dDhrq) dDhsj,a.sgysbh,a.sDhd,b.sspbh,b.nJhsl,b.nDhsl,b.sjhmx
   ,case when a.sZy='门店自动采购订单(dzixun)' then '门店自动订单' 
	    when a.sZy='088 店自动采购订单(dzixun)' then 'DC自动订单' else '手工订单' end flag  from Wjlck.pos_2008.Pos_2008.t_cgdd a,
   Wjlck.pos_2008.Pos_2008.t_cgddmx b where a.scgddbh=b.scgddbh
   and  a.scgddbh>'20210801')
    select a.*,b.sFDBH smdbh,SUBSTRING(a.sjhmx, charindex('\' + b.sFdbh,a.sjhmx) + 4, 
   charindex('\', SUBSTRING(a.sjhmx + '\', charindex('\' + b.sFdbh,a.sjhmx) + 4, 
   LEN(a.sjhmx + '\')-(charindex('\' + b.sFdbh,a.sjhmx) + 3)))-1) as nsl_fd into #tmp_cgdd
	   from x0  a  left join dbo.Tmp_FDB b on 1=1  and   charindex('\'+b.sfdbh,isnull(a.sjhmx,a.sjhmx))>0  where   1=1;

	   with x0 as (
	   select * ,case  when CHARINDEX('F',a.nsl_fd)>0 then 
   substring(a.nsl_fd,0, CHARINDEX('F',a.nsl_fd) ) else a.nsl_fd end nsl_fd_new from #tmp_cgdd a )
	   select a.scgddbh,a.smdbh,a.sspbh,b.sSpmc,b.sFl,b.sPsfs,a.dDhsj,a.sgysbh,a.nsl_fd_new,a.szy from x0 a  
	   left  join  dbo.tmp_spb b on a.smdbh=b.sFdbh and a.sspbh=b.sSpbh 
	   where smdbh='002'

	     with x0 as (
	   select * ,case  when CHARINDEX('F',a.nsl_fd)>0 then 
   substring(a.nsl_fd,0, CHARINDEX('F',a.nsl_fd) ) else a.nsl_fd end nsl_fd_new from #tmp_cgdd a )
	   select a.scgddbh,a.smdbh,a.sspbh,b.sSpmc,b.sFl, a.dDhsj,a.sgysbh,a.nsl_fd_new,a.szy from x0 a  
	   left  join  dbo.Tmp_spb_All b on   a.sspbh=b.sSpbh 
	   where smdbh<>'002'  order by convert(float,a.nsl_fd_new) desc


	   ---------- 无底线降价
	 
-- drop table  #cx
select a.scxdbh,a.ssyfd,a.sKsrq,a.sjsrq,b.sspbh,b.ncxsj  into #cx from wjl.pos_2008.pos_2008.t_spcxd a,
wjl.pos_2008.pos_2008.t_cxdmx b where a.scxdbh=b.scxdbh 
and  a.sCxdbh  in ('202108060890002','202108100890009')

-- drop table #wdx_2
select a.sspbh,scxdbh,count(distinct b.sfdbh) nxsfds,sum(isnull(b.nXssl,0)) nxssl,sum(isnull(b.nXssl*b.nXsdj,0)) nxsje into #wdx_2 from #cx a 
left join dappsource_wjl.dbo.Tmp_Xsnrb b on a.sspbh=b.sSpbh and CONVERT(date,left(b.sxsdh,8))>=convert(date,a.sKsrq)
and CONVERT(date,left(b.sxsdh,8))<=convert(date,a.sjsrq) group by a.sspbh,a.scxdbh  order by  4 desc


select a.sspbh,c.sSpmc,a.scxdbh,c.nJj,c.nSj,a.ncxsj,a.sKsrq,a.sJsrq,b.nxssl,b.nxsje  from #cx a 
left join #wdx_2 b on a.sspbh=b.sspbh and a.scxdbh=b.scxdbh
left join dappsource_wjl.dbo.tmp_spb_all c on a.sspbh=c.sSpbh 
where 1=1  order by b.nxsje desc
 
 
 -- 本期和上期销售涨跌对比
 
 select CONVERT(date,right(a.taskId,8)) drq ,*,ROW_NUMBER()over(partition by sfdbh,sspbh order by CONVERT(date,right(a.taskId,8)) desc) npm into #xs_db
 from dbo.H_Dpzb a  where  right(a.taskId,8) >=CONVERT(varchar,GETDATE()-13,112);

  -- 门店下降的较快的
   with x0 as (
	select a.drq, a.sFdbh  ,COUNT(1) nts,COUNT(distinct a.sSpbh) npzs,sum(a.nXsje*1.0/30) nrjxse,sum(a.nml*1.0/30) nrjmle from #xs_db  a where sFdbh<>'002'
	group by a.drq,sFdbh)
	select a.drq,a.sFdbh,c.sFDMC,a.nts,a.npzs,a.nrjxse,a.nrjmle,b.drq,b.nts,b.npzs,b.nrjxse,b.nrjmle from x0 a 
	left join x0 b on a.sFdbh=b.sFdbh and a.drq<b.drq
	left join dbo.Tmp_FDB c on a.sFdbh=c.sFdbh
	where 1=1 and a.drq='2021-09-05' order  by (a.nrjxse-b.nrjxse)*1.0/a.nrjxse desc

	-- Step 大类下降较快的 drop table #xs_db
	with x0 as (
	select a.drq,LEFT(a.sPlbh,2) sdlbh,COUNT(1) nts,COUNT(distinct a.sSpbh) npzs,sum(a.nXsje*1.0/30) nrjxse,sum(a.nml*1.0/30) nrjmle from #xs_db  a where sFdbh<>'002'
	group by a.drq,LEFT(a.sPlbh,2))
	select a.drq,a.sdlbh,c.sflmc,a.nts,a.npzs,a.nrjxse,a.nrjmle,b.drq,b.nts,b.npzs,b.nrjxse,b.nrjmle from x0 a 
	left join x0 b on a.sdlbh=b.sdlbh and a.drq<b.drq
	left join dbo.tmp_spflb c on a.sdlbh=c.sflbh
	where 1=1 and a.drq='2021-09-05' order  by a.nrjxse-b.nrjxse desc

	-- Step 商品下降
		with x0 as (
	select a.drq,a.sspbh,a.sSpmc,max(a.sPlbh) sflbh,COUNT(1) nts, sum(a.nXsje) nrjxse,sum(a.nMl) nrjmle,ROW_NUMBER()over(partition by a.sspbh order by a.drq) npm  from #xs_db  a where sFdbh<>'002'
	group by a.drq,a.sspbh,a.sSpmc)
	select a.drq,a.sspbh,a.sSpmc,a.sflbh,c.sflmc,a.nts,a.nrjxse,a.nrjmle,b.nts,b.nrjxse,b.nrjmle from x0 a 
	left join x0 b on a.sSpbh=b.sSpbh and a.drq<b.drq
	left join dbo.tmp_spflb c on a.sflbh=c.sflbh
	where 1=1 and a.drq='2021-09-05' order  by a.nrjxse-b.nrjxse desc


	-- 品牌陈列毛利率和实际毛利率
	select * from dbo.Tmp_spb  a 
	left join dbo.R_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
	where a.brand='农夫山泉'


	select * from tmp_spb where sSpmc like '%农夫山泉%'
 

 select sQybh,sSpbh,sSpmc,nJhj,nLsj,(nLsj-nJhj)*1.0/nLsj nmll
 from DApplication.dbo.Base_Sp where  1=1 and sFlbh02 is not null  and sPp like '%农夫山泉%'


 ----
 -------- 实际上限天数  drop table #data1
select a.sFdbh,a.sSpbh,a.sSpmc,a.sLevel,a.sPlbh,a.nRjxl_De,a.nRjxse,a.nJyxx,a.nJysx,c.sPsfs,c.nJj,c.nSj ,a.nRjxl,
case when ISNULL(b.nSl,0)<0 then 0 else ISNULL(b.nSl,0) end nkcsl 
into #data1 from dbo.R_Dpzb a 
left join dbo.Tmp_Kclsb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.dRq=CONVERT(varchar,GETDATE()-1,23)+' 23:59:59.000'
 join dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
where 1=1 and c.sZdbh='1';

with x0 as (
select sum(a.nkcsl*a.nJj) nkcje,sum(a.nRjxl_De*a.nsj) nrjxse,sum(a.nJysx*a.nJj) nsxkcje from #data1 a  where a.sFdbh<>'002')
,x1 as (select a.spsfs, sum(a.nkcsl*a.nJj) nkcje,sum(a.nRjxl_De*a.nSj) nrjxse,sum(a.nJysx*a.nJj) nsxkcje from #data1 a  where a.sFdbh<>'002'
group by a.sPsfs)
select a.*,a.nkcje*1.0/a.nrjxse nzzts,a.nsxkcje*1.0/a.nrjxse nsxkcts from x1 a 
left join x0 b on 1=1
where 1=1 
union
select '',*,a.nkcje*1.0/a.nrjxse nzzts,a.nsxkcje*1.0/a.nrjxse nsxkcts  from x0 a;


with x0 as (
select sum(a.nkcsl*a.nJj) nkcje,sum(a.nRjxl_De*a.nsj) nrjxse,sum(a.nJysx*a.nJj) nsxkcje from #data1 a  where a.sFdbh<>'002')
,x1 as (select a.sLevel, sum(a.nkcsl*a.nJj) nkcje,sum(a.nRjxl_De*a.nSj) nrjxse,sum(a.nJysx*a.nJj) nsxkcje from #data1 a  where a.sFdbh<>'002'
group by a.sLevel)
select a.*,a.nkcje*1.0/a.nrjxse nzzts,a.nsxkcje*1.0/a.nrjxse nsxkcts from x1 a 
left join x0 b on 1=1
where 1=1 
union
select '',*,a.nkcje*1.0/a.nrjxse nzzts,a.nsxkcje*1.0/a.nrjxse nsxkcts  from x0 a  order by 2;


with x0 as (
select sum(a.nkcsl*a.nJj) nkcje,sum(a.nRjxl_De*a.nsj) nrjxse,sum(a.nJysx*a.nJj) nsxkcje from #data1 a  where a.sFdbh<>'002')
,x1 as (select a.sLevel,a.sPsfs, sum(a.nkcsl*a.nJj) nkcje,sum(a.nRjxl_De*a.nJj) nrjxse,sum(a.nJysx*a.nJj) nsxkcje from #data1 a  where a.sFdbh<>'002'
group by  a.sLevel,a.sPsfs with rollup )
select a.*,a.nkcje*1.0/a.nrjxse nzzts,a.nsxkcje*1.0/a.nrjxse nsxkcts from x1 a 
left join x0 b on 1=1
where 1=1 
union
select '','',*,a.nkcje*1.0/a.nrjxse nzzts,a.nsxkcje*1.0/a.nrjxse nsxkcts  from x0 a  order by 2;
 


with x0 as (
select sum(a.nkcsl*a.nJj) nkcje,sum(a.nRjxl_De*a.nsj) nrjxse,sum(a.nJysx*a.nJj) nsxkcje from #data1 a  where a.sFdbh<>'002'
and a.sPsfs='越库' and a.sLevel='C')
,x1 as (select a.sSpbh+sSpmc sspbh, sum(a.nkcsl*a.nJj) nkcje,sum(a.nRjxl_De*a.nJj) nrjxse,sum(a.nJysx*a.nJj) nsxkcje from #data1 a  where a.sFdbh<>'002' and a.sPsfs='越库' and a.sLevel='C'
group by a.sSpbh+sSpmc)
select a.*,case when a.nrjxse=0 then 300 else  a.nkcje*1.0/a.nrjxse end nzzts,case when a.nrjxse=0 then 300 else 
a.nsxkcje*1.0/a.nrjxse end  nsxkcts from x1 a 
left join x0 b on 1=1
where 1=1 

--------企业商品重合度
select distinct  a.sspbh,a.sSpmc  into #btsp
from  dbo.R_Dpzb a
where a.sPlbh not in (select sFlbh from dbo.Tmp_Spflb_Ex) 
and   a.sSpbh not in (select sSpbh from dbo.tmp_spb_ex)
 
 with x0 as(
 select b.sFdbh,a.*  from #btsp a ,(select distinct sfdbh from r_dpzb)b)
 select a.sFdbh,c.sFDMC,sum(case when b.sFdbh is not null then 1 else 0 end ) nfdsps,COUNT(distinct a.sSpbh) nzsps,
 sum(case when b.sFdbh is not null then 1 else 0 end )/COUNT(distinct a.sSpbh)   from x0 a 
 left join R_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
 left join Tmp_FDB c on a.sFdbh=c.sFDBH
 where 1=1 group by a.sFdbh,c.sFDMC order by 5 


 
 -- 从商品上架率管理里面区
 insert into DAppSource_WJL.dbo.R_recommond_sp(sSpbh,dcreate_date,sResource)
 select distinct  sSpbh,convert(date,dSjDate),'好品上架' from dbo.T_Spsj_result_in
 where 1=1 and dSjDate>'2022-03-01'
 and sSpbh not in(select sSpbh  from dbo.R_recommond_sp )  

  -- 用 index_sp 表匹配
  insert into  dbo.R_recommond_spmx(sSpbh,sfdbh,d_into_date) 
  select a.sSpbh,a.sfdbh,a.IntoDate  from 
  (select a.sSpbh,b.sfdbh,b.IntoDate,a.sResource,b.OutDate  
  from  R_recommond_sp a, dbo.Index_Sp b where a.sSpbh=b.sspbh  and (b.IntoDate
  >a.dcreate_date   )) a
 left join  dbo.R_recommond_spmx b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
 where b.sfdbh is null;
-- 选品因素初始化
insert into BD_Flys_Value(sSpbh,sQybh,sFlys,sYsValue_V) 
select distinct sSpbh,a.sQybh,sFlys,sYsValue_V from Xp_BD_Flys_Value_All a
join BD_Flb b on a.sFlbh=b.sFlbh
where sFlys<>'档次'


---  不动销天数
select * into #Tmp_dpzb
 from [122.147.10.202].dappresult.dbo.r_dpzb where sfdbh='018425';


 with x0 as (
select a.dYhrq,b.ddhrq dShrq,a. sdjlx sLx,b.sfdbh,b.sspbh,b.nsl nYhsl,b.ndhsl,b.sBzmx
from [122.147.10.200].dappsource.dbo.tmp_yhb a 
inner join [122.147.10.200].dappsource.dbo.tmp_yhmx b
on a.sdh=b.sdh and a.sFdbh=b.sFdbh
where 1=1  and a.dYhrq>=CONVERT(date,GETDATE()-180) 
and (  a.dYhrq+2<GETDATE() or b.ddhrq is not null) and a.sfdbh='018425')
,x1 as (select a.* from  x0 a 
where  1=1 )
select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id 
into #Tmp_yh 
from x0 a ;




select a.sfdbh,a.sspbh,a.splbh,e.sflmc,a.sspmc,case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,c.scgqy,b.RETURN_ATTRIBUTE,a.nrjxl,a.nbdxts,d.nkcsl,d.nkcje,b.STOP_INTO,
f.dyhrq,f.dShrq,
case  when a.nrjxl=0 then 1000  when a.nrjxl>0 and  d.nkcsl/a.nrjxl>=1000 then 1000 else  d.nkcsl/a.nrjxl    end nzzts
,case  when a.nrjxl=0 then 'bdx'  else '90天以上'  end  sflag  from  #Tmp_dpzb a 
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on a.sfdbh=b.DEPT_CODE and a.sspbh=b.ITEM_CODE
join DappSource_Dw.dbo.goods c on a.sspbh=c.code
left join DappSource_Dw.dbo.tmp_kclsb d on a.sfdbh=d.sfdbh and a.sspbh=d.sspbh and d.drq=CONVERT(date,GETDATE()-1)
left join DappSource_Dw.dbo.tmp_spflb e on a.splbh=e.sflbh
left join #Tmp_yh f on a.sfdbh=f.sfdbh and a.sspbh=f.sspbh and f.id=1
where 1=1 and (a.nbdxts>40  or (a.nrjxl>0 and d.nkcsl/a.nrjxl>90)) and   (( c.sort>'20' and c.sort<'40') or (
LEFT(c.sort,4) in ('1105','1307','1406') ))
and LEFT(c.sort,4)<>'2201' and b.CHARACTER_TYPE='N' and d.nkcsl>0  and b.STOP_INTO='N'
order by d.nkcje desc ;

select * from #Tmp_yh

--------  quyu maol
select a.*,case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,c.scgqy  into #1 from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on a.SHOP_CODE=b.DEPT_CODE and a.ITEM_CODE=b.ITEM_CODE
join DappSource_Dw.dbo.goods c on a.ITEM_CODE=c.code
where a.SHOP_CODE='018425' and  b.CHARACTER_TYPE='N'
and  CONVERT(date,a.SALE_DATE)>=CONVERT(date,GETDATE()-30) and CONVERT(date,a.SALE_DATE)<CONVERT(date,GETDATE())
and   ((  c.sort<'40') or (
LEFT(c.sort,4) in ('1105','1307','1406') ))
and LEFT(c.sort,4)<>'2201';

select a.scgqy,sum(a.SALE_AMOUNT) nxsje,sum(a.SALE_COST) nxscb,sum(a.SALE_AMOUNT-SALE_COST) nxsml
 from #1  a
 group by a.scgqy;



-------
