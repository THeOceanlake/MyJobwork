/* 
    当前处理批次的跟踪
    每批次，分阶段，每10天的情况-累计情况：销售额、回本率、完成率（品种数的清退）、库存处理进度
*/
select * from DAppResult.dbo.Tmp_FDB d where 1=1 
and d.sfdlx   in ('大店A','大店B','小店','中店A','中店B')
    and d.sJc not like '%取消%' and d.dKyrq is not null
  and d.sJylx='连锁门店'-- 78家