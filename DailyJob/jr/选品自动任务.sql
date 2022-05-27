
-- 0424 卫生巾品类不合并
select  '21030199' sflbh_cal,'低温酸奶综合' sflmc,sflbh  into #Tmp_flb  from  dappresult.dbo.tmp_spflb
where sflbh like '210301%'
union 
select '23040198','米果综合',sflbh from  dappresult.dbo.tmp_spflb where sflbh in (
    '23040103','23040109' )
union
select '24040199','大米综合',sflbh from  dappresult.dbo.tmp_spflb where sflbh  like '240401%'
union
select '31050199','沐浴露综合',sflbh from  dappresult.dbo.tmp_spflb where sflbh in ('31050101','31050102')
union
select  sflbh,sflmc,sflbh from  dappresult.dbo.tmp_spflb where 
sflbh in ('23010104','23010105','23010401','23010403','23010404','23010406',
'23020104','23020106','23020108','23020110','23020111','23020112',
'23040308','23040309','23040310','23040311','23040312','31030204',
'33010401','33010405','33010406','31030201','31030202','31030203','31030206','31030207','31030208'
,'23040301','23040302','23040303','23040304','23040305','23040306',
'23040101','23040102','23040107','23040108' )
union
select sflbh,sflmc,sflbh from  dappresult.dbo.tmp_spflb where sflbh  like '230801%';
 
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
  select distinct 'jr' sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sFlbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje, a.nMl  nMl,c.sGys,
 c.sSpbhBz,0 sState,c.nBzt,isnull(convert(money,d.sYsValue),0) nGg,GETDATE() dCreateDate,h.sYsValue sPp,'' sGn,
 ISNULL(f.spec,c.Spec) sGg,0  ndc into #jysp
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
    delete from DAppResult.dbo.Input_Xp_Sp_Fd where sSpbh in (select distinct sSpbh from #jysp)  or sFlbh in (select distinct sFlbh from #jysp)
	delete from DAppResult.dbo.Input_Xp_Sp_All_Fd where sSpbh in (select distinct sspbh from #jysp)  or sFlbh in (select distinct sFlbh from #jysp)
    -- 写入数据
    insert into DAppResult.dbo.Input_Xp_Sp_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl, nXse,nMl,
	sGys,sGjtm,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nxsje nXse,nMl,
	sGys,sSpbhBz,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc from #jysp
    union
    select a.sQybh,'0000' sfdbh,a.sSpbh,a.sflbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	sum(a.nXsje),sum(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) sState,max(a.nBzt),max(convert(money,a.ngg) ), GETDATE()  dCreateDate,
    max(a.spp),MAX('') ,max( a.sGg ) sGg, 0 ndc from #jysp a  group by a.sQybh,a.sSpbh,a.sFlbh;
  
  insert into DAppResult.dbo.Input_Xp_Sp_All_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXse,nMl,sGys,sGjtm,nSsts,nBzt,nGg,
      dCreateDate,sPp,sGn,sGg,nDc)
    select a.sQybh,'0000' ,a.sSpbh,a.sFlbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	sum(a.nXsje),avg(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) nSsts,max(a.nBzt),max(convert(money,a.ngg)), GETDATE()  dCreateDate,
	max(a.spp),MAX(a.sGn) ,max(a.sGg) sGg, 0 ndc from #jysp a group by a.sQybh,a.sSpbh,a.sFlbh;
  



-- Step 5： 总指标更新
	 -- 5.1 品类总指标
     if OBJECT_ID('tempdb..#zzb1') is not null  
		begin 
			drop table #zzb1 
		end
	 select a.sflbh, SUM(a.nXse) as xse,SUM(a.nml) as ml,SUM(a.npxs) as pxs into #zzb1 
	 from DAppResult.dbo.Input_Xp_Sp_Fd a where sfdbh='0000'
	  group by a.sflbh;
	 -- 5.2 当期总门店数
	 if OBJECT_ID('tempdb..#zzb2') is not null  
		begin 
			drop table #zzb2 
		end
	 select  4 nzds into #zzb2 

	-- 5.3 计算指标
	if OBJECT_ID('tempdb..#zzb3') is not null  
		begin 
			drop table #zzb3 
		end
    select a.sSpbh,SUM(a.nXse*b.pxs/(b.xse+0.00001)*0.3 + a.nml*b.pxs/(b.ml+0.00001)*0.3 + a.npxs*0.4) 
	as nZbz, count(a.sFdbh) as Jyds into #zzb3 from  #zzb1 b, DAppResult.dbo.Input_Xp_Sp_Fd a
	where      a.sFdbh='0000' and b.sflbh=a.sflbh  
	  group by a.sspbh;

	delete from DAppResult.dbo.Input_Xp_Zbz where sSpbh in (select sSpbh from #zzb3)

	insert into DAppResult.dbo.Input_Xp_Zbz(sSpbh,nZbz,nJyds,nZds)
	select a.sSpbh,case when a.nZbz<=0 then 0 else a.nZbz end,a.Jyds ,b.* from #zzb3 a,#zzb2 b;