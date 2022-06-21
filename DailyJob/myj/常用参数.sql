-- 100 地址 Dappsource库
--1、 试点门店范围
select * from dbo.Tmp_FDB where binglang_state  =1 or  lengcang_state=1 or  hongbei_state=1;
-- 自动商品范围
select sFdbh,sSpbh from dbo.Sys_GoodsConfig where sSfkj='1';

-- 2、定额数据，每天晚上计算，截至日期是前一天，取日均销量，建议上下限，捕获率
-- 分店，商品，下限，上限,品类，截至日期，定额，捕获率
select sFdbh,sSpbh,nJyxx,nJysx,sPslx,srq,nRjxl_De,a.DE_BHL from  Sys_GoodsConfig_his  a
where  1=1 and CONVERT(date,djssj)=CONVERT(date,GETDATE()-1);
-- 3、门店实时库存或昨日期末库存取值的地方
select * from dbo.Tmp_Kclsb where drq=CONVERT(date,GETDATE()-1); 
-- 4、自动补货原始单：含系统原始量，若有人工修改量，记录人工修改量
select * from  Purchase_DeliveryReceipt a,Purchase_DeliveryReceipt_Items b 
where a.sDh=b.sDh and a.sFdbh=b.sFdbh;
-- 5、门店品类自动补货上线时间
select * from dbo.Tmp_fdb_sx 

--  6 门店物流线路表
select *,sXl from dbo.Tmp_fdb_FB
 left join dbo.Tmp_fdb_sx  d on a.sfdbh=d.sfdbh and case when left(a.sFl,2)='06' then '烘焙' when left(a.sFl,2)='15' then '冷藏' 
when left(a.sFl,2)='33' then '槟榔'  end =d.slx

-- 7  门店基本信息+新增 城市，大区 ，商圈
select * from dbo.Tmp_FDB

-- 8 取昨日期末库存
select * from Tmp_Kclsb where convert(date,drq)=CONVERT(date,GETDATE()-1);
-- 9 取实时库存?
select * from Tmp_Kcb;

-- 10 取模板商品
select * from dbo.Tmp_mbsp ;

-- 11 计算参数
 select * from dappsource.dbo.tmp_cgsp_hb where sFdbh='粤11741' and  sSpbh='2049182' 

-- 计算库存和期末库存的差异
 select a.sFdbh,a.sSpbh,max(c.sSpmc),a.dDDr,a.nddrkc,max(d.nSl) nqmkc,a.nzt,a.nRjxl,a.nJysx,a.nJyxx,a.nYhsl,a.DE_BHL,sum(b.nXssl) nxssl
 from dappsource.dbo.tmp_cgsp_hb a
 left join  DAppSource.dbo.Tmp_Xsnrb b on a.sFdbh=b.sFdbh  and a.sSpbh=b.sSpbh
 and b.dUpdateTime>=CONVERT(date,GETDATE() )
 left join DAppSource.dbo.Tmp_spb_All c on a.sSpbh=c.sSpbh
 left join DAppSource.dbo.Tmp_Kclsb d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh and CONVERT(date,d.dRq)=CONVERT(date,GETDATE()-1)
 where a.sFdbh='粤11963' and  a.sSpbh='1171831'  and a.dDDr=CONVERT(date,GETDATE() )
 group by a.sFdbh,a.sSpbh,a.dDDr,a.nddrkc,a.nzt,a.nRjxl,a.nJysx,a.nJyxx,a.nYhsl,a.DE_BHL


 select a.sFdbh 分店,a.sSpbh 商品 ,max(c.sSpmc) 商品名称,dateadd(day,-1,a.dDDr) 计算日,a.nddrkc 计算时库存,
 max(d.nSl) 期末库存,a.nzt 在途量,a.nRjxl 日均销量,a.nJysx 定额上限,a.nJyxx 定额下限,a.nYhsl 要货量
 ,a.DE_BHL  捕获率,sum(b.nXssl) 昨日销售量
 from dappsource.dbo.tmp_cgsp_hb a
 left join  DAppSource.dbo.Tmp_Xsnrb b on a.sFdbh=b.sFdbh  and a.sSpbh=b.sSpbh
 and b.dUpdateTime>=CONVERT(date,GETDATE() )
 left join DAppSource.dbo.Tmp_spb_All c on a.sSpbh=c.sSpbh
 left join DAppSource.dbo.Tmp_Kclsb d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh and CONVERT(date,d.dRq)=CONVERT(date,GETDATE()-1)
 where a.sFdbh='粤11963' and  a.sSpbh='1171831'  and a.dDDr=CONVERT(date,GETDATE() )
 group by a.sFdbh,a.sSpbh,a.dDDr,a.nddrkc,a.nzt,a.nRjxl,a.nJysx,a.nJyxx,a.nYhsl,a.DE_BHL

-------------  以下是BI报表参数
select '','全部' union
select distinct slx,slx from   dappsource.dbo.Tmp_fdb_sx 


select CONVERT(date,''),'全部' union
select distinct dsxdate,convert(varchar(30),dsxdate,112) from   dappsource.dbo.Tmp_fdb_sx 


 select a.sFdbh,a.sSpbh,max(c.sSpmc),a.dDDr,a.nddrkc,max(d.nSl) nqmkc,a.nzt,a.nRjxl,a.nJysx,a.nJyxx,a.nYhsl,a.DE_BHL,sum(b.nXssl) nxssl
 from dappsource.dbo.tmp_cgsp_hb a
 left join  DAppSource.dbo.Tmp_Xsnrb b on a.sFdbh=b.sFdbh  and a.sSpbh=b.sSpbh
 and b.dUpdateTime>=CONVERT(date,GETDATE() )
 left join DAppSource.dbo.Tmp_spb_All c on a.sSpbh=c.sSpbh
 left join DAppSource.dbo.Tmp_Kclsb d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh and CONVERT(date,d.dRq)=CONVERT(date,GETDATE()-1)
 where a.sFdbh='8108' and  a.sSpbh='1177875'   
 group by a.sFdbh,a.sSpbh,a.dDDr,a.nddrkc,a.nzt,a.nRjxl,a.nJysx,a.nJyxx,a.nYhsl,a.DE_BHL

 select * from DAppSource.dbo.Tmp_Xsnrb a 
  where a.sFdbh='粤23600' and  a.sSpbh='2100353'  and a.dUpdateTime>CONVERT(date,GETDATE())

  select a.sSpbh,b.sSpmc,sum(b.nRjxl_De) nrjxl,COUNT(1) nfds from DAppSource.dbo.R_Sjycsp a
    join DAppSource.dbo.R_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
  where 1=1  and a.sLx in ( '销售异常' ) and b.sPlbh like '06%'
  group by a.sSpbh,b.sSpmc order by 4 desc


    select a.sFdbh, sum(b.nRjxl_De) nrjxl,sum(b.nRjxl_De*b.nJhj)  from DAppSource.dbo.R_Sjycsp a
    join DAppSource.dbo.R_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
	join  DAppSource.dbo.Sys_GoodsConfig c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.sSfkj='1'
  where 1=1  and a.sLx in ( '销售异常' ) and b.sPlbh like '06%'
  group by a.sfdbh order by 2 desc


   select a.sFdbh, a.sSpbh,b.sSpmc, b.nRjxl_De ,b.nRjxl_De*b.nJhj nrjxse from DAppSource.dbo.R_Sjycsp a
    join DAppSource.dbo.R_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
	join  DAppSource.dbo.Sys_GoodsConfig c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.sSfkj='1'
  where 1=1  and a.sLx in ( '销售异常' ) and a.sFdbh='M031' and b.sPlbh like '06%'
   order by 4 desc

    select  * into #1 from DAppSource.dbo.H_Sjycsp where RIGHT(TaskID,8) in ('20220603','20220529')
   and slx='销售异常'


       select  RIGHT(a.TaskID,8) drq,COUNT(distinct a.sFdbh) nfds,sum(b.nRjxl_De*b.nJhj) nrjxse
	   from #1 a
    join DAppSource.dbo.H_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and a.TaskID=b.TaskID
	join  DAppSource.dbo.Sys_GoodsConfig c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.sSfkj='1'
  where 1=1  and a.sLx in ( '销售异常' ) and b.sPlbh like '06%'
  group by RIGHT(a.TaskID,8)order by 1 desc

  select    right(TaskID,8),COUNT(1) from #1  group by RIGHT(Taskid,8)

  select * from #1
  
   select '20220603'计算批次,COUNT(distinct a.sFdbh) 销售异常门店数,COUNT(1) 异常条数,sum(b.nRjxl_De*b.nJhj) 销售异常总日均销售额 from DAppSource.dbo.R_Sjycsp a
    join DAppSource.dbo.R_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
	join  DAppSource.dbo.Sys_GoodsConfig c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.sSfkj='1'
  where 1=1  and a.sLx in ( '销售异常' )   and b.sPlbh like '06%' 
  union
        select  RIGHT(a.TaskID,8) drq,COUNT(distinct a.sFdbh) nfds,COUNT(1),sum(b.nRjxl_De*b.nJhj) nrjxse
	   from #1 a
    join DAppSource.dbo.H_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and a.TaskID=b.TaskID
	join  DAppSource.dbo.Sys_GoodsConfig c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.sSfkj='1'
  where 1=1  and a.sLx in ( '销售异常' ) and b.sPlbh like '06%'
  group by RIGHT(a.TaskID,8)order by 1 desc