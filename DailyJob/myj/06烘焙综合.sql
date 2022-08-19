----------- 2022-07-22 结果
 select  '069999' sflbh_cal,'烘焙综合' sflmc,sflbh into #Tmp_flb  from dbo.tmp_spflb
    where  sflbh like '06%' and LEN(sflbh)=6
    
    select sflbh into #sflb from  #Tmp_flb; 
-- Step 2:有效分店,首先找到 drop table #sfd
        /* 从R_dpzb 找结束时间最多的时间，再匹配这个时间下的门店，就是有效门店 */
    
    select a.smblx,a.sfdbh,a.shjlx,a.sxsdj,a.nsku  into #sfd  from Tmp_fdb_Mb a 
    where 1=1 ; 
    
    -- 在这里就能够将不同 门店合并成不同的背景
	 with x0 as(
	    select   a.sFdbh,b.sMblx,sum(a.nXsje) nxsje,COUNT(1) nsps  from R_Dpzb a
     join Tmp_fdb_mb b on a.sFdbh=b.sfdbh  
   where  a.sPlbh like '06%' group by a.sFdbh ,b.sMblx)
	select distinct  a.sFdbh,a.sMblx  into #sfd_hz 
    from  #sfd a  where a.sfdbh in (select sfdbh from x0 )
    
	-- drop table #xp_sp;
    --select DISTINCT a.sspbh,a.sLx into #xp_sp from tmp_spb_mb a 
    --join (select distinct smblx from #sfd) b on a.sMblx=b.sMblx
    --where  1=1  and a.sLx is not null;
	-- select * from #xp_sp 
    select * into #dpzb from dbo.R_Dpzb;
    --select * into #dpzb from dbo.H_dpzb where right(taskid,8)='20220710';
	-- drop table #jysp
    select distinct 'myj' sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sflbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,
	a.nMl ,c.sGys,
	c.sSpbhBz,0 sState,c.nBzt,replace(replace(c.sGg,'g',''),'ml','') nGg,GETDATE() dCreateDate,c.spp,'' sGn,c.sGg , 0 ndc 
    into #jysp 
	from  #dpzb  a  
	 join  dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join  dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	 left join  dbo.tmp_spflb f on a.sPlbh=f.sFlbh  
	 join Tmp_spb_All h on a.sSpbh=h.sSpbh  
	 join #Tmp_flb g on a.sPlbh=g.sFlbh
	 where 1=1 and    a.sFdbh in (select sFdbh from #sfd) 
	 

	 -- drop table #bjsp
      select distinct 'myj'  sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sflbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,a.nMl,c.sGys,
     c.sSpbhBz,0 nSsts,c.nBzt,replace(replace(c.sGg,'g',''),'ml','')   nGg,GETDATE() dCreateDate,c.spp,'' sGn,c.sGg , 0 ndc
     into #bjsp from #dpzb  a  
	 join dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	left join dbo.tmp_spflb f on a.sPlbh=f.sFlbh  
    join Tmp_spb_All h on a.sSpbh=h.sSpbh  
	 join #Tmp_flb g on a.sPlbh=g.sFlbh
	 where 1=1  and  a.sFdbh in (select sFdbh from #sfd) ;




    delete from dbo.Input_Xp_Sp_Fd where sSpbh in (select distinct sSpbh from #jysp)  or sFlbh in (select distinct sFlbh from #jysp)
	delete from dbo.Input_Xp_Sp_All_Fd where sSpbh in (select distinct sspbh from #bjsp)  or sFlbh in (select distinct sFlbh from #bjsp)
    -- 写入数据
    insert into dbo.Input_Xp_Sp_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl, nXse,nMl,
	sGys,sGjtm,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nxsje nXse,nMl,
	sGys,sSpbhBz,sState,nBzt,case  when ISNUMERIC(ngg)=0 then CONVERT(money,'') else  nGg end nGg,dCreateDate,sPp,sGn,sGg,nDc from #jysp
    union
    select a.sQybh,'0000' sfdbh,a.sSpbh,a.sflbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	sum(a.nXsje),sum(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) sState,max(a.nBzt),max(convert(money,'') ), GETDATE()  dCreateDate,
    max(a.spp),MAX('') ,max( a.sGg ) sGg, 0 ndc from #jysp a
	where  a.sFdbh in (select sFdbh from #sfd_hz)  group by a.sQybh,a.sSpbh,a.sFlbh;

    insert into dbo.Input_Xp_Sp_All_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXse,nMl,sGys,sGjtm,nSsts,nBzt,nGg,
      dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXsje nXse,nMl,sGys,sSpbhBz,nSsts,nBzt,convert(money,'') nGg,
      dCreateDate,sPp,sGn,sGg,nDc from #bjsp a 
      union
    select a.sQybh,'0000' ,a.sSpbh,a.sFlbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	 sum(a.nXsje),avg(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) nSsts,max(a.nBzt),max(convert(money,'')), GETDATE()  dCreateDate,
	  max(a.spp),MAX(a.sGn) ,max(a.sGg) sGg, 0 ndc from #bjsp a
	  where    a.sFdbh in (select sFdbh from #sfd_hz) group by a.sQybh,a.sSpbh,a.sFlbh;


 -- Step 5： 总指标更新
	 -- 5.1 品类总指标
     if OBJECT_ID('tempdb..#zzb1') is not null  
		begin 
			drop table #zzb1 
		end
	 select a.sflbh, SUM(a.nXse) as xse,SUM(a.nml) as ml,SUM(a.npxs) as pxs into #zzb1 
	 from Input_Xp_Sp_Fd a where sfdbh='0000'
	  group by a.sflbh;
	 -- 5.2 当期总门店数
	 if OBJECT_ID('tempdb..#zzb2') is not null  
		begin 
			drop table #zzb2 
		end
	 select count(distinct a.sfdbh) nzds into #zzb2 from  #sfd_hz a

	 select * from #zzb2
	-- 5.3 计算指标
	if OBJECT_ID('tempdb..#zzb3') is not null  
		begin 
			drop table #zzb3 
		end
  with x0 as(
		select a.sspbh,a.sflbh,COUNT(distinct a.sFdbh) njyfds from Input_Xp_Sp_Fd a where a.sfdbh not in('0000','Test001')
	group by a.sspbh,a.sFlbh)
    select a.sSpbh,SUM(a.nXse*b.pxs/(b.xse+0.00001)*0.4 + a.nml*b.pxs/(b.ml+0.00001)*0.3 + a.npxs*0.3) 
	as nZbz, max(c.njyfds) as Jyds into #zzb3 from  #zzb1 b, Input_Xp_Sp_Fd a,x0 c
	where      a.sFdbh='0000' and b.sflbh=a.sflbh  and a.sspbh=c.sspbh and a.sflbh=c.sflbh 
	  group by a.sspbh;
	delete from dbo.Input_Xp_Zbz where sSpbh in (select sSpbh from #zzb3)

	insert into dbo.Input_Xp_Zbz(sSpbh,nZbz,nJyds,nZds)
	select a.sSpbh,case when a.nZbz<0 then 0 else a.nZbz end,a.Jyds,b.nzds from #zzb3 a,#zzb2 b;


    update a set a.sYsValue=case  when b.nBzt>=0 and b.nBzt<5 then '0-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<30 then '20-29天'
	when b.nBzt>=30 and b.nBzt<50 then '30-49天'
	when b.nBzt>=50 and b.nBzt<70 then '50-69天'
	when b.nBzt>=70 and b.nBzt<90 then '70-89天'
	when b.nBzt>=90 then  '90天及以上'
	 end,
	a.sYsValue_V=case  when b.nBzt>=0 and b.nBzt<5 then '0-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<30 then '20-29天'
	when b.nBzt>=30 and b.nBzt<50 then '30-49天'
	when b.nBzt>=50 and b.nBzt<70 then '50-69天'
	when b.nBzt>=70 and b.nBzt<90 then '70-89天'
	when b.nBzt>=90 then  '90天及以上'
	 end from dbo.Xp_BD_Flys_Value_All a 
	left join Tmp_spb_All b on a.sSpbh=b.sSpbh
	where a.sFlys='保质期' and len(a.sYsValue_V)=0 and a.sFlbh='069999'


    update a set a.sYsValue=case  when b.nBzt>=0 and b.nBzt<5 then '0-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<30 then '20-29天'
	when b.nBzt>=30 and b.nBzt<50 then '30-49天'
	when b.nBzt>=50 and b.nBzt<70 then '50-69天'
	when b.nBzt>=70 and b.nBzt<90 then '70-89天'
	when b.nBzt>=90 then  '90天及以上'
	 end,
	a.sYsValue_V=case  when b.nBzt>=0 and b.nBzt<5 then '0-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<30 then '20-29天'
	when b.nBzt>=30 and b.nBzt<50 then '30-49天'
	when b.nBzt>=50 and b.nBzt<70 then '50-69天'
	when b.nBzt>=70 and b.nBzt<90 then '70-89天'
	when b.nBzt>=90 then  '90天及以上'
	 end from dbo.Xp_BD_Flys_Value_All a 
	left join Tmp_spb_All b on a.sSpbh=b.sSpbh
	where a.sFlys='保质期' and len(a.sYsValue_V)=0 and a.sFlbh='069999'






    ---------------
   ----------- 2022-07-22 结果
    select  '069999' sflbh_cal,'烘焙综合' sflmc,sflbh into #Tmp_flb  from dbo.tmp_spflb
    where  sflbh like '06%' and LEN(sflbh)=6
    
    select sflbh into #sflb from  #Tmp_flb; 

	select * from Tmp_FDB 

-- Step 2:有效分店,首先找到 drop table #sfd
        /* 从R_dpzb 找结束时间最多的时间，再匹配这个时间下的门店，就是有效门店 */
    
    select distinct Tmplate_id,Tmplate_name into #mb from Tmp_mbsp  where slx=1;

	-- drop table #sfd
    select b.Tmplate_name smblx,a.sfdbh  into #sfd  from Tmp_fdb  a 
	join #mb b on a.hongbei_template_id=b.Tmplate_id
    where 1=1 ;  


    -- 在这里就能够将不同 门店合并成不同的背景
	 with x0 as(
	    select   a.sFdbh,b.sMblx,sum(a.nXsje) nxsje,COUNT(1) nsps  from R_Dpzb a
     join Tmp_fdb_mb b on a.sFdbh=b.sfdbh  
   where  a.sPlbh like '06%' group by a.sFdbh ,b.sMblx )
	select distinct  a.sFdbh,a.sMblx  into #sfd_hz 
    from  #sfd a  where a.sfdbh in (select sfdbh from x0 )
    
	-- drop table #xp_sp;
    --select DISTINCT a.sspbh,a.sLx into #xp_sp from tmp_spb_mb a 
    --join (select distinct smblx from #sfd) b on a.sMblx=b.sMblx
    --where  1=1  and a.sLx is not null;
	-- select * from #xp_sp 
    select * into #dpzb from  dbo.R_Dpzb;
    --select * into #dpzb from dbo.H_dpzb where right(taskid,8)='20220710';
	-- drop table #jysp
    select distinct 'myj' sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sflbh,a.nJhj,a.nLsj,
	case  when  i.nRjxl>0 and i.nRjxl_De/i.nRjxl>=1.5  then  a.nPxs*i.nRjxl_De/i.nRjxl
	  else  a.nPxs end npxs,a.sSpmc,a.sDw,case  when  i.nRjxl>0 and i.nRjxl_De/i.nRjxl>=1.5  then  a.nXssl*i.nRjxl_De/i.nRjxl
	  else  a.nXssl end nxssl, case  when  i.nRjxl>0 and i.nRjxl_De/i.nRjxl>=1.5  then  a.nXsje*i.nRjxl_De/i.nRjxl
	  else  a.nXsje end nxsje,
	  case  when  i.nRjxl>0 and i.nRjxl_De/i.nRjxl>=1.5  then  a.nMl*i.nRjxl_De/i.nRjxl
	  else  a.nMl end nMl ,c.sGys,
	c.sSpbhBz,0 sState,c.nBzt,replace(replace(c.sGg,'g',''),'ml','') nGg,GETDATE() dCreateDate,c.spp,'' sGn,c.sGg , 0 ndc 
    into #jysp 
	from  #dpzb  a  
	 join  dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join  dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	 left join  dbo.tmp_spflb f on a.sPlbh=f.sFlbh  
	 join Tmp_spb_All h on a.sSpbh=h.sSpbh  
	 join #Tmp_flb g on a.sPlbh=g.sFlbh
	 left join dbo.Sys_GoodsConfig  i on a.sFdbh=i.sfdbh  and a.sSpbh=i.sSpbh
	 where 1=1 and    a.sFdbh in (select sFdbh from #sfd) ;
	  
	  
	 

	 -- drop table #bjsp
      select distinct 'myj'  sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sflbh,a.nJhj,a.nLsj,case  when  i.nRjxl>0 and i.nRjxl_De/i.nRjxl>=1.5  then  a.nPxs*i.nRjxl_De/i.nRjxl
	  else  a.nPxs end nPxs,a.sSpmc,a.sDw,case  when  i.nRjxl>0 and i.nRjxl_De/i.nRjxl>=1.5  then  a.nXssl*i.nRjxl_De/i.nRjxl
	  else  a.nXssl end nXssl, case  when  i.nRjxl>0 and i.nRjxl_De/i.nRjxl>=1.5  then  a.nXsje*i.nRjxl_De/i.nRjxl
	  else  a.nXsje end nXsje,case  when  i.nRjxl>0 and i.nRjxl_De/i.nRjxl>=1.5  then  a.nMl*i.nRjxl_De/i.nRjxl
	  else  a.nMl end nMl,c.sGys,
     c.sSpbhBz,0 nSsts,c.nBzt,replace(replace(c.sGg,'g',''),'ml','')   nGg,GETDATE() dCreateDate,c.spp,'' sGn,c.sGg , 0 ndc
     into #bjsp from #dpzb  a  
	 join dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	left join dbo.tmp_spflb f on a.sPlbh=f.sFlbh  
    join Tmp_spb_All h on a.sSpbh=h.sSpbh  
	 join #Tmp_flb g on a.sPlbh=g.sFlbh
	 left join dbo.Sys_GoodsConfig  i on a.sFdbh=i.sfdbh  and a.sSpbh=i.sSpbh
	 where 1=1  and  a.sFdbh in (select sFdbh from #sfd) ;




    delete from dbo.Input_Xp_Sp_Fd where sSpbh in (select distinct sSpbh from #jysp)  or sFlbh in (select distinct sFlbh from #jysp)
	delete from dbo.Input_Xp_Sp_All_Fd where sSpbh in (select distinct sspbh from #bjsp)  or sFlbh in (select distinct sFlbh from #bjsp)
    -- 写入数据
    insert into dbo.Input_Xp_Sp_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl, nXse,nMl,
	sGys,sGjtm,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nxsje nXse,nMl,
	sGys,sSpbhBz,sState,nBzt,case  when ISNUMERIC(ngg)=0 then CONVERT(money,'') else  nGg end nGg,dCreateDate,sPp,sGn,sGg,nDc from #jysp
    union
    select a.sQybh,'0000' sfdbh,a.sSpbh,a.sflbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	sum(a.nXsje),sum(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) sState,max(a.nBzt),max(convert(money,'') ), GETDATE()  dCreateDate,
    max(a.spp),MAX('') ,max( a.sGg ) sGg, 0 ndc from #jysp a
	where  a.sFdbh in (select sFdbh from #sfd_hz)  group by a.sQybh,a.sSpbh,a.sFlbh;

    insert into dbo.Input_Xp_Sp_All_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXse,nMl,sGys,sGjtm,nSsts,nBzt,nGg,
      dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXsje nXse,nMl,sGys,sSpbhBz,nSsts,nBzt,convert(money,'') nGg,
      dCreateDate,sPp,sGn,sGg,nDc from #bjsp a 
      union
    select a.sQybh,'0000' ,a.sSpbh,a.sFlbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	 sum(a.nXsje),avg(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) nSsts,max(a.nBzt),max(convert(money,'')), GETDATE()  dCreateDate,
	  max(a.spp),MAX(a.sGn) ,max(a.sGg) sGg, 0 ndc from #bjsp a
	  where    a.sFdbh in (select sFdbh from #sfd_hz) group by a.sQybh,a.sSpbh,a.sFlbh;


 -- Step 5： 总指标更新
	 -- 5.1 品类总指标
     if OBJECT_ID('tempdb..#zzb1') is not null  
		begin 
			drop table #zzb1 
		end
	 select a.sflbh, SUM(a.nXse) as xse,SUM(a.nml) as ml,SUM(a.npxs) as pxs into #zzb1 
	 from Input_Xp_Sp_Fd a where sfdbh='0000'
	  group by a.sflbh;
	 -- 5.2 当期总门店数
	 if OBJECT_ID('tempdb..#zzb2') is not null  
		begin 
			drop table #zzb2 
		end
	 select count(distinct a.sfdbh) nzds into #zzb2 from  #sfd_hz a

	 select * from #zzb2
	-- 5.3 计算指标
	if OBJECT_ID('tempdb..#zzb3') is not null  
		begin 
			drop table #zzb3 
		end
  with x0 as(
		select a.sspbh,a.sflbh,COUNT(distinct a.sFdbh) njyfds from Input_Xp_Sp_Fd a where a.sfdbh not in('0000','Test001')
	group by a.sspbh,a.sFlbh)
    select a.sSpbh,SUM(a.nXse*b.pxs/(b.xse+0.00001)*0.4 + a.nml*b.pxs/(b.ml+0.00001)*0.3 + a.npxs*0.3) 
	as nZbz, max(c.njyfds) as Jyds into #zzb3 from  #zzb1 b, Input_Xp_Sp_Fd a,x0 c
	where      a.sFdbh='0000' and b.sflbh=a.sflbh  and a.sspbh=c.sspbh and a.sflbh=c.sflbh 
	  group by a.sspbh;
	delete from dbo.Input_Xp_Zbz where sSpbh in (select sSpbh from #zzb3)

	insert into dbo.Input_Xp_Zbz(sSpbh,nZbz,nJyds,nZds)
	select a.sSpbh,case when a.nZbz<0 then 0 else a.nZbz end,a.Jyds,b.nzds from #zzb3 a,#zzb2 b;


    update a set a.sYsValue=case  when b.nBzt>=0 and b.nBzt<5 then '0-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<30 then '20-29天'
	when b.nBzt>=30 and b.nBzt<50 then '30-49天'
	when b.nBzt>=50 and b.nBzt<70 then '50-69天'
	when b.nBzt>=70 and b.nBzt<90 then '70-89天'
	when b.nBzt>=90 then  '90天及以上'
	 end,
	a.sYsValue_V=case  when b.nBzt>=0 and b.nBzt<5 then '0-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<30 then '20-29天'
	when b.nBzt>=30 and b.nBzt<50 then '30-49天'
	when b.nBzt>=50 and b.nBzt<70 then '50-69天'
	when b.nBzt>=70 and b.nBzt<90 then '70-89天'
	when b.nBzt>=90 then  '90天及以上'
	 end from dbo.Xp_BD_Flys_Value_All a 
	left join Tmp_spb_All b on a.sSpbh=b.sSpbh
	where a.sFlys='保质期'   and a.sFlbh='069999'


    update a set a.sYsValue=case  when b.nBzt>=0 and b.nBzt<5 then '0-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<30 then '20-29天'
	when b.nBzt>=30 and b.nBzt<50 then '30-49天'
	when b.nBzt>=50 and b.nBzt<70 then '50-69天'
	when b.nBzt>=70 and b.nBzt<90 then '70-89天'
	when b.nBzt>=90 then  '90天及以上'
	 end,
	a.sYsValue_V=case  when b.nBzt>=0 and b.nBzt<5 then '0-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<30 then '20-29天'
	when b.nBzt>=30 and b.nBzt<50 then '30-49天'
	when b.nBzt>=50 and b.nBzt<70 then '50-69天'
	when b.nBzt>=70 and b.nBzt<90 then '70-89天'
	when b.nBzt>=90 then  '90天及以上'
	 end from dbo.Xp_BD_Flys_Value a 
	left join Tmp_spb_All b on a.sSpbh=b.sSpbh
	where a.sFlys='保质期'  and a.sFlbh='069999';
    
	-- 调整保质期
	update a set a.sYsValue=case  when b.nBzt>=0 and b.nBzt<5 then '1-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<36 then '20-35天'
	when b.nBzt>=36 and b.nBzt<60 then '36-59天'
	when b.nBzt>=60 then  '60天及以上'
	 end,
	a.sYsValue_V=case  when b.nBzt>=0 and b.nBzt<5 then '1-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<36 then '20-35天'
	when b.nBzt>=36 and b.nBzt<60 then '36-59天'
	when b.nBzt>=60 then  '60天及以上'
	 end from dbo.Xp_BD_Flys_Value a 
	left join Tmp_spb_All b on a.sSpbh=b.sSpbh
	where a.sFlys='保质期'  and a.sFlbh='069999';


    insert into   [AppLinker].DApplication.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select distinct 'myj',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),'0000',0,'0110',
	0,0,'flbh='+a.sflbh_cal from #Tmp_flb   a where  1=1;
	-- drop  table #sfd 
	 	insert into  [Applinker].DApplication.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select DISTINCT  'myj',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),b.sfdbh,0,'0112',0,0,
	'flbh='+a.sflbh_cal from #Tmp_flb  a,#sfd_hz b  where 1=1 ;
 



 --  08-17  15
 

-- 40 个门店新试一下模板
-- 不做新模板，门店在未作必选里选商品试销
-- 选品背景需要人工在 导数据的时候进行筛选
select  '069999' sflbh_cal,'烘焙综合' sflmc,sflbh into #Tmp_flb  from dbo.tmp_spflb
    where  sflbh like '06%' and LEN(sflbh)=6
    
    select sflbh into #sflb from  #Tmp_flb; 
 
-- Step 2:有效分店,首先找到 drop table #sfd
        /* 从R_dpzb 找结束时间最多的时间，再匹配这个时间下的门店，就是有效门店 */
    
    select distinct Tmplate_id,Tmplate_name into #mb from Tmp_mbsp  where slx=1;

	-- drop table #sfd
    select b.Tmplate_name smblx,a.sfdbh  into #sfd  from Tmp_fdb  a 
	join #mb b on a.hongbei_template_id=b.Tmplate_id
    where 1=1 ;  

    -- 在这里就能够将不同 门店合并成不同的背景 drop table #sfd_hz
	 
	select distinct  a.sFdbh  into #sfd_hz 
    from  #sfd a  where 1=1
    and a.sfdbh in ('0196','0217','0231','3288','3902','4459','4736','4967','5179','5207','7755','7762','2959','5056',
'5696','6835','8518','0370','0714','0837','3607','4427','4867','5046','5449','5670','6205','8292'
,'0307','1122','2592','3476','0582','0592','0751','3659','3718','6068','7542','3986','5439',
'6055','6576','8510');
    
	 
    select * into #dpzb from  dbo.R_Dpzb;
    --select * into #dpzb from dbo.H_dpzb where right(taskid,8)='20220710';
	-- drop table #jysp
    select distinct 'myj' sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sflbh,a.nJhj,a.nLsj,
	case  when  i.nRjxl>0 then case   when  i.nRjxl_De/i.nRjxl>=1.5  then  a.nPxs*i.nRjxl_De/i.nRjxl else a.nPxs end 
	  else  a.nPxs end npxs,a.sSpmc,a.sDw,case  when  i.nRjxl>0 then case  when   i.nRjxl_De/i.nRjxl>=1.5  then  a.nXssl*i.nRjxl_De/i.nRjxl else a.nXssl end
	  else  a.nXssl end nxssl, case  when  i.nRjxl>0 then  case when  i.nRjxl_De/i.nRjxl>=1.5  then  a.nXsje*i.nRjxl_De/i.nRjxl else a.nXsje end
	  else  a.nXsje end nxsje,
	  case  when  i.nRjxl>0  then case when  i.nRjxl_De/i.nRjxl>=1.5  then  a.nMl*i.nRjxl_De/i.nRjxl else a.nMl end 
	  else  a.nMl end nMl ,c.sGys,
	c.sSpbhBz,0 sState,c.nBzt,replace(replace(c.sGg,'g',''),'ml','') nGg,GETDATE() dCreateDate,h.spp,'' sGn,c.sGg , 0 ndc 
    into #jysp 
	from  #dpzb  a  
	  join  dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join  dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	 left join  dbo.tmp_spflb f on a.sPlbh=f.sFlbh  
	 left join Tmp_spb_All h on a.sSpbh=h.sSpbh  
	  join #Tmp_flb g on a.sPlbh=g.sFlbh
	 left join dbo.Sys_GoodsConfig  i on a.sFdbh=i.sfdbh  and a.sSpbh=i.sSpbh
	 where 1=1 and    i.sSfkj='1' and  a.sFdbh in (select sFdbh from #sfd)    ;

	 -- drop table #bjsp
      select distinct 'myj'  sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sflbh,a.nJhj,a.nLsj,
	  case  when  i.nRjxl>0 then case   when  i.nRjxl_De/i.nRjxl>=1.5  then  a.nPxs*i.nRjxl_De/i.nRjxl end 
	  else  a.nPxs end npxs,a.sSpmc,a.sDw,case  when  i.nRjxl>0 then case  when   i.nRjxl_De/i.nRjxl>=1.5  then  a.nXssl*i.nRjxl_De/i.nRjxl end
	  else  a.nXssl end nxssl, case  when  i.nRjxl>0 then  case when  i.nRjxl_De/i.nRjxl>=1.5  then  a.nXsje*i.nRjxl_De/i.nRjxl end
	  else  a.nXsje end nxsje,
	  case  when  i.nRjxl>0  then case when  i.nRjxl_De/i.nRjxl>=1.5  then  a.nMl*i.nRjxl_De/i.nRjxl end 
	  else  a.nMl end nMl ,c.sGys,
     c.sSpbhBz,0 nSsts,c.nBzt,replace(replace(c.sGg,'g',''),'ml','')   nGg,GETDATE() dCreateDate,h.spp,'' sGn,c.sGg , 0 ndc
     into #bjsp from #dpzb  a  
	 join dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	left join dbo.tmp_spflb f on a.sPlbh=f.sFlbh  
    join Tmp_spb_All h on a.sSpbh=h.sSpbh  
	 join #Tmp_flb g on a.sPlbh=g.sFlbh
	 left join dbo.Sys_GoodsConfig  i on a.sFdbh=i.sfdbh  and a.sSpbh=i.sSpbh
	 where 1=1 and i.sSfkj=1 and  a.sFdbh in (select sFdbh from #sfd) ;

	  
    delete from dbo.Input_Xp_Sp_Fd where 1=1;
	delete from dbo.Input_Xp_Sp_All_Fd where 1=1;
    -- 写入数据
    insert into dbo.Input_Xp_Sp_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl, nXse,nMl,
	sGys,sGjtm,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nxsje nXse,nMl,
	sGys,sSpbhBz,sState,nBzt,case  when ISNUMERIC(ngg)=0 then CONVERT(money,'') else  nGg end nGg,dCreateDate,sPp,sGn,sGg,nDc from #jysp
    union
    select a.sQybh,'0000' sfdbh,a.sSpbh,a.sflbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	sum(a.nXsje),sum(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) sState,max(a.nBzt),max(convert(money,'') ), GETDATE()  dCreateDate,
    max(a.spp),MAX('') ,max( a.sGg ) sGg, 0 ndc from #jysp a
	where  a.sFdbh in (select sFdbh from #sfd_hz)  group by a.sQybh,a.sSpbh,a.sFlbh;

    insert into dbo.Input_Xp_Sp_All_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXse,nMl,sGys,sGjtm,nSsts,nBzt,nGg,
      dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXsje nXse,nMl,sGys,sSpbhBz,nSsts,nBzt,convert(money,'') nGg,
      dCreateDate,sPp,sGn,sGg,nDc from #bjsp a 
      union
    select a.sQybh,'0000' ,a.sSpbh,a.sFlbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	 sum(a.nXsje),avg(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) nSsts,max(a.nBzt),max(convert(money,'')), GETDATE()  dCreateDate,
	  max(a.spp),MAX(a.sGn) ,max(a.sGg) sGg, 0 ndc from #bjsp a
	  where    a.sFdbh in (select sFdbh from #sfd_hz) group by a.sQybh,a.sSpbh,a.sFlbh;
    
    

 -- Step 5： 总指标更新
	 -- 5.1 品类总指标
     if OBJECT_ID('tempdb..#zzb1') is not null  
		begin 
			drop table #zzb1 
		end
	 select a.sflbh, SUM(a.nXse) as xse,SUM(a.nml) as ml,SUM(a.npxs) as pxs into #zzb1 
	 from Input_Xp_Sp_Fd a where sfdbh='0000'
	  group by a.sflbh;
	   
	 -- 5.2 当期总门店数
	 if OBJECT_ID('tempdb..#zzb2') is not null  
		begin 
			drop table #zzb2 
		end
	 select count(distinct a.sfdbh) nzds into #zzb2 from  #sfd_hz a

	-- 5.3 计算指标
	if OBJECT_ID('tempdb..#zzb3') is not null  
		begin 
			drop table #zzb3 
		end;
  with x0 as(
		select a.sspbh,a.sflbh,COUNT(distinct a.sFdbh) njyfds from Input_Xp_Sp_Fd a where a.sfdbh not in('0000','Test001')
		and a.sFdbh in (select sfdbh from #sfd_hz)
	group by a.sspbh,a.sFlbh)
    select a.sSpbh,SUM(a.nXse*b.pxs/(b.xse+0.00001)*0.4 + a.nml*b.pxs/(b.ml+0.00001)*0.3 + a.npxs*0.3) 
	as nZbz, max(c.njyfds) as Jyds into #zzb3 from  #zzb1 b, Input_Xp_Sp_Fd a,x0 c
	where      a.sFdbh='0000' and b.sflbh=a.sflbh  and a.sspbh=c.sspbh and a.sflbh=c.sflbh 
	  group by a.sspbh;
	delete from dbo.Input_Xp_Zbz where sSpbh in (select sSpbh from #zzb3)

	select * from 

	insert into dbo.Input_Xp_Zbz(sSpbh,sflbh,nZbz,nJyds,nZds)
	select a.sSpbh,'069999',case when a.nZbz<0 then 0 else a.nZbz end,a.Jyds,b.nzds from #zzb3 a,#zzb2 b;

    -- 删除0000  门店内经营门店少 且指标值差的商品，不当作可选的背景商品
    /*
        排除经营门店数过低 低于总门店数的5%，或者店均指标值低于0.2
            可能的影响，部分销售低的商品在总部里体现
        最近一个月引进的新品不排除

    */
	; with x0 as (
    select a.sfdbh,a.sspbh,b.dIntodate,datediff(Day,b.dIntodate,CONVERT(date,GETDATE()))  dtime
    from Input_Xp_Sp_Fd a,Sys_GoodsConfig  b
    where a.sfdbh=b.sfdbh and a.sspbh=b.sspbh and b.sSfkj=1 and a.sFdbh in (select sfdbh from #sfd_hz))
	select a.sSpbh,AVG(a.dtime) avg_time into #avday from  x0 a group by a.sSpbh  having AVG(a.dtime)>=30;

	select *,b.nZbz/(b.nZds)+b.nZbz*(b.nZds-b.nJyds)/(b.nZds*b.nZds) nzhzb from #avday a
	join Input_Xp_Zbz b on a.sSpbh=b.sSpbh
	where 1=1 and b.nZbz/(b.nZds)+b.nZbz*(b.nZds-b.nJyds)/(b.nZds*b.nZds)<0.2 order by b.nJyds  
	select * from Input_Xp_Sp_Fd where sSpbh='1032978' and sFdbh in (select sFdbh from #sfd_hz)

	select * from Sys_GoodsConfig  where sSpbh='1032978' 
	and sFdbh in (select sFdbh from #sfd) and sSfkj=1

了
	------
	

	update a set a.sYsValue=case  when b.nBzt>=0 and b.nBzt<5 then '1-4天'
	when b.nBzt>=5 and b.nBzt<10 then '5-9天'
	when b.nBzt>=10 and b.nBzt<20 then '10-19天'
	when b.nBzt>=20 and b.nBzt<36 then '20-35天'
	when b.nBzt>=36 and b.nBzt<60 then '36-59天'
	when b.nBzt>=60 then  '60天及以上'
	 end,
	a.sYsValue_V=  b.nBzt from dbo.Xp_BD_Flys_Value  a 
	left join Tmp_spb_All b on a.sSpbh=b.sSpbh
	where a.sFlys='保质期'  and a.sFlbh='069999';
	 