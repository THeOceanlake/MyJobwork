--  drop table #Tmp_FDfw
select sFDBH,sFDMC,sFDLX,sPsZt,binglang_state,lengcang_state,hongbei_state into #Tmp_FDfw
from dbo.Tmp_FDB  where  binglang_state  =1 or  lengcang_state=1 or  hongbei_state=1;

-- drop table #tmp_zdbhspfw
select a.sFdbh,b.sFDMC,b.sFDLX,a.sSpbh,a.sPslx,a.nRjxl_De,a.sSfkj into #tmp_zdbhspfw 
from dbo.Sys_GoodsConfig a,#Tmp_FDfw b
where sSfkj='1' and  a.sFdbh=b.sFDBH;

-- 进出表统计
select a.*,b.sSpbh,b.nSl into #tmp_jc from dbo.Tmp_Jcb a 
left join dbo.Tmp_Jcmxb b on a.sJcbh=b.sJcbh and a.sFdbh=b.sFdbh
join #tmp_zdbhspfw c on b.sFdbh=c.sFdbh and b.sSpbh=c.sSpbh
where 1=1 and a.dSj>=CONVERT(date,'2022-05-04') and a.dSj<CONVERT(date,GETDATE());

 select * from #tmp_jc where sJcfl='溢余单'
-- 进出合计
select CONVERT(date,a.dSj) drq,a.sFdbh,a.sSpbh,b.fl_bzname,sum(a.nSl) nsl into #tmp_jchj from #tmp_jc a 
join dbo.Purchase_jcflbzb b on a.sJcfl=b.fl_content
where 1=1  group by   CONVERT(date,a.dSj)  ,a.sFdbh,a.sSpbh,b.fl_bzname;
-- select * from Purchase_jcflbzb where   fl_bzname='损溢'
select *  from #tmp_jchj where   fl_bzname='损溢'

-- 生成日期
 declare @begindate date
 declare @enddate date
 select @begindate=CONVERT(date,'2022-05-04'), @enddate=CONVERT(date,GETDATE())
		 create table #tmp_date(drq date not null);
		 while @begindate<@enddate
		   begin
				insert into #tmp_date(drq) select @begindate
				set @begindate=dateadd(day,1,@begindate)
		   end ;
-- drop table #r
 with x0 as(
 select a.*, LEFT(b.sFl,2) sdl,b.nJj from #tmp_jchj  a  
   join dbo.tmp_spb b on  a.sFdbh=b.sFDBH and a.sSpbh=b.sSpbh
  
where 1=1   )
select a.drq,a.sFdbh,a.sdl,a.fl_bzname sjcfl,sum(a.nJj*a.nsl) njcje,sum(a.nsl) njcsl into #r from x0   a 
group by a.drq,a.sFdbh,a.sdl,a.fl_bzname;

-- drop table #thl
with x0 as (
select a.drq,'06' sdlbh,b.sFDBH from #tmp_date a,#Tmp_FDfw b  where  b.hongbei_state=1
)
select a.drq,a.sFdbh,a.sdlbh,isnull(b.njcje,0) nrkje,isnull(c.njcje,0) nthje,case when  ISNULL(b.njcje,0)<=0 then 0 
else ISNULL(c.njcje,0)/b.njcje*1.0 end nthl into #thl from x0 a 
left join #r b on a.drq=b.drq and a.sFDBH=b.sfdbh and a.sdlbh=b.sdl and b.sjcfl='进出(配入)'
left join #r c on a.drq=c.drq and a.sFDBH=c.sFdbh and a.sdlbh=c.sdl and c.sjcfl='进出(退厂)'
where  1=1;

select * from #r;
with  x0 as (
select count(a.sfdbh) nzfds
from dbo.Tmp_FDB  a  
  join  dbo.Tmp_FDB_sx b on a.sFdbh=b.sfdbh  and b.slx='烘焙' and  b.dsxdate='2022-05-08 00:00:00.000'
where     hongbei_state=1 )
select a.drq,a.sdlbh,AVG(a.nrkje) nrkje,avg(a.nthje) nthje,case when avg(a.nthje)*1.0/AVG(a.nrkje)>0 then 0  else 
  -avg(a.nthje)*1.0/AVG(a.nrkje) end nthl,sum(case when a.nthje<0 then 1 else 0 end ) nythfds,
  (select   nzfds from x0 ) nzmds from #thl a 
  join  dbo.Tmp_FDB_sx b on a.sFdbh=b.sfdbh  and b.slx='烘焙' and  b.dsxdate='2022-05-08 00:00:00.000'
  where 1=1  and a.sdlbh='06'
  group by a.drq,a.sdlbh  order  by a.drq;

  with  x0 as (
select count(a.sfdbh) nzfds
from dbo.Tmp_FDB  a  
  join  dbo.Tmp_FDB_sx b on a.sFdbh=b.sfdbh  and b.slx='烘焙' 
where     hongbei_state=1 )
select  a.*,b.dsxdate  from #thl a 
  join  dbo.Tmp_FDB_sx b on a.sFdbh=b.sfdbh  and b.slx='烘焙'  
  where 1=1   order  by a.drq;

  ---  首批上线门店在上线之后退货金额 门店排序
   with x0 as(
 select a.*, LEFT(b.sFl,2) sdl,b.nJj from #tmp_jchj  a  
   join dbo.tmp_spb b on  a.sFdbh=b.sFDBH and a.sSpbh=b.sSpbh
  join  dbo.Tmp_FDB_sx c on a.sFdbh=c.sfdbh  and c.slx='烘焙' and  c.dsxdate='2022-05-08 00:00:00.000'
where 1=1 and  a.drq>='2022-05-08'    )
select a.sFdbh 分店,a.sdl 大类,sum(case  when a.fl_bzname='进出(配入)'  then  a.nJj*a.nsl else 0 end) 上线后总入库金额,
sum(case  when a.fl_bzname='进出(退厂)'  then  a.nJj*a.nsl else 0 end ) 上线后总退货金额,
- sum(case  when a.fl_bzname='进出(退厂)'  then  a.nJj*a.nsl else 0 end )/sum(case  when a.fl_bzname='进出(配入)' 
 then  a.nJj*a.nsl else 0 end)*1.0 上线后总退货率  from x0   a  
where  1=1 and a.sdl='06'  group by  a.sFdbh,a.sdl  order by 4  ;


   with x0 as(
 select a.*, LEFT(b.sFl,2) sdl,b.nJj from #tmp_jchj  a  
   join dbo.tmp_spb b on  a.sFdbh=b.sFDBH and a.sSpbh=b.sSpbh
  join  dbo.Tmp_FDB_sx c on a.sFdbh=c.sfdbh  and c.slx='烘焙' and  c.dsxdate='2022-05-08 00:00:00.000'
where 1=1 and  a.drq>='2022-05-08'    )
select a.sSpbh 商品,max(b.sSpmc) ,max(b.nBzt),a.sdl 大类,sum(case  when a.fl_bzname='进出(配入)'  then  a.nJj*a.nsl else 0 end) 上线后总入库金额,
sum(case  when a.fl_bzname='进出(退厂)'  then  a.nJj*a.nsl else 0 end ) 上线后总退货金额, 
case  when sum(case  when a.fl_bzname='进出(配入)' 
 then  a.nJj*a.nsl else 0 end)=0 then  0 else   - sum(case  when a.fl_bzname='进出(退厂)'  then  a.nJj*a.nsl else 0 end )/sum(case  when a.fl_bzname='进出(配入)' 
 then  a.nJj*a.nsl else 0 end)*1.0 end 上线后总退货率  from x0   a 
 left join dbo.Tmp_spb_All b on a.sSpbh=b.sSpbh
 
where  1=1 and a.sdl='06'  group by  a.sSpbh,a.sdl  order by 6  ;

select * from Sys_GoodsConfig_his  where  djssj>convert(date,getdate()-1) and sSpbh='2096913'
and sFdbh='E918'

 with x0 as(
 select a.*, LEFT(b.sFl,2) sdl,b.nJj from #tmp_jchj  a  
   join dbo.tmp_spb b on  a.sFdbh=b.sFDBH and a.sSpbh=b.sSpbh
  join  dbo.Tmp_FDB_sx c on a.sFdbh=c.sfdbh  and c.slx='烘焙' and  c.dsxdate='2022-05-08 00:00:00.000'
where 1=1 and  a.drq>='2022-05-08'    )
select a.sSpbh 商品,max(b.sSpmc) ,max(b.nBzt),a.sFdbh,a.sdl 大类,c.nRjxl_De,c.DE_BHL,c.nJysx,c.nJyxx,
sum(case  when a.fl_bzname='进出(配入)'  then  a.nJj*a.nsl else 0 end) 上线后总入库金额,
sum(case  when a.fl_bzname='进出(退厂)'  then  a.nJj*a.nsl else 0 end ) 上线后总退货金额, sum(case  when a.fl_bzname='进出(退厂)'  then  a.nsl else 0 end ) ,
case  when sum(case  when a.fl_bzname='进出(配入)' 
 then  a.nJj*a.nsl else 0 end)=0 then  0 else   - sum(case  when a.fl_bzname='进出(退厂)'  then  a.nJj*a.nsl else 0 end )/sum(case  when a.fl_bzname='进出(配入)' 
 then  a.nJj*a.nsl else 0 end)*1.0 end 上线后总退货率  from x0   a 
 left join dbo.Tmp_spb_All b on a.sSpbh=b.sSpbh
 left join dbo.Sys_GoodsConfig_his c on a.sSpbh=c.sSpbh and a.sfdbh=c.sfdbh and c.djssj>=convert(date,getdate()-1)
where  1=1 and a.sdl='06'  
group by  a.sSpbh,a.sdl,a.sFdbh ,c.nRjxl_De,c.DE_BHL,c.nJysx,c.nJyxx order by 6  ;

  -- 05-17 

   with x0 as(
 select a.*, LEFT(b.sFl,2) sdl,b.nJj from #tmp_jchj  a  
   join dbo.tmp_spb b on  a.sFdbh=b.sFDBH and a.sSpbh=b.sSpbh
  join  dbo.Tmp_FDB_sx c on a.sFdbh=c.sfdbh  and c.slx='烘焙' and  c.dsxdate='2022-05-08 00:00:00.000'
where 1=1 and  a.drq='2022-05-17'    )
select a.drq,a.sSpbh,a.sdl,sum(case  when a.fl_bzname='进出(配入)'  then  a.nJj*a.nsl else 0 end) nrkje,
sum(case  when a.fl_bzname='进出(退厂)'  then  a.nJj*a.nsl else 0 end ) nthje from x0   a  
where  1=1 and a.sdl='06'  group by a.drq,a.sSpbh,a.sdl  order by 5  ;


select a.sJcbh,a.sJcfl,a.sFdbh,a.sSpbh,b.sSpmc,b.sFl,a.nSl,b.nJj,c.nBzt  from #tmp_jc a
left join tmp_spb b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh
left join Tmp_spb_All c on a.sSpbh=c.sSpbh
where a.sFdbh='粤16628' and CONVERT(date,dSj)=CONVERT(date,'2022-05-17')
order by a.nSl*b.nJj
 
 select * from #tmp_jc where sSpbh='1001920'