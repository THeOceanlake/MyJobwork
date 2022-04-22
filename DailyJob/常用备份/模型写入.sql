-- Step 1 :计算分类
        select sflbh,sYt into #sflb from    [AppLinker].dapplication.dbo.Base_flb 
        where 1=1 and UpdateTime>'2021-12-09'   and syt='02';

     -- update BD_Sp set sFlbh=sFlbh_User
    --  update Xp_BD_Flys_Value set sYsValue=sYsValue_V where sFlys not in ('档次','规格','价格带')

	 select a.sflbh,b.sYt,count(distinct a.sspbh) nsps into #sflb_l from Input_xp_sp_fd a,  #sflb  b
	 where a.sflbh=b.sflbh and a.sFdbh='0000' group by a.sflbh,b.sYt having count(distinct a.sspbh)>1;
 
 


-- 2.1 总部任务写入 加一个检查，如果本周计算了模型，则不再写入任务
	insert into   Applinker.DApplication.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select '#USERID#',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),'0000',0,'0126',
	0,0,'fdbh=0000&yt='+a.sYt+'&flbh='+a.sFlbh+'&bkSource=0' from #sflb_l   a