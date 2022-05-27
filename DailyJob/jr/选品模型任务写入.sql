-- Step 1 :计算分类
        select sFlbh  into #sflb from    dbo.BD_flb 
        where 1=1 and UpdateTime>'2022-03-01' 

     -- update BD_Sp set sFlbh=sFlbh_User
    --  update Xp_BD_Flys_Value set sYsValue=sYsValue_V where sFlys not in ('档次','规格','价格带')

	 select a.sflbh,count(distinct a.sspbh) nsps into #sflb_l from Input_xp_sp_fd a,  #sflb  b
	 where a.sflbh=b.sflbh and a.sFdbh='0000' group by a.sflbh  having count(distinct a.sspbh)>1;
-- Step 2.0 规划数更新
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

	select distinct a.sflbh_cal,c.sFdbh,a.sflbh into #Tmp_flb1 from #Tmp_flb a 
	left join Tmp_fdb c on 1=1 and c.sfdbh='018425'
	where 1=1 ;

	 
	select a.sFdbh,  a.sflbh_cal,sum(ISNULL(b.nGhs,0)) nGhs,GETDATE() dAddTime  into #tmp_ghresult
	from #Tmp_flb1 a 
	left join dbo.Input_Plgh b on a.sflbh=b.sPlbh and a.sFdbh=b.sFdbh
	where  1=1  group by a.sFdbh,a.sflbh_cal;

	update a set a.nGhs=b.nGhs from dbo.Input_xp_plgh a 
	join dbo.Input_Plgh b on a.sFdbh=b.sFdbh and a.sFlbh=b.sPlbh
	where 1=1;
    
	update a set a.nGhs=b.nGhs from dbo.Input_xp_plgh a 
	join dbo.#tmp_ghresult b on a.sFdbh=b.sFdbh and a.sFlbh=b.sflbh_cal
	where 1=1;

	insert into dbo.Input_xp_plgh (sqybh,sfdbh,sflbh,nghs)
	select 'jr',a.sFdbh,a.sflbh_cal,a.nGhs from dbo.tmp_ghresult a 
	left join dbo.Input_xp_plgh b on a.sFdbh=b.sFdbh and b.sFlbh=a.sflbh_cal
	where 1=1 and b.sflbh is Null;



-- 2.1 总部任务写入 加一个检查，如果本周计算了模型，则不再写入任务
	insert into   DApplicationJR.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select 'jr',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),'0000',0,'0208',
	0,0,'flbh='+a.sFlbh  from #sflb_l   a

    select '018425' sFdbh into  #sfd
	insert into DApplicationJR.dbo.Task_Process(userid,beginDate,endDate,databegindate,dataenddate,shopId,stat,tasktopicId,flag,laststat,params) 
	select 'jr',CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121),
	CONVERT(varchar(10),getdate(),121),CONVERT(varchar(10),getdate(),121), b.sfdbh,0,'12',0,0,
	'flbh='+a.sFlbh from #sflb_l  a,#sfd b   where 1=1 ;
	