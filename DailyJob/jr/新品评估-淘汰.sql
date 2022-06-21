/*
对建议门店引进的商品（含新品、二次引进，人工引进），开通了，且有库存但长期不动销的商品进行评估，
是继续经营还是淘汰
*/
-- Step 0 : 准备门店开通有库存的全集表
-- Step 0 : 准备门店开通有库存的全集表
select sfdbh,sspbh,min(drq) drq_min_kc,max(drq) drq_max_kc  into #Tmp_kc
from DappSource_Dw.dbo.Tmp_kclsb where drq>convert(date,'2022-03-25')
and sfdbh='018425' and nkcsl>0 group by sfdbh,sspbh;
-- Step 1 : 查门店单品销售最晚日期
select a.SHOP_CODE,a.ITEM_CODE,min( CONVERT(date,a.SALE_DATE)) min_salerq,max( CONVERT(date,a.SALE_DATE)) max_salerq
,sum(a.SALE_QTY) nxssl into #Tmp_xs
 from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
where a.SHOP_CODE='018425' and CONVERT(date,a.SALE_DATE)>=CONVERT(date,'2022-03-25')
   group by  a.SHOP_CODE,a.ITEM_CODE;
 


-- Step 2 ：关联建议清单及判断人工引进
select a.DEPT_CODE sFdbh,a.ITEM_CODE sSpbh,a.STOP_INTO,a.c_introduce_date,a.ITEM_ETAGERE_CODE,a.RETURN_ATTRIBUTE,a.SHIFT_PRICE,a.RETAIL_PRICE
,b.drq_min_kc,b.drq_max_kc,c.min_salerq,c.max_salerq,c.nxssl  into #Base_Sp from DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT a 
left join #Tmp_kc b on a.DEPT_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
left join #Tmp_xs c on a.DEPT_CODE=c.SHOP_CODE and a.ITEM_CODE=c.ITEM_CODE
where a.DEPT_CODE='018425' and a.STOP_INTO='N' and a.CHARACTER_TYPE='N'
and a.VALIDATE_FLAG='Y' and a.STOP_SALE='N';

-- Step 3 :清单准备
select  sfdbh,sspbh,convert(date,convert(varchar(20),CONVERT(int,ssj))) spc,sspmc into #tmp0  
 from [122.147.10.202].dappresult.dbo.yjspb 

select 分店编号 sfdbh,商品编号 sspbh,商品名称 sspmc,convert(date,'2022-03-25') spc into #1 
from DappSource_Dw.dbo.Tmp_Md_Sptz where 建议='建议引进'
and 商品编号 not in (22060171,22060174,23012425,07021299,32011103,24041721,32020231,25030491,22020139,
 23021839,24042021,25041288,25022494,25041284,23050235,58010218,31060346,24041716,24041714,25041419,
 24042201,24060132,30010355,25041418,23060205,23060003,24060028,57020538,06010363,23060206,24060036,
 75060219,06010102,06010103,06010407,24060034,23060029,06010300,06010329,24042018,30010354,46010094,
 24042017) ; 

 select sfdbh,sspbh,sspmc,spc  into #11  from #1   a
 join DappSource_Dw.dbo.goods b on a.sspbh=b.code and b.sort not like '25%'
 union
 select  a.sfdbh,a.sspbh,a.sspmc,a.spc  from #tmp0   a
 left join #1 b on  a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
 where b.sfdbh   is  null;

 -- Step 4 结果形成
 select a.sFdbh,a.sSpbh,c.name,a.STOP_INTO,c.scgqy,a.SHIFT_PRICE,a.RETAIL_PRICE,a.RETURN_ATTRIBUTE,
  a.c_introduce_date nyjsj,a.ITEM_ETAGERE_CODE nrksj,a.drq_min_kc,a.drq_max_kc,a.min_salerq,a.max_salerq 
  ,DATEDIFF(day,isnull(CONVERT(date,a.max_salerq),CONVERT(date,a.ITEM_ETAGERE_CODE)) ,convert(date,getdate())) nbdxts ,
 b.spc,d.nkcsl,a.nxssl,case when b.sfdbh is not null then 'D咨询建议引进'    else  '人工引进'  end sflag   from  #Base_Sp a 
 left join #11 b on a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh
 left join DappSource_Dw.dbo.goods c on a.sSpbh=c.code 
 left join DappSource_Dw.dbo.Tmp_kclsb d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh 
    and CONVERT(date,d.drq)=CONVERT(date,getdate()-1)
 where 1=1 and ((b.sfdbh is null and DATEDIFF(day,CONVERT(date,a.ITEM_ETAGERE_CODE),convert(date,getdate()))<=90 
 and a.ITEM_ETAGERE_CODE is not null  and  ( a.max_salerq   is null or
  DATEDIFF(day,CONVERT(date,a.max_salerq),convert(date,getdate()))>=30   ) 
  or ( b.sfdbh is not null  and  
   DATEDIFF(day,isnull(CONVERT(date,a.max_salerq),CONVERT(date,a.ITEM_ETAGERE_CODE)) ,
   convert(date,getdate()))>=30   ))) and c.sort<'40';
