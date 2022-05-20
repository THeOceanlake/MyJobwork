insert into Tmp_yh(sFdbh,sdh,dAddrq,dYhrq,dShrq,sLx,sBz,dYxrq,dUpdateTime)
select distinct  a.sFdbh,a.sDh,a.dAddtime,a.dDhrq,Null,'点三三自动订货','',dateadd(day,1,a.dDhrq),GETDATE() from dbo.Purchase_DeliveryReceipt a 
,dbo.Purchase_DeliveryReceipt_Items b  where a.sDh=b.sDh
and a.sType='槟榔' and a.dDhrq>=CONVERT(date,'2022-05-06') and  a.sFdbh=b.sFdbh 
 ;


insert into tmp_yhmx(sFdbh,sdh,sspbh,nYhsl,nShsl,dUpdateTime)
select a.sFdbh,a.sDh,b.sSpbh,b.nsl,Null,GETDATE() from dbo.Purchase_DeliveryReceipt a 
,dbo.Purchase_DeliveryReceipt_Items b  where a.sDh=b.sDh
and a.sType='槟榔' and a.dDhrq>=CONVERT(date,'2022-05-06') and  a.sFdbh=b.sFdbh ;