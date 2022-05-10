-- Step 1 :计算分类
        select sflbh into #sflb from    [AppLinker].dapplication.dbo.Base_flb 
        where  1=1 and UpdateTime>'2021-12-01'  and syt='02';
-- Step 2:有效分店,首先找到 drop table #sfd
        /* 从R_dpzb 找结束时间最多的时间，再匹配这个时间下的门店，就是有效门店 */
		with x0 as (
		select  a.EndDate,count(distinct a.sFdbh) nfds  from R_KPI a group by a.EndDate)
		,x1 as (select  a.EndDate,ROW_NUMBER()over(order by a.nfds desc) npm  from x0  a )
		select  a.sFdbh,a.sFdmc,a.sFDLX,a.EndDate  into #sfd from  R_KPI a,
		dbo.tmp_fdb b  where  a.EndDate in ( select EndDate from x1  where npm=1) and a.sFdbh=b.sFDBH
		
 -- 标准库 导入
  select * into #tmp_base_sp from [AppLinker].dapplication.dbo.Base_sp ;

  -- 排除相同国际条码商品
  with x0 as (
  select a.sSpbhBz,a.sFdbh,count(1) nsps  from  R_Dpzb a 
  where sspbhbz  is not null  group by a.sSpbhBz,a.sFdbh  having COUNT(1)>1)
  select distinct sspbhbz  into #sp_ex from x0 ;

--Step 3: 计算门店经营指标
    select distinct '#USERID#' sQybh,a.sFdbh,c.sSpbhBz sspbh,g.sflbh02 sFlbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,a.nMl,c.sGys,
	a.sSpbhBz sGjtm,0 sState,c.nBzt,g.nGg nGg,GETDATE() dCreateDate,g.spp,g.sGn,g.sGg , 0 ndc into #jysp
	from  dbo.R_Dpzb a  
	 join  dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join  dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	 left join  dbo.tmp_spflb f on a.sPlbh=f.sFlbh 
	 join  #tmp_base_sp  g on c.sSpbhBz=g.sSpbh  
	 join Tmp_spb_All h on a.sSpbh=h.sSpbh  
	 where 1=1 and  g.sflbh02 in ( select sFlbh from #sflb) and  a.sFdbh in (select sFdbh from #sfd)
	 and a.sSpbhBz not in (select sSpbhBz from #sp_ex)
    
 -- Step 3.2：计算背景商品,分模式，如果是标准库做背景，则不导
      select distinct '#USERID#'  sQybh,a.sFdbh,c.sSpbhBz sSpbh,g.sflbh02 sFlbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,a.nMl,c.sGys,
     a.sSpbhBz sGjtm,0 nssts,c.nBzt,g.nGg nGg,GETDATE() dCreateDate,g.spp,g.sGn,g.sGg , 0 ndc into #bjsp
     from dbo.R_Dpzb a  
	 join dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	left join dbo.tmp_spflb f on a.sPlbh=f.sFlbh 
    join  #tmp_base_sp g on c.sSpbhBz=g.sSpbh  
    join Tmp_spb_All h on a.sSpbh=h.sSpbh  
	 where 1=1 and g.sflbh02 in ( select sFlbh from #sflb) and  a.sFdbh in (select sFdbh from #sfd)
	 and a.sSpbhBz not in (select sSpbhBz from #sp_ex)

-- Step 4:写入数据
	delete from dbo.Input_Xp_Sp_Fd where sFlbh in (select distinct sFlbh from #jysp);
	delete from dbo.Input_Xp_Sp_All_Fd where sFlbh in (select distinct from #bjsp);

	insert into dbo.Input_Xp_Sp_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXse,nMl,
	sGys,sGjtm,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc)
	select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXsje,nMl,
	sGys,sGjtm,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc from #jysp
	union
	select a.sQybh, '0000' sFdbh,a.sspbh, a.sFlbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	sum(a.nXsje),sum(a.nMl),max(a.sGys),max(a.sGjtm),max(0) sState,max(a.nBzt),max(a.nGg), GETDATE()  dCreateDate,
    max(a.spp),MAX(a.sGn) ,max(a.sGg ) sGg, 0 ndc
     from  #jysp a group by a.sQybh,a.sspbh,a.sFlbh  ; 

	 insert into dbo.Input_Xp_Sp_All_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXse,nMl,sGys,sGjtm,nSsts,nBzt,nGg,
      dCreateDate,sPp,sGn,sGg,nDc)
      select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXsje,nMl,sGys,sGjtm,nSsts,nBzt,nGg,
      dCreateDate,sPp,sGn,sGg,nDc from #bjsp 
       union 
	 select a.sQybh, '0000' sFdbh,a.sspbh, a.sFlbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	 sum(a.nXsje),sum(a.nMl),max(a.sGys),max(a.sGjtm),max(0) nssts,max(a.nBzt),max(a.nGg), GETDATE()  dCreateDate,
     max(a.spp),MAX(a.sGn) ,max(a.sGg ) sGg, 0 ndc
     from  #bjsp a group by a.sQybh,a.sspbh,a.sFlbh  ; 

 -- Step 5： 总指标更新
	 -- 5.1 品类总指标
     if OBJECT_ID('tempdb..#zzb1') is not null  
		begin 
			drop table #zzb1 
		end
	 select a.sFlbh , SUM(a.nXse) as xse,SUM(a.nml) as ml,SUM(a.npxs) as pxs into #zzb1 
	 from dbo.Input_Xp_Sp_Fd a
	 where 1=1  and a.sFdbh='0000' and   a.sFlbh in (select sFlbh from #sflb ) 
	  group by a.sFlbh;
	 -- 5.2 当期总门店数
	 if OBJECT_ID('tempdb..#zzb2') is not null  
		begin 
			drop table #zzb2 
		end
	 select count(distinct a.sfdbh) nzds into #zzb2 from dbo.R_Kpi a
	 ,dbo.tmp_fdb b
	 where 1=1  and a.EndDate in (select distinct EndDate from #sfd) and a.sfdbh=b.sfdbh;

	-- 5.3 计算指标
	if OBJECT_ID('tempdb..#zzb3') is not null  
		begin 
			drop table #zzb3 
		end
        
     select a.sSpbh,SUM(a.nXse*b.pxs/(b.xse+0.00001)*0.3 + a.nml*b.pxs/(b.ml+0.00001)*0.4 + a.npxs*0.3) 
	as nZbz, count(a.sFdbh) as Jyds into #zzb3 from  #zzb1 b, Input_Xp_Sp_Fd a
	where      a.sFdbh='0000' and b.sflbh=a.sflbh  
	  group by a.sspbh;

	delete from dbo.Input_Xp_Zbz where sSpbh in (select sSpbh from #zzb3)

	insert into dbo.Input_Xp_Zbz(sSpbh,nZbz,nJyds,nZds)
	select a.*,b.* from #zzb3 a,#zzb2 b;

       --  update BD_Sp set sFlbh=sFlbh_User

	update a set a.sYsValue_V=c.sYsValue from  DAppResult.dbo.Xp_BD_Flys_Value a 
	join master.dbo.TMP_DXP_TASTE c   on a.sSpbh=c.sSpbh and a.sFlys=c.sflys
	where 1=1  and ISNUMERIC(c.sYsValue)=1 ;

	update a set a.sYsValue_V=c.sYsValue from  DAppResult.dbo.Xp_BD_Flys_Value_All a 
	join master.dbo.TMP_DXP_TASTE c   on a.sSpbh=c.sSpbh and a.sFlys=c.sflys
	where 1=1 and ISNUMERIC(c.sYsValue)=1 ;


	update a set a.sYsValue=c.sYsValue from  DAppResult.dbo.Xp_BD_Flys_Value a 
	join master.dbo.TMP_DXP_TASTE c   on a.sSpbh=c.sSpbh and a.sFlys=c.sflys
	where 1=1  and ISNUMERIC(c.sYsValue)=0 ;

	update a set a.sYsValue=c.sYsValue from  DAppResult.dbo.Xp_BD_Flys_Value_All a 
	join master.dbo.TMP_DXP_TASTE c   on a.sSpbh=c.sSpbh and a.sFlys=c.sflys
	where 1=1  and ISNUMERIC(c.sYsValue)=0  ;

