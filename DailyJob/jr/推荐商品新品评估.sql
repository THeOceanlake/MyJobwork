/*
思路就是将不销售单品，与当前背景下这个单品的排名做对比，看下问题出在哪里
*/
-- Step 1:
select * into #Tmp_Spb from dappsource_Dw.dbo.p_shop_item_output
where dept_code in ('018425','018418','018389','018396');


-- Step 3:导入单品指标  drop table #Base_Sp
select a.sfdbh,a.sspbh,a.sspmc,a.splbh,a.njhj,a.nlsj,a.nxssl,a.nxsje,
a.nml,a.nrjxl
,a.nrjxse,case when a.nrjml<0 then 0 else a.nrjml end nrjml,a.nBdxts
,b.Stop_into,b.Stop_Sale,b.Display_mode into #Base_Sp 
 from [122.147.10.202].DAppResult.dbo.R_dpzb a
 join #Tmp_SPb b on a.sfdbh=b.dept_code and a.sspbh=b.item_code 
where sfdbh in ('018425','018418','018389','018396')
and a.splbh>='20' and a.splbh<'40' ; 

--Step 4:门店品类指标计算 drop table #plzb
select a.sfdbh,a.splbh,sum(a.nxssl) nxssl,sum(a.nxsje) nxsje,
sum(a.nml) nml,sum(a.nrjxl) nrjxl,
sum(a.nrjxse) nrjxse,sum(a.nrjml) nrjml into #plzb 
from #Base_Sp a group by a.sfdbh,a.splbh;

-- Step 5 :门店单品综合指标计算,nRjxl:nrjxse:nRjml=4:3:3,折算到nrjxl 上
-- drop table #Base_1
select a.*,case when b.nrjxl<=0  or b.nrjml=0 or b.nrjxse=0 then 0 
 when b.nrjxl>0 and b.nrjxse<>0 and b.nrjml<>0
then  a.nrjxl*0.4+a.nrjxse*0.3*b.nrjxl/b.nrjxse+a.nrjml*0.3*b.nrjxl/b.nrjml
  end nzbz into #Base_1  from #Base_Sp a
join #plzb b on a.sfdbh=b.sfdbh and a.splbh=b.splbh 
where 1=1 ;

/*
select a.*,b.*,a.nrjxl*0.4,a.nrjxse*0.3*b.nrjxl/b.nrjxse,a.nrjml*0.3*b.nrjxl/b.nrjml  from #Base_Sp a
join #plzb b on a.sfdbh=b.sfdbh and a.splbh=b.splbh 
where 1=1  and a.sfdbh='018425' and a.splbh='21020104' ;

*/
-- select * from #plzb where sfdbh='018425' and splbh='21020104'
-- Step 6:对三个背景店单品，做综合计算 drop table #Tmp_zhzb;
with x0 as (
select splbh,sspbh,sum(nzbz) nzbz,avg(nzbz) nzbz_avg,
count(distinct sfdbh) nmdjys,3 nzmds,min(nbdxts) nbdxts from #Base_1 
where sfdbh in ('018418','018389','018396') group by splbh,sspbh ) 
select a.*,a.nzbz_avg*a.nmdjys/a.nzmds+a.nzbz*(a.nzmds-a.nmdjys)/(a.nzmds*a.nzmds)
 nzhzb into #Tmp_zhzb from x0 a ;

-- Step 7:背景门店需要非停购,总部资料需要开通 
select  item_code sspbh, sum(case when stop_into='N' then 1 else 0 end ) njymds
 into #Tmp_bj  from #Tmp_spb  where dept_code in ('018418','018389','018396')
group by item_code;

-- Step 8:对资料有效单品进行排序，至少两个店资料经营 drop table #Select_sort
select a.*,b.njymds,row_number()over(partition by a.splbh order by a.nzhzb desc) npm
into #Select_sort from #Tmp_Zhzb a
join #Tmp_bj b on a.sspbh=b.sspbh and b.njymds>1
where 1=1  and  a.splbh>='20' and a.splbh<'40';

----- 不动销的新品
select * into #1 from DappSource_Dw.dbo.Tmp_Measures_list
where sadvice='建议引进' and sspbh not in (22060171,22060174,23012425,07021299,32011103,24041721,32020231,25030491,22020139,
 23021839,24042021,25041288,25022494,25041284,23050235,58010218,31060346,24041716,24041714,25041419,
 24042201,24060132,30010355,25041418,23060205,23060003,24060028,57020538,06010363,23060206,24060036,
 75060219,06010102,06010103,06010407,24060034,23060029,06010300,06010329,24042018,30010354,46010094,
 24042017) ;

-- Step 2:库存数据
select a.*,b.STOP_INTO,b.STOP_SALE,b.VALIDATE_FLAG,b.CHARACTER_TYPE,
b.c_introduce_date,b.ITEM_ETAGERE_CODE,c.CURR_STOCK nKcsl into #2   from #1 a 
left join Dappsource_DW.dbo.P_SHOP_ITEM_OUTPUT b on a.sfdbh=b.DEPT_CODE 
and a.sspbh=b.ITEM_CODE
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK c on a.sFdbh=c.STORE_CODE and a.sSpbh=c.ITEM_CODE
where 1=1   ;

-- drop table #tmp_xs
with x0 as (
select distinct Measure_batch,createTime,sfdbh from  #2  )
select b.Measure_batch,  a.SHOP_CODE sFdbh,a.ITEM_CODE sSpbh,sum(a.SALE_REAL_QTY) nxssl,sum(a.SALE_REAL_AMOUNT) nxsje,SUM(a.SALE_COST) ncb
into #tmp_xs from  Dappsource_DW.dbo.P_SALE_TOTAL_LIST_OUTPUT a ,x0 b 
where  1=1 and a.SHOP_CODE=b.sFdbh and convert(date,a.SALE_DATE)>CONVERT(date,b.createTime)
and  convert(date,a.SALE_DATE)<CONVERT(date,GETDATE())
group by b.Measure_batch,a.SHOP_CODE,a.ITEM_CODE;

-- drop table #5
select a.Measure_batch, a.sfdbh, COUNT(1) njsps,sum(case when a.STOP_INTO='N' then 1 else 0 end ) nyjsps,
sum(case when a.ITEM_ETAGERE_CODE is not null then  1 else 0 end ) nykcsps into #5 from #2  a
where 1=1
group by a.Measure_batch, a.sFdbh;

-- 4 新品引进不动销
select a.*,d.sflbh,d.sflmc,c.scgqy,DATEDIFF(day,convert(date,a.ITEM_ETAGERE_CODE),convert(date,GETDATE()))+1 nday,b.nxssl,b.nxsje,b.ncb,
ISNULL(b.nxssl,0)/(DATEDIFF(day,convert(date,a.ITEM_ETAGERE_CODE),convert(date,GETDATE()))+1) nrjxl from #2  a 
left join #tmp_xs b  on a.Measure_batch=b.Measure_batch and a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
left join dappsource_DW.dbo.goods c on a.sspbh=c.code
left join DappSource_Dw.dbo.tmp_spflb d on c.sort=d.sflbh
 where  a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y' 
 and b.nxssl is null and DATEDIFF(day,convert(date,a.ITEM_ETAGERE_CODE),convert(date,GETDATE()))+1>20
and a.ITEM_ETAGERE_CODE is not null;