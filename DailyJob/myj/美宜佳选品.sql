-- 品类结构
-- 分类表 select * from Input_Sort
insert into Input_Sort(sQybh,sFlbh,sFlmc)
select 'myj',sFlbh,sFlmc from dbo.tmp_spflb a where left(a.sFlbh,2) in ('06','15','33');

-- select * from dbo.BD_Flb 
insert into dbo.BD_Flb(sQybh,sFlbh,sFlmc,UpdateTime)
select 'myj' ,sFlbh,sFlmc,GETDATE() from dbo.tmp_spflb a where left(a.sFlbh,2) in ('06','15','33');

insert into dbo.BD_Flb_User(sQybh,sFlbh,sFlmc)
select 'myj' ,sFlbh,sFlmc from dbo.tmp_spflb a where left(a.sFlbh,2) in ('06','15','33'); 
-- 分店表 
insert into  dbo.Input_Shop(sQybh,sFdbh,sFdmc)
select 'myj',sFDBH,sFDMC from dbo.Tmp_FDB 
where sFDBH in (select distinct sFdbh from R_Dpzb);
-- 报告配置
 delete from dbo.Xp_ReportSet;
 insert into dbo.Xp_ReportSet(CtlName,CtlPath,SortIndex)
 select  '标题','Title.ascx',	0 union 
select '二维分析','DoubleWDFX.ascx',3 union
select '附表','AddSheet.ascx',6 union
select '建议淘汰','EliminateSp.ascx',	5 union
select '三维分析','TripleWDFX.ascx',	4 union
select '现状','Status_NEW.ascx',	1 union
select '一维分析','SingleWDFX.ascx',2  ; 

delete from  dbo.Input_DataProcess;
insert into dbo.Input_DataProcess(nPxs_BL,nXse_BL,nMl_BL,ProcessZzb) 
select 0.3,0.3,0.4,1;


-- 指标导入
-- Step 1 :计算分类
        select sflbh into #sflb from   DAppSource.dbo.tmp_spflb a 
        where  1=1 and  left(a.sFlbh,2) in ('06','15','33'); 
-- Step 2:有效分店,首先找到 drop table #sfd
        /* 从R_dpzb 找结束时间最多的时间，再匹配这个时间下的门店，就是有效门店 */
		with x0 as (
		select  a.EndDate,count(distinct a.sFdbh) nfds  from R_Dpzb a group by a.EndDate)
		,x1 as (select  a.EndDate,ROW_NUMBER()over(order by a.EndDate desc) npm  from x0  a )
		select distinct  a.sFdbh,b.sFdmc, a.EndDate  into #sfd from  R_Dpzb a,
		dbo.tmp_fdb b  where  a.EndDate in ( select EndDate from x1  where npm=1)
         and a.sFdbh=b.sFDBH;
--Step 3: 门店经营指标和背景指标
	select distinct 'myj' sQybh,a.sFdbh,a.sSpbh,a.splbh sflbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,a.nMl,c.sGys,
	c.sSpbhBz,0 sState,c.nBzt,replace(replace(c.sGg,'g',''),'ml','') nGg,GETDATE() dCreateDate,c.spp,'' sGn,c.sGg , 0 ndc 
    into #jysp 
	from  dbo.R_Dpzb a  
	 join  dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join  dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	 left join  dbo.tmp_spflb f on a.sPlbh=f.sFlbh  
	 join Tmp_spb_All h on a.sSpbh=h.sSpbh  
	 where 1=1 and  a.splbh in ( select sFlbh from #sflb) and  a.sFdbh in (select sFdbh from #sfd)
	-- and a.sSpbh in (select sspbh from #1)


      select distinct 'myj'  sQybh,a.sFdbh,a.sSpbh,a.splbh sflbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,a.nMl,c.sGys,
     c.sSpbhBz,0 nSsts,c.nBzt,replace(replace(c.sGg,'g',''),'ml','')   nGg,GETDATE() dCreateDate,c.spp,'' sGn,c.sGg , 0 ndc
     into #bjsp from dbo.R_Dpzb a  
	 join dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
	 left join dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
	left join dbo.tmp_spflb f on a.sPlbh=f.sFlbh  
    join Tmp_spb_All h on a.sSpbh=h.sSpbh  
	 where 1=1 and a.splbh in ( select sFlbh from #sflb) and  a.sFdbh in (select sFdbh from #sfd);
   
-- Step 4:写入数据
    -- 删除原有数据-按单品颗粒度
    delete from dbo.Input_Xp_Sp_Fd where sSpbh in (select distinct sSpbh from #jysp)  or sFlbh in (select distinct sFlbh from #jysp)
	delete from dbo.Input_Xp_Sp_All_Fd where sSpbh in (select distinct sspbh from #bjsp)  or sFlbh in (select distinct sFlbh from #jysp)
    -- 写入数据
    insert into dbo.Input_Xp_Sp_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl, nXse,nMl,
	sGys,sGjtm,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nxsje nXse,nMl,
	sGys,sSpbhBz,sState,nBzt,nGg,dCreateDate,sPp,sGn,sGg,nDc from #jysp
    union
    select a.sQybh,'0000' sfdbh,a.sSpbh,a.sflbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	sum(a.nXsje),sum(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) sState,max(a.nBzt),max(convert(money,'') ), GETDATE()  dCreateDate,
    max(a.spp),MAX('') ,max( a.sGg ) sGg, 0 ndc from #jysp a  group by a.sQybh,a.sSpbh,a.sFlbh;

    insert into dbo.Input_Xp_Sp_All_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXse,nMl,sGys,sGjtm,nSsts,nBzt,nGg,
      dCreateDate,sPp,sGn,sGg,nDc)
    select sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXsje nXse,nMl,sGys,sSpbhBz,nSsts,nBzt,nGg,
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
    select a.sSpbh,SUM(a.nXsje*b.pxs/(b.xse+0.00001)*0.3 + a.nml*b.pxs/(b.ml+0.00001)*0.3 + a.npxs*0.4) 
	as nZbz, count(a.sFdbh) as Jyds into #zzb3 from  #zzb1 b, Input_Xp_Sp_Fd a
	where      a.sFdbh='0000' and b.sflbh=a.sflbh  
	  group by a.sspbh;

	delete from dbo.Input_Xp_Zbz where sSpbh in (select sSpbh from #zzb3)

	insert into dbo.Input_Xp_Zbz(sSpbh,nZbz,nJyds,nZds)
	select a.*,b.* from #zzb3 a,#zzb2 b;

    