-- =============================================
-- Author:		<Dxp>
-- Create date: <2021-12-06>
-- Description:	<DC零库存和DC大库存的中间数据源>
-- =============================================
 
ALTER PROCEDURE [dbo].[Proc_DC_BIsources]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
       SET NOCOUNT ON;
	
/*DC标准数据源*/
--Step 1:零库存商品明细 drop table #base_dcsp
/*DC所有单品都追查最后一次要货， 标准库存使用Tmp_dckcb*/
/* 范围取经营商品 ssfkj='1'*/   
select  a.*,isnull(b.nSl,0) nsl into #base_dcsp from dbo.tmp_spb_dc  a left join  
 (select *    from  dbo.Tmp_dckcb where  CONVERT(date,sRq)=(select  max(CONVERT(date,sRq))  from Tmp_dckcb 
 where  CONVERT(date,sRq)<CONVERT(date,GETDATE()))   )  b
on a.sSpbh = b.sSpbh   and ISNULL(a.sCw,'s') =ISNULL(b.sCw,'s')  
where a.sSfkj='1'   and a.sfl not in(select  sFlbh  from Tmp_Spflb_Ex)  
and a.sSpbh not in (select sSpbh from Tmp_spb_ex)   ;

  -- 确认szdbh 字段 是否有效
  if (select count(1) from Sysobjects where name in(UPPER('Sys_Params')))=1
	begin
	   if  (select sParamsVal from Sys_Params where sParamsName='REPORT_ZDBH_GLOBAL')='0'
	   update #base_dcsp set sZdbh='0' where sZdbh<>'0'
	end
   
--Step 2:采购订单  
	-- Step 2.1 :D咨询单  drop table #dzixun
	create table #dzixun(drq date not null,sspbh varchar(30) not null, nsl money,nCgbzs money,nrjxl money );
	if   (select count(1)  from sysObjects  where upper(name)=upper('Purchase_Receipt_Items'))=1
		begin
		     insert into #dzixun(drq,sspbh,nsl,nCgbzs,nrjxl)
			 select CONVERT(date,LEFT(a.sdh,8)) drq,  a.sspbh,a.nsl,a.nCgbzs,nRjxl  
			 from dbo.Purchase_Receipt_Items  a 
			 join #base_dcsp b on a.sSpbh=b.sSpbh
			 join dbo.Tmp_gys c on b.sGys=c.sGysbh and c.sFDBH='0000' where CONVERT(date,LEFT(sdh,8))>=CONVERT(date,GETDATE()-180)
			 and dateadd(day,case  when   isnull(c.nDay,0)>15 or  isnull(c.nDay,0)<=0 
			 then 6 else c.nDay end,CONVERT(date,LEFT(a.sdh,8)))<CONVERT(date,GETDATE()) ;
		end
	-- Step 2.2:实际采购单 drop table #tmp_cgdd
	select a.sSpbh,a.sGys,a.dCgrq,a.dDhrq,a.nCgsl,a.nDhsl into #tmp_cgdd from dbo.Tmp_Cgddmx_dc a 
	left join  dbo.Tmp_Gys b on a.sGys=b.sGysbh and b.sfdbh='0000'
	where a.dCgrq>=CONVERT(date,GETDATE()-180) and (a.dDhrq is not null  or a.dYxrq<GETDATE()
	or  dateadd(day,case  when   isnull(b.nDay,0)>15 or  isnull(b.nDay,0)<=0 then 6 
    else b.nDay end,a.dCgrq )<CONVERT(date,GETDATE())  );

	-- Step 2.3:单据汇总  drop table #Tmp_cgdd_result
	with x0 as(
	select ISNULL(b.sSpbh,a.sSpbh) sspbh,ISNULL(b.dCgrq,a.drq) dcgrq,b.dDhrq,a.nSl ncgsl_raw,b.nCgsl,b.nDhsl 
	   from #dzixun a full join #tmp_cgdd b on a.sSpbh=b.sSpbh and DATEDIFF(HOUR,a.drq,b.dCgrq) between 0 and 48
	where 1=1)
	select a.*,ROW_NUMBER()over(partition by a.sspbh order by a.dcgrq desc,a.nCgsl desc) npm into #Tmp_cgdd_result from x0 a;
	 
  -- Step 3:查进出 drop table #tmp_jc
    with x0 as (
    select CONVERT(date,a.dSj) drq,a.sJcfl,a.sSpbh,sum(a.nSl) nsl  from dbo.Tmp_jcmxb_dc a 
	where   a.dSj>=CONVERT(date,GETDATE()-180) and a.dSj<CONVERT(date,GETDATE())  group by a.sspbh,CONVERT(date,a.dSj)  ,a.sJcfl)
	select a.*,ROW_NUMBER()over(partition by a.sspbh order by a.drq desc) npm into #tmp_jc from x0 a  where a.nsl<0;
  -- Step 4:生成零库存原因表 drop table #dclkcyy
     select a.sspbh,a.sSpmc,a.sFl,a.sGys,a.nJj,a.nSj,b.nRjxl_De*b.nZdkcts_jy nZdsl,b.nRjxl_De*b.nZgkcts_jy nZgsl,a.nsl,a.nCgbzs,a.sSfkj,a.sZdbh,
	 CONVERT(varchar(20),'') syy,CONVERT(date,NULl) dzhcgrq,CONVERT(money,Null) nCgsl,CONVERT(money,Null) nDhsl into #dclkcyy from #base_dcsp a  
	 left join dbo.Purchase_Spb b on a.sSpbh=b.sSpbh  where nsl<=0;

  -- Step 5.0 如果设置了不出单，则最先判断
  if (select count(1)  from sysObjects  where upper(name)=UPPER('Purchase_GysEx'))=1
			begin 
				update a set a.syy='暂不出单' from #dclkcyy a
				join dbo.Purchase_GysEx b on   a.sGys=b.sGysbh
				where len(a.syy)=0 ;
		    end  
  --Step 5:进出原因——最后一次扣减库存是非配送,但是日期要在有效期内
    update a set a.syy=b.sJcfl from #dclkcyy a 
	  join #tmp_jc b on a.sSpbh=b.sSpbh and b.npm=1   and DATEDIFF(day,b.drq,CONVERT(date,getdate()))<7
	  join dbo.Purchase_Djlxb c on b.sJcfl=c.单据类型 
	where 1=1 and c.匹配类型  not in ('出货') and abs(b.nsl)>a.nzdsl*0.2;

  --Step 6:供应商未送货或供应商送货不足
	update a set a.syy=case when b.nDhsl is null then '供应商未送货' when b.nDhsl*1.0/b.nCgsl<0.9 then '供应商送货不足' end,
		 a.dzhcgrq=b.dcgrq,a.nCgsl=b.nCgsl,a.nDhsl=b.nDhsl from #dclkcyy a  
	  join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm=1 
	where 1=1 and b.nCgsl is not null and b.nCgsl>=ISNULL(b.ncgsl_raw,0) and ISNULL(b.nDhsl,0)<b.nCgsl*0.9 and len(a.syy)=0 ;
  -- Step 7:删单或减量：系统出单，但是没有实际单或量少了
	update a set a.syy=case when b.nCgsl is null then '人工删单/减量' when b.nCgsl<b.ncgsl_raw*0.9 then '人工删单/减量' end,
		 a.dzhcgrq=b.dcgrq, a.nCgsl=b.nCgsl,a.nDhsl=b.nDhsl from #dclkcyy a  
	  join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm=1 
	where 1=1 and isnull(b.nCgsl,0)<b.ncgsl_raw*0.9 and b.ncgsl_raw is not null and len(a.syy)=0  ;

   update a set a.syy='人工订货不足', a.dzhcgrq=b.dcgrq,a.nCgsl=b.nCgsl,a.nDhsl=b.nDhsl from #dclkcyy a  
	 left join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm=1  
	 where   len(a.syy)=0  and a.szdbh='0' and b.dcgrq is not null and b.nDhsl>=b.nCgsl*0.9  and b.nCgsl is not null;

	  update a set a.syy='人工未下单', a.dzhcgrq=b.dcgrq,a.nCgsl=b.nCgsl,a.nDhsl=b.nDhsl from #dclkcyy a  
	 left join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm=1  
	 where   len(a.syy)=0 and a.szdbh='0'  and b.nCgsl is  null;

	 update a set a.syy='系统定额不足', a.dzhcgrq=b.dcgrq,a.nCgsl=b.nCgsl,a.nDhsl=b.nDhsl from #dclkcyy a  
	 left join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm=1  
	 where   len(a.syy)=0 and a.szdbh='1'and b.dcgrq is not null and b.nDhsl>=b.nCgsl*0.9 and b.nCgsl is not null;

   
     update a set a.syy='系统定额不足', a.dzhcgrq=b.dcgrq,a.nCgsl=b.nCgsl,a.nDhsl=b.nDhsl from #dclkcyy a  
	 left join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm=1  
	 where   len(a.syy)=0 and a.szdbh='1'and  b.dCgrq  is   null;

	  -- 该出单确未出单
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
		   -- DC近一月库存
		   with x0 as (select  distinct a.drq,b.sSpbh,b.nZdsl,b.nZgsl  from #tmp_date a,#dclkcyy b    )
		   select  a.*,ISNULL(b.nSl,0) nkcsl into #tmp_kc from x0  a left join dbo.Tmp_dckcb b 
		   on a.drq=convert(date,b.sRq)   and  a.sSpbh=b.sSpbh ;
		    
		   -- DC近一月定额 drop table #tmp_lsde
		   with x0 as (select  distinct a.drq, b.sSpbh,b.nZdsl,b.nZgsl  from #tmp_date a,#dclkcyy b)
		   ,x1 as (select a.*,isnull(b.nRjxl_De*b.nZdkcts_jy,a.nZdsl) nxx,isnull(b.nRjxl_De*b.nZgkcts_jy,a.nZgsl) nSx, 
		     ROW_NUMBER()over(partition by a.drq,  a.sspbh order by CONVERT(date,left(b.sbh,8))  desc) npm from x0 a left join dbo.Purchase_Spb_History b on   a.sSpbh=b.sSpbh and a.drq=CONVERT(date,left(b.sbh,8)) 
		     and  CONVERT(date,left(b.sbh,8)) >GETDATE()-40  where 1=1 )   
		   select * into #tmp_lsde from x1 where npm=1;
	 /*DC 系统定额和出单分两块,如果是没有单据,则归属与ERP未出单*/
	 	     -- 该出单的商品  drop table #erp_cd
		 	with x0 as (select  distinct a.drq,b.* from #tmp_date a,#dclkcyy b)
		 ,x1 as (select  distinct  a.sSpbh,a.sSpmc,a.drq,a.sGys   from x0 a
		left join #tmp_kc c on   a.sSpbh=c.sSpbh and a.drq=c.drq
	        join #tmp_lsde d on  a.sSpbh=d.sSpbh and a.drq=d.drq
		where  1=1   and   len(a.syy)=0 and  a.sZdbh=1   and  ISNULL(c.nkcsl,0)<=d.nxx   and  d.nsx-ISNULL(c.nkcsl,0)>0  )
		select  distinct  a.sSpbh,a.sSpmc,a.sGys,max(a.drq) max_drq into #erp_cd  from x1 a
		 join dbo.Tmp_Gys e on e.sFdbh='0000' and a.sGys=e.sGysbh 
		 where   DATEADD(day,isnull(e.nDay,5),a.drq) <convert(date,GETDATE())  and e.sdays is not null  and 
		  case when  e.sType=UPPER('W')  then SUBSTRING(e.sDays,DATEPART(WEEKDAY,a.drq)-1,1)
		 when   e.sType<>UPPER('W')  then SUBSTRING(e.sDays,DATEPART(DD,a.drq),1)  else '0'   end ='1' 
		 group by a.sSpbh,a.sSpmc,a.sGys; 

		 update a set a.syy='ERP未出单', a.dzhcgrq=b.dcgrq,a.nCgsl=b.nCgsl,a.nDhsl=b.nDhsl from #dclkcyy a  
	     left join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm=1  
	     where   len(a.syy)=0  and a.szdbh='1' and   b.dCgrq  is  not null    and b.nCgsl is  null;

		 update a set  a.syy='ERP未出单'  from  #dclkcyy a 
		 join #erp_cd c on   a.sSpbh=c.sSpbh 
		 left join #Tmp_cgdd_result b on a.sSpbh=b.sSpbh and b.npm=1   and b.dcgrq>=c.max_drq
		 where 1=1  and   len(a.syy)=0  and  a.sZdbh=1   and b.sspbh is null and c.sSpbh is not null;

	  
  
       update a set a.syy='其他' from #dclkcyy a   where   len(a.syy)=0 ;
	-- Step 8:未出单的单据更新：如果系统出单在最后日期之后，且未达起订量
	if   (select count(1)  from sysObjects  where upper(name)=upper('Purchase_Receipt_Items_History'))=1
	  begin
		with x0 as(
		select  sspbh, sbh,convert(date,srq) drq ,nZddhje,nZddhsl,GenState,
		ROW_NUMBER()over(partition by sspbh order by convert(date,srq) desc) npm  from  dbo.Purchase_Receipt_Items_History 
		where 1=1  and  GenState<>'已出单' )
		select * into #ycdp from x0 where npm=1;

		update a set a.syy=b.GenState from #dclkcyy a 
		 join #ycdp b on  a.sSpbh=b.sSpbh and ( b.drq>=a.dzhcgrq or a.dzhcgrq  is null )
		where 1=1 ; 
		end

	--Step 9:零库存存表保存

	delete  dbo.Tmp_Dclkcyy where drq= convert(date,getdate());
	insert into   dbo.Tmp_Dclkcyy(drq,sSpbh,sSpmc,sFl,sFlmc,nJj,nSj,nZdsl,nZgsl,nRjxl,dZhyhr,nCgsl,nDhsl,syy,nkcsl)
	select convert(date,getdate()) drq, a.sSpbh,c.sSpmc,c.sFl,d.sFlmc,c.nJj,c.nSj,
	case when ceiling(ISNULL(b.nRjxl_De,b.nRjxl)*b.nZdkcts_jy)<ISNULL(c.nZdcl,0) 
	then ISNULL(c.nZdcl,0)else ceiling(ISNULL(b.nRjxl_De,b.nRjxl)*b.nZdkcts_jy) end nxx,
	case when ceiling(ISNULL(b.nRjxl_De,b.nRjxl)*b.nZgkcts_jy)<ISNULL(c.nZdcl,0) then ISNULL(c.nZdcl,0)
	else ceiling(ISNULL(b.nRjxl_De,b.nRjxl)*b.nZgkcts_jy) end nsx,ISNULL(b.nRjxl_De,b.nRjxl) nRjxl,a.dzhcgrq,a.nCgsl,a.nDhsl,a.syy,a.nsl
	from #dclkcyy a 
	left join  purchase_spb b on a.sspbh=b.sSpbh
	left join  dbo.Tmp_spb_dc c on a.sspbh=c.sSpbh
	left join  dbo.tmp_spflb d on c.sFl=d.sFlbh
	where 1=1;

 -- 二 DC大库存
 /*DC 大库存原因，采购包装数过大,人工下单，系统下单，人工加量，其他退货
 库存调整和盘点都是盘点，入配(返仓) - 门店退货
 */
 -- Step 2.1 :用标准-周转天数和数量判断
;with x0 as (select a.sSpbh,sum(a.nRjxl_De) nrjxl_de  from  dbo.R_Dpzb a where 1=1 and  a.EndDate>CONVERT(date,GETDATE()-14)
group by a.sSpbh)
 select a.*,b.nRjxl_De,case  when ISNULL(c.nRjxl_De,0)=0 then 300 else  a.nSl/c.nRjxl_De  end  nzzts
 ,CEILING(b.nRjxl_De*b.nZdkcts_jy) nxx,CEILING(b.nRjxl_De*b.nZgkcts_jy) nsx into #dcdkcsp from #base_dcsp a 
 left join  dbo.purchase_spb b on a.sspbh=b.sSpbh
 left join x0 c on a.sspbh=c.sSpbh
 where 1=1 and case  when ISNULL(c.nRjxl_De,0)=0 then 300 else  a.nSl/c.nRjxl_De  end >50
 and a.nSl>10 and a.njj*a.nsl>100  ;
  
 -- Step 2.2:从进出里查DC的最后进货记录，如果是采购追采购单，如果是其他进出，用其他进出判断 drop table #jc_rq
 with x0 as (
 select a.sSpbh,b.sJcfl,b.nSl,b.dSj,ROW_NUMBER()over(partition by a.sSpbh order by b.dsj desc,b.nsl desc) npm from #dcdkcsp a 
 left join  dbo.Tmp_jcmxb_dc b on a.sSpbh=b.sSpbh   and b.dSj>CONVERT(date,GETDATE()-180) and b.dSj<CONVERT(date,GETDATE() )  and b.nsl>0
 where  1=1  )
 select a.* into #jc_rq   from x0 a where 1=1 and  (a.npm=1 or a.npm is null);
  
 -- Step 2.3:存原因临时表 drop table #tmp_dcspzzyy
 select a.sSpbh,a.sSpmc,a.sFl,a.sGys,a.nxx nZdsl,a.nsx nZgsl,a.nCgbzs,a.sPsfs,a.sZdbh,a.nSl,convert(date,null) dYhrq ,
 convert(date,null) dDhrq,convert(money,null)  nCgsl,convert(money,null) nDhsl,CEILING(a.nzzts) nzzts, convert(varchar(50),'') syy
 into #tmp_dcspzzyy from #dcdkcsp a ;

 -- Step 2.4:更新盘点、返仓原因，非验收类型 遗留库存
  update a set a.syy='遗留库存' from #tmp_dcspzzyy a join #jc_rq b on a.sSpbh=b.sSpbh  where b.dSj is null;

  update a set a.syy=case  when  c.匹配类型='进出' then  b.sJcfl  else c.匹配类型   end ,a.dDhrq=b.dSj,a.nDhsl=b.nSl
  from #tmp_dcspzzyy a join #jc_rq b on a.sSpbh=b.sSpbh  
  join  dbo.Purchase_Djlxb c on b.sJcfl=c.单据类型
   where c.匹配类型 not in ('出货')  and abs(b.nSl*1.0/a.nsl)>=0.4 ;

 -- Step 2.5 :商品匹配采购单，验收类型
   with x0 as (
   select a.*,ROW_NUMBER()over(partition by a.sspbh order by a.dcgrq desc,a.ncgsl desc) ncgpm  from #Tmp_cgdd_result a where nDhsl>0 )
   update a set a.syy=case 
   when b.sspbh is null then '遗留库存'
   when a.nCgbzs>=a.nsl*0.6  and b.nDhsl=a.nCgbzs then '采购包装数过大'
   when b.ncgsl_raw is null then '人工下单' when b.ncgsl_raw is not null and b.nCgsl>b.ncgsl_raw then '人工加量或加单'
   when b.ncgsl_raw is not null and b.nCgsl<=b.ncgsl_raw then '系统定额过大' end,a.dYhrq=b.dcgrq,a.dDhrq=b.dDhrq,a.nCgsl=b.nCgsl,a.nDhsl=b.nDhsl from #tmp_dcspzzyy a 
   left join x0 b on a.sSpbh=b.sspbh and b.ncgpm=1
   where 1=1  and len(syy)=0;

   -- Step 2.6:再往前追溯一次
    with x0 as (
	 select a.sSpbh,b.sJcfl,b.nSl,b.dSj,ROW_NUMBER()over(partition by a.sSpbh order by b.dsj desc,b.nsl desc) npm from #dcdkcsp a 
	 left join  dbo.Tmp_jcmxb_dc b on a.sSpbh=b.sSpbh   and b.dSj>CONVERT(date,GETDATE()-180) and b.dSj<CONVERT(date,GETDATE() )  and b.nsl>0
	 where  1=1  )
	 select a.* into #jc_rq1   from x0 a where 1=1 and  a.npm=2;

	 -- Step 2.7:更新盘点、返仓原因，非验收类型 遗留库存
 
	  update a set a.syy=case  when  c.匹配类型='进出' then  b.sJcfl  else c.匹配类型   end ,a.dDhrq=b.dSj,a.nDhsl=b.nSl
	  from #tmp_dcspzzyy a join #jc_rq1 b on a.sSpbh=b.sSpbh  
	  join  dbo.Purchase_Djlxb c on b.sJcfl=c.单据类型
	   where c.匹配类型 not in ('出货')  and abs(b.nSl*1.0/a.nsl)>=0.4 ;

         	-- Step 2.8:预期到货，原因划分之后，对非盘点
	    with x0 as(
	    select a.sSpbh,a.sSpmc,a.dYhrq,b.dcgrq,b.dDhrq,b.nCgsl,b.nDhsl,ROW_NUMBER()over(partition by a.sspbh order by b.dCgrq desc,b.nsl desc) npm from #tmp_dcspzzyy a join #Tmp_cgdd_result b on a.sSpbh=b.sspbh and a.dYhrq>b.dcgrq
		where a.syy in ('人工下单','系统定额过大') and b.nDhsl>0),
		 x1 as (select *  from  x0 a 
		  join x0 b on  a.sspbh=b.sspbh and b.npm=2
		  where a.npm=1 and datediff(hour,a.dCgrq,b.dDhrq)>0 and datediff(hour,b.DCgrq,a.DCgrq)>30)
		  select  distinct a.sspbh into #yq from x1 a;

		  update  a set a.syy='预期到货' from  #tmp_dcspzzyy a,#yq b where a.sspbh=b.sspbh;
	

		update  #tmp_dcspzzyy set syy='其他' where len(syy)=0 or  syy is null;

		 delete dbo.Tmp_dczzyy where  drq=CONVERT(date,GETDATE());
		 insert into dbo.Tmp_dczzyy(drq,sSpbh,sSpmc,sFl,sGys,nZdsl,nZgsl,nCgbzs,sPsfs,sZdbh,nkcsl,dYhrq,dDhrq,nCgsl,nDhsl,nzzts,syy)
		 select CONVERT(date,getdate()),a.sSpbh,a.sSpmc,a.sFl,a.sGys,a.nZdsl,a.nZgsl,a.nCgbzs,a.sPsfs,a.sZdbh,a.nSl,a.dYhrq,a.dDhrq,a.nCgsl,
		 a.nDhsl,a.nzzts,a.syy from #tmp_dcspzzyy a;
End
