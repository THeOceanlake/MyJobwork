/* 报表初始化*/
if  (select count(1) from Sysobjects where name in(UPPER('TMP_MDLKCYY')))=0
 begin
		CREATE TABLE [dbo].[TMP_MDLKCYY](
			[drq] [date] NOT NULL,-- 计算时间
			[sFdbh] [varchar](10) NOT NULL,--门店或分店的内部编号，不含DC编码
			[sSpbh] [varchar](13) NOT NULL,-- 商品的编码，一般只含D咨询计算范围内的商品
			[sSpmc] [varchar](100) NULL,  -- 商品的资料表名称
			[sFl] [varchar](8) NULL,      -- 商品归属分类的编码
			[nZdsl] [money] NULL,         -- 计算日当期的KPI建议下限，无建议的用零代替
			[nZgsl] [money] NULL,	-- 计算日当期的KPI建议上限，无建议的用零代替
			[sZdbh] [varchar](10) NULL,   -- 是否自动补货属性，为1表示商品的出单或定额调整是系统负责，0为人工负责
			[sSfkj] [varchar](10) NULL,   -- 是否可进属性，即表示商品的是否能正常采购，一般零库存范围内需要是正常采购商品，即此属性值为1
			[sPsfs] [varchar](10) NULL,   -- 商品的配送方式
			[syy] [varchar](20) NULL,     -- 产生零库存的原因，库存数量是取昨日期末库存或当日期初 库存，如能取实时库存最好
			[nRjxl] [money] NULL,         -- 门店的日均销售量
			[nRjxse] [money] NULL,        -- 门店单品的日均销售额
			[dzhyhrq] [date],
            [nsl] money,                         -- 当前库存
			primary key (drq,sfdbh,sspbh),
  
		)  ;
		create index mdlkcyy on [dbo].[TMP_MDLKCYY](syy);
		create index mdlkcdrq on [dbo].[TMP_MDLKCYY](drq);
  end;


 if  (select count(1) from Sysobjects where name in(UPPER('tmp_mdspzzyy')))=0
  begin 
	CREATE TABLE [dbo].[tmp_mdspzzyy](
			[drq] date NOT NULL,
			[sfdbh] [varchar](20) NOT NULL,
			[sspbh] [varchar](20) NOT NULL,
			[sspmc] [varchar](100) NULL,
			[sfl] [varchar](20) NULL,
			[sgys] [varchar](20) NULL,
			[njj] [money] NULL,
			[nsj] [money] NULL,
			[szdbh] [varchar](10) NULL,
			[spsfs] [varchar](10) NULL,
			[nrjxse] [money] NULL,
			[nrjxl] [money] NULL,
			[nkc] [money] NOT NULL,
			[nzzts] [numeric](19, 4) NULL,
			[npsbzs] [money] NULL,
			[nCgbzs] [money] null,
			[dzhdhr] [date] NULL,
			[dzhyhr] [date] NULL,
			[syy] [varchar](20) NULL,
			[sfwqzs] [varchar](10)  NULL,
			[nbzzzts] [int]  NULL,
			[sfcx] [varchar](10)  NULL,
			[nYhsl][money] Null,
			[nDhsl][money] Null,
            [sSource][varchar](100) NULL,
			Primary Key(drq,sfdbh,sSpbh) 
		) ;
                create index    Index_mdzzyy_date  on    tmp_mdspzzyy(drq);
                create index    Index_mdzzyy_all  on    tmp_mdspzzyy(drq,sfdbh,sspbh);
                create index    Index_mdzzyy_fdsp  on    tmp_mdspzzyy(sfdbh,sspbh);
  end;
-- DC零库存表
if  (select count(1) from Sysobjects where name in(UPPER('Tmp_Dclkcyy')))=0
  begin
	CREATE TABLE [dbo].[Tmp_Dclkcyy](
		[dRq] [date] NOT NULL,     -- 计算日期
		[sSpbh] [varchar](13) NOT NULL,-- 商品编号
		[sSpmc] [varchar](200) NULL, -- 商品名称
		[sFl] [varchar](10) NULL,   -- 分类编号
		[sFlmc] [varchar](50) NULL, -- 分类名称
		[nJj] [money] NULL,         -- 进货价
		[nSj] [money] NULL,         -- 零售价
		[nZdsl] [money] NULL,       -- 下限数量
		[nZgsl] [money] NULL,       -- 上限数量
		[nRjxl] [money] NULL,       -- DC配送范围内所有门店的日均销量总和
		[dzhYhr] [date] NULL,       -- 最后订货日
		[nCgsl] [money] NULL,       -- 采购数量
		[nDhsl] [money] NULL,       -- 到货数量
		[syy] [varchar](14) NOT NULL, -- 零库存原因
		[nKcsl] [money] NULL,         -- 
                [sSource][varchar](100) NULL,
		Primary Key(dRq,sSpbh)
	) ON [PRIMARY];
	end

-- DC周转原因
if  (select count(1) from Sysobjects where name in(UPPER('Tmp_dczzyy')))=0
  begin
		CREATE TABLE [dbo].[Tmp_dczzyy](
			[drq] [date] NOT NULL,
			[sSpbh] [varchar](50) NOT NULL,
			[sSpmc] [varchar](200) NULL,
			[sFl] [varchar](20) NULL,
			[sGys] [varchar](20) NULL,
			[nZdsl] [money] NULL,
			[nZgsl] [money] NULL,
			[nCgbzs] [money] NULL,
			[sPsfs] [varchar](10) NULL,
			[sZdbh] [varchar](10) NULL,
			[nkcsl] [money] NULL, -- 库存数量
			[nrjxl] [money] NULL, -- DC 配送范围内所有门店的日均销量总和
			[dYhrq] [date] NULL,-- 最后要货日期，即原因生效的要货日，如果最后一次是进出，则将进出单日期(空则和入库日当天一致)
			[dDhrq] [date] NULL,-- 最后到货日期,造成大库存的最后进货日
			[nCgsl] [money] NULL,
			[nDhsl] [money] NULL,
			[nzzts] [money] NULL,
			[syy] [varchar](50) NOT NULL,
			Primary Key(drq,sSpbh)
		) ON [PRIMARY]
	end
-- 门店销售表
if  (select count(1) from Sysobjects where name in(UPPER('Tmp_Mdxs_day')))=0
create table Tmp_Mdxs_day(drq date not null,sFdbh varchar(30) not null,nXsje money,nxssl money,nml money,primary key(drq,sFdbh)); 

--  分类排除表和商品排除表
if (select count(1) from Sysobjects where name in(UPPER('tmp_spb_ex')))=0
	CREATE TABLE [dbo].[tmp_spb_ex](
	[sSpbh] [varchar](20) NOT NULL,
	[sSpmc] [varchar](100) NULL,
       PRIMARY KEY   
(
	[sSpbh]  
) );


if (select count(1) from Sysobjects where name in(UPPER('tmp_spflb_ex')))=0
		CREATE TABLE [dbo].[Tmp_Spflb_Ex](
	[sFlbh] [varchar](10) NOT NULL,
PRIMARY KEY   
( [sFlbh] ASC ) 
)  