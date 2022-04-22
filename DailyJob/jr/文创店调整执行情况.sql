/*
  门店商品调整后落实情况核查-通用版
  适用范围  门店一次性大范围调整及 部分商品推荐的落实
    新品进入：状态开通-无库存，已经引进-状态开通且有库存，未执行-状态未开
    淘汰单品：未执行-状态正常，执行-状态商品状态关闭

*/
-- Step 1: 取建议数据
select  分店编号 sFdbh,分店名称 sFdmc,商品编号 sSpbh,商品名称 sSpmc,建议 sJyl
 into #1  from dbo.Tmp_Md_Sptz  where 建议<>'停购淘汰';

-- Step 2:库存数据
select a.*,b.STOP_INTO,b.STOP_SALE,b.VALIDATE_FLAG,b.CHARACTER_TYPE,
b.c_introduce_date,b.ITEM_ETAGERE_CODE,c.CURR_STOCK nKcsl into #2   from #1 a 
left join Dappsource_DW.dbo.P_SHOP_ITEM_OUTPUT b on a.sfdbh=b.DEPT_CODE 
and a.sspbh=b.ITEM_CODE
left join DappSource_Dw.dbo.V_D_PRICE_AND_STOCK c on a.sFdbh=c.STORE_CODE and a.sSpbh=c.ITEM_CODE
where 1=1 ;

-- 部分专柜商品不开通
-- 22060171,22060174,23012425,07021299,32011103,24041721,32020231,25030491,22020139,23021839,24042021,25041288,25022494,25041284,23050235,58010218,31060346,24041716,24041714,25041419,24042201,24060132,30010355,25041418,23060205,23060003,24060028,57020538,06010363,23060206,24060036,75060219,06010102,06010103,06010407,24060034,23060029,06010300,06010329,24042018,30010354,46010094,24042017,
-- Step 3: 评估执行
/*
建议淘汰
停购淘汰
现有商品规划淘汰
建议引进
*/
select a.*,
case   
	when a.sJyl='建议引进'  then case  when  a.CHARACTER_TYPE='Y' then '转联营'
      when a.STOP_INTO='N' and a.stop_sale='N' and a.CHARACTER_TYPE='N' and a.VALIDATE_FLAG='Y'  then '已执行'
      when a.STOP_INTO<>'N' or a.stop_sale<>'N' or a.CHARACTER_TYPE<>'N' or a.VALIDATE_FLAG<>'Y' 
      then '未执行' when a.stop_into is null then '未执行' 
       end 
  when a.sJyl not in ('建议引进') then 
     case when a.STOP_INTO='Y' or a.stop_into is null   then '已执行' else '未执行'     end
  end ssfzx into #3  
  
 from #2  a  where  1=1;

 select a.* ,
 case when  a.ssfzx='已执行' then case when  a.sJyl='建议引进' and isnull(a.nkcsl,0)>0 then '已进门店'
      when a.sJyl='建议引进' and isnull(a.nkcsl,0)<=0 then '开通未配货'
      when a.sJyl not in ('建议引进')  and isnull(a.nkcsl,0)>0 then '已停购有库存'
      when a.sJyl not in ('建议引进')  and isnull(a.nkcsl,0)<=0 then '清退完成'    end 
  when  a.ssfzx='未执行' then  case 
    when a.sJyl='建议引进' and isnull(a.nkcsl,0)>0 then '未开通有库存'
    when a.sJyl='建议引进' and a.stop_into is not null then '资料未修改'
    when a.sJyl='建议引进' and a.stop_into is null  then '无门店商品资料'
    when a.sJyl not in ('建议引进')  and isnull(a.nkcsl,0)>0   then  '未停购有库存'
    when a.sJyl not in ('建议引进')  and isnull(a.nkcsl,0)<=0   then  '未停购无库存'   
     end
      when a.ssfzx='转联营' then '转联营'
end  sflag1 from #3 a 