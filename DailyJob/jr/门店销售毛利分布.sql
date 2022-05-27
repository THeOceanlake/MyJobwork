/*
    目的是 根据门店的日结销售的实际毛利率，与20%的标准线，对比，
    分析毛利率分布的区间以及低毛利的单品
    PS 如果只有成本，无销售金额，则是-100%，损失的毛利额则是成本
*/
--
select * from dbo.P_RETAIL_DETAIL_OUTPUT a 
where a.SHOP_CODE='018425' and  a.ITEM_CODE='22030349';

select a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,SUM(a.SALE_REAL_QTY) nXssl,sum(a.SALE_COST) nXscb,
sum(a.SALE_AMOUNT) nxsje into #1  from P_SALE_TOTAL_LIST_OUTPUT   a
where a.SHOP_CODE='018425' and  CONVERT(date,a.SALE_DATE)>=CONVERT(date,'2022-04-21')
and  CONVERT(date,a.SALE_DATE)<=CONVERT(date,'2022-05-21')
group by  a.SHOP_CODE  ,a.ITEM_CODE  ;

select a.*,case when isnull(a.nxsje,0)<=0  and  ISNULL(a.nXscb,0)=0 then 0
when  isnull(a.nxsje,0)=0  and  ISNULL(a.nXscb,0)>0 then -1 
when  isnull(a.nxsje,0)>0  then (isnull(a.nxsje,0)-isnull(a.nXscb,0))*1.0/isnull(a.nxsje,0)   end nmll,0.2 nbzmll
into #2    from  #1  a 
where ISNULL(a.nXscb,0)>=0;


-- drop table #3
select a.*,b.SHIFT_PRICE,b.RETAIL_PRICE,a.nXssl*b.RETAIL_PRICE nyqxse,
case when a.nXssl=0 then 0 else  a.nXssl*b.RETAIL_PRICE-a.nXscb end nyqmle
, case when a.nXssl=0 then 0 else  a.nXssl*b.RETAIL_PRICE end-a.nxsje+a.nXscb nysmle  ,
 floor(cast(ROUND(a.nmll-a.nbzmll,2) as numeric(8,2))/0.05) nqj into #3
 from  #2 a  
left join P_SHOP_ITEM_OUTPUT b on a.sFdbh=b.DEPT_CODE and a.sSpbh=b.ITEM_CODE
where 1=1;

select a.sFdbh,a.sSpbh,c.name sspmc,d.sflbh,d.sflmc,a.SHIFT_PRICE,a.RETAIL_PRICE,c.scgqy,
a.nXssl,a.nxsje,a.nXscb,a.nyqxse,a.nyqmle,a.nysmle,a.nmll,
'['+convert(varchar(20),nqj*5+20)+'%-'+convert(varchar(20),(nqj+1)*5+20)+'%)毛利区间',nqj from #3 a 
join dbo.goods c on a.sSpbh=c.code
left join dbo.tmp_spflb d on c.sort=d.sflbh
where 1=1 and d.sflbh<'40'  order by sflbh  ;



--
select * from dbo.P_RETAIL_DETAIL_OUTPUT a 
where a.SHOP_CODE='018425' and  a.ITEM_CODE='22030349';

select a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,SUM(a.SALE_REAL_QTY) nXssl,sum(a.SALE_COST) nXscb,
sum(a.SALE_AMOUNT) nxsje into #1  from P_SALE_TOTAL_LIST_OUTPUT   a
where a.SHOP_CODE='018425' and  CONVERT(date,a.SALE_DATE)>=CONVERT(date,'2022-04-21')
and  CONVERT(date,a.SALE_DATE)<=CONVERT(date,'2022-05-21')
group by  a.SHOP_CODE  ,a.ITEM_CODE  ;

select a.*,case when isnull(a.nxsje,0)<=0  and  ISNULL(a.nXscb,0)=0 then 0
when  isnull(a.nxsje,0)=0  and  ISNULL(a.nXscb,0)>0 then -1 
when  isnull(a.nxsje,0)>0  then (isnull(a.nxsje,0)-isnull(a.nXscb,0))*1.0/isnull(a.nxsje,0)   end nmll,0.2 nbzmll
into #2    from  #1  a 
where ISNULL(a.nXscb,0)>=0;


-- drop table #3
select a.*,b.SHIFT_PRICE,b.RETAIL_PRICE, case when a.nXssl=0 then 0 else ROUND(a.nXscb/0.8,2) end nyqxse,
case when a.nXssl=0 then 0 else  ROUND(a.nXscb/4.0,2) end nyqmle
,case when a.nXssl=0 then 0 else  ROUND(a.nXscb/4.0,2) end-a.nxsje+a.nXscb nysmle  ,
 floor(cast(ROUND(a.nmll-a.nbzmll,2) as numeric(8,2))/0.05) nqj into #3
 from  #2 a  
left join P_SHOP_ITEM_OUTPUT b on a.sFdbh=b.DEPT_CODE and a.sSpbh=b.ITEM_CODE
where 1=1;

select a.sFdbh,a.sSpbh,c.name sspmc,d.sflbh,d.sflmc,a.SHIFT_PRICE,a.RETAIL_PRICE,c.scgqy,
a.nXssl,a.nxsje,a.nXscb,a.nyqxse,a.nyqmle,case when a.nysmle<=0 then  0 else  a.nysmle end ,a.nmll,
'['+convert(varchar(20),nqj*5+20)+'%-'+convert(varchar(20),(nqj+1)*5+20)+'%)毛利区间',nqj from #3 a 
join dbo.goods c on a.sSpbh=c.code
left join dbo.tmp_spflb d on c.sort=d.sflbh
where 1=1 and d.sflbh<'40' and c.scgqy<>'生鲜部'  and  left(d.sflbh,4)<>'2201'  order by sflbh  ;
