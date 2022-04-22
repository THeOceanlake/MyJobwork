/*
  018418     20218    首铸万科广场店
  018389     20089  天安数码城店 
  018396     20096  东城碧桂园苹果店
 试点门店	018425
	从规划选新品，规划从外导入
  
  
*/
-- Step 1 规划数导入
select '018425' sfdbh,sflbh, nghjyz nGhs into #mdgh 
  from  dappsource_Dw.dbo.Tmp_Mdghs;
  
  
  select '018425' sfdbh,sfl sflbh, nghs nGhs  into #mdgh 
  from  dappsource_Dw.dbo.Tmp_Mdgh_new;

--select left(ghfabh,6) sfdbh,sflbh,njypls nghs into #mdgh  
--from [122.147.10.202].DAppResult.dbo.Gh_Ghfamx
--where ghfabh='01842520220306155935';


-- Step 2:导入商品资料
select * into #Tmp_Spb from [122.147.160.32].DApplicationBI.dbo.p_shop_item_output
where dept_code in ('018425','018418','018389','018396');

 

-- Step 3:导入单品指标  drop table #Base_Sp
select a.sfdbh,a.sspbh,a.sspmc,a.splbh,a.njhj,a.nlsj,a.nxssl,a.nxsje,
a.nml,a.nrjxl,a.nPxs
,a.nrjxse,case when a.nrjml<0 then 0 else a.nrjml end nrjml,a.nBdxts
,b.Stop_into,b.Stop_Sale,b.Display_mode into #Base_Sp 
 from [122.147.10.202].DAppResult.dbo.R_dpzb a
 join #Tmp_SPb b on a.sfdbh=b.dept_code and a.sspbh=b.item_code 
where sfdbh in ('018425','018418','018389','018396')
and a.splbh>='20' and a.splbh<'40' ;

--Step 4:门店品类指标计算 drop table #plzb
select a.sfdbh,a.splbh,sum(a.nxssl) nxssl,sum(a.nxsje) nxsje,
sum(a.nml) nml,sum(a.nrjxl) nrjxl,sum(nPxs) nPxs,
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

-- Step 9:数据筛选
/*排名是前五，且日均销量>0.2,然后放在一起排序，从尾部淘汰,食品的不动销天数*1.5
——意思就是虽然引进了，但没有本店已有
商品好，还是不引进*/
select * from #Select_sort a 
  join #Tmp_spb b on a.sspbh=b.item_code and b.dept_code='018425'
 where  1=1 and a.npm<=10 and a.nzhzb>0.2 and b.stop_into<'N'  ;


-- Step 9.1 :先全部引进，再淘汰 drop table #Tmp_r1
-- 0310 排名放开到10
select a.sfdbh,a.sspbh,a.splbh,a.nzbz nzhzb,a.nbdxts,isnull(b.nzhzb,0) nbjzb,
isnull(b.npm,0) nyjpm,'现有商品' sflag into #Tmp_r1
 from #Base_1 a 
 left join #Select_sort  b on a.sspbh=b.sspbh and a.splbh=b.splbh 
 and b.npm<=10 and b.nzhzb>0.2
 where a.sfdbh='018425'
union
select '018425',a.sspbh,a.splbh,0,a.nbdxts,a.nzhzb,a.npm,'背景引进' from #Select_sort  a 
left join #Base_1 b on  a.sspbh=b.sspbh and a.splbh=b.splbh and b.sfdbh='018425'
where b.sfdbh is null and a.npm<=10 and a.nzhzb>0.2
order by 3 ;



-- Step 9.2 :对结果排名——按指标倒排序，然后用规划截取
-- 导入 总部资料，确定部门数据
select * into #Tmp_goods from [122.147.10.200].dappsource.dbo.goods;

-- drop table #Tmp_plxz 
select a.sfdbh,a.splbh,count(distinct a.sspbh) nsps  into #Tmp_plxz 
 from #Base_sp  a group by a.sfdbh,a.splbh;

-- 9.3 另一种方案
/*
	对于本店有销售在单品优先保留：食品日均在0.06 非食 0.03
	剩下的单品再和背景可选商品末尾淘汰，竞争余下位置
*/
-- Step 9.3.0  保留数据 drop table #Tmp_stay_one
-- 0310 保留数据需要要非停购的
with x0 as(
select a.*,b.scgqy,c.stop_into,c.Stop_sale,c.Return_attribute,c.c_disuse_date
   from #Tmp_r1 a
left join #Tmp_goods b on  a.sspbh=b.code
join #Tmp_spb c on a.sfdbh=c.dept_code and a.sspbh=c.item_code where 1=1
and  c.sTop_into='N' and c.Stop_sale='N'    )
select  *  into #Tmp_stay_one from x0 a  where 1=1 
and  ((  a.scgqy ='非食品部' and isnull(a.nzhzb,0)>=0.03) or 
  ( a.scgqy <>'非食品部' and isnull(a.nzhzb,0)>=0.06 ));

-- 余下商品排序,如果引进不足，再在本店里保留商品 drop table #r
with x0 as (
select a.*,row_number()over(partition by a.sfdbh,a.splbh 
order by  case when isnull(a.nbjzb,0)>0 then a.nbjzb else a.nzhzb end  desc,a.nbdxts ) npm
from #Tmp_r1  a left join #Tmp_stay_one b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where b.sfdbh is null    ),
x1 as (select sfdbh,splbh,count(distinct sspbh) nblsps from #Tmp_stay_one
group by sfdbh,splbh)
select a.sfdbh,a.sspbh,a.splbh,a.nzhzb,a.nbdxts,a.nbjzb,a.nyjpm,a.sflag,
a.scgqy,b.nsps njysps,c.nghs,'保留' sjy  into #r
 from  #Tmp_stay_one a
join #Tmp_plxz b on a.sfdbh=b.sfdbh and a.splbh=b.splbh
join #mdgh c on a.sfdbh=c.sfdbh and a.splbh=c.sflbh
where 1=1
union 
select a.sfdbh,a.sspbh,a.splbh,a.nzhzb,a.nbdxts,a.nbjzb,a.nyjpm,a.sflag,e.scgqy,
b.nsps,c.nghs,case when f.Stop_into='N' and a.npm<=c.nghs-d.nblsps and a.sflag='现有商品' then '保留'
     when a.npm<=c.nghs-d.nblsps  and a.sflag='背景引进' then '建议引进'
     when a.npm>c.nghs-d.nblsps and a.sflag='背景引进' then '规划淘汰'
     when a.npm>c.nghs-d.nblsps  and a.sflag='现有商品' then '建议淘汰'
     when f.Stop_into<>'N'  and a.sflag='现有商品' then '停购淘汰'
     end from x0  a
join #Tmp_plxz b on a.sfdbh=b.sfdbh and a.splbh=b.splbh
join #mdgh c on a.sfdbh=c.sfdbh and a.splbh=c.sflbh
left join x1 d on a.sfdbh=d.sfdbh and a.splbh=d.splbh
left join #Tmp_goods e on  a.sspbh=e.code  
left join #Tmp_spb f on a.sfdbh=f.dept_code and a.sspbh=f.item_code 
where 1=1   order by 1,3;
 

select * from #select_sort where splbh='21010101'
select * from #Base_sp where splbh='21020101' and sfdbh='018425'
select * from #Base_1 where splbh='21020101' and sfdbh='018425'


select * into #Tmp_fdb from   [122.147.160.32].DApplicationBI.dbo.Tmp_fdb;
select * into #Tmp_flb from   [122.147.160.32].DApplicationBI.dbo.Tmp_spflb;
select a.sfdbh,c.sfdmc,a.sspbh,b.name,a.splbh,d.sflmc,a.scgqy,e.njhj,e.nlsj,e.nrjxl,e.nrjxse,e.nrjml,a.nbdxts,
a.nzhzb,a.nbjzb,a.nyjpm,a.sflag,a.npmzb,a.nttpm,a.nsps,a.nghs,a.ndqsps,a.sjy from #r a 
left join #Tmp_goods b on a.sspbh=b.code
left join #Tmp_fdb c on a.sfdbh=c.sfdbh
left join #Tmp_flb d on a.splbh=d.sflbh
left join #Base_1 e on a.sfdbh=e.sfdbh and a.sspbh=e.sspbh
where 1=1  order by splbh ;

with x0 as (
select  a.sfdbh,a.splbh,count(1) nresult from #r a   where a.sjy  in ('保留','建议引进')
group by  a.sfdbh,a.splbh )
select a.sfdbh 分店编号,c.sfdmc 分店名称,a.sspbh 商品编号,b.name 商品名称,a.splbh 分类编号,d.sflmc 分类名称
,a.scgqy 采购区域,a.sflag 商品归属属性
,a.njysps 门店陈列商品数,a.nghs 规划数,f.nresult 品类最后保留商品数,a.sjy 
 建议,isnull(e.njhj,b.inprc) 进价,isnull(e.nlsj,b.rtlprc) 售价
 ,case when e.stop_into='N' then '否' else  '是' end  是否停购,
 case when e.stop_sale='N' then '否' else  '是' end  是否停售, e.nrjxl 日均销量,e.nrjxse 日均销售额,e.nrjml 日均毛利额
,a.nbdxts 不动销天数,
a.nzhzb 综合指标,a.nbjzb 背景指标值,a.nyjpm 背景排名 from #r a 
left join #Tmp_goods b on a.sspbh=b.code
left join #Tmp_fdb c on a.sfdbh=c.sfdbh
left join #Tmp_flb d on a.splbh=d.sflbh
left join #Base_1 e on a.sfdbh=e.sfdbh and a.sspbh=e.sspbh
left join x0  f on a.sfdbh=f.sfdbh and a.splbh=f.splbh
-- left join #tmp_spb g on a.sfdbh=g.dept_code and a.sspbh=g.item_code
where 1=1   and sjy<>'规划淘汰' order by a.splbh;
 
 select  * from #Base_1 where splbh='23010122'
 
 select * from #Tmp_goods   where splbh='21010110'
  select * from #r where splbh='23010122'
  
  select * from #Tmp_r1 where splbh='23010122'
 


 select * from #Tmp_spb where item_code='02060423'
  select * from #Base_1 where sspbh='02060423'
 
 
 select * from #r  a
 left join #Tmp_spb b on a.sfdbh=b.dept_code and a.sspbh=b.item_code
 where b.Stop_into<>'N' and a.nzhzb>0
 
 select * from #Tmp_spb where item_code='34030006'
 
 
 --------- 尾货商品
 -- 导入门店当前库存
 select * into #Tmp_kcb from [122.147.160.32].DApplicationBI.dbo.V_D_PRICE_AND_STOCK
where STORE_CODE in ('018425','018418','018389','018396');

select a.sfdbh,c.sfdmc,a.sspbh,a.sspmc,a.splbh,d.sflmc,a.njhj,a.nlsj,b.scgqy 
,a.nrjxl,a.nrjxse,a.nrjml,a.nbdxts,a.stop_into,a.Stop_sale,e.curr_stock nkc
 from #Base_1  a
 left join #Tmp_goods b on a.sspbh=b.code
left join #Tmp_fdb c on a.sfdbh=c.sfdbh
left join #Tmp_flb d on a.splbh=d.sflbh
left join #Tmp_kcb e on a.sfdbh=e.store_code and a.sspbh=e.item_code
where a.sfdbh='018425' and a.stop_into<>'N'  order by splbh 



-------------  V 1.0  版本
/*
  018418     20218    首铸万科广场店
  018389     20089  天安数码城店 
  018396     20096  东城碧桂园苹果店
 试点门店	018425
	从规划选新品，规划从外导入
  
  
*/
-- Step 1 规划数导入
select '018425' sfdbh,sflbh, nghjyz nGhs into #mdgh 
  from  dappsource_Dw.dbo.Tmp_Mdghs;
  
  
  select '018425' sfdbh,sfl sflbh, nghs nGhs  into #mdgh 
  from  dappsource_Dw.dbo.Tmp_Mdgh_new;
  
  
  select '018425' sfdbh,sflbh sflbh,sflmc, nghs nGhs  into #mdgh 
  from  dappsource_Dw.dbo.Tmp_gh_0325;
  
  select * from #mdgh

--select left(ghfabh,6) sfdbh,sflbh,njypls nghs into #mdgh  
--from [122.147.10.202].DAppResult.dbo.Gh_Ghfamx
--where ghfabh='01842520220306155935';


-- Step 2:导入商品资料
-- drop table #Tmp_Spb
select * into #Tmp_Spb from [122.147.160.32].DApplicationBI.dbo.p_shop_item_output
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
select * from #Base_sp where sfdbh='018425' and splbh='21040110'
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

-- Step 9:数据筛选
/*排名是前五，且日均销量>0.2,然后放在一起排序，从尾部淘汰,食品的不动销天数*1.5
——意思就是虽然引进了，但没有本店已有
商品好，还是不引进*/
select * from #Select_sort a 
  join #Tmp_spb b on a.sspbh=b.item_code and b.dept_code='018425'
 where  1=1 and a.npm<=10 and a.nzhzb>0.2 and b.stop_into<'N'  ;


-- Step 9.1 :先全部引进，再淘汰 drop table #Tmp_r1
-- 0310 排名放开到10
select a.sfdbh,a.sspbh,a.splbh,a.nzbz nzhzb,a.nbdxts,isnull(b.nzhzb,0) nbjzb,
isnull(b.npm,0) nyjpm,'现有商品' sflag into #Tmp_r1
 from #Base_1 a 
 left join #Select_sort  b on a.sspbh=b.sspbh and a.splbh=b.splbh 
 and b.npm<=10 and b.nzhzb>0.2
 where a.sfdbh='018425'
union
select '018425',a.sspbh,a.splbh,0,a.nbdxts,a.nzhzb,a.npm,'背景引进' from #Select_sort  a 
left join #Base_1 b on  a.sspbh=b.sspbh and a.splbh=b.splbh and b.sfdbh='018425'
where b.sfdbh is null and a.npm<=10 and a.nzhzb>0.2
order by 3 ;



-- Step 9.2 :对结果排名——按指标倒排序，然后用规划截取
-- 导入 总部资料，确定部门数据
select * into #Tmp_goods from [122.147.10.200].dappsource.dbo.goods;

-- drop table #Tmp_plxz 
select a.sfdbh,a.splbh,count(distinct a.sspbh) nsps  into #Tmp_plxz 
 from #Base_sp  a group by a.sfdbh,a.splbh;

with x0 as(
select a.*,b.scgqy ,
 -- case when a.nzhzb<>0 or a.nbdxts>0 then a.nzhzb else a.nbjzb end 
 a.nzhzb*0.6+a.nbjzb*0.4 npmzb  from #Tmp_r1 a
left join #Tmp_goods b on  a.sspbh=b.code where 1=1 
)
,x1 as (select a.*, row_number()over(partition by a.sfdbh,a.splbh
order by a.npmzb, case when  a.scgqy ='非食品部' then a.nbdxts 
when a.scgqy <>'非食品部' then a.nbdxts*1.5  end desc) nttpm  from x0 a
 where 1=1 )
,x2 as (select a.sfdbh,a.splbh,count(distinct a.sspbh) ndqsps   
 from #Tmp_r1  a group by a.sfdbh,a.splbh ) 
select a.*,b.nsps,c.nghs,d.ndqsps,
case when d.ndqsps<=c.nghs  and a.sflag='现有商品' then '保留'
     when d.ndqsps<=c.nghs  and a.sflag='背景引进' then '建议引进'
     when d.ndqsps>c.nghs  and a.nttpm<=d.ndqsps-c.nghs and a.sflag='背景引进' then '规划淘汰'
     when d.ndqsps>c.nghs  and a.nttpm<=d.ndqsps-c.nghs and a.sflag='现有商品' then '建议淘汰'
     when d.ndqsps>c.nghs  and a.nttpm>d.ndqsps-c.nghs and a.sflag='背景引进' then '建议引进'
     when d.ndqsps>c.nghs  and a.nttpm>d.ndqsps-c.nghs and a.sflag='现有商品' then '保留'
     end sjy  into #r
 from x1  a
join #Tmp_plxz b on a.sfdbh=b.sfdbh and a.splbh=b.splbh
join #mdgh c on a.sfdbh=c.sfdbh and a.splbh=c.sflbh
join x2 d on a.sfdbh=d.sfdbh and a.splbh=d.splbh
order by a.sfdbh,a.splbh;

-- 9.3 另一种方案
/*
	对于本店有销售在单品优先保留：食品日均在0.06 非食 0.03
	剩下的单品再和背景可选商品末尾淘汰，竞争余下位置
*/
-- Step 9.3.0  保留数据 drop table #Tmp_stay_one
-- 0310 保留数据需要要非停购的
with x0 as(
select a.*,b.scgqy,c.stop_into,c.Stop_sale,c.Return_attribute,c.c_disuse_date
   from #Tmp_r1 a
left join #Tmp_goods b on  a.sspbh=b.code
join #Tmp_spb c on a.sfdbh=c.dept_code and a.sspbh=c.item_code where 1=1
and  c.sTop_into='N' and c.Stop_sale='N'    )
select  *,row_number()over(partition by a.sfdbh,a.splbh order by a.nzhzb desc,a.nbdxts) nplpm
  into #Tmp_stay_one from x0 a  where 1=1 
and  ((  a.scgqy ='非食品部' and isnull(a.nzhzb,0)>=0.03) or 
  ( a.scgqy <>'非食品部' and isnull(a.nzhzb,0)>=0.06 ));

-- 余下商品排序,如果引进不足，再在本店里保留商品 drop table #r
with x0 as (
select a.*,row_number()over(partition by a.sfdbh,a.splbh 
order by  case when isnull(a.nbjzb,0)>0 then a.nbjzb else a.nzhzb end  desc,a.nbdxts ) npm
from #Tmp_r1  a left join #Tmp_stay_one b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
where b.sfdbh is null       ),
x2 as (select a.sfdbh,a.sspbh,a.splbh,a.nzhzb,a.nbdxts,a.nbjzb,a.nyjpm,a.sflag,
a.scgqy,b.nsps njysps,c.nghs,case when a.nplpm<=c.nghs then    '保留'
else '现有商品规划淘汰' end  sjy 
 from  #Tmp_stay_one a
join #Tmp_plxz b on a.sfdbh=b.sfdbh and a.splbh=b.splbh
join #mdgh c on a.sfdbh=c.sfdbh and a.splbh=c.sflbh
where 1=1 ),
x1 as (select sfdbh,splbh,count(distinct sspbh) nblsps from x2
where  sjy='保留' group by sfdbh,splbh)
select a.sfdbh,a.sspbh,a.splbh,a.nzhzb,a.nbdxts,a.nbjzb,a.nyjpm,a.sflag,
a.scgqy,a.njysps,a.nghs,a.sjy 
into #r
 from  x2 a
union 
select a.sfdbh,a.sspbh,a.splbh,a.nzhzb,a.nbdxts,a.nbjzb,a.nyjpm,a.sflag,e.scgqy,
b.nsps,c.nghs,case when f.Stop_into='N' 
  and a.npm<=c.nghs-isnull(d.nblsps,0) and a.sflag='现有商品' then '保留'
     when a.npm<=c.nghs-isnull(d.nblsps,0)  and a.sflag='背景引进' then '建议引进'
     when a.npm>c.nghs-isnull(d.nblsps,0) and a.sflag='背景引进' then '规划淘汰'
     when a.npm>c.nghs-isnull(d.nblsps,0)  and a.sflag='现有商品' then '建议淘汰'
     when f.Stop_into<>'N'  and a.sflag='现有商品' then '停购淘汰'
     end from x0  a
left join #Tmp_plxz b on a.sfdbh=b.sfdbh and a.splbh=b.splbh
left join #mdgh c on a.sfdbh=c.sfdbh and a.splbh=c.sflbh
left join x1 d on a.sfdbh=d.sfdbh and a.splbh=d.splbh
left join #Tmp_goods e on  a.sspbh=e.code  
left join #Tmp_spb f on a.sfdbh=f.dept_code and a.sspbh=f.item_code 
where 1=1  order by 1,3;
 

--select * from #tmp_r1 where splbh='21040110'
--select * from #r where  sjy  is null 

--select * from #Base_sp where splbh='21020101' and sfdbh='018425'
--select * from #Base_1 where splbh='21020101' and sfdbh='018425'


select * into #Tmp_fdb from   [122.147.160.32].DApplicationBI.dbo.Tmp_fdb;
select * into #Tmp_flb from   [122.147.160.32].DApplicationBI.dbo.Tmp_spflb;
select a.sfdbh,c.sfdmc,a.sspbh,b.name,a.splbh,d.sflmc,a.scgqy,e.njhj,e.nlsj,e.nrjxl,e.nrjxse,e.nrjml,a.nbdxts,
a.nzhzb,a.nbjzb,a.nyjpm,a.sflag,a.npmzb,a.nttpm,a.nsps,a.nghs,a.ndqsps,a.sjy from #r a 
left join #Tmp_goods b on a.sspbh=b.code
left join #Tmp_fdb c on a.sfdbh=c.sfdbh
left join #Tmp_flb d on a.splbh=d.sflbh
left join #Base_1 e on a.sfdbh=e.sfdbh and a.sspbh=e.sspbh
where 1=1  order by splbh ;
--- select * from #base_sp where splbh='21010103' and sfdbh='018425'
 -- select * from #Tmp_spb where   dept_code='018425'
 
 select * from #select_sort where splbh='21010109'

with x0 as (
select  a.sfdbh,a.splbh,count(1) nresult from #r a   where a.sjy  in ('保留','建议引进')
group by  a.sfdbh,a.splbh )
select a.sfdbh 分店编号,c.sfdmc 分店名称,a.sspbh 商品编号,b.name 商品名称,a.splbh 分类编号,d.sflmc 分类名称
,a.scgqy 采购区域,a.sflag 商品归属属性
,a.njysps 门店陈列商品数,a.nghs 规划数,f.nresult 品类最后保留商品数,a.sjy 
 建议,isnull(e.njhj,b.inprc) 进价,isnull(e.nlsj,b.rtlprc) 售价
 ,case when e.stop_into='N' then '否'
 when e.stop_into IS not null and e.stop_into<>'N' then     '是' end  是否停购,
 case  when e.stop_sale='N' then '否'    when e.stop_sale IS not null and e.stop_sale<>'N' then     '是' end  是否停售
 , e.nrjxl 日均销量,e.nrjxse 日均销售额,e.nrjml 日均毛利额
,a.nbdxts 不动销天数,
a.nzhzb 综合指标,a.nbjzb 背景指标值,a.nyjpm 背景排名 from #r a 
left join #Tmp_goods b on a.sspbh=b.code
left join #Tmp_fdb c on a.sfdbh=c.sfdbh
left join #Tmp_flb d on a.splbh=d.sflbh
left join #Base_1 e on a.sfdbh=e.sfdbh and a.sspbh=e.sspbh
left join x0  f on a.sfdbh=f.sfdbh and a.splbh=f.splbh
-- left join #tmp_spb g on a.sfdbh=g.dept_code and a.sspbh=g.item_code
where 1=1    and sjy<>'规划淘汰'  
  order by a.splbh;
--- 在全店范围筛选 drop table #bbcpl
with x0 as (
select  a.sfdbh,a.splbh,count(1) nresult,max(a.njysps) njysps
 from #r a   where a.sjy  in ('保留','建议引进')
group by  a.sfdbh,a.splbh )
select distinct a.sfdbh   ,a.sflbh splbh    
,isnull(f.njysps,0) njysps  ,a.nghs  ,f.nresult,isnull(f.nresult,0)-isnull(a.nghs,0) nghcy into #bbcpl
    from #mdgh a  
left join x0  f on a.sfdbh=f.sfdbh and a.sflbh=f.splbh 
where 1=1   order by a.sflbh;

--select * from #bbcpl

-- Step 10.1 全店指标
-- drop table #Tmp_Spb_all
select c.* into #Tmp_Spb_all from  
 [122.147.160.32].DApplicationBI.dbo.P_SHOP_ITEM_OUTPUT c,
  #tmp_fdb d, #tmp_goods e
where   c.DEPT_CODE=d.sfdbh  and c.item_code=e.code and c.CHARACTER_TYPE='N' 
and e.sort>='20' and e.sort<'40'
   and d.smdlx   in ('大店A','大店B','小店','中店A','中店B')
   and d.dkyrq is not null and d.sjc not like '%取消%'
   and c.STOP_INTO='N' and c.STOP_SALE='N' and c.VALIDATE_FLAG='Y'
  and d.sJylx='连锁门店' and e.sort in (select  splbh from  #bbcpl
  where nghcy<0) ;
  
-- Step 10.3:导入单品指标  drop table #Base_Sp_all
select a.sfdbh,a.sspbh,a.sspmc,a.splbh,a.njhj,a.nlsj,a.nxssl,a.nxsje,
a.nml,a.nrjxl
,a.nrjxse,case when a.nrjml<0 then 0 else a.nrjml end nrjml,a.nBdxts
,b.Stop_into,b.Stop_Sale,b.Display_mode into #Base_Sp_all 
 from [122.147.10.202].DAppResult.dbo.R_dpzb a
 join #Tmp_Spb_all b on a.sfdbh=b.dept_code and a.sspbh=b.item_code 
where 1=1
and a.splbh>='20' and a.splbh<'40' ;
select * from #Base_sp where sfdbh='018425' and splbh='21040110'
--Step 4:门店品类指标计算 drop table #plzb_all
select a.sfdbh,a.splbh,sum(a.nxssl) nxssl,sum(a.nxsje) nxsje,
sum(a.nml) nml,sum(a.nrjxl) nrjxl,
sum(a.nrjxse) nrjxse,sum(a.nrjml) nrjml into #plzb_all 
from #Base_Sp_all a group by a.sfdbh,a.splbh;

-- Step 5 :门店单品综合指标计算,nRjxl:nrjxse:nRjml=4:3:3,折算到nrjxl 上
-- drop table #Base_11
select a.*,case when b.nrjxl<=0  or b.nrjml=0 or b.nrjxse=0 then 0 
 when b.nrjxl>0 and b.nrjxse<>0 and b.nrjml<>0
then  a.nrjxl*0.4+a.nrjxse*0.3*b.nrjxl/b.nrjxse+a.nrjml*0.3*b.nrjxl/b.nrjml
  end nzbz into #Base_11  from #Base_Sp_all a
join #plzb_all b on a.sfdbh=b.sfdbh and a.splbh=b.splbh 
where 1=1 ;

/*
select a.*,b.*,a.nrjxl*0.4,a.nrjxse*0.3*b.nrjxl/b.nrjxse,a.nrjml*0.3*b.nrjxl/b.nrjml  from #Base_Sp a
join #plzb b on a.sfdbh=b.sfdbh and a.splbh=b.splbh 
where 1=1  and a.sfdbh='018425' and a.splbh='21020104' ;

*/
-- select * from #plzb where sfdbh='018425' and splbh='21020104'
-- Step 10.6:对三个背景店单品，做综合计算 drop table #Tmp_zhzb_all;
with x0 as (
select splbh,sspbh,sum(nzbz) nzbz,avg(nzbz) nzbz_avg,
count(distinct sfdbh) nmdjys,78 nzmds,min(nbdxts) nbdxts from #Base_11 
where 1=1 group by splbh,sspbh ) 
select a.*,a.nzbz_avg*a.nmdjys/a.nzmds+a.nzbz*(a.nzmds-a.nmdjys)/(a.nzmds*a.nzmds)
 nzhzb into #Tmp_zhzb_all from x0 a ;

-- Step 10.7:背景门店需要非停购,总部资料需要开通 drop table #Tmp_bj_all
select  item_code sspbh, sum(case when stop_into='N' then 1 else 0 end ) njymds
 into #Tmp_bj_all  from #Tmp_spb_all  where 1=1
group by item_code;

-- Step 10.8:对资料有效单品进行排序，至少两个店资料经营 drop table #Select_sort_all
select a.*,b.njymds,row_number()over(partition by a.splbh order by a.nzhzb desc) npm
into #Select_sort_all from #Tmp_Zhzb_all a
join #Tmp_bj_all b on a.sspbh=b.sspbh and b.njymds>10
left join #r c on a.sspbh=c.sspbh  
where 1=1  and  c.sspbh is null and  a.splbh>='20' and a.splbh<'40'
and  a.nzhzb>0.1;
select *from #r
--Step 10.9 :根据差异选品
with x0 as(
select a.*,b.sfdbh,b.njysps,b.nghs,b.nresult from #Select_sort_all a 
join #bbcpl b on   a.splbh=b.splbh
where a.npm<=abs(b.nghcy) and b.nghcy<0 )
select a.sfdbh 分店编号,c.sfdmc 分店名称,a.sspbh 商品编号,b.name 商品名称,a.splbh 分类编号,
d.sflmc 分类名称
,'' 采购区域,'背景引进' 商品归属属性
,a.njysps 门店陈列商品数,a.nghs 规划数,a.nresult 品类最后保留商品数,
case when e.stop_sale='N' then '保留' else '建议引进' end  
 建议,isnull(e.njhj,b.inprc) 进价,isnull(e.nlsj,b.rtlprc) 售价
 ,case when e.stop_into='N' then '否'
 when e.stop_into IS not null and e.stop_into<>'N' then     '是' end  是否停购,
 case  when e.stop_sale='N' then '否'    when e.stop_sale IS not null and e.stop_sale<>'N' then     '是' end  是否停售
 , e.nrjxl 日均销量,e.nrjxse 日均销售额,e.nrjml 日均毛利额
,a.nbdxts 不动销天数,
a.nzhzb 综合指标,a.nzhzb 背景指标值,a.npm 背景排名 from x0 a 
left join #Tmp_goods b on a.sspbh=b.code
left join #Tmp_fdb c on a.sfdbh=c.sfdbh
left join #Tmp_flb d on a.splbh=d.sflbh
left join #Base_11 e on a.sfdbh=e.sfdbh and a.sspbh=e.sspbh
where 1=1  order by a.splbh;


select a.sflbh,a.sflmc,b.njysps,a.nghs,b.nresult,b.nghcy from #mdgh a left join 
#bbcpl b on a.sfdbh=b.sfdbh and a.sflbh=b.splbh 
where 1=1  order by a.sflbh


 --------- 尾货商品
 -- 导入门店当前库存
 select * into #Tmp_kcb from [122.147.160.32].DApplicationBI.dbo.V_D_PRICE_AND_STOCK
where STORE_CODE in ('018425','018418','018389','018396');

select a.sfdbh,c.sfdmc,a.sspbh,a.sspmc,a.splbh,d.sflmc,a.njhj,a.nlsj,b.scgqy 
,a.nrjxl,a.nrjxse,a.nrjml,a.nbdxts,a.stop_into,a.Stop_sale,e.curr_stock nkc
 from #Base_1  a
 left join #Tmp_goods b on a.sspbh=b.code
left join #Tmp_fdb c on a.sfdbh=c.sfdbh
left join #Tmp_flb d on a.splbh=d.sflbh
left join #Tmp_kcb e on a.sfdbh=e.store_code and a.sspbh=e.item_code
where a.sfdbh='018425' and a.stop_into<>'N'  order by splbh 

