USE [DappSource_Dw]
GO
/****** Object:  StoredProcedure [dbo].[Cal_plzzts]    Script Date: 2022/4/11 14:49:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Dxp>
-- Create date: <2022-03-31>
-- Description:	<按客户标准，每天更新大类的周转标准天数>
-- =============================================
ALTER PROCEDURE [dbo].[Cal_plzzts]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	        -- 大类标准周转天数计算
        -- Step 0 :取 日结的库存
        select c_store_id sfdbh,c_gcode sspbh,c_number nkcsl,c_A nKcje into #Tmp_mdkc   from openquery( [122.147.160.20],
        'select * from tbs_day_inventory where c_store_id<>''015901''
        and c_day_date=trunc(sysdate-1)');

        -- Step 1:商品表 分店表 分类表准备
        select * into #Tmp_fdb from DappSource_Dw.dbo.Tmp_fdb

        select * into #Tmp_flb from DappSource_Dw.dbo.Tmp_spflb

        select * into #Tmp_mdspb from DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT
        select * into #goods from DappSource_Dw.dbo.goods
        -- 近30天销售准备
        --select * into #Tmp_xs from [122.147.10.200].Dappsource.dbo.Tmp_xs a
        --where 1=1 and  a.drq>=convert(date,getdate()-30) 
        --and a.drq<CONVERT(date,GETDATE());

		--select  * into #Tmp_xs  from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
		--where 1=1 and CONVERT(date,a.SALE_DATE)>=convert(date,getdate()-30) 
  --      and  CONVERT(date,a.SALE_DATE)<CONVERT(date,GETDATE());

        -- Step 2:基础表生成
        /*
            --排除母婴、生超、加盟门店
            -- 排除联营商品
            -- 排除停购商品
            -- 分类为20-39，含 '1105','1307','1406' ，不包含 2103低温奶/果汁,2104冷藏食品,2105冷冻食品2106冷冻粽子
			,2201烟,2203白酒/保健酒,2204进口酒/葡萄酒,2309母婴食品,3903小家电
            -- 
        */
        select a.dept_code sfdbh,b.sfdmc,a.item_code sspbh,c.name sspmc,c.sort sflbh,
        a.shift_price njj,a.retail_price nlsj,a.display_mode,a.c_introduce_date,c.isnormal,c.scgqy into #Base_sp from #Tmp_mdspb a
        join #Tmp_fdb b on a.dept_code=b.sfdbh
        join  #goods c  on c.code=a.item_code
        -- join #tmp_flb d on c.sort=d.sflbh
        where 1=1 and b.sfdmc not like '%取消%'
            and  b.sJc not like '%取消%' and b.sjylx='连锁门店' and b.smdlx   in ('大店A','大店B','小店','中店A','中店B')
            and b.dkyrq is not null and  (( c.sort>='20' and c.sort<'40') or (
        LEFT(c.sort,4) in ('1105','1307','1406') ))
        and LEFT(c.sort,4) not in ('2021','2103','2104','2105','2106','2201','2203','2204','2309','3903')
		  and   a.STOP_INTO='N' and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y'
        and a.character_type='N';

        -- Step 3:昨晚库存？ 有进价和售价的区分
        select left(a.sflbh,4) sdlbh,c.sflmc,sum(isnull(b.nKcje,0)) nkcje into #dlkc from #Base_sp a 
        left join #tmp_mdkc b on a.sfdbh=b.sfdbh and a.sspbh=b.sspbh
        left join  #Tmp_flb c on left(a.sflbh,4)=c.sflbh
        where 1=1 group by  left(a.sflbh,4)  ,c.sflmc ;

        -- 0330 修改
       with x0 as (
		select convert(date,SALE_DATE) drq,LEFT(b.sort,4) sdlbh, sum(isnull(a.SALE_COST,0)) nxscb 
        from DappSource_Dw.dbo.P_SALE_TOTAL_LIST_OUTPUT a 
		join #goods b on a.ITEM_CODE=b.code
        join #Base_sp c on a.SHOP_CODE=c.sFdbh and a.ITEM_CODE=c.sSpbh
		where    CONVERT(date,a.SALE_DATE)>=convert(date,getdate()-30)    and  CONVERT(date,a.SALE_DATE)<CONVERT(date,GETDATE())
		  group by  convert(date,a.SALE_DATE)  ,LEFT(b.sort,4)
		)
		,x1 as (
		select a.sdlbh,sum(nxscb)*1.0/30 nrjxscb from  x0 a  group by sdlbh)
		,x2 as (
		select distinct a.sflbh,a.sflmc from #Tmp_flb a  
		where 1=1 and (( a.sflbh>='20' and a.sflbh<'40') or (
        LEFT(a.sflbh,4) in ('1105','1307','1406') ))
        and LEFT(a.sflbh,4) not in ('2021','2103','2104','2105','2106','2201','2203','2204','2309','3903')
		) 
		,x3 as (select distinct b.sflbh,b.sflmc from  x2 a 
		join #Tmp_flb b on left(a.sflbh,4)=b.sflbh
		where  len(b.sflbh)=4) 
		select a.sflbh,a.sflmc,b.nkcje,c.nrjxscb, case when c.nrjxscb=0 then 50
		else b.nkcje*1.0/c.nrjxscb end nbbzzts into #3 from x3 a 
		left join #dlkc b on a.sflbh=b.sdlbh
		left join x1 c on a.sflbh=c.sdlbh
		where 1=1  order by 1;

		delete from DappSource_Dw.dbo.Tmp_sort_standard where drq=CONVERT(date,getdate());
        insert into DappSource_Dw.dbo.Tmp_sort_standard(drq,sFlbh,sFlmc,nkcje,nrjxscb,nPlzzts)
		select CONVERT(date,GETDATE()) drq,sflbh,sflmc,nkcje,nrjxscb ,ceiling(isnull(nbbzzts,55)) from #3;
END
