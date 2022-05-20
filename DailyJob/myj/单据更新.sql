declare @day int  -- 单据取数的开始时间距当前日期的间隔天数
declare @nday_ps int -- 单据和进出相匹配的有效天数
declare @nday_zs int   
select @day=7,@nday_ps=3, @nday_zs=6
-- Step 1: 取要货单和采购

    select a.dYhrq,a.dShrq,a.sLx,b.sFdbh,b.sspbh,a.sdh,b.nYhsl,0 nshsl,a.sBz,c.sGys  into #Tmp_yh
	from tmp_yh a
	inner join tmp_yhmx b on a.sdh=b.sdh and a.sFdbh=b.sFdbh
	join Tmp_spb_All c on  b.sspbh=c.sSpbh
    join Tmp_FDB d on a.sFdbh=d.sFDBH 
	where  1=1 and a.dYhrq>=CONVERT(date,GETDATE()-@day) and    a.dYhrq<=CONVERT(date,GETDATE());

	select a.dYhrq,a.dShrq,a.sLx,b.sFdbh,b.sspbh,a.sdh,b.nYhsl,0 nshsl,a.sBz,sGys into #tmp_cg
	from tmp_cgdd a
	inner join tmp_cgddmx b on a.sdh=b.sdh and a.sFdbh=b.sFdbh
    join Tmp_FDB d on a.sFdbh=d.sFDBH 
	where  1=1  and a.dYhrq>=CONVERT(date,GETDATE()-@day) and   a.dYhrq<=CONVERT(date,GETDATE());
	

--Step 2: 取进出中要货和采购的到货类型（从标准进出表中排除调拨 盘点，损溢） drop table #Jcmx
	select a.sFdbh,b.sSpbh, CONVERT(date,a.dSj) drq,sum(b.nSl) ndhsl,
	ROW_NUMBER()over(partition by a.sfdbh,b.sspbh order by CONVERT(date,a.dSj)) npm ,e.sGys into #Jcmx
	from Tmp_Jcb a,Tmp_Jcmxb b,Purchase_jcflbzb c,Tmp_FDB d,Tmp_spb_All e  where a.sJcbh=b.sJcbh and a.sJcfl=c.fl_content and c.fl_bzname not in ('盘点','调拨','损溢')
	and a.dSj>=CONVERT(date,GETDATE()-@day) and  a.dSj<=CONVERT(date,GETDATE()) and b.nSl<>0
	and a.sFdbh=d.sFDBH    and b.sSpbh=e.sSpbh
	group by a.sFdbh,b.sSpbh ,CONVERT(date,a.dSj),e.sgys;

-- Step 3:对进出范围内关联的单据排序，然后每条记录进行分配，如果配送和非配送能分开，则分开进行，如果不能就合并处理 drop table #tmp_dj
    select dYhrq,sdh,sFdbh,sSpbh,nYhsl,nShsl,sLx,sBz,'采购单' sflag,0 sfupdate,CONVERT(datetime,Null) dShrq,sGys  into #Tmp_dj from #tmp_cg
	union 
	select dYhrq,sdh,sFdbh,sSpbh,nYhsl,nShsl,sLx,sBz,'要货单',0 sfupdate,CONVERT(datetime,Null) dShrq,sGys from #Tmp_yh
 
 
	-- 循环更新 
	declare @maxpm int -- 进出表的最大排名
	declare @i int  -- 循环变量

	set @maxpm=(select max(npm) from #Jcmx)
	set @i=1
	while @i<=@maxpm
		begin
			select * into #tmp_jcmx from #Jcmx where npm=@i;
			select a.sFdbh,a.sSpbh,a.drq,a.ndhsl,a.npm,b.sdh,b.nYhsl,b.nShsl,b.sflag,0 sfupdate,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh ,a.drq order by b.dyhrq,b.nYhsl desc) nyhpm into #tmp_match 
			from #tmp_jcmx a 
			left join   dbo.Tmp_FDB  c on a.sFdbh=c.sFDBH
			left join  dbo.tmp_spb d on a.sFdbh=d.sFDBH and a.sSpbh=d.sSpbh
			left join Tmp_Gys e on a.sGys=e.sGysbh and a.sfdbh=e.sfdbh
			left join #Tmp_dj b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and a.drq>=convert(date,b.dYhrq) and 
	           a.drq<=case when b.sflag='要货单' then DATEADD(day,case  when ISNULL(c.nDhzcjg,0)<=0 or ISNULL(c.nDhzcjg,0)>7 then  2 else c.nDhzcjg end,b.dYhrq) when b.sflag='采购单' then DATEADD(day,case  when  ISNULL(e.nDay,0)<=0 or   ISNULL(e.nDay,0)>20 then 6 else e.nDay end ,b.dYhrq)   end    
	        where 1=1   and b.nYhsl>=abs(a.ndhsl) and b.nshsl<b.nYhsl 
			--  and b.sfupdate=0 
			;

			declare @nyhpm int
			set @nyhpm=1

			-- 更新单据和进出
			while (select count(1) from #tmp_match where ndhsl<>0 and sfupdate=0  )>0
			    begin
			    update b set b.nShsl=b.nshsl+case when a.ndhsl>=a.nYhsl-b.nshsl then a.nYhsl-b.nshsl else a.nDhsl end,b.sfupdate=1,b.dShrq=case when b.dShrq is  null 
				then a.drq else b.dShrq end from #tmp_match a,#Tmp_dj b 
				where a.nyhpm=@nyhpm and a.sdh=b.sdh and a.sfdbh=b.sFdbh and a.sspbh=b.sspbh ;

				-- 同一个门店商品的进出数量更新
				update a set a.sfupdate=case when  a.nyhpm=@nyhpm then  1 else a.sfupdate end,
				a.ndhsl=a.ndhsl-case when a.ndhsl>=a.nYhsl-b.nshsl then a.nYhsl-b.nshsl else a.nDhsl end from #tmp_match a,#Tmp_dj b 
				where 1=1 and a.sdh=b.sdh and a.sfdbh=b.sFdbh and a.sspbh=b.sspbh ;

				set @nyhpm =@nyhpm+1
				end
			drop table #tmp_match;
			drop table #tmp_jcmx;
			set @i=@i+1
		end

 -- Step 3 :更新实体要货表和采购表
    update a set a.dShrq=b.drq from dbo.tmp_yh a,(select sdh,sfdbh,min(dShrq) drq from #Tmp_dj where sfupdate=1  group by sdh,sfdbh)b where a.sdh=b.sdh and a.sFdbh=b.sFdbh ;
    update a set a.nShsl=b.nShsl from dbo.tmp_yhmx a,#Tmp_dj b where a.sdh=b.sdh and a.sFdbh=b.sFdbh and a.sspbh=b.sSpbh and b.sfupdate=1;
	update a set a.dShrq=b.drq from dbo.Tmp_Cgdd a,(select sdh,sfdbh,min(dShrq) drq from #Tmp_dj where sfupdate=1  group by sdh,sfdbh)b where a.sdh=b.sdh and a.sFdbh=b.sFdbh ;
	update a set a.nShsl=b.nShsl from dbo.Tmp_Cgddmx a,#Tmp_dj b where a.sdh=b.sdh and a.sFdbh=b.sFdbh and a.sspbh=b.sSpbh and b.sfupdate=1;