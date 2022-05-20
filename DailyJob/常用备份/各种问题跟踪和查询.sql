-----  缺货变化
select a.*, CONVERT(date,right(a.taskId,8)) drq into #1 from dbo.H_Qhsp a 
where a.sFdbh='018425' and CONVERT(date,right(a.taskId,8))>=CONVERT(date,GETDATE()-15);

-- drop table #2
select a.*,b.nRjxse,b.nRjxl,b.sSpmc,b.nJhj,b.nLsj,b.nZdsl,b.nZgsl,a.nDhts*b.nRjml nqhmle,
ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.drq desc ) npm into #2 from #1 a 
left join dbo.H_Dpzb b on a.Taskid=b.TaskId  and a.sspbh=b.sSpbh and a.sFdbh=b.sFdbh
where 1=1 ;

select ISNULL(a.sFdbh,b.sFdbh) sFdbh,ISNULL(a.sSpbh,b.sSpbh) sSpbh,ISNULL(a.sSpmc,b.sSpmc) sspmc,
ISNULL(a.nJhj,b.nJhj) njhj,ISNULL(a.nLsj,b.nLsj) nLsj,a.nZdsl,a.nZgsl,
a.nDhts,b.nDhts,a.nRjxse,b.nRjxse,
a.nqhmle,b.nqhmle ,ISNULL(a.nqhmle,0)-ISNULL(b.nqhmle,0) nqhce  from #2 a 
full join #2 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.npm=2  and a.npm+1=b.npm
where 1=1  and a.npm=1  order by  ISNULL(a.nqhmle,0)-ISNULL(b.nqhmle,0) desc
/*  之后取 累计增加额 70% 的商品即可  */

------ 贝叶斯公式计算 商品发生销售的概率
/*
	门店商品会发生销售的概率判断
*/
/* 还有淡季和旺季的 区别，如果是季节性商品，按最后销售日期计算概率的话会把特殊时期的
情形一：旺季商品，季节性商品，促销商品，销售激增之后缺货
情形二：因为供应商不送，造成商品缺货，使得有库存天数减少，发生销售概率下降，
情形三：

 */
-- select  a.sfdbh,b.sSpbh, max(CONVERT(date,a.dSj)) max_drq into #Tmp_zhxsrq   from dbo.Tmp_Xsb a,dbo.Tmp_Xsnrb b 
-- where a.sXsdh=b.sXsdh and a.dSj>=CONVERT(date,getdate()-60)  
-- and a.sfdbh=b.sFdbh and a.sfdbh='012' and b.nXssl>0  group by  a.sfdbh,b.sSpbh;
-- Step 0:  取30天内的销售
select CONVERT(date,a.dSj) drq,a.sfdbh,b.sSpbh,sum(b.nXssl) nxssl into #Tmp_xs from dbo.Tmp_Xsb a,dbo.Tmp_Xsnrb b 
where a.sXsdh=b.sXsdh and a.dSj>=CONVERT(date,getdate()-30) and a.dSj<CONVERT(date,GETDATE())
and a.sfdbh=b.sFdbh and a.sfdbh='012'  group by CONVERT(date,a.dSj) ,a.sfdbh,b.sSpbh;


-- Step 1:取30天的期末库存 drop table #Tmp_kc
select a.sFdbh,a.sSpbh,a.dRq drq_raw,a.nSl,CONVERT(date,a.dRq) dRq  into #Tmp_kc
from dbo.Tmp_Kclsb a  where a.sFdbh='012' and 
a.dRq>=CONVERT(date,GETDATE()-31) and a.dRq<CONVERT(date,GETDATE());

-- Step 2:生成近30天日期
declare @begindate date
declare @enddate date
select @begindate=CONVERT(date,GETDATE()-30), @enddate=CONVERT(date,GETDATE())
create table #tmp_date(drq date not null);
while @begindate<@enddate
begin
	insert into #tmp_date(drq) select @begindate
	set @begindate=dateadd(day,1,@begindate)
end ;

-- Step 3:计算范围

select distinct a.sFdbh,a.sSpbh,b.drq into #Base_sp from dbo.R_Dpzb a ,#tmp_date b  where 1=1 and a.sFdbh='012';

-- Step 4: 计算概率
-- Step 4.1:有库存的概率
   select a.sFdbh,a.sSpbh,sum(case when ISNULL(b.nsl,0)>0 then 1 else 0 end) nykcts,
   sum(case when ISNULL(b.nsl,0)>0 then 1 else 0 end)/count(a.drq) nPa
   into #tmp_kcgl from #Base_sp a 
   left join #Tmp_kc b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and a.drq=b.dRq
   where 1=1  group by a.sFdbh,a.sSpbh;

-- Step 4.2 :有库存时产生销售的概率
   select a.sFdbh,a.sSpbh,sum(case when ISNULL(b.nsl,0)>0 or (ISNULL(b.nsl,0)<=0 and ISNULL(c.nxssl,0)>0) then 1 else 0 end) nykcts,
   sum(case when  ISNULL(c.nxssl,0)>0 then 1 else 0 end) nyxsts into #Tmp_xsgl  from #Base_sp a 
   left join #Tmp_kc b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and  DATEdiff(day,b.dRq,a.drq)=1
   left join #Tmp_xs c on a.sFdbh=c.sfdbh and a.sSpbh=c.sSpbh and a.drq=c.drq
   where 1=1  group by a.sFdbh,a.sSpbh;

   select a.sFdbh,a.sSpbh,a.sSpmc,a.sZdbh,a.nRjxl_De,a.nZdsl,a.nZgsl,a.nXssl,b.nykcts,b.nPa,
   case when c.nykcts=0 then 0 else c.nyxsts*1.0/c.nykcts end nxsgl,b.nPa*case when c.nykcts=0 then 0 else c.nyxsts*1.0/c.nykcts end
   from  dbo.R_Dpzb a 
   left join #tmp_kcgl b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
   left join #Tmp_xsgl c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
   where 1=1 and a.sFdbh='012' order by a.nRjxl_De desc
    
     


