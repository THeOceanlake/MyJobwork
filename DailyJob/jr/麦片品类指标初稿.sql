1、JR重点品类


select  sflbh sflbh_cal,  sflmc,sflbh into #tmp_flb from dbo.tmp_spflb
where sflbh like '230803%';

 

-- 准备阶段
select distinct sflbh_cal,sflbh into #sflb from  #tmp_flb a 
where  1=1 ; 
-- Step 0 :获取数据
--  select distinct 'jr' sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sFlbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,case when a.nml<=0 then 0 else a.nMl end nMl,c.sGys,
--  c.sSpbhBz,0 sState,c.nBzt,isnull(convert(money,d.ngg),0) *convert(int,isnull(d.nxsbzs,1)) nGg,GETDATE() dCreateDate,f.brand sPp,'' sGn,ISNULL(f.spec,c.Spec) sGg,
--  case when isnull(convert(money,d.ngg),0) *convert(int,isnull(d.nxsbzs,1))>0 then a.nLsj/(isnull(convert(money,d.ngg),0) *convert(int,isnull(d.nxsbzs,1))) else 0 end ndc into #jysp
--   from DAppResult.dbo.R_Dpzb a  
--  join DAppResult.dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
--  left join DAppStore.dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
--  left join  master.dbo.TMP_DXP_BZGG d on a.sSpbh=d.sSpbh  
--    join [122.147.10.200].DAppSource.dbo.p_shop_item_output e on a.sFdbh=e.dept_code and a.sSpbh=e.item_code
--    left join [122.147.10.200].DAppSource.dbo.goods_all f on a.sSpbh=f.code
-- join #sflb g on a.splbh=g.sflbh
--  where 1=1 and   b.sjylx='连锁门店' and b.sFDBH in  ('018425','018418','018389','018396')
--  and b.sFDMC not like '%取消%' and  e.validate_flag='Y' and e.CHARACTER_TYPE='N' 
--  and e.stop_into='N' and e.stop_sale='N' and b.dKyrq is not null ;


 --------0424 
  select distinct 'jr' sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sFlbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,case when a.nml<=0 then 0 else a.nMl end nMl,c.sGys,
 c.sSpbhBz,0 sState,c.nBzt,isnull(convert(money,d.sYsValue),0) nGg,GETDATE() dCreateDate,h.sYsValue sPp,'' sGn,
 ISNULL(f.spec,c.Spec) sGg,
 case when isnull(convert(money,d.sYsValue),0)>0 then a.nLsj/( isnull(convert(money,d.sYsValue),0)) else 0 end ndc into #jysp
  from DAppResult.dbo.R_Dpzb a  
 join DAppResult.dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
 left join DAppStore.dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
 left join  master.dbo.TMP_DXP_TASTE d on a.sSpbh=d.sSpbh  and  d.sFlys='规格' 
  left join  master.dbo.TMP_DXP_TASTE h on a.sSpbh=h.sSpbh  and  h.sFlys='品牌' 
   join [122.147.10.200].DAppSource.dbo.p_shop_item_output e on a.sFdbh=e.dept_code and a.sSpbh=e.item_code
   left join [122.147.10.200].DAppSource.dbo.goods_all f on a.sSpbh=f.code
join #sflb g on a.splbh=g.sflbh
 where 1=1 and   b.sjylx='连锁门店' and b.sFDBH in  ('018425','018418','018389','018396')
 and b.sFDMC not like '%取消%' and  e.validate_flag='Y' and e.CHARACTER_TYPE='N' 
 and e.stop_into='N' and e.stop_sale='N' and b.dKyrq is not null ;

    -- 删除原有数据-按单品颗粒度
    delete from dbo.Input_Xp_Sp_Fd where sSpbh in (select distinct sSpbh from #jysp)  or sFlbh in (select distinct sFlbh from #jysp)
	delete from dbo.Input_Xp_Sp_All_Fd where sSpbh in (select distinct sspbh from #jysp)  or sFlbh in (select distinct sFlbh from #jysp)
    -- 写入数据
    insert into dbo.Input_Xp_Sp_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl, nXse,nMl,
	sGys,sGjtm,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nxsje nXse,nMl,
	sGys,sSpbhBz,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc from #jysp
    union
    select a.sQybh,'0000' sfdbh,a.sSpbh,a.sflbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	sum(a.nXsje),sum(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) sState,max(a.nBzt),max(convert(money,a.ngg) ), GETDATE()  dCreateDate,
    max(a.spp),MAX('') ,max( a.sGg ) sGg, 0 ndc from #jysp a  group by a.sQybh,a.sSpbh,a.sFlbh;
  
  insert into dbo.Input_Xp_Sp_All_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXse,nMl,sGys,sGjtm,nSsts,nBzt,nGg,
      dCreateDate,sPp,sGn,sGg,nDc)
    select a.sQybh,'0000' ,a.sSpbh,a.sFlbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	 sum(a.nXsje),avg(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) nSsts,max(a.nBzt),max(convert(money,a.ngg)), GETDATE()  dCreateDate,
	  max(a.spp),MAX(a.sGn) ,max(a.sGg) sGg, 0 ndc from #jysp a group by a.sQybh,a.sSpbh,a.sFlbh;