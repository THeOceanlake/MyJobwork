/*
    通过历史补货单

     一种是有拆零位的配送商品的频率和金额评估
     一种是没有拆零位的配送商品的频率和金额，频率很高，拆零没有意义，日均很高
     拆零商品是销售还可以的，店均为0 的直接
     需要回答的问题
        1 哪些商品需要拆零？—— 最小包装数 是店均销量的50天以上，5 以上
        2 动态拆零位的特点和优势？ 
            动态拆零位 是针对销售不好的配送商品，降低因包装数的原因产生大库存。同时这些商品一次配送能支持很长一段时间的
                 销售，一直占用拆零位也是一种浪费，可以将库位释放出来给其他单品使用。
        3 哪些商品适配动态拆零位？-建模计算
            简单算法：将现有占用拆零位，但频率不高的商品退出，kpi?频率？
目前的难点：
    1、当前数据结构不支持动态拣货位的效果评估；
*/

--  门店在要货数据 drop table #Tmp_yh
select * into #T_tihi from  [122.147.10.200].dappsource.dbo.t_tihi

 
select a.dYhrq,b.ddhrq dShrq,a. sdjlx sLx,b.sfdbh,b.sspbh,b.nsl nYhsl,b.ndhsl,b.sBzmx into #Tmp_yhd
from [122.147.10.200].dappsource.dbo.tmp_yhb a 
inner join [122.147.10.200].dappsource.dbo.tmp_yhmx b
on a.sdh=b.sdh and a.sFdbh=b.sFdbh
-- join #Tmp_fdb c on a.sfdbh=c.sfdbh
where 1=1  and a.dYhrq>=CONVERT(date,GETDATE()-90) 
and (  a.dYhrq+2<GETDATE() or b.ddhrq is not null);

select CONVERT(date,a.dShrq) drq,b.locn_brcd,COUNT(distinct a.sspbh) nsps,
sum(a.nYhsl) Yhsl,sum(a.nDhsl) nDhsl into  #T1  from #Tmp_yhd a,
#T_tihi b  where a.sspbh=b.SIZE_DESC and b.LOCN_Class='零拣'
and a.dShrq is not null  group by CONVERT(date,a.dShrq)  ,b.locn_brcd order by 1,2 ;

-- 
select a.locn_brcd,STDEV(a.nDhsl),AVG(a.nDhsl) from #T1 a group by a.locn_brcd

-- FD0000110  N-1
select a.locn_brcd,count(1)  from #T_tihi a where a.locn_class='零拣' group by a.locn_brcd order by 2 desc


select *  from #T_tihi a where a.locn_class='零拣'
and a.locn_brcd='FD0000110'

select * from #T1  order by nsps desc

 -- 生成日期
  declare @begindate date
 declare @enddate date
 select @begindate=CONVERT(date,GETDATE()-90), @enddate=CONVERT(date,GETDATE())
 create table #tmp_date(drq date not null);
 while @begindate<@enddate
   begin
		insert into #tmp_date(drq) select @begindate
		set @begindate=dateadd(day,1,@begindate)
   end 

   with x0 as (
   select * from #tmp_date a ,(select distinct  locn_brcd,count(1) nhwsps  from #T_tihi where locn_class='零拣' 
   group by locn_brcd ) b)
   select * from x0 a 
   left join #T1 b on a.drq=b.drq and a.locn_brcd=b.locn_brcd
   where 1=1  order  by  1,2 