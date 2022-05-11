 -- 自动补货商品明细
select a.sfdbh,b.sflbh into #zdbhfl
from [122.147.10.200].dappsource.dbo.sys_deliverysort a,
[122.147.160.32].DApplicationBI.dbo.tmp_spflb b where  b.sflbh like a.sflbh+'%' and LEN(b.sflbh)=8
or b.sflbh in ('1309','2103','2104');

--
-- 暂不补货

update a  set  a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliveryGysEx b 
where a.sgys=b.sgys ;



update a  set  a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliverySortEx b
where a.splbh like b.sflbh+'%' and a.sfdbh=b.sfdbh ;


update a  set  a.szdbh='0' from #mdlkcsp  a,[122.147.10.200].DAppSource.dbo.Sys_DeliverySpEx b
where a.sspbh=b.sspbh and b.begindate<GETDATE() and b.enddate>GETDATE() and nFlag=1 ;


---- DC采购区域
select '','全部' union 
select distinct  isnormal,isnormal from   [122.147.160.32].DApplicationBI.dbo.goods
where isnormal is not null and sort>'11' and sort<'40'

-- 分类树
select '' as sflbh,'全部' as sflmc,'0' as sparentflbh,'1' as isparent
union all
select distinct sflbh,sflbh+sflmc,case when len(sflbh)=2 then '0' else substring(sflbh,1,len(sflbh)-2) end as sparentflbh,
case when len(sflbh)=6 then '1' else '0' end as isparent 
from [122.147.160.32].dapplicationBI.dbo.tmp_spflb 
WHERE len(sflbh)>=2  and sflbh>'11' and sflbh<'40' order by 1

-- 部门
select '','全部' union 
select distinct  scgqy,scgqy from   [122.147.160.32].DApplicationBI.dbo.goods
where isnormal is not null and sort>'11' and sort<'40'

-- 分店编号
select '','全部' union
select sfdbh,sfdbh+sfdmc from  DAppStore.dbo.Tmp_FDB 
where sFDBH in ('018329','012006','018389','012007','018425')

-- 剩余天数
and isnull(a.nsl,0)<=a.nrjxl*@day 

-- 历史库存
-- 使用历史日结库存 drop table #Tmp_mdkc
  select c_store_id sfdbh,c_gcode sspbh,c_number nkcsl,c_A nkcje into #Tmp_mdkc   from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date=to_date(''2022-01-01'',''yyyy/mm/dd'' )')


-- 实时库存
-- drop table #Base_1
select   a.*,ISNULL(b.CURR_STOCK,0)  nkcsl into #Base_1 from #Base_sp a
left join [122.147.160.32].DApplicationBI.dbo.V_D_PRICE_AND_STOCK  b
     on   a.sfdbh=b.STORE_CODE and a.sspbh=b.ITEM_CODE


delete from tmp_xs_qwl where drq>=convert(datetime,convert(varchar(10),getdate(),120))-15

insert into tmp_xs_qwl(sfdbh,sspbh,drq,nxsj,nxssl,nxsje)
select b.shop_code sfdbh,b.item_code sspbh,convert(datetime,convert(varchar(10),b.sale_date,112)) drq,max(sell_price) nxsj,sum(b.qty) nxssl,sum(b.subtotal) nxsje from 
P_RETAIL_DETAIL_OUTPUT b where shop_code in ('012001','012002','012006','012011','018300','018308','018320','018336','018342','018361') 
and left(b.pcno,1)<>'9' and b.sale_date>=convert(datetime,convert(varchar(10),getdate(),120))-15
group by b.shop_code,b.item_code,convert(datetime,convert(varchar(10),b.sale_date,112))


-- 排除分类

declare @sql varchar(2000)
set @sql=''
select @sql= @sql+','+sflbh+sflmc from dappsource_dw.dbo.tmp_spflb
where sflbh in ('2021','2103','2104','2105','2106','2201','2203','2204','2309','3903')
select @sql

-- 门店范围
and d.smdlx   in ('大店A','大店B','小店','中店A','中店B')
and d.sJylx='连锁门店'
and d.dkyrq is not null and d.sjc not like '%取消%'


-- 进出调整
update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
from #mddkc a  join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品') 
and b.npm=1
left join #jcmx c on  a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh  and c.sjcfl not in('入库','调入(配送折让)','调入(配送)','调入(配送)赠品')
 and c.npm=2
where  1=1  and len(a.syy)=0 and ((b.nDhsl>=a.nsl*0.2) or (b.nDhsl<a.nDhsl*0.2 and c.sfdbh is not null));


-- 销售
select convert(date,SALE_DATE) drq,LEFT(b.sort,4) sdlbh, sum(isnull(a.SALE_COST,0)) nxscb from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
		join #goods b on a.ITEM_CODE=b.code
		where    CONVERT(date,a.SALE_DATE)>=convert(date,getdate()-30)    and  CONVERT(date,a.SALE_DATE)<CONVERT(date,GETDATE())
		  group by  convert(date,a.SALE_DATE)  ,LEFT(b.sort,4)


--停购库存的数据 drop table #1
select a.DEPT_CODE,a.ITEM_CODE,a.STOP_INTO,b.nkcje,b.nkcsl,a.RETURN_ATTRIBUTE into #1 from dbo.P_SHOP_ITEM_OUTPUT a 
join dbo.tmp_kclsb b on a.DEPT_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh and b.drq=CONVERT(date,GETDATE()-1)
where a.DEPT_CODE='018425' and b.nkcje>0 and a.STOP_INTO='Y' and a.CHARACTER_TYPE='N';

select COUNT(1), SUM(case when  b.sFdbh IS  not null then 1 else 0 end ) njysps,SUM(case when  b.sFdbh IS    null then 1 else 0 end ) nwjysps ,
SUM(nkcje), SUM(case when  b.sFdbh IS  not null then a.nkcje else 0 end ) njyspskcje,
SUM(case when  b.sFdbh IS    null then a.nkcje else 0 end ) nwjysps from #1  a
left join Tmp_Measures_list b on a.DEPT_CODE=b.sFdbh and a.item_code=b.sSpbh and b.Enddate>GETDATE()
 join dbo.goods c on a.ITEM_CODE=c.code
left join tmp_spflb d on c.sort=d.sflbh
left join P_SHOP_ITEM_OUTPUT e on a.DEPT_CODE=e.DEPT_CODE and a.ITEM_CODE=e.ITEM_CODE
where 1=1 and (( c.sort>'20' and c.sort<'40') or (
LEFT(c.sort,4) in ('1105','1307','1309','1406') ))
and LEFT(c.sort,4)<>'2201';

select  a.DEPT_CODE,a.ITEM_CODE,c.name,d.sflbh,d.sflmc,c.scgqy,a.nkcsl,a.nkcje,b.sAdvice_raw,b.sAdvice_result ,a.RETURN_ATTRIBUTE from #1  a
left join Tmp_Measures_list b on a.DEPT_CODE=b.sFdbh and a.item_code=b.sSpbh and b.Enddate>GETDATE()
  join dbo.goods c on a.ITEM_CODE=c.code
left join tmp_spflb d on c.sort=d.sflbh
where 1=1  and (( c.sort>'20' and c.sort<'40') or (
LEFT(c.sort,4) in ('1105','1307','1309','1406') ))
and LEFT(c.sort,4)<>'2201'