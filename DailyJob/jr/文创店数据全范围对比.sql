/*
全范围对比，横向和纵向对比
横向：背景店、维联店、全店

*/
-- Step 0:取2022-03-25以来的销售、客单和动销、周转和品种数

-- Step 1:
declare @begindate date
declare @enddate date 
set @begindate=CONVERT(date,'#RQ#')
set @enddate=CONVERT(date,'#ENDRQ#') 
select a.* into #base_data from DAppResult.dbo.H_Kpi a  
join  DAppResult.dbo.Tmp_FDB b on a.sFdbh=b.sFDBH 
where 1=1  and  a.enddate>=@begindate and a.enddate<=@enddate   #Params#   ;



select right(a.taskid,8) drq,a.sFdbh,a.sFdmc,a.nRjxse,a.nRjml,a.nRjkd,a.nDxl,a.nQhssl,a.nZzts,a.nZjzy,a.nQhss,a.nmll
,a.nBqFkcbl,a.nBqXsycbl ,a.nJypzs into #1  from #base_data a 
where 1=1     #Params1# ; 


     
select top 50  a.drq 日期,'维联店' 范围, AVG(a.nZzts)  店均周转天数,avg(a.nRjxse) 店日均销售额,avg(a.nmll) 店日均毛利率,AVG(a.nRjml) 店日均毛利额,AVG(a.nRjkd)  店日均客单数,
AVG(a.ndxl)  店均动销率,AVG(a.nQhssl)  店均缺货损失率,avg(a.nQhss) 店均缺货损失额,AVG(a.nZjzy)  店均资金占用,AVG(a.nJypzs) 店均商品数    from #1 a 
where 1=1  and a.sFdbh in ('018320','018346','018300','018308','012011','018390','018391')   group by a.drq
union
select top 50  a.drq 日期,'全店', AVG(a.nZzts)  店均周转天数,avg(a.nRjxse) 店日均销售额,avg(a.nmll) 店日均毛利率,AVG(a.nRjml) 店日均毛利额,AVG(a.nRjkd)  店日均客单数,
AVG(a.ndxl)  店均动销率,AVG(a.nQhssl)  店均缺货损失率,avg(a.nQhss) 店均缺货损失额,AVG(a.nZjzy)  店均资金占用,AVG(a.nJypzs) 店均商品数    
from #1 a 
join  DAppResult.dbo.Tmp_FDB b on a.sFdbh=b.sFDBH 
where 1=1  and  b.sFDLX in ('大店A','大店B','小店','中店A','中店B') 
and   b.sJylx='连锁门店' and b.dkyrq is not null and b.sjc not like '%取消%'  
group by a.drq
union
select top 50  a.drq 日期,'文创店', AVG(a.nZzts)  店均周转天数,avg(a.nRjxse) 店日均销售额,avg(a.nmll) 店日均毛利率,AVG(a.nRjml) 店日均毛利额,AVG(a.nRjkd)  店日均客单数,
AVG(a.ndxl)  店均动销率,AVG(a.nQhssl)  店均缺货损失率,avg(a.nQhss) 店均缺货损失额,AVG(a.nZjzy)  店均资金占用,AVG(a.nJypzs) 店均商品数 
from #1 a  
where 1=1 and a.sFdbh='018425'   group by a.drq
#OB# order by a.drq #OE#