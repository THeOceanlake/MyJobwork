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



-------------  以下是BI报表参数
select '','全部' union
select distinct slx,slx from   dappsource.dbo.Tmp_fdb_sx 


select CONVERT(date,''),'全部' union
select distinct dsxdate,convert(varchar(30),dsxdate,112) from   dappsource.dbo.Tmp_fdb_sx 