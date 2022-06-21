select 分店编号 sfdbh,商品编号 sspbh,商品名称 sspmc,convert(date,'2022-03-25') spc into #1 
from DappSource_Dw.dbo.Tmp_Md_Sptz a 
join DappSource_Dw.dbo.goods b on a.商品编号=b.code where 建议='建议引进'
and 商品编号 not in (22060171,22060174,23012425,07021299,32011103,24041721,32020231,25030491,22020139,
 23021839,24042021,25041288,25022494,25041284,23050235,58010218,31060346,24041716,24041714,25041419,
 24042201,24060132,30010355,25041418,23060205,23060003,24060028,57020538,06010363,23060206,24060036,
 75060219,06010102,06010103,06010407,24060034,23060029,06010300,06010329,24042018,30010354,46010094,
 24042017) and  ; 


 select * from  [122.147.10.202].DAppResult.dbo.R_Jyttsp where sfdbh='018425';


select * from  [122.147.10.202].DAppResult.dbo.R_Jythsp where sfdbh='018425'

-- 销售
select * from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT

-- 停购有库存商品清理进度
-- Step 0 :取一段时间内的所有数据
select * into #Tmp_StopList from Tmp_StopList  a  
where a.drq>=CONVERT(date,GETDATE()-30) and a.drq<CONVERT(date,GETDATE());

-- Step 1：前后两天的数据对比：新增商品数，退出商品数，总库存金额 -- drop table #r
select ISNULL(b.drq,DATEADD(day,1,a.drq)) drq,  ISNULL(b.sFdbh,a.sFdbh) sFdbh,ISNULL(b.sSpbh,a.sSpbh) sSpbh,
 b.nkcje,case when  ISNULL(a.nKcsl,0)>0 and ISNULL(b.nKcsl,0)<=0 then 'down' 
 when  ISNULL(a.nKcsl,0)<=0 and ISNULL(b.nKcsl,0)>0 then 'new' else 'old' end  sflag  into #r   from #Tmp_StopList a  
full join #Tmp_StopList b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and DATEDIFF(DAY,a.drq,b.drq)=1
	and  a.drq>=CONVERT(date,'2022-05-28')  and b.drq<CONVERT(date,GETDATE())
	and DATEADD(day,1,a.drq)<CONVERT(date,GETDATE())
where 1=1  ;

select a.drq,a.sFdbh,count(1) ntgsps,sum(a.nkcje) nKcje,sum(case  when a.sflag='down' then 1 end ) ntcsl,
sum(case when a.sflag='new' then 1 else 0 end ) nxzsl,sum(case when a.sflag='old' then 1 end ) nbl from #r a  
where a.drq<CONVERT(date,GETDATE()) group by a.drq,a.sFdbh
order by a.drq;



-------------
select t.*,
(select sum(nxssl) from [122.147.10.200].dappsource.dbo.tmp_xs where sspbh=t.item_code and drq >=t.rksj and sfdbh=t.dept_code)
from
(select a.*,
 ( select min(drq) from tmp_kclsb where drq>a.c_introduce_date and sspbh=a.item_code  and nkcsl<>0 and sfdbh='018425') rksj
  from  [122.147.10.200].dappsource.dbo.p_shop_item_output a where a.dept_code='018425'
 and a.c_introduce_date>= DATEADD(day, -90, GETDATE()) 
 and a.stop_into='N' and a.stop_sale='N')t 


select  * into #tmp_xs from [122.147.10.200].dappsource.dbo.tmp_xs where   sfdbh='018425'
and  drq>= CONVERT(date,GETDATE()-90);

with x0 as(
select a.DEPT_CODE,a.ITEM_CODE, 
min(case when b.drq is not null then b.drq else a.c_introduce_date end) drksj
 from   DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT a 
left join DappSource_Dw.dbo.tmp_kclsb b on a.dept_code=b.sfdbh and a.ITEM_CODE=b.sspbh and b.nkcsl<>0 
where 1=1 and  a.dept_code='018425'  and a.c_introduce_date>= DATEADD(day, -90, GETDATE()) 
 and a.stop_into='N' and a.stop_sale='N'
 group by a.DEPT_CODE,a.ITEM_CODE)
 select a.*,sum(b.nXssl) nxssl_45,sum(c.nXssl) nxssl from x0  a 
 left join  #tmp_xs b on a.dept_code=b.sfdbh and a.ITEM_CODE=b.sSpbh and b.drq>=dateadd(day,45,a.drksj)
 left join #tmp_xs c on a.dept_code=c.sfdbh and a.ITEM_CODE=c.sSpbh and c.drq>=a.drksj
 where 1=1  group by a.DEPT_CODE,a.ITEM_CODE,a.drksj;



select ISNULL(b.drq,DATEADD(day,1,a.drq)) drq,  ISNULL(b.sFdbh,a.sFdbh) sFdbh,ISNULL(b.sSpbh,a.sSpbh) sSpbh,
 b.nkcje,case when  ISNULL(a.nKcsl,0)>0 and ISNULL(b.nKcsl,0)<=0 then 'down' 
 when  ISNULL(a.nKcsl,0)<=0 and ISNULL(b.nKcsl,0)>0 then 'new' else 'old' end  sflag  into #r   from #Tmp_StopList a  
full join #Tmp_StopList b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and DATEDIFF(DAY,a.drq,b.drq)=1
	and  a.drq>=CONVERT(date,'2022-05-28')  and b.drq<CONVERT(date,GETDATE())
	and DATEADD(day,1,a.drq)<CONVERT(date,GETDATE())
where 1=1  ;


-- Step 1: 基础数据准备
-- drop table #raw_sp
select a.sMonth,a.Bdate,a.Edate,a.sFdbh,a.sFdmc,a.sSpbh,a.sSpmc,a.sgys,a.sgysmc into #raw_sp  
from DappSource_Dw.dbo.Tmp_TailCargo a where 1=1 and a.sUpdate is null; 

 
-- Step 3:基础数据准备
-- drop table #1;
select a.sFdbh sFdbh,a.sFdmc sFdmc,a.sSpbh sSpbh,a.sSpmc sSpmc,a.smonth,a.Bdate,a.Edate,
b.SHOP_SUPPLIER_CODE sgys,b.SHIFT_PRICE njj,b.RETAIL_PRICE nsj,
case when b.SEND_CLASS_T='01' then '配送' when b.SEND_CLASS_T='02' then '直送'
when b.SEND_CLASS_T='03' then '一步越库' when b.SEND_CLASS_T='04' then '二步越库' end spsfs,
b.stop_into,b.stop_sale,b.VALIDATE_FLAG,b.character_Type,b.min_purchase_qty nPsbzs
,b.c_disuse_date,b.c_introduce_date,b.return_attribute,b.DisPlay_mode  into #1
from  #raw_sp  a 
left join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT  b on b.DEPT_CODE=a.sFdbh and b.ITEM_CODE=a.sSpbh 
where 1=1   and ( b.STOP_INTO<>'N' or b.STOP_INTO is null) ;



select a.sMonth,a.Bdate,a.Edate,
max(DATEDIFF(day,a.bdate,a.Edate)),
max(DATEDIFF(day,a.bdate,convert(date,getdate()))),COUNT(1) ,COUNT(distinct sFdbh) nfds,COUNT(distinct sSpbh) nsps
 from #1  a 
where 1=1  group by a.sMonth,a.Bdate,a.Edate
order by a.sMonth






--------0620 草稿
select * into #tmp_cql   FROM [122.147.10.200].Source_His.dbo.Shop_Cqlnew  where  srq>='2022-05-20' and convert(date,srq)>=convert(date,getdate()-30)
and sfdbh='018425';
SELECT convert(date,srq,23) 日期,CONVERT(MONEY,SUM(ncxqhs))/SUM(ncxsps) 畅缺率 FROM  #tmp_cql  
     WHERE  1=1
     GROUP BY convert(date,srq,23)   order by 1;

-- 修改
select * into #tmp_cql   FROM [122.147.10.200].Source_His.dbo.Shop_Cqlnew a
where  srq>='2022-05-20' and convert(date,srq)>=convert(date,getdate()-30)
#Params# ;
SELECT convert(date,srq,23) drq,a.sFdbh,CONVERT(MONEY,SUM(ncxqhs))/SUM(ncxsps) ncql 
into #cql1
FROM  #tmp_cql  
WHERE  1=1
GROUP BY convert(date,srq,23),a.sFdbh ;

select convert(varchar(30),a.drq) 日期,avg(a.ncql) 畅缺率  from #cql1 a 
group by  a.drq  order by 1;



select CONVERT(date,a.SALE_DATE) 日期,sum(a.SALE_AMOUNT) 销售金额,sum(a.SALE_COST) 销售成本,sum(a.SALE_AMOUNT-a.SALE_COST) 销售毛利,
sum(a.SALE_AMOUNT-a.SALE_COST)/sum(a.SALE_AMOUNT) 毛利率 from [122.147.160.31].DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
join [122.147.160.31].DappSource_Dw.dbo.goods d on a.ITEM_CODE=d.code
where a.SHOP_CODE in ('018425')   and CONVERT(date,a.SALE_DATE)>=CONVERT(date,getdate()-60)  and 
(( d.sort>'20' and d.sort<'40') or (
LEFT(d.sort,4) in ('1105','1307','1406') )) and LEFT(d.sort,4)<>'2201'
group by CONVERT(date,a.SALE_DATE)  order by 1


select CONVERT(date,a.SALE_DATE) drq,a.SHOP_CODE sFdbh,sum(a.SALE_AMOUNT) nXsje,
sum(a.SALE_COST) nXscb,sum(a.SALE_AMOUNT-a.SALE_COST) nXsmle,
case when sum(a.SALE_AMOUNT)<=0 then  0 else 
 sum(a.SALE_AMOUNT-a.SALE_COST)/sum(a.SALE_AMOUNT) end  nmll  into #cwpmll
from [122.147.160.31].DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
join [122.147.160.31].DappSource_Dw.dbo.goods d on a.ITEM_CODE=d.code
where a.SHOP_CODE in ('012006','012007','018329','018389','018425')  
 and CONVERT(date,a.SALE_DATE)>=CONVERT(date,getdate()-60)  and 
(( d.sort>'20' and d.sort<'40') or (
LEFT(d.sort,4) in ('1105','1307','1406') )) and LEFT(d.sort,4)<>'2201'
group by CONVERT(date,a.SALE_DATE),a.SHOP_CODE ;

Select convert(varchar(30),a.drq) 日期,avg(a.nxsje) 销售金额,avg(a.nxscb) 销售成本,avg(a.nXsmle) 毛利额,
avg(a.nmll) 毛利率 from #cwpmll a 
where 1=1  group by  a.drq order by 1


-- 草稿数据
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


-- 在嘉荣更新零库存 进出原因
-- 因为嘉荣的历史定额是能够取到的，需要最后一次进出记录大于当天定额的30%，且在最后一次有效订货日之后
update a set a.syy=b.sJcfl from #mdlkcsp a 
join #jcmx0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
--left join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
left join DappSource_Dw.dbo.Tmp_zhdhr d on a.sFdbh=d.sfdbh and a.sSpbh=d.sspbh
left join dbo.SYS_DELIVERYSET e on a.sFdbh=e.sfdbh and a.sSpbh=e.sSpbh and CONVERT(date,b.dsj)=CONVERT(date,e.Drq)
where  abs(b.nsl)>=e.nSx*0.3   and b.nSl<-2 and ( b.dsj>=d.drq or d.drq is null) and b.dsj>=GETDATE()-7;


-- 在JR可以利用定额历史表进行判定

update a set  a.syy= case  when d.sFdbh is not null then  '系统定额不足' else '暂不下单' end   from  #mdlkcsp a 
left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
left join dbo.SYS_DELIVERYSET d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh 
		and (a.dzhxtxdr=d.Drq  or d.Drq=GETDATE()-5 ) 
where 1=1  and   len(a.syy)=0  and  a.sZdbh=1   and b.sfdbh is null;