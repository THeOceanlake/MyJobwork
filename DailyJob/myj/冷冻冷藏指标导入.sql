-- 计算分类
select  '060199' sflbh_cal,'短保面包综合' sflmc,sflbh into #Tmp_flb  from dbo.tmp_spflb
where sflbh like '0601%'
union 
select '060299','短保蛋糕综合',sflbh from dbo.tmp_spflb where sflbh like '0602%'
union
select '060399','长保面包综合',sflbh from dbo.tmp_spflb where sflbh like '0603%'
union
select '060499','长保蛋糕综合',sflbh from dbo.tmp_spflb where sflbh like '0604%'
union
select '060599','烘焙工坊综合',sflbh from dbo.tmp_spflb where sflbh like '0605%'
union
select '060699','中/西式糕点综合',sflbh from dbo.tmp_spflb where sflbh like '0606%'
union
select '150199','冷藏鲜奶综合',sflbh from dbo.tmp_spflb where sflbh like '1501%'
union
select '150299','冷藏酸奶综合',sflbh from dbo.tmp_spflb where sflbh like '1502%'
union
select '150399','冷藏饮料综合',sflbh from dbo.tmp_spflb where sflbh like '1503%'
union
select '150499','冷藏其他综合',sflbh from dbo.tmp_spflb where sflbh like '1504%'
union 
select '339901','槟榔综合',sflbh from dbo.tmp_spflb where sflbh like '33%'
-- insert into  dbo.Input_Sort(sQybh,sFlbh,sFlmc)
-- select distinct  'myj', sflbh_cal,sflmc from #tmp_flb  
-- where sflbh_cal not  in(select distinct sflbh  from   dbo.Input_Sort )

-- insert into  dbo.BD_Flb(sQybh,sFlbh,sFlmc)
-- select distinct  'myj', sflbh_cal,sflmc from #tmp_flb  
-- where sflbh_cal not  in(select distinct sflbh  from  dbo.BD_Flb )

-- 指标导入
-- Step 1 :计算分类
        select sflbh into #sflb from  #Tmp_flb; 
-- Step 2:有效分店,首先找到 drop table #sfd
        /* 从R_dpzb 找结束时间最多的时间，再匹配这个时间下的门店，就是有效门店 */
		with x0 as (
		select  a.EndDate,count(distinct a.sFdbh) nfds  from R_Dpzb a group by a.EndDate)
		,x1 as (select  a.EndDate,ROW_NUMBER()over(order by a.EndDate desc) npm  from x0  a )
		select distinct  a.sFdbh,b.sFdmc, a.EndDate  into #sfd from  R_Dpzb a,
		dbo.tmp_fdb b  where  a.EndDate in ( select EndDate from x1  where npm=1)
         and a.sFdbh=b.sFDBH;
--Step 3: 门店经营指标和背景指标
 

--    select sspbh  into #1 from dbo.tmp_mbsp  where  upper(tmplate_type)='BL'
--    and Tmplate_id=1 ;  
 
	select distinct 'myj' sQybh,a.sFdbh,a.sSpbh, g.sflbh_cal sflbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,
	a.nMl ,c.sGys,
	c.sSpbhBz,0 sState,c.nBzt,replace(replace(c.sGg,'g',''),'ml','') nGg,GETDATE() dCreateDate,c.spp,'' sGn,c.sGg , 0 ndc 
    into #jysp 
	from  dbo.R_Dpzb a  
	 join  dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join  dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	 left join  dbo.tmp_spflb f on a.sPlbh=f.sFlbh  
	 join Tmp_spb_All h on a.sSpbh=h.sSpbh  
      join #Tmp_flb g on a.sPlbh=g.sFlbh
	 where 1=1   and  a.sFdbh in (select sFdbh from #sfd)
	 


      select distinct 'myj'  sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sflbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,a.nMl,c.sGys,
     c.sSpbhBz,0 nSsts,c.nBzt,replace(replace(c.sGg,'g',''),'ml','')   nGg,GETDATE() dCreateDate,c.spp,'' sGn,c.sGg , 0 ndc
     into #bjsp from dbo.R_Dpzb a  
	 join dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	left join dbo.tmp_spflb f on a.sPlbh=f.sFlbh  
    join Tmp_spb_All h on a.sSpbh=h.sSpbh  
     join #Tmp_flb g on a.sPlbh=g.sFlbh
	 where 1=1   and  a.sFdbh in (select sFdbh from #sfd);
   
-- Step 4:写入数据
    -- 删除原有数据-按单品颗粒度
    delete from dbo.Input_Xp_Sp_Fd where sSpbh in (select distinct sSpbh from #jysp)  or sFlbh in (select distinct sFlbh from #jysp)
	delete from dbo.Input_Xp_Sp_All_Fd where sSpbh in (select distinct sspbh from #bjsp)  or sFlbh in (select distinct sFlbh from #jysp)
    -- 写入数据
    insert into dbo.Input_Xp_Sp_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl, nXse,nMl,
	sGys,sGjtm,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nxsje nXse,nMl,
	sGys,sSpbhBz,sState,nBzt,case  when ISNUMERIC(ngg)=0 then CONVERT(money,'') else  nGg end ,dCreateDate,sPp,sGn,sGg,nDc from #jysp
    union
    select a.sQybh,'0000' sfdbh,a.sSpbh,a.sflbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	sum(a.nXsje),sum(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) sState,max(a.nBzt),max(convert(money,'') ), GETDATE()  dCreateDate,
    max(a.spp),MAX('') ,max( a.sGg ) sGg, 0 ndc from #jysp a  group by a.sQybh,a.sSpbh,a.sFlbh;

    insert into dbo.Input_Xp_Sp_All_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXse,nMl,sGys,sGjtm,nSsts,nBzt,nGg,
      dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXsje nXse,nMl,sGys,sSpbhBz,nSsts,nBzt,
    case  when ISNUMERIC(ngg)=0 then CONVERT(money,'') else  nGg end ,
      dCreateDate,sPp,sGn,sGg,nDc from #bjsp a 
      union
    select a.sQybh,'0000' ,a.sSpbh,a.sFlbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	 sum(a.nXsje),avg(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) nSsts,max(a.nBzt),max(convert(money,'')), GETDATE()  dCreateDate,
	  max(a.spp),MAX(a.sGn) ,max(a.sGg) sGg, 0 ndc from #bjsp a group by a.sQybh,a.sSpbh,a.sFlbh;


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
	 select count(distinct a.sfdbh) nzds into #zzb2 from dbo.R_Dpzb a
	 ,dbo.tmp_fdb b
	 where 1=1  and a.EndDate in (select distinct EndDate from #sfd) and a.sfdbh=b.sfdbh;

	-- 5.3 计算指标
	if OBJECT_ID('tempdb..#zzb3') is not null  
		begin 
			drop table #zzb3 
		end
    select a.sSpbh,SUM(a.nXse*b.pxs/(b.xse+0.00001)*0.3 + a.nml*b.pxs/(b.ml+0.00001)*0.3 + a.npxs*0.4) 
	as nZbz, count(a.sFdbh) as Jyds into #zzb3 from  #zzb1 b, Input_Xp_Sp_Fd a
	where      a.sFdbh='0000' and b.sflbh=a.sflbh  
	  group by a.sspbh;

	delete from dbo.Input_Xp_Zbz where sSpbh in (select sSpbh from #zzb3)

	insert into dbo.Input_Xp_Zbz(sSpbh,nZbz,nJyds,nZds)
	select a.sSpbh,case when a.nZbz<0 then 0 else a.nZbz end,a.Jyds,b.nzds from #zzb3 a,#zzb2 b;

   -- 小类和范围因素，手工维护
   	update a set a.sYsValue=c.sFlmc,a.sYsValue_V=c.sFlmc from dbo.Xp_BD_Flys_Value_All a 
	left join Tmp_spb_All b on a.sSpbh=b.sSpbh
	left join tmp_spflb c on b.sFl=c.sFlbh
	where a.sFlys='小类' and len(a.sYsValue_V)=0

	update a set a.sYsValue=c.sFlmc,a.sYsValue_V=c.sFlmc from dbo.Xp_BD_Flys_Value  a 
	left join Tmp_spb_All b on a.sSpbh=b.sSpbh
	left join tmp_spflb c on b.sFl=c.sFlbh
	where a.sFlys='小类' and len(a.sYsValue_V)=0

    update a set a.sYsValue=case when b.sspbh is not null then '模板内' else '模板外' end  
	,a.sYsValue_V=case when b.sspbh is not null then '模板内' else '模板外' end from dbo.Xp_BD_Flys_Value  a 
	left join (select distinct sspbh from  tmp_mbsp) b on a.sSpbh=b.sspbh
	where a.sFlys='范围' and len(a.sYsValue_V)=0

		update a set a.sYsValue=case when b.sspbh is not null then '模板内' else '模板外' end  
	,a.sYsValue_V=case when b.sspbh is not null then '模板内' else '模板外' end from dbo.Xp_BD_Flys_Value_All  a 
	left join (select distinct sspbh from  tmp_mbsp) b on a.sSpbh=b.sspbh
	where a.sFlys='范围' and len(a.sYsValue_V)=0

    		update a set   a.sYsValue_V=case when b.sspbh is not null then '模板内' else '模板外' end from dbo.bd_flys_value  a 
	left join (select distinct sspbh from  tmp_mbsp) b on a.sSpbh=b.sspbh
	where a.sFlys='范围' and len(a.sYsValue_V)=0

    	update a set a.sYsValue_V=c.sFlmc from dbo.bd_flys_value a 
	left join Tmp_spb_All b on a.sSpbh=b.sSpbh
	left join tmp_spflb c on b.sFl=c.sFlbh
	where a.sFlys='小类' and len(a.sYsValue_V)=0
   -- 因素因子更新
	update a set  a.sYsValue_V=c.sYsValue_V from   dbo.Xp_BD_Flys_Value a 
	join  dbo.Tmp_Sp_Flys_Backup c   on a.sSpbh=c.sSpbh and a.sFlys=c.sflys
	where 1=1 and a.sYsValue_V<>c.sYsValue_V and isnumeric(c.sYsValue_V)=1;

	update a set a.sYsValue_V=c.sYsValue_V from   dbo.Xp_BD_Flys_Value_All a 
	join  dbo.Tmp_Sp_Flys_Backup c   on a.sSpbh=c.sSpbh and a.sFlys=c.sflys
	where 1=1 and a.sYsValue_V<>c.sYsValue_V and isnumeric(c.sYsValue_V)=1;

	update a set a.sYsValue=c.sYsValue_V,a.sYsValue_V=c.sYsValue_V from   dbo.Xp_BD_Flys_Value a 
	join  dbo.Tmp_Sp_Flys_Backup c   on a.sSpbh=c.sSpbh and a.sFlys=c.sflys
	where 1=1 and a.sYsValue<>c.sYsValue_V and isnumeric(c.sYsValue_V)=0;

	update a set a.sYsValue=c.sYsValue_V, a.sYsValue_V=c.sYsValue_V from   dbo.Xp_BD_Flys_Value_All a 
	join  dbo.Tmp_Sp_Flys_Backup c   on a.sSpbh=c.sSpbh and a.sFlys=c.sflys
	where 1=1 and a.sYsValue<>c.sYsValue_V and isnumeric(c.sYsValue_V)=0;











 