 
-- 
select  * from  TMP_Measures_list

select * from dbo.Tmp_Md_Sptz

-- 1 门店大调整
insert into Tmp_Measures_list(Measure_name,Measure_batch,CreateTime,sFdbh,sSpbh,sSpmc,sAdvice)
select '门店大调整','文创店0325大调整',CONVERT(datetime,'2022-03-25'),分店编号,商品编号,商品名称,建议
 from   dbo.Tmp_Md_Sptz


-- 2 高库存处理

select * into #tmp_mdspzz from  master.dbo.TMP_ZZ_0331 where drq=CONVERT(date,'2022-04-18')
and syy<>'新品';

select   * into #badgoods1 from  [122.147.10.200].DAppSource.dbo.BadStock_Goods_His
where CalDate='2022-04-18';

select * into #Allot_Jhmx_CS from [122.147.10.200].DAppSource.dbo.Allot_Jhmx_CS

select * into #Allot_Jhzd_CS from [122.147.10.200].DAppSource.dbo.Allot_Jhzd_CS

select * into #BadStock_Notice_CS from [122.147.10.200].DAppSource.dbo.BadStock_Notice_CS

select * into #BadStock_Notice_Items_CS from [122.147.10.200].DAppSource.dbo.BadStock_Notice_Items_CS

select * from #badgoods1 a 
join #tmp_mdspzz b on a.sfdbh=b.sFdbh and a.sspbh=b.sSpbh
where 1=1

insert into Tmp_Measures_list(Measure_name,Measure_batch,CreateTime,sFdbh,sSpbh,sSpmc,sAdvice)
select '高库存处理','20220418期',a.dcreatedate,b.sfdbh_output,b.sSpbh,c.name,'门店间调拨' from #Allot_Jhzd_CS a
join  #Allot_Jhmx_CS  b on a.sjhdh=b.sjhdh
 left join dbo.goods c on b.sspbh=c.code
where 1=1;


insert into Tmp_Measures_list(Measure_name,Measure_batch,CreateTime,sFdbh,sSpbh,sSpmc,sAdvice)
select  '高库存处理','20220418期',a.dThrq,a.sfdbh,b.sSpbh,c.name,a.sLx from #BadStock_Notice_CS a 
left join #BadStock_Notice_Items_CS b on  a.sdh=b.sdh 
 left join dbo.goods c on b.sspbh=c.code
 left join Tmp_Measures_list d on  a.sfdbh=d.sfdbh and b.sspbh=d.sspbh
 where 1=1  and d.sfdbh is null

--- 90天处理方案处理
  select '1月' smonth,convert(date,'2022-01-01') Bdate,dateadd(day,-1,CONVERT(date,'2022-04-01')) edate into #Tmp_time union
select '2月' smonth,convert(date,'2022-02-01') ,dateadd(day,-1,CONVERT(date,'2022-05-01'))
union
select '3月' smonth,convert(date,'2022-03-01') ,dateadd(day,-1,CONVERT(date,'2022-06-01'))
union
select '4月' smonth,convert(date,'2022-04-01') ,dateadd(day,-1,CONVERT(date,'2022-07-01'))
;


insert into Tmp_Measures_list(Measure_name,Measure_batch,CreateTime,sFdbh,sSpbh,sSpmc,sAdvice)
select '停购商品90天处理方案',a.清理计划时间,b.Bdate,a.sFdbh,a.sspbh,a.sspmc,'90天促销' from   DappSource_Dw.dbo.Tmp_dr_0419 a
join #Tmp_time b on a.清理计划时间=b.smonth
 