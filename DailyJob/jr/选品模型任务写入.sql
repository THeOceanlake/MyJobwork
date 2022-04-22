-- Step 1 :计算分类
        select sFlbh  into #sflb from    dbo.BD_flb 
        where 1=1 and UpdateTime>'2022-03-01' 

     -- update BD_Sp set sFlbh=sFlbh_User
    --  update Xp_BD_Flys_Value set sYsValue=sYsValue_V where sFlys not in ('档次','规格','价格带')

	 select a.sflbh,count(distinct a.sspbh) nsps into #sflb_l from Input_xp_sp_fd a,  #sflb  b
	 where a.sflbh=b.sflbh and a.sFdbh='0000' group by a.sflbh  having count(distinct a.sspbh)>1;
 
 


-- 2.1 总部任务写入 加一个检查，如果本周计算了模型，则不再写入任务
	insert into   DApplicationJR.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select 'jr',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),'0000',0,'0208',
	0,0,'flbh='+a.sFlbh  from #sflb_l   a

    select '018425' sFdbh into  #sfd
	insert into DApplicationJR.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select 'jr',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121), b.sfdbh,0,'12',0,0,
	'flbh='+a.sFlbh from #sflb_l  a,#sfd b   where 1=1 