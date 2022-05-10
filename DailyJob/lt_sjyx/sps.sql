 
 
-- drop table #btsp
select  distinct   a.sspbh,a.sSpmc  into #btsp
from  dbo.R_Dpzb a
where a.sPlbh not in (select sFlbh from dbo.Tmp_Spflb_Ex) 
and   a.sSpbh not in (select sSpbh from dbo.tmp_spb_ex)
 
 select COUNT(1) from #btsp;

 with x0 as(
 select b.sFdbh,a.*  from #btsp a ,(select distinct sfdbh from r_dpzb)b)
 select a.sFdbh,c.sfdmc, sum(case when b.sSpbh is not null then 1 else 0 end ) nfdsps,COUNT(distinct a.sSpbh) nzsps,
 sum(case when b.sFdbh is not null then 1 else 0 end )*1.0/COUNT(distinct a.sSpbh)   from x0 a 
 left join R_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
 left join Tmp_FDB c on a.sFdbh=c.sFDBH
 where 1=1 group by a.sFdbh ,c.sfdmc ;

  select a.sFdbh,COUNT(1) nmdsps,COUNT(1)*1.00/max(b.nzsps) from R_Dpzb a 
 ,(select COUNT(1) nzsps from #btsp )b
 where  1=1 group by a.sFdbh

  with x0 as(
 select b.sFdbh,a.*  from #btsp a ,(select distinct sfdbh from r_dpzb)b)
 select *  from x0 a 
 left join R_Dpzb b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
 --left join Tmp_FDB c on a.sFdbh=c.sFDBH
 where 1=1 and  a.sfdbh='001'   order by a.sspbh

 select a.sspbh,a.sspmc,COUNT(distinct b.sFdbh) nfds from  #btsp a 
 left join R_Dpzb b on a.sSpbh=b.sSpbh
 group by a.sspbh,a.sSpmc  order by 3 


/*
12944

sFdbh	nmdsps	经营比例
001	3589	0.2772713226205
002	4088	0.3158220024721
003	5534	0.4275339925834
004	5654	0.4368046971569
005	4222	0.3261742892459
006	6024	0.4653893695920
007	4678	0.3614029666254
008	5021	0.3879017305315
009	5495	0.4245210135970
*/