
-- Step 1 :计算分类
        select sFlbh  into #sflb from   dbo.BD_Flb
        where 1=1 and UpdateTime>'2022-03-01' 

		 select a.sflbh,count(distinct a.sspbh) nsps into #sflb_1 from Input_xp_sp_fd a,  #sflb  b
	 where a.sflbh=b.sflbh and a.sFdbh='0000' group by a.sflbh having count(distinct a.sspbh)>1;

-- Step 2.0 规划数更新
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

	select distinct a.sflbh_cal,c.sFdbh,a.sflbh into #Tmp_flb1 from #Tmp_flb a 
	left join Tmp_fdb_sx c on 1=1  
	where 1=1 ;

	 
	select a.sFdbh,  a.sflbh_cal,sum(ISNULL(b.nGhs,0)) nGhs,GETDATE() dAddTime  into #tmp_ghresult
	from #Tmp_flb1 a 
	left join dbo.Input_Plgh b on a.sflbh=b.sPlbh and a.sFdbh=b.sFdbh
	where  1=1  group by a.sFdbh,a.sflbh_cal;

	update a set a.nGhs=b.nGhs from dbo.Input_xp_ghs a 
	join dbo.Input_Plgh b on a.sFdbh=b.sFdbh and a.sFlbh=b.sPlbh
	where 1=1;
    
	update a set a.nGhs=b.nGhs from dbo.Input_xp_ghs a 
	join dbo.#tmp_ghresult b on a.sFdbh=b.sFdbh and a.sFlbh=b.sflbh_cal
	where 1=1;

	insert into dbo.Input_xp_ghs (sqybh,sfdbh,sflbh,nghs)
	select 'jr',a.sFdbh,a.sflbh_cal,a.nGhs from #tmp_ghresult a 
	left join dbo.Input_xp_ghs b on a.sFdbh=b.sFdbh and b.sFlbh=a.sflbh_cal
	where 1=1 and b.sflbh is Null;


-- 2.1 总部任务写入 加一个检查，如果本周计算了模型，则不再写入任务
	insert into   [AppLinker].DApplication.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select 'myj',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),'0000',0,'0110',
	0,0,'flbh='+a.sFlbh from #sflb_1   a where sFlbh='339901'
	-- drop  table #sfd
	   	with x0 as (
		select  a.EndDate,count(distinct a.sFdbh) nfds  from R_Dpzb a group by a.EndDate)
		,x1 as (select  max(a.EndDate) EndDate   from x0  a )
		select distinct  top 10 a.sFdbh, a.EndDate into #sfd  from  R_Dpzb a where  a.EndDate in ( select EndDate from x1 )
		and  a.sFdbh  in (select    sFDBH from dbo.Tmp_FDB where binglang_state  =1 or  lengcang_state=1 or  hongbei_state=1);

	 	insert into  [Applinker].DApplication.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select   'myj',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),b.sfdbh,0,'0112',0,0,
	'flbh='+a.sFlbh from #sflb_1  a,#sfd b  where 1=1   
	;
