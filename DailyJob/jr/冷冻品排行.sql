--  冷冻品商品排行

-- Step 0:准备销售，选取生活超市
-- drop table #Tmp_fdb
select * into #Tmp_fdb from [122.147.10.200].dappsource.dbo.tmp_fdb c
where    c.smdlx in ('嘉荣SPAR生活超市','生活超市') and c.sjylx='连锁门店' and c.dkyrq is not null 
and c.sjc  not like '%取消%' ;

select * into #goods from [122.147.10.200].dappsource.dbo.goods;
select * into #Tmp_spflb from [122.147.10.200].dappsource.dbo.tmp_spflb;


select  * into #1 from  dappresult.dbo.H_Dpzb a
 where 1=1 and   RIGHT(TaskID,8)>='20210501' and RIGHT(TaskID,8)<='20210731'
 and a.sfdbh in (select sfdbh from #Tmp_fdb );
  
  select   a.sfdbh,a.sspbh,isnull(b.sFl, a.splbh) sfl,max(b.sspmc)sspmc,
  MAX(b.njj) njhj , MAX(b.nsj) nlsj,SUM(a.nxsje)/3 nxsje,
 SUM(a.nml)/3 nml, SUM(a.nPxs)/3 nPxs  into #zb
 from #1  a
 left join DAppStore.dbo.Tmp_spb_all b on a.sspbh=b.sspbh
 where RIGHT(TaskID,8) in ( '20210731','20210626', '20210529')
 and splbh>'20' and splbh<'40'  
 group by a.sfdbh,a.sspbh,isnull(b.sFl, a.splbh);


-- Step 1:指标综合 
select a.*,LEFT(a.sfl,6) sxlbh,b.isnormal into #base_data   from #zb a 
join #goods b on a.sspbh=b.code and b.isnormal='冷冻商品'
where 1=1 ;

-- Step 2:门店品类指标计算 drop table #plzb
select a.sfdbh,a.sxlbh sFlbh,sum(a.nxsje) nxsje,
sum(a.nml) nml,sum(a.nPxs) nPxs  into #plzb 
from #base_data a group by a.sfdbh,a.sxlbh;

-- Step 3:
select a.*,case when b.nPxs<=0  or b.nml=0 or b.nxsje=0 then 0 
 when b.nPxs>0 and b.nxsje<>0 and b.nml<>0
then  a.nPxs*0.4+a.nxsje*0.3*b.nPxs/b.nxsje+a.nml*0.3*b.nPxs/b.nml
  end nzbz into #Base_1  from #Base_data a
join #plzb b on a.sfdbh=b.sfdbh and a.sxlbh=b.sFlbh 
where 1=1 ;

-- Step 4
with x0 as (
select sxlbh splbh,sspbh,sum(nzbz) nzbz,avg(nzbz) nzbz_avg,
count(distinct sfdbh) nmdjys,24 nzmds  from #Base_1 
where 1=1 group by sxlbh,sspbh ) 
select a.*,a.nzbz_avg*a.nmdjys/a.nzmds+a.nzbz*(a.nzmds-a.nmdjys)/(a.nzmds*a.nzmds)
 nzhzb into #Tmp_zhzb from x0 a ;

select a.splbh,c.sflmc,a.sSpbh,b.code2,b.name,a.nzhzb,
ROW_NUMBER()over(partition by a.splbh order by a.nzhzb desc) npm from #Tmp_zhzb a
left join #goods b on a.sSpbh=b.code
left join #Tmp_spflb c on a.splbh=c.sflbh
where 1=1  order by a.splbh,npm 