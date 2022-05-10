		--确定开始时间结束时间(每次重新取前七天) 
        declare @beginSj datetime 
        declare @EndSj datetime 
         
        set @beginSj =  convert(varchar(10),GETDATE()-7,23)  
        set @EndSj =  convert(varchar(10),GETDATE(),23)  
          
        -- 建立时间表 
        create table #Rqb( Sj datetime)   
         
        declare @Sj datetime 
        set @Sj = @beginSj 
        while @Sj<@EndSj 
        begin 
        insert into #Rqb 
        select @Sj 
        set @Sj=@Sj+1 
        end 
         select * from #Rqb
        --采购单 
		select a.ddhrq dCgrq,a.sshrq,a.sgys,b.sspbh,b.nsl,b.ndhsl 
		into  #sPCgmx  from [122.147.10.200].DAppSource.dbo.tmp_cgdd a
		,[122.147.10.200].dappsource.dbo.tmp_cgddmx b where a.sdh=b.sdh
		 and a.sfdbh='015901' and a.ddhrq>=@beginSj
		 and a.ddhrq<=@EndSj  ;

      
        select LEFT(convert(varchar(10),dCgrq,112),10) as 采购日期,sSpbh as 商品代码,SUM(nsl)as 采购数量 into #spCgmx_Day  
        from #sPCgmx  group by LEFT(convert(varchar(10),dCgrq,112),10),sSpbh 
         
          
        --到货单 
    
        select LEFT(convert(varchar(10),sshrq,112),10) as 收货日期,sSpbh as 商品代码,SUM(nDhsl)as 到货数量 into #spDhMx_Day  
        from #sPCgmx  group by LEFT(convert(varchar(10),sshrq,112),10),sSpbh 
         
        --select a.Sj,ISNULL(b.商品代码,a.商品代码)as 商品代码,采购数量,ISNULL(到货数量,0)as 到货数量 into #CgDh 
        --from  #Cg a left join #spDhMx_Day b on a.Sj=b.收货日期 
          
        --进出单 
		select a.dsj,a.sfdbh,a.sjcfl,b.sspbh,b.nsl,b.njj,b.nsl*b.njj nje into #jcb
		from [122.147.10.200].DAppSource.dbo.tmp_jcb a,
			[122.147.10.200].DAppSource.dbo.tmp_jcmxb b  where a.sjcbh=b.sjcbh 
		and  a.sfdbh=b.sfdbh and a.sfdbh='015901'  and  a.dsj>=@beginSj
		and a.dsj<=@EndSj;

 
         
        select LEFT(convert(varchar(10),dsj,112),10) as 进出日期,sSpbh as 商品代码,SUM(nsl)as 进货数量  into #spJcMx_Day 
        from #jcb where sjcfl in ('入库','入库赠品','返厂','退配')  group by LEFT(convert(varchar(10),dsj,112),10),sSpbh 
         
        --调拨单 
        select LEFT(convert(varchar(10),dsj,112),10) as 调拨日期,sSpbh as 商品代码,SUM(nsl)as 调拨数量  into #spDbMx_Day 
        from #jcb where sjcfl in ('调出','调出赠品')  group by LEFT(convert(varchar(10),dsj,112),10),sSpbh 
         
         
        --盘点单 
      
        select LEFT(convert(varchar(10),dsj,112),10) as 盘点日期,sSpbh as 商品代码,SUM(nsl)as 盘点数量  into #spPdMx_Day 
        from #jcb where sjcfl in ('损溢')  group by LEFT(convert(varchar(10),dsj,112),10),sSpbh 
         
        --配送单 
 
        select LEFT(convert(varchar(10),dsj,112),10) as 配送日期,sSpbh as 商品代码,SUM(nsl) as 配送数量  into #spPsMx_Day 
        from #jcb  where sjcfl in ('配送','批发')  group by LEFT(convert(varchar(10),dsj,112),10),sSpbh 
         
         
        --要货单 
        select a.dYhrq,b.ddhrq dShrq,a. sdjlx sLx,b.sfdbh,b.sspbh,b.nsl nYhsl,b.ndhsl into #Tmp_yh
		from [122.147.10.200].dappsource.dbo.tmp_yhb a 
		inner join [122.147.10.200].dappsource.dbo.tmp_yhmx b
		on a.sdh=b.sdh and a.sFdbh=b.sFdbh
		where 1=1    and a.dYhrq>=@beginSj
		and   a.dYhrq<=@EndSj ;

          
        select LEFT(convert(varchar(10),dYhrq,112),10) as 要货日期,sSpbh as 商品代码,SUM(nYhsl)as 要货数量  into #yhmxb_Day 
        from #Tmp_yh  group by LEFT(convert(varchar(10),dYhrq,112),10),sSpbh 
         
        --总商品单 
    
        select *  into #T_tihi from  [122.147.10.200].DAppSource.dbo.T_TiHi ;
		select *  into #Goods from  [122.147.10.200].DAppSource.dbo.goods ;
		
		select  a.code  as 商品代码,a.name  as 商品名称 into #Spb  from #Goods a
		join #T_tihi b on a.code=b.SIZE_DESC
		where a.alc='配送' and   (( a.sort>'20' and a.sort<'40') or (
		 LEFT(a.sort,4) in ('1105','1307','1406') )) and LEFT(a.sort,4)<>'2201'  ;
        --库存单 
        select  a.dRq as 日期,a.sSpbh as 商品代码,a.nkcSl as 库存数量 into #Kcb   
        from [122.147.160.31].dappsource_Dw.dbo.Tmp_Kclsb a 
        where a.sfdbh='015901' and a.dRq>=@beginSj
		 and a.dRq<=@EndSj;  
          
        select * into #SpRq from #Rqb ,#Spb  
         
        delete a from  Purchase_CJYPB  a ,#SpRq b where  a.商品代码=b.商品代码 and a.日期=b.Sj 
               
        insert into Purchase_CJYPB (日期,商品代码,采购数量,进货数量,到货数量,调拨数量,盘点数量,要货数量,配送数量,库存数量) 
        select a.Sj,a.商品代码 , isnull(b.采购数量,0)as 采购数量,ISNULL(到货数量,0)as 到货数量, 
                      ISNULL(进货数量,0) as 进货数量,ISNULL(调拨数量,0) as 调拨数量,ISNULL(盘点数量,0) as 盘点数量, 
                      ISNULL(要货数量,0)as 要货数量,isnull(0-配送数量,0)as 配送数量,isnull(库存数量,0) from #SpRq a  
                      left join #spCgmx_Day b on a.Sj=b.采购日期 and a.商品代码=b.商品代码 
                      left join #spDhMx_Day c on a.Sj=c.收货日期 and a.商品代码=c.商品代码 
                      left join #spJcMx_Day d on a.Sj=d.进出日期 and a.商品代码=d.商品代码 
                      left join #yhmxb_Day e on a.Sj=e.要货日期 and a.商品代码=e.商品代码 
                      left join #spPsMx_Day f on a.Sj=f.配送日期 and a.商品代码=f.商品代码 
                      left join #Kcb g on a.Sj=g.日期 and a.商品代码=g.商品代码   
                      left join #spDbMx_Day h on a.Sj=h.调拨日期 and a.商品代码=h.商品代码 
                      left join #spPdMx_Day i on a.Sj=i.盘点日期 and a.商品代码=i.商品代码    
          
        ------------------------------------------------- 移动平均 
         --------------------------------------- 30天移动平均 除去库存为0也没有配送数量的天数（当库存数量不满足一个包装数且无配送 跳过这一天）,限制了最大为1.6倍 
        
		  select * into #Purchase_Spb_History from [122.147.10.200].DAppSource.dbo.Sys_PurchaseSet_History 
		  where  CONVERT(date,srq)>=CONVERT(date,GETDATE()-30);
		 
		 update a set a.日均出货量3=b.nYcrjxl_De,a.日均出货量4=b.nYcrjxl_De ,a.下限4= b.nXx , a.上限4= b.nsx  
		  from Purchase_CJYPB a   join #Purchase_Spb_History  b   on a.日期= convert(datetime,b.srq) and a.商品代码=b.sSpbh
		  where 1=1 and a.日期>=@beginSj 
       
        Sql = Sql + vbCrLf + -------------------------------------------------- 周转天数   
         update a set a.周转天数=case when 日均出货量4<>0 then (select  sum(库存数量)/30  from Purchase_CJYPB  
         where 日期 <= a.日期 and 日期>a.日期-30 and 商品代码 =a.商品代码)/日均出货量4 else null end  from Purchase_CJYPB a 
         where 日期>=@beginSj 
		  
		   