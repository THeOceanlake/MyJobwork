--2022-03-17-------------
1、JR重点品类


select  '21030199' sflbh_cal,'低温酸奶综合' sflmc,sflbh  from dbo.tmp_spflb
where sflbh like '210301%'
union
select '23040199','薯片综合',sflbh from dbo.tmp_spflb where sflbh in (
    '23040101','23040102','23040107','23040108')
union 
select '23040198','米果综合',sflbh from dbo.tmp_spflb where sflbh in (
    '23040103','23040109' )
union 
select '23040390','即食海苔综合',sflbh from dbo.tmp_spflb where sflbh in (
    '23040301','23040302','23040303','23040304','23040305','23040306' )
union
select '24040199','大米综合',sflbh from dbo.tmp_spflb where sflbh  like '240401%'
union
select '31030299','卫生巾综合',sflbh from dbo.tmp_spflb 
where sflbh  in ('31030201','31030202','31030203','31030206','31030207','31030208')
union
select '31050199','沐浴露综合',sflbh from tmp_spflb where sflbh in ('31050101','31050102')
union
select  sflbh,sflmc,sflbh from dbo.tmp_spflb where 
sflbh in ('23010104','23010105','23010401','23010403','23010404','23010406',
'23020104','23020106','23020108','23020110','23020111','23020112',
'23040308','23040309','23040310','23040311','23040312','31030204',
'33010401','33010405','33010406');

insert into DAppResult.dbo.Input_Sort(sQybh,sFlbh,sFlmc)
select distinct  'jr', sflbh_cal,sflmc from #tmp_flb  
where sflbh_cal not  in(select distinct sflbh  from  DAppResult.dbo.Input_Sort )

insert into DAppResult.dbo.BD_Flb(sQybh,sFlbh,sFlmc)
select distinct  'jr', sflbh_cal,sflmc from #tmp_flb  
where sflbh_cal not  in(select distinct sflbh  from  DAppResult.dbo.BD_Flb )


-- 准备阶段
select distinct sflbh_cal,sflbh into #sflb from  #tmp_flb a 
where  1=1 ; 
-- Step 0 :获取数据
 select distinct 'jr' sQybh,a.sFdbh,a.sSpbh,g.sflbh_cal sFlbh,a.nJhj,a.nLsj,a.nPxs,a.sSpmc,a.sDw,a.nXssl,a.nXsje,case when a.nml<=0 then 0 else a.nMl end nMl,c.sGys,
 c.sSpbhBz,0 sState,c.nBzt,isnull(convert(money,d.ngg),0) *convert(int,isnull(d.nxsbzs,1)) nGg,GETDATE() dCreateDate,f.brand sPp,'' sGn,ISNULL(f.spec,c.Spec) sGg,
 case when isnull(convert(money,d.ngg),0) *convert(int,isnull(d.nxsbzs,1))>0 then a.nLsj/(isnull(convert(money,d.ngg),0) *convert(int,isnull(d.nxsbzs,1))) else 0 end ndc into #jysp
  from DAppResult.dbo.R_Dpzb a  
 join DAppResult.dbo.Tmp_FDB b on  a.sFdbh=b.sfdbh 
 left join DAppStore.dbo.tmp_spb c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
 left join  master.dbo.TMP_DXP_BZGG d on a.sSpbh=d.sSpbh  
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
	sum(a.nXsje),sum(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) sState,max(a.nBzt),max(convert(money,'') ), GETDATE()  dCreateDate,
    max(a.spp),MAX('') ,max( a.sGg ) sGg, 0 ndc from #jysp a  group by a.sQybh,a.sSpbh,a.sFlbh;
  
  insert into dbo.Input_Xp_Sp_All_Fd(sQybh,sFdbh,sSpbh,sFlbh,nJhj,nLsj,nPxs,sSpmc,sDw,nXssl,nXse,nMl,sGys,sGjtm,nSsts,nBzt,nGg,
      dCreateDate,sPp,sGn,sGg,nDc)
    select a.sQybh,'0000' ,a.sSpbh,a.sFlbh,avg(a.nJhj),avg(a.nLsj),sum(a.nPxs),max(a.sSpmc),max(a.sDw),sum(a.nXssl),
	 sum(a.nXsje),avg(a.nMl),max(a.sGys),max(a.sSpbhBz),max(0) nSsts,max(a.nBzt),max(convert(money,'')), GETDATE()  dCreateDate,
	  max(a.spp),MAX(a.sGn) ,max(a.sGg) sGg, 0 ndc from #jysp a group by a.sQybh,a.sSpbh,a.sFlbh;
  



   
-- Step 4  : 更新功能、类型等字段
	update a set a.sGn=LEFT(b.sFlmc,LEN(b.sflmc)-4) from DAppResult.dbo.Input_Xp_Sp_Fd a ,DAppResult.dbo.tmp_spflb b,
	[122.147.10.200].DAppSource.dbo.goods c 
	where a.sSpbh=c.CODE and  c.SORT=b.sFlbh and a.sFlbh='21030199';
	
	update a set a.sGn=LEFT(b.sFlmc,LEN(b.sflmc)-4) from DAppResult.dbo.Input_Xp_Sp_All_Fd a ,DAppResult.dbo.tmp_spflb b,
	[122.147.10.200].DAppSource.dbo.goods c 
	where a.sSpbh=c.CODE and  c.SORT=b.sFlbh and a.sFlbh='21030199';

    	 update a set a.nGg=isnull(convert(money,b.ngg),0) *convert(int,isnull(b.nxsbzs,1))
	  from DAppResult.dbo.Input_Xp_Sp_All_Fd a  ,master.dbo.TMP_DXP_BZGG b

	where a.sSpbh=b.sSpbh  and ISNULL(a.nGg,0)=0   


	
	 update a set a.nGg=isnull(convert(money,b.ngg),0) *convert(int,isnull(b.nxsbzs,1))
	  from DAppResult.dbo.Input_Xp_Sp_Fd a  ,master.dbo.TMP_DXP_BZGG b

	where a.sSpbh=b.sSpbh  and ISNULL(a.nGg,0)=0   

-- Step 5:界面上修改规格信息，
-- Step 6 :反向保存规格和其他参数



----------反向保存数据
insert into master.dbo.TMP_DXP_TASTE(sSpbh,sFlys,sYsValue)
select a.sSpbh,a.sFlys,case when len(a.sYsValue_V)>0 then a.sYsValue_V else  a.sYsValue end from  DAppResult.dbo.Xp_BD_Flys_Value a  
left join master.dbo.TMP_DXP_TASTE b on a.sSpbh=b.sSpbh and a.sFlys=b.sFlys
where  1=1  and b.sSpbh is null and a.sFlys<>'档次'

update b set b.sYsValue= case when len(a.sYsValue_V)>0 then a.sYsValue_V else  a.sYsValue end from  DAppResult.dbo.Xp_BD_Flys_Value a  
  join master.dbo.TMP_DXP_TASTE b on a.sSpbh=b.sSpbh and a.sFlys=b.sFlys
where  1=1  and b.sSpbh is not null
 and ( b.sYsValue ='0' or b.sYsValue<>case when len(a.sYsValue_V)>0 then a.sYsValue_V else  a.sYsValue end)

 

-- 以后更新用这一个表就可以了

update c set c.ngg=a.sYsValue_V from  DAppResult.dbo.Xp_BD_Flys_Value a 
 -- left join  DAppResult.dbo.Xp_BD_Flys_Value b on a.sSpbh=b.sSpbh and b.sFlys='规格'
join master.dbo.TMP_DXP_BZGG c   on a.sSpbh=c.sSpbh
where a.sFlys='规格'   and (  c.ngg is null or convert(money,c.ngg)=0 ) 
and a.sFlbh='23020104' ;


update a set a.sYsValue=c.sYsValue from  DAppResult.dbo.Xp_BD_Flys_Value a 
join master.dbo.TMP_DXP_TASTE c   on a.sSpbh=c.sSpbh and a.sFlys=c.sflys
where   a.sFlbh='23020104' and a.sFlys='口味' ;

 update a set a.sYsValue=c.sYsValue from  DAppResult.dbo.Xp_BD_Flys_Value_All a 
  join master.dbo.TMP_DXP_TASTE c   on a.sSpbh=c.sSpbh and a.sFlys=c.sflys
where   a.sFlbh='23020104' and a.sFlys='口味' ;



update b set b.sYsValue=a.sYsValue from  DAppResult.dbo.Xp_BD_Flys_Value a  
  join master.dbo.TMP_DXP_TASTE b on a.sSpbh=b.sSpbh and b.sFlys in ('口味','功能','果仁') 
   and a.sFlys=b.sFlys
where  a.sFlys in ('口味','功能','果仁') and a.sFlbh='23020104'
and len(b.sYsValue)=0 and len(a.sYsValue)>0

---------------------- 规划数 ---------
select  '21030199' sflbh_cal,'低温酸奶综合' sflmc,sflbh into #Tmp_flb  from dbo.tmp_spflb
where sflbh like '210301%'
union
select '23040199','薯片综合',sflbh from dbo.tmp_spflb where sflbh in (
    '23040101','23040102','23040107','23040108')
union 
select '23040198','米果综合',sflbh from dbo.tmp_spflb where sflbh in (
    '23040103','23040109' )
union 
select '23040390','即食海苔综合',sflbh from dbo.tmp_spflb where sflbh in (
    '23040301','23040302','23040303','23040304','23040305','23040306' )
union
select '24040199','大米综合',sflbh from dbo.tmp_spflb where sflbh  like '240401%'
union
select '31030299','卫生巾综合',sflbh from dbo.tmp_spflb 
where sflbh  in ('31030201','31030202','31030203','31030206','31030207','31030208')
union
select '31050199','沐浴露综合',sflbh from tmp_spflb where sflbh in ('31050101','31050102')
union
select  sflbh,sflmc,sflbh from dbo.tmp_spflb where 
sflbh in ('23010104','23010105','23010401','23010403','23010404','23010406',
'23020104','23020106','23020108','23020110','23020111','23020112',
'23040308','23040309','23040319','23040310','23040311','23040312','31030204',
'33010401','33010405','33010406');

select distinct a.sflbh_cal into #1 from #Tmp_flb a 
left join dbo.Input_Plgh b on a.sflbh_cal=b.sPlbh and b.sFdbh='018425'
where b.sPlbh is null 

insert into dbo.Input_Plgh(sFdbh,sPlbh,nGhs,dAddTime)
select '018425',  a.sflbh_cal,sum(ISNULL(b.nGhs,0)) ,GETDATE()     from #Tmp_flb a 
left join dbo.Input_Plgh b on a.sflbh=b.sPlbh and b.sFdbh='018425'
where  a.sflbh_cal in (select sflbh_cal from #1 ) group by a.sflbh_cal


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