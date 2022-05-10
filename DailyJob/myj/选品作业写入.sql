
-- Step 1 :计算分类
        select sFlbh  into #sflb from  dappsource.dbo.BD_Flb
        where 1=1 and UpdateTime>'2022-03-01' 

		 select a.sflbh,count(distinct a.sspbh) nsps into #sflb_1 from Input_xp_sp_fd a,  #sflb  b
	 where a.sflbh=b.sflbh and a.sFdbh='0000' group by a.sflbh having count(distinct a.sspbh)>1;



-- 2.1 总部任务写入 加一个检查，如果本周计算了模型，则不再写入任务
	insert into   [AppLinker].DApplication.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select 'myj',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),'0000',0,'0110',
	0,0,'flbh='+a.sFlbh from #sflb_1   a where sFlbh='339901'

	   	with x0 as (
		select  a.EndDate,count(distinct a.sFdbh) nfds  from R_Dpzb a group by a.EndDate)
		,x1 as (select  max(a.EndDate) EndDate   from x0  a )
		select distinct  top 10 a.sFdbh, a.EndDate into #sfd  from  R_Dpzb a where  a.EndDate in ( select EndDate from x1 );

	 	insert into  [Applinker].DApplication.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select top 10 'myj',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),b.sfdbh,0,'0112',0,0,
	'flbh='+a.sFlbh from #sflb_1  a,#sfd b  where 1=1 and a.sflbh='339901';