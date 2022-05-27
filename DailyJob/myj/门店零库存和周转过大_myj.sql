-- 门店零库存和大库存数据源
--Step 1：试点门店和自动补货商品
select sFDBH,sFDMC,sFDLX,sPsZt into #Tmp_FDfw
from dbo.Tmp_FDB  where  binglang_state  =1 or  lengcang_state=1 or  hongbei_state=1;

-- drop table #tmp_zdbhspfw
select a.sFdbh,b.sFDMC,b.sFDLX,a.sSpbh,a.sPslx,a.sSfkj into #tmp_zdbhspfw 
from dbo.Sys_GoodsConfig a,#Tmp_FDfw b
where sSfkj='1' and  a.sFdbh=b.sFDBH;
 
-- Step 2：生成基础表 drop table #base_sp
-- drop table #mdspde
select a.sFdbh,sSpbh,nJyxx,nJysx,sPslx,srq,a.nRjxl_De into #mdspde from  Sys_GoodsConfig_his  a,
#Tmp_FDfw b
where  1=1 and a.sFdbh=b.sFDBH and CONVERT(date,djssj)=CONVERT(date,GETDATE()-1);

select a.sFdbh,a.sSpbh,c.sSpmc,c.sFl,c.sGys,d.nJj,d.nSj,1 sZdbh,d.sPsfs,e.nRjxl_De*c.nJj nrjxse,
e.nJysx nZgsl,e.nJyxx nZdsl,e.nRjxl_De nRjxl
,d.nCgbzs,ISNULL(d.nPsbzs,1) nPsbzs, a.sSfkj ,c.nbzt   into #base_sp
from #tmp_zdbhspfw  a
left join Tmp_spb_All  c on a.sSpbh=c.sSpbh
left join tmp_spb d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh
left join #mdspde e on a.sFdbh=e.sFdbh and a.sSpbh=e.sSpbh
where  1=1   and c.sFl not in (select sflbh from tmp_spflb_ex)
and a.sSpbh not in (select sSpbh from tmp_spb_ex) ; 

-- drop table #mdkc;
select a.sFdbh,a.sSpbh,CONVERT(date,GETDATE()-1) drq,
case when isnull(a.nSl,0)<=0 then 0 else a.nSl end nsl into #mdkc
from dbo.Tmp_Kclsb a with(nolock),#Tmp_FDfw b  
where a.dRq>=CONVERT(date,GETDATE()-1) and a.sFdbh=b.sFDBH;

-- Step 3:生成门店零库存商品表 drop table #mdlkcsp
select a.*,isnull(b.nsl,0) nsl,CONVERT(varchar(20),'') syy,convert(datetime,Null ) dzhyhrq into #mdlkcsp from #base_sp a 
left join #mdkc b on  a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where 1=1 and ISNULL(b.nsl,0)<=a.nRjxl_De*3;

-- Step 4:查门店最后一次要货或采购 单据时间往前查180天  drop table #Tmp_yh
    -- Step 4.1 :要货数据 ，如果D咨询还管出单的话就有必要存原单
	with x0 as (
	select a.dYhrq,a.dShrq,a.sLx,b.*,a.sBz
	from tmp_yh a  	inner join tmp_yhmx b on a.sdh=b.sdh and a.sFdbh=b.sFdbh
	join  #base_sp c on a.sFdbh=c.sFdbh and b.sspbh=c.sSpbh
	where  1=1 and a.dYhrq>=CONVERT(date,GETDATE()-180) and ( a.dYhrq+1<GETDATE() or a.dshrq is not null) )
	select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id into #Tmp_yh 
	from x0 a ;

	-- drop table #Tmp_cg
	with x0 as(
	select a.dYhrq,a.dShrq,a.sLx,b.*,a.sBz
	from tmp_cgdd a inner join tmp_cgddmx b on a.sdh=b.sdh and a.sFdbh=b.sFdbh
	join  #base_sp c on a.sFdbh=c.sFdbh and b.sspbh=c.sSpbh
	where  1=1  and a.dYhrq>=CONVERT(date,GETDATE()-180) and (a.dYhrq+5<GETDATE() or  a.dshrq is not null)
	)
	select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYHsl desc) id into #Tmp_cg
	from x0 a;
	-- Step 4.2 ：D咨询原单 drop table #Dzixun_raw
	create table #Dzixun_raw(dYhrq datetime,sbh varchar(50),sFdbh varchar(50),sSpbh varchar(30),nCgsl money,nCgbzs money,GenState varchar(100),sMemo varchar(100));
	
	select a.sDh,CONVERT(date,a.dDhrq) dYhrq,a.sFdbh,b.sSpbh,b.nsl into #zdd_raw 
	from Purchase_DeliveryReceipt a
	,dbo.Purchase_DeliveryReceipt_Items b where a.sDh=b.sDh and a.sFdbh=b.sFdbh
	and CONVERT(date,a.dDhrq)>=CONVERT(date,GETDATE()-180) ;

	 insert into #Dzixun_raw(dYhrq,sbh,sFdbh,sSpbh,nCgsl,nCgbzs,GenState,sMemo)
	 select a.dYhrq,sdh,a.sFdbh,a.sSpbh,a.nsl nCgsl,case when c.sPsfs='统配' then  c.nPsbzs else c.nCgbzs end,
	 '' GenState,'自动订单'sMemo   
	 from  #zdd_raw a
		join #base_sp c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
		join dbo.Tmp_Gys b on c.sGys=b.sGysbh and b.sFDBH='0000'
		where  a.dYhrq>=CONVERT(date,GETDATE()-180) 
		and (( c.spsfs='统配' and DATEADD(day,isnull(b.nDay,1),a.dYhrq) <GETDATE() )  or 
		( c.spsfs<>'统配' and DATEADD(day,isnull(b.nDay,5), a.dYhrq)<GETDATE())) and nsl>0;
 	
		--Step 4.3 :生成最后的单据，这里需要调研D咨询单转ERP实际单的有效期 drop table #TMP_dh_cal
		with x0 as (
		select sFdbh,sspbh,sdh,dYhrq,dShrq,sLx,nYhsl,nShsl,sBz,id,'门店向DC要货' flag  from #Tmp_yh  where 1=1
		 union
		select sFdbh,sspbh,sdh,dYhrq,dShrq,sLx,nYhsl,nShsl,sBz,id,'门店采购单'  from #Tmp_cg where 1=1)
		select ISNULL(a.sFdbh,b.sFdbh) sfdbh,ISNULL(a.sspbh,b.sSpbh) sspbh,ISNULL(a.dYhrq,b.dYhrq) dYhrq,a.dShrq, a.nYhsl,b.nCgsl nYhsl_raw,
		a.nShsl,b.GenState,b.sMemo,a.sLx,sBz,a.flag,ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
		ISNULL(a.sspbh,b.sSpbh) order by isnull(a.dyhrq,b.dyhrq) desc) npm_cal,b.nCgbzs,case when a.sFdbh is null then '系统单' end is_auto 
		into #TMP_dh_cal from x0 a 
		full join #Dzixun_raw b on a.sFdbh=b.sFdbh and a.sspbh=b.sSpbh and DATEDIFF(HOUR,b.dYhrq,a.dYhrq)>0 
		and DATEDIFF(HOUR,b.dYhrq,a.dYhrq)<24
		where 1=1 ;

		-- select max(dYhrq) from #Tmp_yh where nYhsl is not null  order by dYhrq desc
		-- select * from #Dzixun_raw  order by dYhrq desc
		-- Step 5：最后的进出和销售日期,同一天出的越多原因靠前   drop table #jcmx0
		-- 从最长间隔天数和有效期反推最后订货日就可以了
		with x0 as (
		select  convert(date,a.dSj) dsj,a.sFdbh,b.sSpbh,a.sJcfl,sum(b.nSl) nsl
		  from dbo.Tmp_Jcb a ,dbo.Tmp_Jcmxb b,#Tmp_FDfw c where a.sJcbh=b.sJcbh
		and a.sFdbh=b.sFdbh and a.dSj>CONVERT(date,GETDATE()-30) and a.sFdbh=c.sFDBH
		 group by   convert(date,a.dSj),a.sFdbh,b.sSpbh,a.sJcfl)
		select  a.*, ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by convert(date,a.dsj) desc,a.nsl )  npm into #jcmx0
		from x0 a where a.nsl<0;

		-- drop table #xsrq
		with x0 as(
		select a.*,b.sSpbh,b.nXssl,b.nXsje,b.nMl from Tmp_Xsb  a, dbo.Tmp_xsnrb  b where a.sXsdh=b.sXsdh and a.sfdbh=b.sFdbh
		and a.dSj>=CONVERT(varchar,GETDATE()-14,112) ) 
		select a.sFdbh,a.sSpbh,CONVERT(date,left(b.sxsdh,8),23) max_xs,sum(b.nXssl) nXssl,
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by CONVERT(date,left(b.sxsdh,8),23) desc) npm 
		into #xsrq from #mdlkcsp a,x0 b where a.sFdbh=b.sFdbh 
		and a.sSpbh=b.sSpbh 
		group by a.sFdbh,a.sSpbh,CONVERT(date,left(b.sxsdh,8),23);

	-- Step 6:分原因
		-- 对特殊设置进行区分,所有原因归为 暂不出单
		if (select count(1)  from sysObjects  where name=UPPER('Purchase_DeliveryReceipt_ExGys'))=1
			begin 
				update a set a.syy='暂不出单' from #mdlkcsp a
				join dbo.Purchase_DeliveryReceipt_ExGys b on a.sFdbh=b.sFdbh and a.sGys=b.sGysbh;
		    end   
		update a set a.syy='暂不出单' from #mdlkcsp a
		 where   a.sfdbh in (select sParamsVal from Purchase_Params  where sParamsName='DeliveryBchFd');      
		--Step 6.1  如果最后一次的进出记录 在最后一次销售之后，同时类型是扣减库存的，则是进出，这里需要注意的是时间的选择
		update a set a.syy=b.sJcfl from #mdlkcsp a 
		join #jcmx0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
		left join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
		where  (b.dSj>c.max_xs or c.sFdbh is null)  and abs(b.nSl)>2 
		and abs(b.nSl)>=round(a.nzgsl*0.7,0) and (( a.sPsfs='统配' and b.dSj>CONVERT(date,GETDATE()-2)) 
		or (a.sPsfs<>'统配' and b.dSj>CONVERT(date,GETDATE()-7)));

		-- Step 6.1:突发销售
		update a set a.syy='突发销售' from #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
		join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
		where len(a.syy)=0  and  (( a.sPsfs='统配' and c.max_xs>CONVERT(date,GETDATE()-5)) 
		or (a.sPsfs<>'统配' and c.max_xs>CONVERT(date,GETDATE()-14))) and c.nXssl>2      
                 and   c.nXssl>=round(a.nzgsl*0.7,0) and c.nXssl>a.nRjxl*5
			and (c.max_xs>b.dShrq or b.dShrq is null) ;

		 

	    -- Step 6.1.2 如果是非突发销售，而最近又没订货的，则是系统订额不足或人工未下单，如果未到订货日就会分错
		  -- 生成日期
		 declare @begindate date
		 declare @enddate date
		 select @begindate=CONVERT(date,GETDATE()-30), @enddate=CONVERT(date,GETDATE())
		 create table #tmp_date(drq date not null);
		 while @begindate<@enddate
		   begin
				insert into #tmp_date(drq) select @begindate
				set @begindate=dateadd(day,1,@begindate)
		   end ;
		   -- 近一月库存
		   with x0 as (select  distinct a.drq,b.sFdbh,b.sSpbh,b.nZdsl,b.nZgsl  from #tmp_date a,#mdlkcsp b    )
		   select  a.*,ISNULL(b.nSl,0) nkcsl into #tmp_kc from x0  a 
		   left join dbo.Tmp_Kclsb b on a.drq=b.dRq and a.sFdbh=b.sFdbh and  a.sSpbh=b.sSpbh
		   ;
		   -- 近一月定额 drop table #tmp_lsde
		   select a.sFdbh,sSpbh,nJyxx,nJysx,sPslx,srq,djssj into #mdspde_ls from  Sys_GoodsConfig_his  a,
			#Tmp_FDfw b
			where  1=1 and a.sFdbh=b.sFDBH and CONVERT(date,djssj)>=CONVERT(date,GETDATE()-31);

		   with x0 as (select  distinct a.drq,b.sFdbh,b.sSpbh,b.nZdsl,b.nZgsl  from #tmp_date a,#mdlkcsp b)
		   ,x1 as (select a.*,isnull(b.nJysx,a.nzgsl) nsx,isnull(b.nJyxx,a.nzdsl) nxx
		   from x0 a left join #mdspde_ls b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and a.drq=dateadd(day,1,CONVERT(date,b.srq))
		   where 1=1 )   
		   select * into #tmp_lsde from x1  ;

		   -- 在出单日库存低于下限时，没有单据，则是出单有问题
		
		     -- 该出单的商品  drop table #erp_cd
		 	with x0 as (select  distinct a.drq,b.* from #tmp_date a,#mdlkcsp b)
		 ,x1 as (select  distinct a.sFdbh,a.sSpbh,a.sSpmc,a.drq,a.sGys,a.sPsfs   from x0 a
		left join #tmp_kc c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and a.drq=c.drq
	        join #tmp_lsde d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh and a.drq=d.drq
		where  1=1   and   len(a.syy)=0 and  a.sZdbh=1   and  ISNULL(c.nkcsl,0)<d.nxx   and  d.nsx-ISNULL(c.nkcsl,0)>0  )
		select  distinct a.sFdbh,a.sSpbh,a.sSpmc,a.sGys,max(a.drq) max_drq into #erp_cd  from x1 a
		 join dbo.Tmp_Gys e on e.sFDBH='0000' and a.sGys=e.sGysbh
		  join dbo.Tmp_FDB f on a.sFdbh=f.sFDBH
		 where  case when  a.sPsfs='直送' and  DATEADD(day,isnull(e.nDay,5),a.drq) <convert(date,GETDATE())  and e.sdays is not null  and e.sType=UPPER('W')  then SUBSTRING(e.sDays,DATEPART(WEEKDAY,a.drq)-1,1)
		 when  a.sPsfs='直送' and DATEADD(day,isnull(e.nDay,5),a.drq)<convert(date,GETDATE())  and e.sdays is not null  and e.sType<>UPPER('W')  then SUBSTRING(e.sDays,DATEPART(DD,a.drq),1)
		 when a.sPsfs<>'直送' and   DATEADD(day,2,a.drq)<convert(date,GETDATE())   then '1'   else '0'   end ='1' 
		 group by a.sFdbh,a.sSpbh,a.sSpmc,a.sGys; 

		 update a set  a.syy=  '系统定额不足'   from  #mdlkcsp a 
		 join #erp_cd c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh 
		  left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  and b.dYhrq>=c.max_drq
		 where 1=1  and   len(a.syy)=0  and  a.sZdbh='1'   and b.sfdbh is null  and c.sFdbh is not null;
	 

		 update a set  a.syy= case when  c.IntoDate>GETDATE()-5 then  '系统定额不足' else '新品' end   from  #mdlkcsp a 
		 left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  and   b.dYhrq>=convert(date,GETDATE()-30)
		 left join dbo.Index_Sp c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh 
		 where 1=1  and   len(a.syy)=0  and  a.sZdbh='1'  and b.sfdbh is null;

		  update a set  a.syy='人工未下单'  from  #mdlkcsp a 
		 left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  and b.dYhrq>convert(date,GETDATE()-7)
		 where 1=1  and   len(a.syy)=0  and  a.sZdbh='0'    and b.sfdbh is null;
	  
		-- Step 6.2 直送商品，供应商未送，采购单，供应商到货量为空
	   update a set a.dzhyhrq=b.dYhrq,a.syy=spsfs+'供应商未送货'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
	    where 1=1    and  len(a.syy)=0  and a.sPsfs<>'统配' and isnull(b.nShsl,0)=0 ;

  
	  -- Step 6.4 供应商送货不足，采购量到货量低于90%
	  update a set a.dzhyhrq=b.dYhrq,a.syy=spsfs+'供应商送货不足'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
	  where 1=1  and  len(a.syy)=0  and a.sPsfs<>'统配' and b.nYhsl>0  and  b.nShsl*1.0/b.nYhsl<0.9 ;
	  
	  -- Step 6.5 人工订货不足，szdbh=0
	  update a set a.syy='人工未下单'  from  #mdlkcsp a 
		left  join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
	  where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)=0 ;
   
	  update a set a.dzhyhrq=b.dYhrq,a.syy='人工订货不足'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
	  where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)>0  and b.nShsl*1.0/b.nYhsl>=0.9 ;


	  -- Step 6.6 DC未送货 或 送货不足
	  update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心未送货'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
	  where 1=1  and   len(a.syy)=0  and b.sfdbh is not null  and   isnull(b.nShsl,0)=0 and a.sPsfs='统配'
	  and b.nYhsl>0;
  
	   update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心送货不足'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
	  where 1=1  and   len(a.syy)=0  and b.nShsl>0 and  b.nYhsl*1.0/b.nShsl<0.9 and a.sPsfs='统配' ;


	  -- Step 6.7 :系统未下单，或定额不足
	  -- 系统未下单 需要考虑节奏日，如果即使到节奏日出了单，那也是定额不足，后面用异常出单修正原来的原因
		update a set  a.syy='系统定额不足'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
		where 1=1  and   len(a.syy)=0  and  a.sZdbh=1    and b.sfdbh is null;
  
		-- Step 6.8:系统定额不足,但如果是手工改小的采购单 
		update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
		where 1=1  and   len(a.syy)=0   and b.nShsl>0   and  b.nShsl*1.0/b.nYhsl>=0.9
		and  a.sZdbh=1   and b.sLx ='门店自动' ;
	    select * from #TMP_dh_cal where nYhsl>0
		--Step 6.9: 人工改小或删单
		update a set a.dzhyhrq=b.dYhrq,a.syy='人工减量或删单'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
	    and ((b.nShsl>0  and b.nYhsl_raw>b.nYhsl 
			and isnull(b.nYhsl,0)>0) or (b.nYhsl_raw>0 and b.nYhsl is null ))
		where 1=1  and   len(a.syy)=0   
		and  a.sZdbh=1 and b.sfdbh is not null ;



		--Step 6.10: 系统定额不足，人工未减量，供应商到货
		update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
		where 1=1  and   len(a.syy)=0   and b.nShsl>0 and  b.nShsl*1.0/b.nYhsl>=0.9
		and  a.sZdbh=1  and b.nYhsl_raw=b.nYhsl  ;

		 -- 起订量等限制
		-- Step 6.11:未出单的单据更新：如果系统出单在最后日期之后，且未达起订量 drop table #ycdp 
		with x0 as(
		select sfdbh, sspbh, sbh, dYhrq   ,GenState,
		ROW_NUMBER()over(partition by sspbh order by dYhrq desc) npm  from   #Dzixun_raw 
		where 1=1  and  GenState not in ('补货数量为0','已出单' ,'已存在紧急订单' ))
		select * into #ycdp from x0 where npm=1;
		 
		 update a set a.syy= b.GenState  from #mdlkcsp a   join #ycdp b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
		where a.syy in ('人工未下单','系统定额不足') and b.sFdbh is not null; 
	 
		 update a set a.syy='系统定额不足' from #mdlkcsp a    where len(a.syy)=0 and a.sZdbh='1'; 
		 if  (select count(1)  from sysObjects  where name=UPPER('Purchase_DeliveryReceipt_Items'))=1
			 begin 
				  with x0 as(
				select sfdbh, sspbh, sDh,convert(date,left(sdh,8)) drq ,nZddhje,nZddhsl,spsfs,
				ROW_NUMBER()over(partition by sfdbh,sspbh order by convert(date,left(sdh,8)) desc) npm  from  dbo.Purchase_DeliveryReceipt_Items 
				where 1=1 and convert(date,left(sdh,8))>=dateadd(day,-180,convert(date,GETDATE())) and spsfs    like '%<线下>%' )
				select * into #ycdp1 from x0 where npm=1;

				 update a set a.syy='用户定额出单' from #mdlkcsp a   join #ycdp b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
				 where a.syy in ('系统定额不足') and b.sFdbh is not null; 
		   end
	
		 update a set a.syy='其他' from #mdlkcsp a    where len(a.syy)=0 ; 
		 delete from dbo.TMP_MDLKCYY where drq=convert(date,GETDATE());
         delete from dbo.TMP_MDLKCYY where drq<=convert(date,GETDATE()-100);
		 insert into dbo.TMP_MDLKCYY(drq,sfdbh,sspbh,sspmc,sfl,nZdsl,nZgsl,szdbh,ssfkj,spsfs,syy,dzhyhrq,nrjxl,nrjxse,nsl)
		 select convert(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sSpmc,a.sFl,a.nZgsl ,a.nZdsl ,a.sZdbh,a.sSfkj,a.sPsfs,a.syy,
		 a.dzhyhrq,b.nRjxl,b.nRjxse ,nsl  from  #mdlkcsp a 
		 left join dbo.R_dpzb b on  a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh;


-- 第二部分 门店大库存
    -- Step 2.1 ：大库存数据生成 drop table #mddkc
	/*  门店大库存 */
		with x0 as (
		select a.*,b.nSl, convert(numeric(15,4),case when  a.nrjxl*a.nsj=0 then 300 
			else b.nsl*a.njj*1.0/(a.nRjxl*a.nsj) end) nzzts  from #base_sp a 
		left join #mdkc b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
		where 1=1 and ISNULL(b.nsl,0)>6 and ISNULL(b.nsl,0)*a.nJj>50 and b.nsl*a.njj*1.0/(a.nRjxl*a.nsj+0.001)>60)
		select a.sFdbh,a.sSpbh,a.sspmc ,a.sFl,b.sdw,b.sGys,b.nJj,b.nSj,b.sZdbh,b.sPsfs,a.nRjxl,a.nRjxl*a.nSj nrjxse,a.nsl
		, a.nzzts,a.nPsbzs,a.nCgbzs,convert(date,Null) dzhyhr,convert(date,Null) dzhdhr, 
		convert(varchar(20),'') syy,convert(varchar(5),'') sfwqzs,convert(varchar(20),'') sfcx,convert(money,Null) nYhsl,convert(money,Null) nDhsl into #mddkc  from x0  a 
		join dbo.tmp_spb b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh where 1=1 ; 

		--Step 2.2:最后一天进货 drop table #jcmx_raw
		select  CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #jcmx_raw
		  from dbo.Tmp_Jcb a ,dbo.Tmp_Jcmxb b   where a.sJcbh=b.sJcbh
		and a.sFdbh=b.sFdbh and a.dSj>convert(date,GETDATE()-180) 
		group by CONVERT(date,a.dsj)  ,a.sfdbh,a.sjcfl,b.sspbh ;

		-- drop table #jcmx
		with x0 as (
		 select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
		 ,a.nsl   from #jcmx_raw a  
		 join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		 where 1=1 and  a.nsl>2 )
		 select * into #jcmx from x0  where npm<=2;
 
    --  原因划分
    -- Step 2.3:遗留库存
	    with x0 as (
		 select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
		 ,a.nsl   from #jcmx_raw a  
		 join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		 where 1=1  and a.nsl>0  )
		update a set a.syy='遗留库存'   from #mddkc  a 
		left join x0 b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
		where 1=1  and b.sFdbh is null;

	 
    --Step 2.4: 特陈设置的,
		update a set a.syy='特陈过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl  from #mddkc a  
		 join #jcmx b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
		join dbo.Tmp_Tc c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
		and c.dKssj<b.dsj and c.dJssj>b.dsj and  c.nTcsl>6 and   c.nTcsl>=a.nsl*0.5 
		where 1=1 and len(a.syy)=0;
	
	-- Step 2.5:对盘点调拨 划分：盘点，调拨量大于当前库存数量的一半
		update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl,
		a.sfwqzs=case when b.nDhsl<a.nsl*0.2 and d.sfdbh is not null and d.nDhsl>a.nsl*0.1  then '是' end   from #mddkc a  
		 join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
                     and b.sjcfl in (select fl_content from dbo.Purchase_jcflbzb where  fl_bzname in('盘点','调拨','损溢') )
                 left join #jcmx d on a.sfdbh=d.sFdbh and a.sSpbh=d.sSpbh and d.npm=2 
                    and  d.sjcfl in (select fl_content from dbo.Purchase_jcflbzb where  fl_bzname in('盘点','调拨','损溢') )
		where  1=1  and len(a.syy)=0  and  (b.nDhsl>=a.nsl*0.2  or  (b.nDhsl<a.nsl*0.2 and d.sfdbh is not null and d.ndhsl>a.nsl*0.1 ));
		-- Step 2.6:对最后一次到货的包装数：包装数>=5,包装数大于当前库存的0.6倍，就是包装数过大
		  
		with x0 as(
		select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm,
		a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
		join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
		left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
		where  1=1   and len(a.syy)=0 and d.dShrq is not null and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
	     )
		update a set a.syy= case when a.spsfs<>'配送'   and  b.nDhsl=a.nCgbzs   then  '采购包装数过大'
		when  a.spsfs='配送' and b.nDhsl=a.nPsbzs then   '配送包装数过大' end
		  ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl
		  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
		 where  1=1  and b.ndhsl>=a.nsl*0.6 and b.nDhsl>=5   ;

	-- Step 2.7 :最后一次要货查是谁下的单 如果系统单，但是到货量大 那么就是人工原因，到货量小于系统单，系统原因，其他 手工原因
    --如果是在采购里面加单的话，那么就是手工加量或加单
		with x0 as(
		select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm,
		a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs  from #mddkc a 
		-- join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
		left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
		where  1=1   and len(a.syy)=0 and d.dShrq is not null  and d.nShsl>=a.nsl*0.2 )
		update a set a.syy= case when   b.sLx like '%自动%'  and (( b.nYhsl_raw is null ) 
			or (b.nYhsl_raw is not null and b.nYhsl<=b.nYhsl_raw ))    then '系统定额过大' 
		when   b.sLx not  like '%自动%'      then '人工下单' 
		when   b.sLx like '%自动%'  and b.nYhsl_raw is not null and b.nYhsl>b.nYhsl_raw  then '人工加量或加单'
		  else '其他' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl
		  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
		 ;

	-- Step 2.8:往前追溯一次
	  update #mddkc set sfwqzs='是' where len(syy)=0;
	---- Step 2.9 : 生成次到货数据  drop table  #jcmx1
	--    with x0 as (
	--	 select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
	--	 ,a.nsl   from #jcmx_raw a  
	--	 join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
	--	 where 1=1 )
	--	 select * into #jcmx1 from x0  where npm<=2;
	---- Step 2.10:对盘点调拨 划分：第二次盘点，调拨量大于当前库存数量的0.1就算
	--	update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl from #mddkc a  
	--	join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
	--	join dbo.Purchase_jcflbzb c on b.sJcfl=c.fl_content
	--	where  1=1 and c.fl_bzname in('盘点','调拨','损溢')  and b.nDhsl>a.nsl*0.1 and len(a.syy)=0;
	-- Step 2.11:对最后一次到货的包装数： 最后一次到货量等于包装数
			with x0 as(
		select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm,
		a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
		join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
		left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
		where  1=1   and len(a.syy)=0 and d.dShrq is not null and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
	     )
		update a set a.syy= case when a.spsfs<>'配送'   and  b.nDhsl=a.nCgbzs   then  '采购包装数过大'
		when  a.spsfs='配送' and b.nDhsl=a.nPsbzs then   '配送包装数过大' end
		  ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl
		  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
		 where  1=1  and   b.nDhsl>=a.nsl*0.6 and b.nDhsl>=5   ;
    -- Step 2.12:要货到货匹配再查一次
		with x0 as(
		select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw, 
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm 
		,a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs  from #mddkc a 
		-- join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
		left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
		where  1=1   and len(a.syy)=0 and d.dShrq is not null   )
		update a set a.syy= case when   b.sLx like '%自动%'  and (( b.nYhsl_raw is null ) 
			or (b.nYhsl_raw is not null and b.nYhsl<=b.nYhsl_raw ))    then '系统定额过大' 
		when   b.sLx not  like '%自动%'       then '人工下单' 
		when   b.sLx like '%自动%'  and b.nYhsl_raw is not null and b.nYhsl>b.nYhsl_raw  then '人工加量或加单'
		  else '其他' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1 ;
	-- Step 2.13:更新预期到货 drop table #dhyq
		select distinct a.sfdbh,a.sspbh into #dhyq from #tmp_dh_cal a
		join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		where  a.npm_cal=1 and b.npm_cal>=2 and 
		datediff(hour,a.dyhrq,b.dshrq)>0 and datediff(hour,b.dyhrq,a.dyhrq)>0
		and a.nYhsl_raw is not null  and a.dshrq is not null 
		order by a.sfdbh,a.sspbh;
		
		update a set a.syy='逾期到货' from #mddkc a
		join #dhyq b on   a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		where 1=1 ;
	-- Step 2.14:   更新剩余 
        update a set a.syy='其他'  from #mddkc a  where  1=1   and len(a.syy)=0 ;
	-- Step 2.15:更新线下定额出单
	 if  (select count(1)  from sysObjects  where name=UPPER('Purchase_DeliveryReceipt_Items'))=1
			 begin 
				  with x0 as(
				select sfdbh, sspbh, sDh,convert(date,left(sdh,8)) drq ,nZddhje,nZddhsl,spsfs,
				ROW_NUMBER()over(partition by sfdbh,sspbh order by convert(date,left(sdh,8)) desc) npm  from  dbo.Purchase_DeliveryReceipt_Items 
				where 1=1 and convert(date,left(sdh,8))>=dateadd(day,-180,convert(date,GETDATE())) and spsfs    like '%<线下>%' )
				select * into #ycdp_dkc from x0 where npm=1;

				 update a set a.syy='用户定额出单' from #mdlkcsp a   join #ycdp_dkc b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
				 where a.syy in ('系统定额过大') and b.sFdbh is not null; 
		   end;
  --  -- Step 2.16:更新促销
		 with x0 as(
		 select  distinct sFdbh,sSpbh from dbo.tmp_cxb where  dkssj<GETDATE() and  djssj>GETDATE())
		 update a set a.sfcx='是' from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  
		 where 1=1;

	-- Step 2.17 :对配送包装数变动  特指从大变小，造成系统订单过大进行修改
		update a set  a.syy= case when a.sPsfs='配送'  then '配送包装数过大' else '采购包装数过大' end from #mddkc a join #TMP_dh_cal b on CONVERT(date,a.dzhyhr)=CONVERT(date,b.dYhrq) and a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh
		and a.nDhsl=b.nCgbzs  and  case when a.sPsfs='配送'  then a.nPsbzs else  a.nCgbzs end <>a.nDhsl
		where a.syy='系统定额过大';



		-- Step 2.17:写入结果
		delete from  dbo.tmp_mdspzzyy where drq=convert(date,GETDATE());
        delete from  dbo.tmp_mdspzzyy where drq=convert(date,GETDATE()-100);
		insert into dbo.tmp_mdspzzyy(drq,sfdbh,sspbh,sspmc,sfl,sgys,njj,nsj,szdbh,spsfs,nrjxse,nrjxl,nkc,nzzts,npsbzs,ncgbzs,dzhdhr,dzhyhr,
		syy,sfwqzs,nbzzzts,sfcx,nDhsl)
		select CONVERT(date,GETDATE()) drq, a.sFdbh,a.sSpbh,sSpmc,sFl,sGys,nJj,nSj,sZdbh,sPsfs,nrjxse,nRjxl,nsl,case when convert(numeric(19,2),nzzts)>10000 then 1000 else convert(numeric(19,2),nzzts) end,nPsbzs,
		nCgbzs,dzhdhr,dzhyhr,syy,sfwqzs,60 nbzzzts,a.sfcx,nDhsl from #mddkc a
		 
		where 1=1  ;







----------------
-- 门店零库存和大库存数据源
--Step 1：试点门店和自动补货商品
select sFDBH,sFDMC,sFDLX,sPsZt into #Tmp_FDfw
from dbo.Tmp_FDB  where  binglang_state  =1 or  lengcang_state=1 or  hongbei_state=1;

-- drop table #tmp_zdbhspfw
select a.sFdbh,b.sFDMC,b.sFDLX,a.sSpbh,a.sPslx, a.sSfkj into #tmp_zdbhspfw 
from dbo.Sys_GoodsConfig a,#Tmp_FDfw b
where sSfkj='1' and  a.sFdbh=b.sFDBH;

-- Step 2：生成基础表 drop table #base_sp
-- drop table #mdspde
select a.sFdbh,sSpbh,nJyxx,nJysx,sPslx,srq,a.nRjxl_De into #mdspde from  Sys_GoodsConfig_his  a,
#Tmp_FDfw b
where  1=1 and a.sFdbh=b.sFDBH and CONVERT(date,djssj)=CONVERT(date,GETDATE()-1);

select a.sFdbh,a.sSpbh,c.sSpmc,c.sFl,c.sGys,c.nJj,c.nSj,1 sZdbh,d.sPsfs,e.nRjxl_De*c.nJj nrjxse,e.nJysx nZgsl,e.nJyxx nZdsl,e.nRjxl_De,b.nRjxl
,d.nCgbzs,ISNULL(d.nPsbzs,1) nPsbzs, a.sSfkj,case when left(c.sFl,2)='06' then '烘焙' when left(c.sFl,2)='15' then '冷藏' 
when left(c.sFl,2)='33' then '槟榔'  end  spllx,c.nBzt into #base_sp
from #tmp_zdbhspfw  a
inner join  dbo.R_Dpzb b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh
left join Tmp_spb_All  c on a.sSpbh=c.sSpbh
left join tmp_spb d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh
left join #mdspde e on a.sFdbh=e.sFdbh and a.sSpbh=e.sSpbh
where  1=1   and c.sFl not in (select sflbh from tmp_spflb_ex)
and a.sSpbh not in (select sSpbh from tmp_spb_ex); 

-- drop table #mdkc;
select a.sFdbh,a.sSpbh,CONVERT(date,GETDATE()-1) drq,case when isnull(a.nSl,0)<=0 then 0 else a.nSl end nsl into #mdkc
from dbo.Tmp_Kclsb a with(nolock),#Tmp_FDfw b  where a.dRq>=CONVERT(date,GETDATE()-1) and a.sFdbh=b.sFDBH;

-- Step 3:生成门店零库存商品表 drop table #mdlkcsp
select a.*,isnull(b.nsl,0) nsl,CONVERT(varchar(20),'') syy,convert(datetime,Null ) dzhyhrq into #mdlkcsp from #base_sp a 
left join #mdkc b on  a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where 1=1 and ISNULL(b.nsl,0)<=a.nRjxl_De*3;

-- Step 4:查门店最后一次要货或采购 单据时间往前查180天  drop table #Tmp_yh
    -- Step 4.1 :要货数据 ，如果D咨询还管出单的话就有必要存原单
	with x0 as (
	select a.dYhrq,a.dShrq,a.sLx,b.*,a.sBz
	from tmp_yh a  	inner join tmp_yhmx b on a.sdh=b.sdh and a.sFdbh=b.sFdbh
	join  #base_sp c on a.sFdbh=c.sFdbh and b.sspbh=c.sSpbh
	where  1=1 and a.dYhrq>=CONVERT(date,GETDATE()-180) and (  a.dYhrq+2<convert(date,GETDATE()) or a.dshrq is not null) )
	select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id into #Tmp_yh 
	from x0 a ;
	 
	-- drop table #Tmp_cg
	with x0 as(
	select a.dYhrq,a.dShrq,a.sLx,b.*,a.sBz
	from tmp_cgdd a inner join tmp_cgddmx b on a.sdh=b.sdh and a.sFdbh=b.sFdbh
	join  #base_sp c on a.sFdbh=c.sFdbh and b.sspbh=c.sSpbh
	where  1=1  and a.dYhrq>=CONVERT(date,GETDATE()-180) and (a.dYhrq+5<GETDATE() or  a.dshrq is not null)
	)
	select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYHsl desc) id into #Tmp_cg
	from x0 a;
	-- Step 4.2 ：D咨询原单 drop table #Dzixun_raw
	create table #Dzixun_raw(dYhrq datetime,sbh varchar(50),sFdbh varchar(50),sSpbh varchar(30),nCgsl money,nCgbzs money,GenState varchar(100),sMemo varchar(100));
	-- drop table #zdd_raw 
	select a.sDh,CONVERT(date,a.dDhrq) dYhrq,a.sFdbh,b.sSpbh,b.nsl into #zdd_raw from Purchase_DeliveryReceipt a
	,dbo.Purchase_DeliveryReceipt_Items b where a.sDh=b.sDh and a.sFdbh=b.sFdbh
	and CONVERT(date,a.dDhrq)>=CONVERT(date,GETDATE()-180) and CONVERT(date,a.dDhrq)>=CONVERT(date,'2022-05-07') ;

	 insert into #Dzixun_raw(dYhrq,sbh,sFdbh,sSpbh,nCgsl,nCgbzs,GenState,sMemo)
	 select a.dYhrq,sdh,a.sFdbh,a.sSpbh,a.nsl nCgsl,case when c.sPsfs='统配' then  c.nPsbzs else c.nCgbzs end,
	 '' GenState,'自动订单'sMemo   
	 from  #zdd_raw a
		join #base_sp c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
		join dbo.Tmp_Gys b on c.sGys=b.sGysbh and b.sFDBH='0000'
		where  a.dYhrq>=CONVERT(date,GETDATE()-180) 
		and (( c.spsfs='统配' and DATEADD(day,isnull(b.nDay,2),a.dYhrq) <convert(date,GETDATE()) )  or 
		( c.spsfs<>'统配' and DATEADD(day,isnull(b.nDay,5), a.dYhrq)<convert(date,GETDATE()))) and nsl>0;
 	
		--Step 4.3 :生成最后的单据，这里需要调研D咨询单转ERP实际单的有效期 drop table #TMP_dh_cal
		with x0 as (
		select sFdbh,sspbh,sdh,dYhrq,dShrq,sLx,nYhsl,nShsl,sBz,id,'门店向DC要货' flag,stype  from #Tmp_yh  where 1=1
		 union
		select sFdbh,sspbh,sdh,dYhrq,dShrq,sLx,nYhsl,nShsl,sBz,id,'门店采购单',''  from #Tmp_cg where 1=1)
		select ISNULL(a.sFdbh,b.sFdbh) sfdbh,ISNULL(a.sspbh,b.sSpbh) sspbh,ISNULL(a.dYhrq,b.dYhrq) dYhrq,a.dShrq, a.nYhsl,b.nCgsl nYhsl_raw,
		a.nShsl,b.GenState,b.sMemo,a.sLx,sBz,a.flag,ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
		ISNULL(a.sspbh,b.sSpbh) order by isnull(a.dyhrq,b.dyhrq) desc) npm_cal,b.nCgbzs,case when a.sFdbh is null then '系统单' end is_auto 
		,stype into #TMP_dh_cal from x0 a 
		full join #Dzixun_raw b on a.sFdbh=b.sFdbh and a.sspbh=b.sSpbh and DATEDIFF(HOUR,b.dYhrq,a.dYhrq)>0 
		and DATEDIFF(HOUR,b.dYhrq,a.dYhrq)<24
		where 1=1 ;
		 
		-- Step 5：最后的进出和销售日期,同一天出的越多原因靠前   drop table #jcmx0
		with x0 as (
		select  convert(date,a.dSj) dsj,a.sFdbh,b.sSpbh,a.sJcfl,sum(b.nSl) nsl
		  from dbo.Tmp_Jcb a ,dbo.Tmp_Jcmxb b,#Tmp_FDfw c where a.sJcbh=b.sJcbh
		and a.sFdbh=b.sFdbh and a.dSj>CONVERT(date,GETDATE()-30) and a.sFdbh=c.sFDBH
		 group by   convert(date,a.dSj),a.sFdbh,b.sSpbh,a.sJcfl)
		select  a.*, ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by convert(date,a.dsj) desc,a.nsl )  npm into #jcmx0
		from x0 a where a.nsl<0;

		-- drop table #xsrq
		with x0 as(
		select a.*,b.sSpbh,b.nXssl,b.nXsje,b.nMl from Tmp_Xsb  a, dbo.Tmp_xsnrb  b where a.sXsdh=b.sXsdh and a.sfdbh=b.sFdbh
		and a.dSj>=CONVERT(varchar,GETDATE()-14,112) ) 
		select a.sFdbh,a.sSpbh,CONVERT(date,left(b.sxsdh,8),23) max_xs,sum(b.nXssl) nXssl,
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by CONVERT(date,left(b.sxsdh,8),23) desc) npm 
		into #xsrq from #mdlkcsp a,x0 b where a.sFdbh=b.sFdbh 
		and a.sSpbh=b.sSpbh 
		group by a.sFdbh,a.sSpbh,CONVERT(date,left(b.sxsdh,8),23);

	-- Step 6:分原因
		-- 对特殊设置进行区分,所有原因归为 暂不出单
		if (select count(1)  from sysObjects  where name=UPPER('Purchase_DeliveryReceipt_ExGys'))=1
			begin 
				update a set a.syy='暂不出单' from #mdlkcsp a
				join dbo.Purchase_DeliveryReceipt_ExGys b on a.sFdbh=b.sFdbh and a.sGys=b.sGysbh;
		    end   
		update a set a.syy='暂不出单' from #mdlkcsp a
		 where   a.sfdbh in (select sParamsVal from Purchase_Params  where sParamsName='DeliveryBchFd'); 
		 
		 --新上线批次的自动补货属性更新为0
		 update a set a.syy='新上线自动补货' from #mdlkcsp a 
		 join dbo.Tmp_fdb_sx b on a.sFdbh=b.sfdbh and a.spllx=b.slx
		 where 1=1  and len(a.syy)=0 and DATEADD(DAY,2,convert(date,b.dsxdate))>=CONVERT(date,GETDATE()) ;

		--Step 6.1  如果最后一次的进出记录 在最后一次销售之后，同时类型是扣减库存的，则是进出，这里需要注意的是时间的选择
		update a set a.syy=b.sJcfl from #mdlkcsp a 
		join #jcmx0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
		left join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
		where  len(a.syy)=0 and  (b.dSj>c.max_xs or c.sFdbh is null)  and abs(b.nSl)>=2 
		and abs(b.nSl)>=round(a.nzgsl*0.7,0) and (( a.sPsfs='统配' and b.dSj>CONVERT(date,GETDATE()-5)) 
		or (a.sPsfs<>'统配' and b.dSj>CONVERT(date,GETDATE()-14)))  and b.dsj<CONVERT(date,GETDATE()) ;

	
		-- Step 6.1:突发销售
		update a set a.syy='突发销售' from #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
		join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
		where len(a.syy)=0  and  (( a.sPsfs='统配' and c.max_xs>CONVERT(date,GETDATE()-5)) 
		or (a.sPsfs<>'统配' and c.max_xs>CONVERT(date,GETDATE()-14))) and c.nXssl>=2      
             and   c.nXssl>=round(a.nzgsl*0.7,0) and c.nXssl>a.nRjxl*3
			and (c.max_xs>b.dShrq or b.dShrq is null) ;

	

		  update a set  a.syy='人工未下单'  from  #mdlkcsp a 
		 left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  and b.dYhrq>convert(date,GETDATE()-7)
		 where 1=1  and   len(a.syy)=0  and  a.sZdbh='0'    and b.sfdbh is null;
	  
		-- Step 6.2 直送商品，供应商未送，采购单，供应商到货量为空
	   update a set a.dzhyhrq=b.dYhrq,a.syy=spsfs+'供应商未送货'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
	    where 1=1    and  len(a.syy)=0  and a.sPsfs<>'统配' and isnull(b.nShsl,0)=0 ;

  
	  -- Step 6.4 供应商送货不足，采购量到货量低于90%
	  update a set a.dzhyhrq=b.dYhrq,a.syy=spsfs+'供应商送货不足'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
	  where 1=1  and  len(a.syy)=0  and a.sPsfs<>'统配' and b.nYhsl>0  and  b.nShsl*1.0/b.nYhsl<0.9 ;
	  
	  -- Step 6.5 人工订货不足，szdbh=0
	  update a set a.syy='人工未下单'  from  #mdlkcsp a 
		left  join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
	  where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)=0 ;
   
	  update a set a.dzhyhrq=b.dYhrq,a.syy='人工订货不足'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
	  where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)>0  and b.nShsl*1.0/b.nYhsl>=0.9 ;


	  -- Step 6.6 DC未送货 或 送货不足
	  update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心未送货'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
	  where 1=1  and   len(a.syy)=0  and b.sfdbh is not null  and   isnull(b.nShsl,0)=0 and a.sPsfs='统配'
	  and b.nYhsl>0;
  
	   update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心送货不足'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
	  where 1=1  and   len(a.syy)=0  and b.nShsl>0 and  b.nShsl*1.0/b.nYhsl<0.9 and a.sPsfs='统配' ;

	   
	  -- Step 6.7 :系统未下单，或定额不足
	  -- 系统未下单 需要考虑节奏日，如果即使到节奏日出了单，那也是定额不足，后面用异常出单修正原来的原因
		update a set  a.syy='系统定额不足'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
		where 1=1  and   len(a.syy)=0  and  a.sZdbh=1    and b.sfdbh is null;
  
		-- Step 6.8:系统定额不足,但如果是手工改小的采购单 
		update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
		where 1=1  and   len(a.syy)=0   and b.nShsl>0   and  b.nShsl*1.0/b.nYhsl>=0.9
		and  a.sZdbh=1   and isnull(b.nYhsl_raw,0)>0 and b.nYhsl>=b.nYhsl_raw ;
	   -- select * from #TMP_dh_cal where nYhsl>0
		--Step 6.9: 人工改小或删单
		update a set a.dzhyhrq=b.dYhrq,a.syy='人工减量或删单'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
	    and ((b.nShsl>0  and b.nYhsl_raw>b.nYhsl 
			and isnull(b.nYhsl,0)>0) or (b.nYhsl_raw>0 and b.nYhsl is null ))
		where 1=1  and   len(a.syy)=0   and  a.sZdbh=1 and b.sfdbh is not null ;



		--Step 6.10: 系统定额不足，人工未减量，供应商到货
		update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
		where 1=1  and   len(a.syy)=0   and b.nShsl>0 and  b.nShsl*1.0/b.nYhsl>=0.9
		and  a.sZdbh=1  and b.nYhsl_raw=b.nYhsl  ;

		 -- 起订量等限制
		-- Step 6.11:未出单的单据更新：如果系统出单在最后日期之后，且未达起订量 drop table #ycdp 
		with x0 as(
		select sfdbh, sspbh, sbh, dYhrq   ,GenState,
		ROW_NUMBER()over(partition by sspbh order by dYhrq desc) npm  from   #Dzixun_raw 
		where 1=1  and  GenState not in ('补货数量为0','已出单' ,'已存在紧急订单' ))
		select * into #ycdp from x0 where npm=1;
		 
		 update a set a.syy= b.GenState  from #mdlkcsp a   join #ycdp b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
		where a.syy in ('人工未下单','系统定额不足') and b.sFdbh is not null; 
	 
		 update a set a.syy='系统定额不足' from #mdlkcsp a    where len(a.syy)=0 and a.sZdbh='1'; 
		 if  (select count(1)  from sysObjects  where name=UPPER('Purchase_DeliveryReceipt_Items'))=1
			 begin 
				  with x0 as(
				select sfdbh, sspbh, sDh,convert(date,left(sdh,8)) drq ,nZddhje,nZddhsl,spsfs,
				ROW_NUMBER()over(partition by sfdbh,sspbh order by convert(date,left(sdh,8)) desc) npm  from  dbo.Purchase_DeliveryReceipt_Items 
				where 1=1 and convert(date,left(sdh,8))>=dateadd(day,-180,convert(date,GETDATE())) and spsfs    like '%<线下>%' )
				select * into #ycdp1 from x0 where npm=1;

				 update a set a.syy='用户定额出单' from #mdlkcsp a   join #ycdp b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
				 where a.syy in ('系统定额不足') and b.sFdbh is not null; 
		   end
	
		 update a set a.syy='其他' from #mdlkcsp a    where len(a.syy)=0 ; 
		 delete from dbo.TMP_MDLKCYY where drq=convert(date,GETDATE());
         delete from dbo.TMP_MDLKCYY where drq<=convert(date,GETDATE()-100);
		 insert into dbo.TMP_MDLKCYY(drq,sfdbh,sspbh,sspmc,sfl,nZdsl,nZgsl,szdbh,ssfkj,spsfs,syy,dzhyhrq,nrjxl,nrjxse,nsl)
		 select convert(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sSpmc,a.sFl,a.nZgsl ,a.nZdsl ,a.sZdbh,a.sSfkj,a.sPsfs,a.syy,
		 a.dzhyhrq,a.nRjxl_De,a.nRjxse ,nsl  from  #mdlkcsp a  ;

		

	 
-- 第二部分 门店大库存
    -- Step 2.1 ：大库存数据生成 drop table #mddkc
	/*  门店大库存 */
		with x0 as (
		select a.*,b.nSl, convert(numeric(15,4),case when  a.nRjxl_De=0 then 300 
			else b.nsl*1.0/(a.nRjxl_De) end) nzzts ,case  when   a.spllx='槟榔' then  30 else  ceiling(a.nBzt*0.8) end  nbzzzts
			from #base_sp a 
		left join #mdkc b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
		where 1=1 and ISNULL(b.nsl,0)>2  and  case when  a.nRjxl_De=0 then 300 else  b.nsl*1.0/(a.nRjxl_De) end>
		case  when   a.spllx='槟榔' then  30 else  ceiling(a.nBzt*0.8) end  )
		select a.sFdbh,a.sSpbh,a.sspmc ,a.sFl,b.sdw,b.sGys,a.nJj,a.nSj,b.sZdbh,b.sPsfs,a.nRjxl_De nRjxl,a.nrjxse,a.nsl
		, a.nzzts,a.nPsbzs,a.nCgbzs,convert(date,Null) dzhyhr,convert(date,Null) dzhdhr, 
		convert(varchar(20),'') syy,convert(varchar(5),'') sfwqzs,convert(varchar(20),'') sfcx,
		convert(money,Null) nYhsl,convert(money,Null) nDhsl,a.nbzzzts into #mddkc  from x0  a 
		join dbo.tmp_spb b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh where 1=1 ; 

		--Step 2.2:最后一天进货 drop table #jcmx_raw
		select  CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #jcmx_raw
		  from dbo.Tmp_Jcb a ,dbo.Tmp_Jcmxb b   where a.sJcbh=b.sJcbh
		and a.sFdbh=b.sFdbh and a.dSj>convert(date,GETDATE()-180) 
		group by CONVERT(date,a.dsj)  ,a.sfdbh,a.sjcfl,b.sspbh ;

		-- drop table #jcmx
		with x0 as (
		 select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
		 ,a.nsl   from #jcmx_raw a  
		 join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		 where 1=1 and  a.nsl>2 )
		 select * into #jcmx from x0  where npm<=2;
 
    --  原因划分
    -- Step 2.3:遗留库存
	    with x0 as (
		 select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
		 ,a.nsl   from #jcmx_raw a  
		 join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		 where 1=1  and a.nsl>0  )
		update a set a.syy='遗留库存'   from #mddkc  a 
		left join x0 b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
		where 1=1  and b.sFdbh is null;

	 
    --Step 2.4: 特陈设置的,
		update a set a.syy='特陈过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl  from #mddkc a  
		 join #jcmx b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
		join dbo.Tmp_Tc c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
		and c.dKssj<b.dsj and c.dJssj>b.dsj and  c.nTcsl>6 and   c.nTcsl>=a.nsl*0.5 
		where 1=1 and len(a.syy)=0;
	
	-- Step 2.5:对盘点调拨 划分：盘点，调拨量大于当前库存数量的一半
	update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl,
	a.sfwqzs=case when b.nDhsl<a.nsl*0.2 and d.sfdbh is not null and d.nDhsl>a.nsl*0.1  then '是' end   from #mddkc a  
		join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
            and (b.sJcfl='报货单' or ( b.sjcfl in (select fl_content from dbo.Purchase_jcflbzb where  fl_bzname in('盘点','调拨','损溢') )))
        left join #jcmx d on a.sfdbh=d.sFdbh and a.sSpbh=d.sSpbh and d.npm=2 
        and (d.sJcfl='报货单' or ( d.sjcfl in (select fl_content from dbo.Purchase_jcflbzb where  fl_bzname in('盘点','调拨','损溢'))))
	where  1=1  and len(a.syy)=0  and  (b.nDhsl>=a.nsl*0.2  or  (b.nDhsl<a.nsl*0.2 and d.sfdbh is not null and d.ndhsl>a.nsl*0.1 ));
		-- Step 2.6:对最后一次到货的包装数：包装数>=4,包装数大于当前库存的0.6倍，就是包装数过大
	with x0 as(
	select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
	ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm,
	a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
	join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
	left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
	where  1=1   and len(a.syy)=0 and d.dShrq is not null and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
	    )
	update a set a.syy= case when a.spsfs<>'配送'   and  b.nDhsl=a.nCgbzs   then  '采购包装数过大'
	when  a.spsfs='配送' and b.nDhsl=a.nPsbzs then   '配送包装数过大' end
		,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl
		from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
		where  1=1  and b.ndhsl>=a.nsl*0.6 and b.nDhsl>=4   ;

	-- Step 2.7 :最后一次要货查是谁下的单 如果系统单，但是到货量大 那么就是人工原因，到货量小于系统单，系统原因，其他 手工原因
    --如果是在采购里面加单的话，那么就是手工加量或加单
	with x0 as(
	select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
	ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm,
	a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs,d.stype  from #mddkc a 
	-- join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
	-- left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
	where  1=1   and len(a.syy)=0 and d.dShrq is not null  and d.nShsl>=a.nsl*0.2 )
	update a set a.syy= case when b.nYhsl_raw is not null and b.nYhsl<=b.nYhsl_raw     then '系统定额过大' 
	when   b.stype not  like '%天牧%'  and  b.nYhsl_raw  is null      then '人工下单' 
	when   b.nYhsl_raw is not null and b.nYhsl>b.nYhsl_raw  then '人工加量或加单'
		else '其他' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl
		from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1;


	-- Step 2.8:往前追溯一次
	  update #mddkc set sfwqzs='是' where len(syy)=0;
	---- Step 2.9 : 生成次到货数据  drop table  #jcmx1
	    with x0 as (
		 select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
		 ,a.nsl   from #jcmx_raw a  
		 join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		 where 1=1 )
		 select * into #jcmx1 from x0  where npm<=2;
	-- Step 2.10:对盘点调拨 划分：第二次盘点，调拨量大于当前库存数量的0.1就算
		update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl from #mddkc a  
		join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
		join dbo.Purchase_jcflbzb c on b.sJcfl=c.fl_content
		where  1=1 and (c.fl_bzname in('盘点','调拨','损溢','其他进出') or b.sJcfl='报货单')  and b.nDhsl>a.nsl*0.1 and len(a.syy)=0;
	-- Step 2.11:对最后一次到货的包装数： 最后一次到货量等于包装数
		with x0 as(
		select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm,
		a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
		join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
		--left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
		where  1=1   and len(a.syy)=0 and d.dShrq is not null and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
	     )
		update a set a.syy= case when a.spsfs<>'配送'   and  b.nDhsl=a.nCgbzs   then  '采购包装数过大'
		when  a.spsfs='配送' and b.nDhsl=a.nPsbzs then   '配送包装数过大' end
		  ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl
		  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
		 where  1=1  and   b.nDhsl>=a.nsl*0.6 and b.nDhsl>=4   ;
    -- Step 2.12:要货到货匹配再查一次
		with x0 as(
		select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw, 
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm 
		,a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs,d.stype  from #mddkc a 
		-- join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
		left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
		where  1=1   and len(a.syy)=0 and d.dShrq is not null   )
		update a set a.syy= case when   b.nYhsl_raw is not null and b.nYhsl<=b.nYhsl_raw      then '系统定额过大' 
		when   b.stype  not  like '%天牧%' and b.nYhsl_raw is null        then '人工下单' 
		when   b.stype like '%天牧%'  and b.nYhsl_raw is not null and b.nYhsl>b.nYhsl_raw  then '人工加量或加单'
		  else '其他' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
		  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1 ;
	-- Step 2.13:更新预期到货 drop table #dhyq
		select distinct a.sfdbh,a.sspbh into #dhyq from #tmp_dh_cal a
		join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		where  a.npm_cal=1 and b.npm_cal>=2 and 
		datediff(hour,a.dyhrq,b.dshrq)>0 and datediff(hour,b.dyhrq,a.dyhrq)>0
		and a.nYhsl_raw is not null  and a.dshrq is not null 
		order by a.sfdbh,a.sspbh;
		
		update a set a.syy='逾期到货' from #mddkc a
		join #dhyq b on   a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		where 1=1 ;
	-- Step 2.14:   更新剩余 
        update a set a.syy='其他'  from #mddkc a  where  1=1   and len(a.syy)=0 ;
	-- Step 2.15:更新线下定额出单
	 if  (select count(1)  from sysObjects  where name=UPPER('Purchase_DeliveryReceipt_Items'))=1
			 begin 
				  with x0 as(
				select sfdbh, sspbh, sDh,convert(date,left(sdh,8)) drq ,nZddhje,nZddhsl,spsfs,
				ROW_NUMBER()over(partition by sfdbh,sspbh order by convert(date,left(sdh,8)) desc) npm  from  dbo.Purchase_DeliveryReceipt_Items 
				where 1=1 and convert(date,left(sdh,8))>=dateadd(day,-180,convert(date,GETDATE())) and spsfs    like '%<线下>%' )
				select * into #ycdp_dkc from x0 where npm=1;

				 update a set a.syy='用户定额出单' from #mdlkcsp a   join #ycdp_dkc b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
				 where a.syy in ('系统定额过大') and b.sFdbh is not null; 
		   end;
  --  -- Step 2.16:更新促销
		 with x0 as(
		 select  distinct sFdbh,sSpbh from dbo.tmp_cxb where  dkssj<GETDATE() and  djssj>GETDATE())
		 update a set a.sfcx='是' from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  
		 where 1=1;

	-- Step 2.17 :对配送包装数变动  特指从大变小，造成系统订单过大进行修改
		update a set  a.syy= case when a.sPsfs='统配'  then '配送包装数过大' else '采购包装数过大' end 
		from #mddkc a join #TMP_dh_cal b on CONVERT(date,a.dzhyhr)=CONVERT(date,b.dYhrq) and a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh
		and a.nDhsl=b.nCgbzs  and  case when a.sPsfs='统配'  then a.nPsbzs else  a.nCgbzs end <>a.nDhsl
		where a.syy='系统定额过大';



		-- Step 2.17:写入结果
		delete from  dbo.tmp_mdspzzyy where drq=convert(date,GETDATE());
        delete from  dbo.tmp_mdspzzyy where drq=convert(date,GETDATE()-100);
		insert into dbo.tmp_mdspzzyy(drq,sfdbh,sspbh,sspmc,sfl,sgys,njj,nsj,szdbh,spsfs,nrjxse,nrjxl,nkc,nzzts,npsbzs,ncgbzs,dzhdhr,dzhyhr,
		syy,sfwqzs,nbzzzts,sfcx,nDhsl)
		select CONVERT(date,GETDATE()) drq, a.sFdbh,a.sSpbh,sSpmc,sFl,sGys,nJj,nSj,sZdbh,sPsfs,nrjxse,nRjxl,nsl,case when convert(numeric(19,2),nzzts)>10000 then 1000 else convert(numeric(19,2),nzzts) end,nPsbzs,
		nCgbzs,dzhdhr,dzhyhr,syy,sfwqzs,a.nbzzzts,a.sfcx,nDhsl from #mddkc a
		where 1=1  ;










		--------任务版
		select sFDBH,sFDMC,sFDLX,sPsZt into #Tmp_FDfw
from dbo.Tmp_FDB  where  binglang_state  =1 or  lengcang_state=1 or  hongbei_state=1;

-- drop table #tmp_zdbhspfw
select a.sFdbh,b.sFDMC,b.sFDLX,a.sSpbh,a.sPslx, a.sSfkj into #tmp_zdbhspfw 
from dbo.Sys_GoodsConfig a,#Tmp_FDfw b
where sSfkj='1' and  a.sFdbh=b.sFDBH;

-- Step 2：生成基础表 drop table #base_sp
-- drop table #mdspde
select a.sFdbh,sSpbh,nJyxx,nJysx,sPslx,srq,a.nRjxl_De into #mdspde from  Sys_GoodsConfig_his  a,
#Tmp_FDfw b
where  1=1 and a.sFdbh=b.sFDBH and CONVERT(date,djssj)=CONVERT(date,GETDATE()-1);

select a.sFdbh,a.sSpbh,c.sSpmc,c.sFl,c.sGys,c.nJj,c.nSj,1 sZdbh,d.sPsfs,e.nRjxl_De*c.nJj nrjxse,e.nJysx nZgsl,e.nJyxx nZdsl,e.nRjxl_De,b.nRjxl
,d.nCgbzs,ISNULL(d.nPsbzs,1) nPsbzs, a.sSfkj,case when left(c.sFl,2)='06' then '烘焙' when left(c.sFl,2)='15' then '冷藏' 
when left(c.sFl,2)='33' then '槟榔'  end  spllx,c.nBzt into #base_sp
from #tmp_zdbhspfw  a
inner join  dbo.R_Dpzb b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh
left join Tmp_spb_All  c on a.sSpbh=c.sSpbh
left join tmp_spb d on a.sFdbh=d.sFdbh and a.sSpbh=d.sSpbh
left join #mdspde e on a.sFdbh=e.sFdbh and a.sSpbh=e.sSpbh
where  1=1   and c.sFl not in (select sflbh from tmp_spflb_ex)
and a.sSpbh not in (select sSpbh from tmp_spb_ex); 

-- drop table #mdkc;
select a.sFdbh,a.sSpbh,CONVERT(date,GETDATE()-1) drq,case when isnull(a.nSl,0)<=0 then 0 else a.nSl end nsl into #mdkc
from dbo.Tmp_Kclsb a with(nolock),#Tmp_FDfw b  where a.dRq>=CONVERT(date,GETDATE()-1) and a.sFdbh=b.sFDBH;

-- Step 3:生成门店零库存商品表 drop table #mdlkcsp
select a.*,isnull(b.nsl,0) nsl,CONVERT(varchar(20),'') syy,convert(datetime,Null ) dzhyhrq into #mdlkcsp from #base_sp a 
left join #mdkc b on  a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
where 1=1 and ISNULL(b.nsl,0)<=a.nRjxl_De*3;

-- Step 4:查门店最后一次要货或采购 单据时间往前查180天  drop table #Tmp_yh
    -- Step 4.1 :要货数据 ，如果D咨询还管出单的话就有必要存原单
	with x0 as (
	select a.dYhrq,a.dShrq,a.sLx,b.*,a.sBz
	from tmp_yh a  	inner join tmp_yhmx b on a.sdh=b.sdh and a.sFdbh=b.sFdbh
	join  #base_sp c on a.sFdbh=c.sFdbh and b.sspbh=c.sSpbh
	where  1=1 and a.dYhrq>=CONVERT(date,GETDATE()-180) and (  a.dYhrq+2<convert(date,GETDATE()) or a.dshrq is not null) )
	select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYhsl desc) id into #Tmp_yh 
	from x0 a ;
	 
	-- drop table #Tmp_cg
	with x0 as(
	select a.dYhrq,a.dShrq,a.sLx,b.*,a.sBz
	from tmp_cgdd a inner join tmp_cgddmx b on a.sdh=b.sdh and a.sFdbh=b.sFdbh
	join  #base_sp c on a.sFdbh=c.sFdbh and b.sspbh=c.sSpbh
	where  1=1  and a.dYhrq>=CONVERT(date,GETDATE()-180) and (a.dYhrq+5<GETDATE() or  a.dshrq is not null)
	)
	select a.*,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by dYhrq desc,nYHsl desc) id into #Tmp_cg
	from x0 a;
	-- Step 4.2 ：D咨询原单 drop table #Dzixun_raw
	create table #Dzixun_raw(dYhrq datetime,sbh varchar(50),sFdbh varchar(50),sSpbh varchar(30),nCgsl money,nCgbzs money,GenState varchar(100),sMemo varchar(100));
	-- drop table #zdd_raw 
	select a.sDh,CONVERT(date,a.dDhrq) dYhrq,a.sFdbh,b.sSpbh,b.nsl into #zdd_raw from Purchase_DeliveryReceipt a
	,dbo.Purchase_DeliveryReceipt_Items b where a.sDh=b.sDh and a.sFdbh=b.sFdbh
	and CONVERT(date,a.dDhrq)>=CONVERT(date,GETDATE()-180) and CONVERT(date,a.dDhrq)>=CONVERT(date,'2022-05-07') ;

	 insert into #Dzixun_raw(dYhrq,sbh,sFdbh,sSpbh,nCgsl,nCgbzs,GenState,sMemo)
	 select a.dYhrq,sdh,a.sFdbh,a.sSpbh,a.nsl nCgsl,case when c.sPsfs='统配' then  c.nPsbzs else c.nCgbzs end,
	 '' GenState,'自动订单'sMemo   
	 from  #zdd_raw a
		join #base_sp c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
		join dbo.Tmp_Gys b on c.sGys=b.sGysbh and b.sFDBH='0000'
		where  a.dYhrq>=CONVERT(date,GETDATE()-180) 
		and (( c.spsfs='统配' and DATEADD(day,isnull(b.nDay,2),a.dYhrq) <convert(date,GETDATE()) )  or 
		( c.spsfs<>'统配' and DATEADD(day,isnull(b.nDay,5), a.dYhrq)<convert(date,GETDATE()))) and nsl>0;
 	
		--Step 4.3 :生成最后的单据，这里需要调研D咨询单转ERP实际单的有效期 drop table #TMP_dh_cal
		with x0 as (
		select sFdbh,sspbh,sdh,dYhrq,dShrq,sLx,nYhsl,nShsl,sBz,id,'门店向DC要货' flag,stype  from #Tmp_yh  where 1=1
		 union
		select sFdbh,sspbh,sdh,dYhrq,dShrq,sLx,nYhsl,nShsl,sBz,id,'门店采购单',''  from #Tmp_cg where 1=1)
		select ISNULL(a.sFdbh,b.sFdbh) sfdbh,ISNULL(a.sspbh,b.sSpbh) sspbh,ISNULL(a.dYhrq,b.dYhrq) dYhrq,a.dShrq, a.nYhsl,b.nCgsl nYhsl_raw,
		a.nShsl,b.GenState,b.sMemo,a.sLx,sBz,a.flag,ROW_NUMBER()over(partition by ISNULL(a.sFdbh,b.sFdbh),
		ISNULL(a.sspbh,b.sSpbh) order by isnull(a.dyhrq,b.dyhrq) desc) npm_cal,b.nCgbzs,case when a.sFdbh is null then '系统单' end is_auto 
		,stype into #TMP_dh_cal from x0 a 
		full join #Dzixun_raw b on a.sFdbh=b.sFdbh and a.sspbh=b.sSpbh and DATEDIFF(HOUR,b.dYhrq,a.dYhrq)>0 
		and DATEDIFF(HOUR,b.dYhrq,a.dYhrq)<24
		where 1=1 ;
		 
		-- Step 5：最后的进出和销售日期,同一天出的越多原因靠前   drop table #jcmx0
		with x0 as (
		select  convert(date,a.dSj) dsj,a.sFdbh,b.sSpbh,a.sJcfl,sum(b.nSl) nsl
		  from dbo.Tmp_Jcb a ,dbo.Tmp_Jcmxb b,#Tmp_FDfw c where a.sJcbh=b.sJcbh
		and a.sFdbh=b.sFdbh and a.dSj>CONVERT(date,GETDATE()-30) and a.sFdbh=c.sFDBH
		 group by   convert(date,a.dSj),a.sFdbh,b.sSpbh,a.sJcfl)
		select  a.*, ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by convert(date,a.dsj) desc,a.nsl )  npm into #jcmx0
		from x0 a where a.nsl<0;

		-- drop table #xsrq
		with x0 as(
		select a.*,b.sSpbh,b.nXssl,b.nXsje,b.nMl from Tmp_Xsb  a, dbo.Tmp_xsnrb  b where a.sXsdh=b.sXsdh and a.sfdbh=b.sFdbh
		and a.dSj>=CONVERT(varchar,GETDATE()-14,112) ) 
		select a.sFdbh,a.sSpbh,CONVERT(date,left(b.sxsdh,8),23) max_xs,sum(b.nXssl) nXssl,
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by CONVERT(date,left(b.sxsdh,8),23) desc) npm 
		into #xsrq from #mdlkcsp a,x0 b where a.sFdbh=b.sFdbh 
		and a.sSpbh=b.sSpbh 
		group by a.sFdbh,a.sSpbh,CONVERT(date,left(b.sxsdh,8),23);

	-- Step 6:分原因
		-- 对特殊设置进行区分,所有原因归为 暂不出单
		if (select count(1)  from sysObjects  where name=UPPER('Purchase_DeliveryReceipt_ExGys'))=1
			begin 
				update a set a.syy='暂不出单' from #mdlkcsp a
				join dbo.Purchase_DeliveryReceipt_ExGys b on a.sFdbh=b.sFdbh and a.sGys=b.sGysbh;
		    end   
		update a set a.syy='暂不出单' from #mdlkcsp a
		 where   a.sfdbh in (select sParamsVal from Purchase_Params  where sParamsName='DeliveryBchFd'); 
		 
		 --新上线批次的自动补货属性更新为0
		 update a set a.syy='新上线自动补货' from #mdlkcsp a 
		 join dbo.Tmp_fdb_sx b on a.sFdbh=b.sfdbh and a.spllx=b.slx
		 where 1=1  and len(a.syy)=0 and DATEADD(DAY,2,convert(date,b.dsxdate))>=CONVERT(date,GETDATE()) ;

		--Step 6.1  如果最后一次的进出记录 在最后一次销售之后，同时类型是扣减库存的，则是进出，这里需要注意的是时间的选择
		update a set a.syy=b.sJcfl from #mdlkcsp a 
		join #jcmx0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
		left join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
		where  len(a.syy)=0 and  (b.dSj>c.max_xs or c.sFdbh is null)  and abs(b.nSl)>=2 
		and abs(b.nSl)>=round(a.nzgsl*0.7,0) and (( a.sPsfs='统配' and b.dSj>CONVERT(date,GETDATE()-5)) 
		or (a.sPsfs<>'统配' and b.dSj>CONVERT(date,GETDATE()-14)))  and b.dsj<CONVERT(date,GETDATE()) ;

	
		-- Step 6.1:突发销售
		update a set a.syy='突发销售' from #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
		join #xsrq c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh and c.npm=1
		where len(a.syy)=0  and  (( a.sPsfs='统配' and c.max_xs>CONVERT(date,GETDATE()-5)) 
		or (a.sPsfs<>'统配' and c.max_xs>CONVERT(date,GETDATE()-14))) and c.nXssl>=2      
             and   c.nXssl>=round(a.nzgsl*0.7,0) and c.nXssl>a.nRjxl*3
			and (c.max_xs>b.dShrq or b.dShrq is null) ;

		  update a set  a.syy='人工未下单'  from  #mdlkcsp a 
		 left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  and b.dYhrq>convert(date,GETDATE()-7)
		 where 1=1  and   len(a.syy)=0  and  a.sZdbh='0'    and b.sfdbh is null;
	  
		-- Step 6.2 直送商品，供应商未送，采购单，供应商到货量为空
	   update a set a.dzhyhrq=b.dYhrq,a.syy=spsfs+'供应商未送货'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
	    where 1=1    and  len(a.syy)=0  and a.sPsfs<>'统配' and isnull(b.nShsl,0)=0 ;

  
	  -- Step 6.4 供应商送货不足，采购量到货量低于90%
	  update a set a.dzhyhrq=b.dYhrq,a.syy=spsfs+'供应商送货不足'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
	  where 1=1  and  len(a.syy)=0  and a.sPsfs<>'统配' and b.nYhsl>0  and  b.nShsl*1.0/b.nYhsl<0.9 ;
	  
	  -- Step 6.5 人工订货不足，szdbh=0
	  update a set a.syy='人工未下单'  from  #mdlkcsp a 
		left  join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1
	  where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)=0 ;
   
	  update a set a.dzhyhrq=b.dYhrq,a.syy='人工订货不足'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
	  where 1=1  and  len(a.syy)=0  and a.sZdbh=0 and ISNULL(b.nYhsl,0)>0  and b.nShsl*1.0/b.nYhsl>=0.9 ;


	  -- Step 6.6 DC未送货 或 送货不足
	  update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心未送货'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
	  where 1=1  and   len(a.syy)=0  and b.sfdbh is not null  and   isnull(b.nShsl,0)=0 and a.sPsfs='统配'
	  and b.nYhsl>0;
  
	   update a set a.dzhyhrq=b.dYhrq,a.syy='物流中心送货不足'  from  #mdlkcsp a 
		join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
	  where 1=1  and   len(a.syy)=0  and b.nShsl>0 and  b.nShsl*1.0/b.nYhsl<0.9 and a.sPsfs='统配' ;

	   
	  -- Step 6.7 :系统未下单，或定额不足
	  -- 系统未下单 需要考虑节奏日，如果即使到节奏日出了单，那也是定额不足，后面用异常出单修正原来的原因
		update a set  a.syy='系统定额不足'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
		where 1=1  and   len(a.syy)=0  and  a.sZdbh=1    and b.sfdbh is null;
  
		-- Step 6.8:系统定额不足,但如果是手工改小的采购单 
		update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1 
		where 1=1  and   len(a.syy)=0   and b.nShsl>0   and  b.nShsl*1.0/b.nYhsl>=0.9
		and  a.sZdbh=1   and isnull(b.nYhsl_raw,0)>0 and b.nYhsl>=b.nYhsl_raw ;
	   -- select * from #TMP_dh_cal where nYhsl>0
		--Step 6.9: 人工改小或删单
		update a set a.dzhyhrq=b.dYhrq,a.syy='人工减量或删单'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
	    and ((b.nShsl>0  and b.nYhsl_raw>b.nYhsl 
			and isnull(b.nYhsl,0)>0) or (b.nYhsl_raw>0 and b.nYhsl is null ))
		where 1=1  and   len(a.syy)=0   and  a.sZdbh=1 and b.sfdbh is not null ;



		--Step 6.10: 系统定额不足，人工未减量，供应商到货
		update a set a.dzhyhrq=b.dYhrq,a.syy='系统定额不足'  from  #mdlkcsp a 
		left join  #Tmp_dh_cal b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm_cal=1  
		where 1=1  and   len(a.syy)=0   and b.nShsl>0 and  b.nShsl*1.0/b.nYhsl>=0.9
		and  a.sZdbh=1  and b.nYhsl_raw=b.nYhsl  ;

	
	
		 update a set a.syy='其他' from #mdlkcsp a    where len(a.syy)=0 ; 
		 delete from dbo.TMP_MDLKCYY where drq=convert(date,GETDATE());
       
		 insert into dbo.TMP_MDLKCYY(drq,sfdbh,sspbh,sspmc,sfl,nZdsl,nZgsl,szdbh,ssfkj,spsfs,syy,dzhyhrq,nrjxl,nrjxse,nsl)
		 select convert(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sSpmc,a.sFl,a.nZgsl ,a.nZdsl ,a.sZdbh,a.sSfkj,a.sPsfs,a.syy,
		 a.dzhyhrq,a.nRjxl_De,a.nRjxse ,nsl  from  #mdlkcsp a  ;

		

-- 第二部分 门店大库存
    -- Step 2.1 ：大库存数据生成 drop table #mddkc
	/*  门店大库存 */
		with x0 as (
		select a.*,b.nSl, convert(numeric(15,4),case when  a.nRjxl_De=0 then 300 
			else b.nsl*1.0/(a.nRjxl_De) end) nzzts ,case  when   a.spllx='槟榔' then  30 else  ceiling(a.nBzt*0.8) end  nbzzzts
			from #base_sp a 
		left join #mdkc b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh 
		where 1=1 and ISNULL(b.nsl,0)>2  and  case when  a.nRjxl_De=0 then 300 else  b.nsl*1.0/(a.nRjxl_De) end>
		case  when   a.spllx='槟榔' then  30 else  ceiling(a.nBzt*0.8) end  )
		select a.sFdbh,a.sSpbh,a.sspmc ,a.sFl,b.sdw,b.sGys,a.nJj,a.nSj,b.sZdbh,b.sPsfs,a.nRjxl_De nRjxl,a.nrjxse,a.nsl
		, a.nzzts,a.nPsbzs,a.nCgbzs,convert(date,Null) dzhyhr,convert(date,Null) dzhdhr, 
		convert(varchar(20),'') syy,convert(varchar(5),'') sfwqzs,convert(varchar(20),'') sfcx,
		convert(money,Null) nYhsl,convert(money,Null) nDhsl,a.nbzzzts into #mddkc  from x0  a 
		join dbo.tmp_spb b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh where 1=1 ; 

		--Step 2.2:最后一天进货 drop table #jcmx_raw
		select  CONVERT(date,a.dsj) dsj,a.sfdbh,a.sjcfl,b.sspbh,SUM(b.nsl) nsl  into #jcmx_raw
		  from dbo.Tmp_Jcb a ,dbo.Tmp_Jcmxb b   where a.sJcbh=b.sJcbh
		and a.sFdbh=b.sFdbh and a.dSj>convert(date,GETDATE()-180) 
		group by CONVERT(date,a.dsj)  ,a.sfdbh,a.sjcfl,b.sspbh ;

		-- drop table #jcmx
		with x0 as (
		 select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
		 ,a.nsl   from #jcmx_raw a  
		 join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		 where 1=1 and  a.nsl>2 )
		 select * into #jcmx from x0  where npm<=2;
 
    --  原因划分
    -- Step 2.3:遗留库存
	    with x0 as (
		 select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
		 ,a.nsl   from #jcmx_raw a  
		 join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		 where 1=1  and a.nsl>0  )
		update a set a.syy='遗留库存'   from #mddkc  a 
		left join x0 b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
		where 1=1  and b.sFdbh is null;

	 
    --Step 2.4: 特陈设置的,
		update a set a.syy='特陈过大',a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl  from #mddkc a  
		 join #jcmx b on a.sFdbh=b.sfdbh and a.sSpbh=b.sSpbh and b.npm=1 
		join dbo.Tmp_Tc c on a.sFdbh=c.sFdbh and a.sSpbh=c.sSpbh
		and c.dKssj<b.dsj and c.dJssj>b.dsj and  c.nTcsl>6 and   c.nTcsl>=a.nsl*0.5 
		where 1=1 and len(a.syy)=0;
	
	-- Step 2.5:对盘点调拨 划分：盘点，调拨量大于当前库存数量的一半
	update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl,
	a.sfwqzs=case when b.nDhsl<a.nsl*0.2 and d.sfdbh is not null and d.nDhsl>a.nsl*0.1  then '是' end   from #mddkc a  
		join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh and b.npm=1
            and (b.sJcfl='报货单' or ( b.sjcfl in (select fl_content from dbo.Purchase_jcflbzb where  fl_bzname in('盘点','调拨','损溢') )))
        left join #jcmx d on a.sfdbh=d.sFdbh and a.sSpbh=d.sSpbh and d.npm=2 
        and (d.sJcfl='报货单' or ( d.sjcfl in (select fl_content from dbo.Purchase_jcflbzb where  fl_bzname in('盘点','调拨','损溢'))))
	where  1=1  and len(a.syy)=0  and  (b.nDhsl>=a.nsl*0.2  or  (b.nDhsl<a.nsl*0.2 and d.sfdbh is not null and d.ndhsl>a.nsl*0.1 ));
		-- Step 2.6:对最后一次到货的包装数：包装数>=4,包装数大于当前库存的0.6倍，就是包装数过大
	with x0 as(
	select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
	ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm,
	a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
	join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
	left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
	where  1=1   and len(a.syy)=0 and d.dShrq is not null and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
	    )
	update a set a.syy= case when a.spsfs<>'配送'   and  b.nDhsl=a.nCgbzs   then  '采购包装数过大'
	when  a.spsfs='配送' and b.nDhsl=a.nPsbzs then   '配送包装数过大' end
		,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl
		from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
		where  1=1  and b.ndhsl>=a.nsl*0.6 and b.nDhsl>=4   ;

	-- Step 2.7 :最后一次要货查是谁下的单 如果系统单，但是到货量大 那么就是人工原因，到货量小于系统单，系统原因，其他 手工原因
    --如果是在采购里面加单的话，那么就是手工加量或加单
	with x0 as(
	select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
	ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm,
	a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs,d.stype  from #mddkc a 
	-- join #jcmx b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
	-- left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
	where  1=1   and len(a.syy)=0 and d.dShrq is not null  and d.nShsl>=a.nsl*0.2 )
	update a set a.syy= case when b.nYhsl_raw is not null and b.nYhsl<=b.nYhsl_raw     then '系统定额过大' 
	when   b.stype not  like '%天牧%'  and  b.nYhsl_raw  is null      then '人工下单' 
	when   b.nYhsl_raw is not null and b.nYhsl>b.nYhsl_raw  then '人工加量或加单'
		else '其他' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl
		from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1;


	-- Step 2.8:往前追溯一次
	  update #mddkc set sfwqzs='是' where len(syy)=0;
	---- Step 2.9 : 生成次到货数据  drop table  #jcmx1
	    with x0 as (
		 select a.dsj,a.sfdbh,a.sjcfl,a.sspbh,a.nsl nDhsl,ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by a.dsj desc,a.nsl desc) npm
		 ,a.nsl   from #jcmx_raw a  
		 join #mddkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		 where 1=1 )
		 select * into #jcmx1 from x0  where npm<=2;
	-- Step 2.10:对盘点调拨 划分：第二次盘点，调拨量大于当前库存数量的0.1就算
		update a set a.syy=b.sJcfl,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl from #mddkc a  
		join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
		join dbo.Purchase_jcflbzb c on b.sJcfl=c.fl_content
		where  1=1 and (c.fl_bzname in('盘点','调拨','损溢','其他进出') or b.sJcfl='报货单')  and b.nDhsl>a.nsl*0.1 and len(a.syy)=0;
	-- Step 2.11:对最后一次到货的包装数： 最后一次到货量等于包装数
		with x0 as(
		select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw ,
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm,
		a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs from #mddkc a 
		join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
		--left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
		where  1=1   and len(a.syy)=0 and d.dShrq is not null and convert(date,d.dshrq)=CONVERT(date,b.dsj) 
	     )
		update a set a.syy= case when a.spsfs<>'配送'   and  b.nDhsl=a.nCgbzs   then  '采购包装数过大'
		when  a.spsfs='配送' and b.nDhsl=a.nPsbzs then   '配送包装数过大' end
		  ,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj ,a.nDhsl=b.nDhsl
		  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1
		 where  1=1  and   b.nDhsl>=a.nsl*0.6 and b.nDhsl>=4   ;
    -- Step 2.12:要货到货匹配再查一次
		with x0 as(
		select a.sFdbh,a.sSpbh,d.dShrq dSj,isnull(d.nShsl,0) nDhsl,a.sPsfs,a.sZdbh,d.sLx,d.sBz,d.nYhsl,d.dYhrq,d.nYhsl_raw, 
		ROW_NUMBER()over(partition by a.sfdbh,a.sspbh order by d.dYhrq desc,d.nYhsl desc) nyhpm 
		,a.nrjxl,a.nrjxse,a.nsl,a.nPsbzs,a.nCgbzs,d.stype  from #mddkc a 
		-- join #jcmx1 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh
		left join  dbo.Tmp_Gys c on a.sGys=c.sGysbh and a.sFdbh=c.sFDBH
		 join #TMP_dh_cal d on a.sFdbh=d.sFdbh and a.sSpbh=d.sspbh  
		where  1=1   and len(a.syy)=0 and d.dShrq is not null   )
		update a set a.syy= case when   b.nYhsl_raw is not null and b.nYhsl<=b.nYhsl_raw      then '系统定额过大' 
		when   b.stype  not  like '%天牧%' and b.nYhsl_raw is null        then '人工下单' 
		when   b.stype like '%天牧%'  and b.nYhsl_raw is not null and b.nYhsl>b.nYhsl_raw  then '人工加量或加单'
		  else '其他' end,a.dzhyhr=b.dYhrq,a.dzhdhr=b.dSj,a.nDhsl=b.nDhsl 
		  from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  and b.nyhpm=1 ;
	-- Step 2.13:更新预期到货 drop table #dhyq
		select distinct a.sfdbh,a.sspbh into #dhyq from #tmp_dh_cal a
		join #tmp_dh_cal b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		where  a.npm_cal=1 and b.npm_cal>=2 and 
		datediff(hour,a.dyhrq,b.dshrq)>0 and datediff(hour,b.dyhrq,a.dyhrq)>0
		and a.nYhsl_raw is not null  and a.dshrq is not null 
		order by a.sfdbh,a.sspbh;
		
		update a set a.syy='逾期到货' from #mddkc a
		join #dhyq b on   a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
		where 1=1 ;
	-- Step 2.14:   更新剩余 
        update a set a.syy='其他'  from #mddkc a  where  1=1   and len(a.syy)=0 ;

  --  -- Step 2.16:更新促销
		 with x0 as(
		 select  distinct sFdbh,sSpbh from dbo.tmp_cxb where  dkssj<GETDATE() and  djssj>GETDATE())
		 update a set a.sfcx='是' from #mddkc a join x0 b on a.sFdbh=b.sFdbh and a.sSpbh=b.sSpbh  
		 where 1=1;

	-- Step 2.17 :对配送包装数变动  特指从大变小，造成系统订单过大进行修改
		update a set  a.syy= case when a.sPsfs='统配'  then '配送包装数过大' else '采购包装数过大' end 
		from #mddkc a join #TMP_dh_cal b on CONVERT(date,a.dzhyhr)=CONVERT(date,b.dYhrq) and a.sFdbh=b.sfdbh and a.sSpbh=b.sspbh
		and a.nDhsl=b.nCgbzs  and  case when a.sPsfs='统配'  then a.nPsbzs else  a.nCgbzs end <>a.nDhsl
		where a.syy='系统定额过大';



		-- Step 2.17:写入结果
		delete from  dbo.tmp_mdspzzyy where drq=convert(date,GETDATE());
		insert into dbo.tmp_mdspzzyy(drq,sfdbh,sspbh,sspmc,sfl,sgys,njj,nsj,szdbh,spsfs,nrjxse,nrjxl,nkc,nzzts,npsbzs,ncgbzs,dzhdhr,dzhyhr,
		syy,sfwqzs,nbzzzts,sfcx,nDhsl)
		select CONVERT(date,GETDATE()) drq, a.sFdbh,a.sSpbh,sSpmc,sFl,sGys,nJj,nSj,sZdbh,sPsfs,nrjxse,nRjxl,nsl,case when convert(numeric(19,2),nzzts)>10000 then 1000 else convert(numeric(19,2),nzzts) end,nPsbzs,
		nCgbzs,dzhdhr,dzhyhr,syy,sfwqzs,a.nbzzzts,a.sfcx,nDhsl from #mddkc a
		where 1=1  ;