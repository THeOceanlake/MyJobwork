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
         
        --采购单 
        select dCgrq,sSpbh,nCgsl into #sPCgmx  
        from Tmp_Cgddmx_dc 
        where dCgrq>=@beginSj and dCgrq<=@EndSj --and 商品代码=@sSpbh 
         
        select LEFT(convert(varchar(10),dCgrq,112),10) as 采购日期,sSpbh as 商品代码,SUM(nCgsl)as 采购数量 into #spCgmx_Day  
        from #sPCgmx  group by LEFT(convert(varchar(10),dCgrq,112),10),sSpbh 
         
        --select a.Sj,ISNULL(商品代码,@sSpbh)as 商品代码,ISNULL(采购数量,0)as 采购数量  into #Cg 
        --from  #Rqb a left join #spCgmx_Day b on a.Sj=b.采购日期 
         
          
        --到货单 
        select isnull(dDhrq,dzhdhrq) dDhrq,sSpbh,nDhsl into #spDhMx  
        from Tmp_Cgddmx_dc 
        where isnull(dDhrq,dzhdhrq)>=@beginSj and isnull(dDhrq,dzhdhrq)<=@EndSj --and 商品代码=@sSpbh 
         
        select LEFT(convert(varchar(10),dDhrq,112),10) as 收货日期,sSpbh as 商品代码,SUM(nDhsl)as 到货数量 into #spDhMx_Day  
        from #spDhMx  group by LEFT(convert(varchar(10),dDhrq,112),10),sSpbh 
         
        --select a.Sj,ISNULL(b.商品代码,a.商品代码)as 商品代码,采购数量,ISNULL(到货数量,0)as 到货数量 into #CgDh 
        --from  #Cg a left join #spDhMx_Day b on a.Sj=b.收货日期 
          
        --进出单 
        select a.dsj,a.sSpbh,a.nSl into #Jhmxb   
        from tmp_jcmxb_dc a left join  tmp_spb_Dc b on a.sSpbh=b.sSpbh 
        left join Purchase_Djlxb c on  a.sjcfl=c.单据类型  
        where a.sSpbh=b.sSpbh and a.dsj>=@beginSj and a.dsj<=@EndSj and c.匹配类型='进出' --and a.商品代码=@sSpbh  
         
        select LEFT(convert(varchar(10),dsj,112),10) as 进出日期,sSpbh as 商品代码,SUM(nsl)as 进货数量  into #spJcMx_Day 
        from #Jhmxb  group by LEFT(convert(varchar(10),dsj,112),10),sSpbh 
         
          
        --调拨单 
        select a.dsj,a.sSpbh,a.nsl into #Dbmxb   
        from tmp_jcmxb_dc a left join tmp_spb_Dc b on a.sSpbh=b.sSpbh 
        left join Purchase_Djlxb c on  a.sjcfl=c.单据类型  
        where a.sSpbh=b.sSpbh and a.dsj>=@beginSj and a.dsj<=@EndSj and c.匹配类型 ='调拨' --and a.商品代码=@sSpbh  
         
        select LEFT(convert(varchar(10),dsj,112),10) as 调拨日期,sSpbh as 商品代码,SUM(nsl)as 调拨数量  into #spDbMx_Day 
        from #Dbmxb  group by LEFT(convert(varchar(10),dsj,112),10),sSpbh 
         
         
        --盘点单 
        select a.dsj,a.sSpbh,a.nsl into #pdmxb   
        from tmp_jcmxb_dc a left join tmp_spb_Dc b on a.sSpbh=b.sSpbh 
        left join Purchase_Djlxb c on  a.sjcfl=c.单据类型  
        where a.sSpbh=b.sSpbh and  a.dsj>=@beginSj and a.dsj<=@EndSj and c.匹配类型 in ('盘点','损溢') --and a.商品代码=@sSpbh  
         
        select LEFT(convert(varchar(10),dsj,112),10) as 盘点日期,sSpbh as 商品代码,SUM(nsl)as 盘点数量  into #spPdMx_Day 
        from #pdmxb  group by LEFT(convert(varchar(10),dsj,112),10),sSpbh 
         
        --配送单 

        select a.dsj,a.sSpbh,a.nsl  into #Psmxb   
        from tmp_jcmxb_dc a left join tmp_spb_Dc b on a.sSpbh=b.sSpbh 
        left join Purchase_Djlxb c on  a.sjcfl=c.单据类型  
        where a.sSpbh=b.sSpbh and a.dsj>=@beginSj and a.dsj<=@EndSj and c.匹配类型 ='出货'  --and a.商品代码=@sSpbh  

        select LEFT(convert(varchar(10),dsj,112),10) as 配送日期,sSpbh as 商品代码,SUM(nsl) as 配送数量  into #spPsMx_Day 
        from #Psmxb  group by LEFT(convert(varchar(10),dsj,112),10),sSpbh 
         
         
        --要货单 
        		 

        select a.dYhrq,b.sSpbh,b.nYhsl into #yhmxb  
        from tmp_yh a left join tmp_yhmx b on a.sdh = b.sdh and a.sFdbh = b.sFdbh where 
        dYhrq>=@beginSj and dYhrq<=@EndSj 
          
        select LEFT(convert(varchar(10),dYhrq,112),10) as 要货日期,sSpbh as 商品代码,SUM(nYhsl)as 要货数量  into #yhmxb_Day 
        from #yhmxb  group by LEFT(convert(varchar(10),dYhrq,112),10),sSpbh 
         
        --总商品单 
        select sSpbh as 商品代码,sSpmc as 商品名称 into #Spb from  tmp_spb_Dc  
         
        --库存单 
        select  a.sRq as 日期,a.sSpbh as 商品代码,a.nSl as 库存数量 into #Kcb   
        from  Tmp_dckcbls a left join tmp_spb_Dc b  
        on a.sSpbh=b.sSpbh 
        where a.sSpbh=b.sSpbh and a.sRq>=@beginSj and a.sRq<=@EndSj --and a.商品代码=@sSpbh  
          
        select * into #SpRq from #Rqb ,#Spb  
         
         
        delete a from  Purchase_CJYPB  a ,#SpRq b where  a.商品代码=b.商品代码 and a.日期=b.Sj 
               
        insert into Purchase_CJYPB (日期,商品代码,采购数量,进货数量,到货数量,调拨数量,盘点数量,要货数量,配送数量,库存数量) 
        select a.Sj,a.商品代码 , isnull(b.采购数量,0)as 采购数量,ISNULL(到货数量,0)as 到货数量, 
                      ISNULL(进货数量,0) as 进货数量,ISNULL(调拨数量,0) as 调拨数量,ISNULL(盘点数量,0) as 盘点数量, 
                      ISNULL(要货数量,0)as 要货数量,isnull(0-配送数量,0)as 配送数量,库存数量 from #SpRq a  
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
         update a set a.日均出货量3=b.nRjxl_30,a.日均出货量4=b.nRjxl ,a.下限4= b.nZdkcts_jy*b.nRjxl , a.上限4= b.nZgkcts_jy*b.nRjxl   from Purchase_CJYPB a left join Purchase_spb  b  
         on a.日期= convert(datetime,left(b.sBh,8)) and a.商品代码=b.sSpbh where    b.sSpbh is not null   and a.日期>=@beginSj 
          
         update a set a.日均出货量3=b.nRjxl_30,a.日均出货量4=b.nRjxl,a.下限4= b.nZdkcts_jy*b.nRjxl , a.上限4= b.nZgkcts_jy*b.nRjxl   from Purchase_CJYPB a left join Purchase_Spb_History   b  
         on a.日期= convert(datetime,left(b.sBh,8)) and a.商品代码=b.sSpbh where    b.sSpbh is not null and a.日期>=@beginSj 
        Sql = Sql + vbCrLf + -------------------------------------------------- 周转天数   
         update a set a.周转天数=case when 日均出货量4<>0 then (select  sum(库存数量)/30  from Purchase_CJYPB  
         where 日期 <= a.日期 and 日期>a.日期-30 and 商品代码 =a.商品代码)/日均出货量4 else null end  from Purchase_CJYPB a 
         where 日期>=@beginSj 