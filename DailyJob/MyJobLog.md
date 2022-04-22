### 2022-04-06

1、KPI巡查

    1.1 嘉荣本期KPI

    周转天数 ：本期40天，环比上期下降1.2天；

    销售金额：小幅上升

    缺货损失率：3.2%，有下降趋势

    资金占用：小幅增加

2、嘉荣重点品类 功能

3、默认用户新增权限

```sql
insert into DApplication.dbo.Admin_UserTmp(ManageId,ManageName,MenuId)
select distinct a.ManageId,a.ManageName,b.MenuId  from ( select distinct ManageId,ManageName from  DApplication.dbo.Admin_UserTmp) a,
DApplication.dbo.Admin_Menu  b
where  b. MenuName in ('接口数据诊断')
```

4、嘉荣大库存处理

    现在有这么几件事

```txt
第一步 修正大库存类别标准，给出新的大库存商品
第二步 将这些单品用逆向物流处理一遍
第三步  余下的单品用其他方案处理
```

### 2022-04-07

一、嘉荣的大库存标准统一

    1、

    2、高库存定义：库存周转天数高于 品类公司平均水平，
非停购非停销，不剔除新品，21-39处级（除2201，2203，2204，2309，3903大类）
日配21,（除2101工业面包，2103低温奶，2104冷藏，2105冷冻，2106冷冻，）
生鲜: 只包含 1307冷冻肉类、1105蛋品、1406冷冻水产品类(只保留3大类)

### 2022-04-09

1、嘉荣大库存清理清单

2、嘉荣文创店规划数据更新

### 2022-04-11

1、文创店商品调整落实情况

    因JR执行工作还未实际展开，暂时搁置-代码准备

2、JR重点品类建模

    建一个对应关系表

3 模型有问题

```txt
1 即食禽肉干混合太多，2  310401 混合洗发和护发产品，需要分开

```

### 2022-04-12 星期二

case when isnull(#规格#,0)>0 then #价格带#/#规格# else 0 end

1、逆向物流数据

```sql
update a set a.sGysdhr=case when b.type is null then '' else '(' + b.type + ')' + isnull(b.wwwadr,'') end,a.sMdthr=isnull(b.shop_return_date,'') from BadStock_Goods a,vendor b where a.sgysbh=b.code 
```

#### 2022-04-18

1 嘉荣逆向物流参数设置

    1、调拨单 最低金额 500

    2  DC定额系数 从 2 倍 改成 3倍

    3 返仓再销售商品数100


### 2022-04-20

1、配送包装数过大解决方案

    1.1 拆零位

    1.2 动态拆零位

    1.3 4个试点门店集群
