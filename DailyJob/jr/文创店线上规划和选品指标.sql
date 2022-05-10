/*
门店线上数据的查询
*/
-- Step 1:获取线上销售流水，收银台>901 不等于903
select a.SHOP_CODE sfdbh,a.ITEM_CODE sspbh,SUM(a.QTY) nxssl,SUM(a.SUBTOTAL-DISCOUNT) nxsje,SUM(a.SUBTOTAL-DISCOUNT)-sum(a.QTY*a.INPUT_PRICE) nxsml,
COUNT(1) npxs into #Tmp_xs from DappSource_Dw.dbo.P_RETAIL_DETAIL_OUTPUT a 
where a.shop_code='018425' and CONVERT(date,a.SALE_DATE)>=CONVERT(date,GETDATE()-30)
and CONVERT(date,a.SALE_DATE)<CONVERT(date,GETDATE())
and a.Pcno>901 and a.Pcno<>903  group by a.SHOP_CODE,a.ITEM_CODE;

-- Step 2 :关联门店商品资料表
insert into [122.147.10.202].dappresult.dbo.Input_Gh_Sp(sQybh,sFdbh,sSpbh,sFlbh,sSpmc,nJhj,nLsj,nXse,nMl,nPxs,nZbz,sSpbhBz)
select 'jr','000025',a.sspbh,c.sort,c.name,b.SHIFT_PRICE,b.RETAIL_PRICE,a.nxsje,
cast(round(a.nxsml,3) as numeric(8,3)),a.npxs,a.npxs,c.code2
 from #Tmp_xs a
join DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT b on a.sfdbh=b.DEPT_CODE and a.sspbh=b.ITEM_CODE and b.CHARACTER_TYPE='N'
join DappSource_Dw.dbo.goods c on a.sspbh=c.code
where 1=1 ;

-- Step 3:选品数据导入
select  '21030199' sflbh_cal,'低温酸奶综合' sflmc,sflbh into #sflb  from DappSource_Dw.dbo.tmp_spflb
where sflbh like '210301%'
union 
select '23040198','米果综合',sflbh from dbo.tmp_spflb where sflbh in (
    '23040103','23040109' )
union
select '24040199','大米综合',sflbh from dbo.tmp_spflb where sflbh  like '240401%'
union
select '31050199','沐浴露综合',sflbh from tmp_spflb where sflbh in ('31050101','31050102')
union
select  sflbh,sflmc,sflbh from dbo.tmp_spflb where 
sflbh in ('23010104','23010105','23010401','23010403','23010404','23010406',
'23020104','23020106','23020108','23020110','23020111','23020112',
'23040308','23040309','23040310','23040311','23040312','31030204',
'33010401','33010405','33010406','31030201','31030202','31030203','31030206','31030207','31030208'
,'23040301','23040302','23040303','23040304','23040305','23040306',
'23040101','23040102','23040107','23040108' );

-- 线上门店数据
select * into #Taste from [122.147.10.202].master.dbo.TMP_DXP_TASTE 

  select distinct 'jr' sQybh,'000025' sFdbh,a.sSpbh,g.sflbh_cal sFlbh,e.SHIFT_PRICE nJhj,e.RETAIL_PRICE nLsj,a.nPxs,f.name sSpmc,
  f.munit sDw,a.nXssl,a.nXsje, a.nxsml nMl,f.billto sGys,
 f.code2 sSpbhBz,0 sState,f.validperiod nBzt,isnull(convert(money,d.sYsValue),0) nGg,GETDATE() dCreateDate,isnull(h.sYsValue,f.brand) sPp,'' sGn,
 ISNULL(f.spec,'0') sGg,
 case when isnull(convert(money,d.sYsValue),0)>0 then e.RETAIL_PRICE/( isnull(convert(money,d.sYsValue),0)) else 0 end ndc into #jysp
  from #Tmp_xs a  
 join DappSource_Dw.dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 

 left join #Taste d on a.sSpbh=d.sSpbh  and  d.sFlys='规格' 
  left join  #Taste h on a.sSpbh=h.sSpbh  and  h.sFlys='品牌' 
   join DappSource_Dw.dbo.p_shop_item_output e on a.sFdbh=e.dept_code and a.sSpbh=e.item_code
   left join DappSource_Dw.dbo.goods f on a.sSpbh=f.code
join #sflb g on f.sort=g.sflbh
 where 1=1 and   b.sjylx='连锁门店' and b.sFDBH in  ('018425','018418','018389','018396')
 and b.sFDMC not like '%取消%' and  e.validate_flag='Y' and e.CHARACTER_TYPE='N' 
 and e.stop_into='N' and e.stop_sale='N' and b.dKyrq is not null ;


  insert into [122.147.10.202].dappresult.dbo.Input_Xp_Sp_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl, nXse,nMl,
	sGys,sGjtm,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nxsje nXse,nMl,
	sGys,sSpbhBz,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc from #jysp
