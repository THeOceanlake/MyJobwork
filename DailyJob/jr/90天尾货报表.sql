select * into #Tmp_TailCargo from [122.147.160.31].DappSource_Dw.dbo.Tmp_TailCargo;

with x0 as (
select smonth,max(drq) drq from [122.147.160.31].DappSource_Dw.dbo.Tmp_TailCargo_suggest
group by smonth)
select * into #Tmp_TailCargo_suggest from [122.147.160.31].DappSource_Dw.dbo.Tmp_TailCargo_suggest a 
x0 b where a.smonth=b.smonth and a.drq=b.drq

select a.*,b.drq,c.SHIFT_PRICE nPsj,c.RETAIL_PRICE nLsj,b.nqckc,b.nDqkc,b.nDays_remaining,b.ndays_already,b.szt,b.nsjjd,b.nkccljd,b.ncxj_last,
b.ncxj_suggest,b.ssftj into #1 from #Tmp_TailCargo a 
left join #Tmp_TailCargo_suggest b on a.sMonth=b.sMonth and a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
left join [122.147.160.31].DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT c on a.sfdbh=c.DEPT_CODE and a.sspbh=c.ITEM_CODE
where 1=1  ;

select a.smonth 计划批次,a.Bdate 计划开始日期,a.Edate 计划结束日期,a.sfdbh 分店编号,a.sfdmc 分店名称,
a.sspbh 商品编号
,a.sspmc 商品名称,a.ntjj 特进价,a.sManager 采购经理,a.drq 计算日期,a.nPsj 配送价,a.nLsj 零售价,a.nqckc 期初库存数量
,a.nDqkc 当前库存数量,a.nDays_remaining 方案剩余天数,a.ndays_already 已过天数,a.szt 当前状态,
a.nsjjd 时间进度,a.nkccljd 库存处理进度,a.ncxj_last 最后促销价,a.ncxj_suggest加个建议,a.ssftj 是否需要调价进入下一阶段
 from #1  a