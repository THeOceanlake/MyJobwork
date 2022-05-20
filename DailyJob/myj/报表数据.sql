declare @begintime datetime
declare @endtime    datetime
select @begintime='#Bdate#',@endtime='#Edate#'
SET @endtime = CONVERT(VARCHAR(10),  @endtime, 120) + ' ' + '23:59:59'
----销售(总销售额)
select drq,SUM(isnull(nxsje,0)) zxsje,count(distinct a.sfdbh) fds into #zxs from tmp_xsb_db a,tmp_fdb b 
  where a.sfdbh=b.sfdbh and a.drq>=@begintime and a.drq<=@endtime
#Params# 
group by a.drq

----报损(总报损量、总报损额)
select  drq,sum(-nbssl) bsl,sum(-nbssl*njj) bsje into #zbs 
from   tmp_xsb_db a,tmp_fdb b 
where a.sfdbh=b.sfdbh and a.drq>=@begintime and a.drq<= @endtime
#Params# 
group by a.drq

----入库(总入库量、总入库额)
select drq,sum(nrksl) rkl,sum(nrksl*njj) rkje into #zrk
from tmp_xsb_db a,tmp_fdb b 
where a.sfdbh=b.sfdbh and a.drq>=@begintime and a.drq<= @endtime
#Params# 
group by a.drq

----退货(总退货量、总退货额)
select drq,sum(-nthsl) thl,sum(-nthsl*njj) thje into #zth 
from tmp_xsb_db a,tmp_fdb b 
where a.sfdbh=b.sfdbh and a.drq>=@begintime and a.drq<= @endtime
#Params# 
group by a.drq

----要货
select a.drq, sum(nyhsl) as nyhsl,sum(nyhsl*nJj) as nyhje  into #zyh 
from tmp_xsb_db a,tmp_fdb b 
where a.sfdbh=b.sfdbh and a.drq>=@begintime and a.drq<= @endtime
#Params# 
group by a.drq

----缺货(总缺货损失额)
select t.drq,SUM(nrjxje) qhsje into #zqh from (
select a.drq,a.sFdbh,a.sspbh,a.nkc,a.nrjxje from tmp_xsb_db a,tmp_fdb b 
where a.sfdbh=b.sfdbh and isnull(a.nkc,0)<=0  and a.drq>=@begintime and a.drq<= @endtime
#Params#
)t   group by t.drq


----周转(总资金占用、周转天数)
select a.drq,sum(isnull(case when nkc<0 then 0 else nkc end ,0)*njj) nkcje 
,case when  sum(nrjxje)=0 then null  else  sum(isnull(case when nkc<0 then 0 else nkc end,0)*njj)/sum(nrjxje)  end zzts ,sum(nrjxje) nrjxje
into #zzz
from tmp_xsb_db a,tmp_fdb b 
where a.sfdbh=b.sfdbh and a.drq>=@begintime and a.drq<= @endtime
#Params#
group by drq


---总人工干预率
select t2.drq,isnull(t1.gys,0)*1.0/t2.sps gyl into #zgy from (
select convert(varchar(8),dRq,112) drq,count(a.sspbh) gys  from Output_Mdyh_All a,tmp_fdb b,tmp_spb_all c
where a.sfdbh=b.sfdbh and a.sspbh=c.sspbh  and nsl>0 and nSjsl is not null   and nSl<>nsjsl   and  a.drq>=@begintime and a.drq<= @endtime
#Params# 
group by convert(varchar(8),dRq,112))t1
right join
(select convert(varchar(8),dRq,112) drq,count(a.sspbh) sps from Output_Mdyh_All a,tmp_fdb b,tmp_spb_all c
where a.sfdbh=b.sfdbh and a.sspbh=c.sspbh and nsl>0 and nSjsl is not null  and  a.drq>=@begintime and a.drq<= @endtime
#Params#
group by convert(varchar(8),dRq,112))t2 
on t1.drq=t2.drq order by 1

--汇总
select a.drq 日期,a.zxsje 销售额,a.fds 分店数,b.bsje 报损额,h.nyhje 要货额,g.rkje 进货额,c.thje 退货额,
c.thje/g.rkje 退货率,
d.qhsje 缺货损失额,d.qhsje/e.nrjxje 缺货损失率,e.nkcje 资金占用,
e.zzts 周转天数,f.gyl 人工干预率 from #zxs a 
left join #zbs b on a.drq=b.drq
left join #zth c on a.drq=c.drq 
left join #zqh d on a.drq=d.drq 
left join #zzz e on a.drq=e.drq 
left join #zgy f on a.drq=f.drq
left join #zrk g on a.drq=g.drq
left join #zyh h on a.drq=h.drq
where 1=1 
order by 1




---每日任务执行 tmp_xsb_db：日期、门店、商品、销量、销售额、最近7天日均销量
delete from tmp_xsb_db where drq>=convert(varchar(8),GETDATE()-3,112)

insert into tmp_xsb_db(drq,sfdbh,sspbh,njj,sfl,nxssl,nxsje)
select t1.drq,t1.sfdbh,t1.sspbh,max(njj) njj,max(sfl) sfl,sum(isnull(nxssl,0)) nxssl,
sum(isnull(nxsje,0)) nxsje from 
(
select a.drq,b.* from 
(select distinct left(sjcbh,8) drq from tmp_jcb where left(sjcbh,8)>=convert(varchar(8),GETDATE()-3,112)) a,
(select a.sfdbh,b.sfl,a.sspbh,b.njj from sys_goodsconfig a,tmp_spb_all b where a.sspbh=b.sspbh and a.ssfkj='1'
and a.sfdbh in (select sfdbh from tmp_fdb where (binglang_state=1 or hongbei_state=1 or lengcang_state=1)
 and ssfph=1)) b
)t1
left join tmp_xsnrb t2 
on t1.drq=left(t2.sxsdh,8) and t1.sfdbh=t2.sfdbh and t1.sspbh=t2.sspbh group by t1.drq,t1.sfdbh,t1.sspbh

update tmp_xsb_db set nrjxl=b.nrjxl_7 from tmp_xsb_db a,(
select a.drq,a.sfdbh,a.sspbh,sum(b.nxssl)/7 nrjxl_7 from tmp_xsb_db a,tmp_xsb_db b where a.sFdbh=b.sfdbh and a.sspbh=b.sspbh 
and a.drq>=convert(varchar(8),GETDATE()-3,112) and b.drq>=convert(datetime,a.drq)-6 and b.drq<=convert(datetime,a.drq) 
group by a.drq,a.sfdbh,a.sspbh) b where a.drq=b.drq and a.sFdbh=b.sfdbh and a.sspbh=b.sspbh 

update tmp_xsb_db set nrjxje=b.nrjxje_7 from tmp_xsb_db a,(
select a.drq,a.sfdbh,a.sspbh,sum(b.nxsje)/7 nrjxje_7 from tmp_xsb_db a,tmp_xsb_db b where a.sFdbh=b.sfdbh and a.sspbh=b.sspbh 
and a.drq>=convert(varchar(8),GETDATE()-3,112) and b.drq>=convert(datetime,a.drq)-6 and b.drq<=convert(datetime,a.drq) 
group by a.drq,a.sfdbh,a.sspbh) b where a.drq=b.drq and a.sFdbh=b.sfdbh and a.sspbh=b.sspbh 

---入库
update tmp_xsb_db set nrksl=b.nrksl from tmp_xsb_db a,(
select convert(varchar(8),a.dsj,112) drq,b.sfdbh,b.sspbh,sum(b.nsl)  as nrksl
from tmp_jcb a,tmp_jcmxb b,sys_goodsconfig c,Purchase_jcflbzb e
where a.sJcbh=b.sJcbh and b.sfdbh=c.sfdbh and a.sfdbh=c.sfdbh and b.sspbh=c.sspbh  
and a.sjcfl=e.fl_content and e.fl_bzname='进出(配入)' and c.ssfkj='1'
and a.dsj>=CONVERT(datetime,convert(varchar(8),GETDATE(),112))-3
group by convert(varchar(8),a.dsj,112),b.sfdbh,b.sspbh) b where a.drq=b.drq and a.sFdbh=b.sfdbh and a.sspbh=b.sspbh 

---报损
update tmp_xsb_db set nbssl=b.nbssl from tmp_xsb_db a,(
select convert(varchar(8),a.dsj,112) drq,b.sfdbh,b.sspbh,sum(b.nsl) as nbssl
from tmp_jcb a,tmp_jcmxb b,sys_goodsconfig c
where a.sJcbh=b.sJcbh and b.sfdbh=c.sfdbh and a.sfdbh=c.sfdbh and b.sspbh=c.sspbh 
and  a.sjcfl='损耗单'  and c.ssfkj='1'
and a.dsj>=CONVERT(datetime,convert(varchar(8),GETDATE(),112))-3
group by convert(varchar(8),a.dsj,112),b.sfdbh,b.sspbh) b 
where a.drq=b.drq and a.sFdbh=b.sfdbh and a.sspbh=b.sspbh

---退厂
update tmp_xsb_db set nthsl=b.nthsl from tmp_xsb_db a,(
select convert(varchar(8),a.dsj,112) drq,b.sfdbh,b.sspbh,sum(b.nsl)  as nthsl
from tmp_jcb a,tmp_jcmxb b,sys_goodsconfig c,Purchase_jcflbzb e
where a.sJcbh=b.sJcbh and b.sfdbh=c.sfdbh and a.sFdbh=c.sFdbh  and b.sspbh=c.sspbh 
and a.sjcfl=e.fl_content and e.fl_bzname='进出(退厂)' and c.ssfkj='1'
and a.dsj>=CONVERT(datetime,convert(varchar(8),GETDATE(),112))-3
group by convert(varchar(8),a.dsj,112),b.sfdbh,b.sspbh) b where a.drq=b.drq and a.sFdbh=b.sfdbh and a.sspbh=b.sspbh

---要货
update tmp_xsb_db set nyhsl=b.nyhsl from tmp_xsb_db a,(
select convert(varchar(8),a.dDhrq,112) drq,b.sfdbh,b.sspbh,sum(b.nsl)  as nyhsl
from Purchase_DeliveryReceipt a,Purchase_DeliveryReceipt_Items b,sys_goodsconfig c
where a.sDh=b.sDh and b.sfdbh=c.sfdbh and a.sFdbh=c.sFdbh and b.sspbh=c.sspbh
and c.ssfkj='1' and nsl>0
and a.dDhrq>=CONVERT(datetime,convert(varchar(8),GETDATE(),112))-3
group by convert(varchar(8),a.dDhrq,112),b.sfdbh,b.sspbh) b where a.drq=b.drq and a.sFdbh=b.sfdbh and a.sspbh=b.sspbh

update tmp_xsb_db set nkc=b.nsl from tmp_xsb_db a,tmp_kclsb b where a.sFdbh=b.sfdbh and a.sspbh=b.sspbh and a.drq=convert(varchar(8),b.drq,112)
and a.drq>=convert(varchar(8),GETDATE()-3,112)


