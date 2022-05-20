USE [DappSource_Dw]
GO
/****** Object:  Table [dbo].[Admin_UserManage]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Admin_UserManage](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [varchar](50) NULL,
	[ManageID] [varchar](50) NULL,
	[Password] [varchar](50) NULL,
	[ManageName] [varchar](50) NULL,
	[Power_FL] [varchar](500) NULL,
	[Power_FDBH] [varchar](2000) NULL,
	[IsFlAdmin] [varchar](1) NULL,
	[IsProFlAdmin] [varchar](1) NULL,
	[IsRecFlAdmin] [varchar](1) NULL,
	[FlPower] [varchar](1) NULL,
	[ProFlPower] [varchar](1) NULL,
	[RecFlPower] [varchar](1) NULL,
	[GhsAdmin] [varchar](1) NULL,
	[PowerYT] [varchar](200) NULL,
	[PowerQY] [varchar](200) NULL,
	[DeptId] [varchar](50) NULL,
	[Job] [varchar](50) NULL,
	[RoleName] [varchar](2) NULL,
	[FDBH] [varchar](10) NULL,
	[Forbidden_FDBH] [varchar](2000) NULL,
	[Forbidden_FDBH_XD] [varchar](1000) NULL,
 CONSTRAINT [PK_Admin_UserManage] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Admin_UserShop]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Admin_UserShop](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [varchar](50) NULL,
	[ShopID] [varchar](10) NULL,
	[ShopName] [varchar](200) NULL,
	[ShopKind] [varchar](1) NULL,
	[Password] [varchar](50) NULL,
	[ConfigId] [int] NULL,
	[DbConfigId] [int] NULL,
	[sClpsr] [varchar](7) NULL,
	[RecBatch] [int] NULL,
	[sFdpsr] [varchar](7) NULL,
	[sLdpsr] [varchar](7) NULL,
	[sMdlx] [varchar](50) NULL,
	[sJylx] [varchar](20) NULL,
	[sSdpsr] [varchar](7) NULL,
 CONSTRAINT [PK_Admin_UserShop] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[goods]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[goods](
	[gid] [varchar](13) NULL,
	[code] [varchar](13) NOT NULL,
	[name] [varchar](60) NULL,
	[spec] [varchar](40) NULL,
	[sort] [varchar](16) NULL,
	[rtlprc] [money] NULL,
	[inprc] [money] NULL,
	[whsprc] [money] NULL,
	[wrh] [varchar](10) NULL,
	[munit] [varchar](10) NULL,
	[code2] [varchar](20) NULL,
	[qpc] [money] NULL,
	[alcqty] [money] NULL,
	[brand] [varchar](50) NULL,
	[billto] [varchar](10) NULL,
	[memo] [varchar](255) NULL,
	[validperiod] [int] NULL,
	[createdate] [datetime] NULL,
	[alc] [varchar](10) NULL,
	[mulwrh] [int] NULL,
	[isnormal] [varchar](20) NULL,
	[openstock] [varchar](2) NULL,
	[ntpbzl] [money] NULL,
	[syt] [varchar](20) NULL,
	[stop_into] [varchar](2) NULL,
	[stop_sale] [varchar](2) NULL,
	[ti] [money] NULL,
	[hi] [money] NULL,
	[if_handle_inventory] [varchar](20) NULL,
	[if_unite] [varchar](10) NULL,
	[packing_size] [varchar](30) NULL,
	[scgqy] [varchar](50) NULL,
	[LAST_CHANGE_DATE] [datetime] NULL,
	[RETURN_ATTRIBUTE] [varchar](25) NULL,
	[member_price] [money] NULL,
	[shop_dept] [varchar](20) NULL,
	[mid_packing_qty] [money] NULL,
	[packing_volume] [varchar](30) NULL,
	[Count_Class] [varchar](2) NULL,
	[shop_return_attribute] [varchar](2) NULL,
	[n_lv_price] [varchar](10) NULL,
	[n_lv_brand] [varchar](50) NULL,
	[n_free_brand] [varchar](20) NULL,
	[standard_attr] [varchar](50) NULL,
	[function_attr] [varchar](60) NULL,
	[structure_sku] [varchar](2) NULL,
 CONSTRAINT [PK__goods__1BFD2C07] PRIMARY KEY CLUSTERED 
(
	[code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[P_RETAIL_DETAIL_OUTPUT]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[P_RETAIL_DETAIL_OUTPUT](
	[SHOP_TYPE] [varchar](10) NOT NULL,
	[SHOP_CODE] [varchar](20) NOT NULL,
	[ID] [varchar](50) NOT NULL,
	[LINE] [varchar](10) NOT NULL,
	[BILLNO] [varchar](50) NOT NULL,
	[PCNO] [varchar](10) NOT NULL,
	[ITEM_CODE] [varchar](13) NOT NULL,
	[ITEM_NAME] [varchar](60) NULL,
	[ITEM_TYPE_CODE] [varchar](10) NULL,
	[QTY] [money] NULL,
	[UNIT_PRICE] [money] NULL,
	[SELL_PRICE] [money] NULL,
	[SHIFE] [varchar](10) NOT NULL,
	[SALE_DATE] [datetime] NOT NULL,
	[IF_UNISALE] [varchar](10) NULL,
	[DISCOUNT] [money] NULL,
	[PAYEE_CODE] [varchar](10) NULL,
	[SALES_TYPE] [varchar](20) NULL,
	[SUBTOTAL] [money] NULL,
	[DISCOUNT_RATE] [money] NULL,
	[CONSUME_CARD_CODE] [varchar](256) NULL,
	[MEMBER_CODE] [varchar](13) NULL,
	[DEPOSIT_CARD_CODE] [varchar](256) NULL,
	[CAUSE_DESC] [varchar](40) NULL,
	[BANK_CODE] [varchar](100) NULL,
	[BANK_CARD_CODE] [varchar](4000) NULL,
	[TICKET_CODE] [varchar](256) NULL,
	[COMB_ITEM_CODE] [varchar](30) NULL,
	[TICKET_DISCOUNT] [money] NULL,
	[BANK_DISCOUNT] [money] NULL,
	[SELL_DISCOUNT] [money] NULL,
	[DISCOUNT_TYPE] [varchar](10) NULL,
	[DISCOUNT_MONEY] [money] NULL,
	[GIFT_STAMP_SCORE] [money] NULL,
	[STAMP_NUM_ADD] [money] NULL,
	[CREATE_DATE_TIME] [datetime] NOT NULL,
	[RECEIVE_DATE_TIME] [datetime] NULL,
	[RECORD_STATUS] [varchar](10) NOT NULL,
	[INPUT_PRICE] [numeric](14, 4) NULL,
	[c_print_type] [varchar](50) NULL,
 CONSTRAINT [P_RETAIL_DETAIL_O_PK] PRIMARY KEY CLUSTERED 
(
	[ITEM_CODE] ASC,
	[SALE_DATE] ASC,
	[SHOP_CODE] ASC,
	[ID] ASC,
	[LINE] ASC,
	[BILLNO] ASC,
	[PCNO] ASC,
	[SHIFE] ASC,
	[SHOP_TYPE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[P_RETAIL_MASTER]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[P_RETAIL_MASTER](
	[shop_code] [varchar](20) NULL,
	[sale_date] [datetime] NULL,
	[pcno] [varchar](10) NULL,
	[id] [varchar](60) NULL,
	[total] [money] NULL,
	[npxs] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[P_RETAIL_MASTER_OUTPUT]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[P_RETAIL_MASTER_OUTPUT](
	[SHOP_TYPE] [varchar](10) NOT NULL,
	[SHOP_CODE] [varchar](20) NOT NULL,
	[ID] [varchar](50) NOT NULL,
	[BILLNO] [varchar](50) NOT NULL,
	[SALE_DATE] [datetime] NOT NULL,
	[PCNO] [varchar](10) NOT NULL,
	[SHIFE] [varchar](10) NOT NULL,
	[TOTAL] [money] NULL,
	[TOTAL_DISCOUNT] [money] NULL,
	[PAY_CASH] [money] NULL,
	[PAY_CUSTOMER_CARD] [money] NULL,
	[PAY_CREDIT_CARD] [money] NULL,
	[OTHER] [money] NULL,
	[PAYEE_CODE] [varchar](10) NULL,
	[RAST_money] [money] NULL,
	[MEMBER_CODE] [varchar](20) NULL,
	[CONSUME_CARD_CODE] [varchar](256) NULL,
	[PAY_CONSUME_CARD] [money] NULL,
	[PAY_DEPOSIT_CARD] [money] NULL,
	[DEPOSIT_CARD_CODE] [varchar](256) NULL,
	[BANK_CODE] [varchar](100) NULL,
	[PAY_SCORE_CARD] [money] NULL,
	[BANK_CARD_CODE] [varchar](8000) NULL,
	[TICKET_DISCOUNT] [money] NULL,
	[TICKET_CODE] [varchar](256) NULL,
	[BANK_DISCOUNT] [money] NULL,
	[SELL_DISCOUNT] [money] NULL,
	[PAY_MOBILE] [money] NULL,
	[PAY_MOBILE_2] [money] NULL,
	[PAY_MOBILE_3] [money] NULL,
	[ITEM_DISCOUNT] [money] NULL,
	[BILL_DISCOUNT] [money] NULL,
	[BARCODE_DISCOUNT] [money] NULL,
	[GIFT_STAMP_SCORE] [money] NULL,
	[GIFT_STAMP_QTY] [money] NULL,
	[STAMP_NUM_ADD] [money] NULL,
	[SALE_TIMES] [money] NULL,
	[CUSTOMER_TYPE] [varchar](20) NULL,
	[CREATE_DATE_TIME] [datetime] NOT NULL,
	[RECEIVE_DATE_TIME] [datetime] NULL,
	[RECORD_STATUS] [varchar](10) NOT NULL,
 CONSTRAINT [P_RETAIL_MASTER_O_PK] PRIMARY KEY CLUSTERED 
(
	[SALE_DATE] ASC,
	[SHOP_CODE] ASC,
	[BILLNO] ASC,
	[PCNO] ASC,
	[SHIFE] ASC,
	[ID] ASC,
	[SHOP_TYPE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[P_SALE_TOTAL_LIST_OUTPUT]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[P_SALE_TOTAL_LIST_OUTPUT](
	[SHOP_TYPE] [varchar](20) NULL,
	[ITEM_CODE] [varchar](20) NOT NULL,
	[SHOP_CODE] [varchar](10) NOT NULL,
	[SALE_REAL_QTY] [money] NULL,
	[SALE_REAL_AMOUNT] [money] NULL,
	[SALE_QTY] [money] NULL,
	[SALE_AMOUNT] [money] NULL,
	[SALE_DATE] [varchar](10) NOT NULL,
	[SALE_COST] [money] NULL,
	[SALE_AVERAGE_COST] [money] NULL,
	[CHALK_DATE] [varchar](10) NULL,
	[CREATE_DATE_TIME] [datetime] NULL,
	[RECEIVE_DATE_TIME] [datetime] NULL,
	[RECORD_STATUS] [varchar](10) NULL,
PRIMARY KEY CLUSTERED 
(
	[SHOP_CODE] ASC,
	[ITEM_CODE] ASC,
	[SALE_DATE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[p_shift_bill_ERP]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[p_shift_bill_ERP](
	[SHIFT_BILL_CODE] [nvarchar](20) NOT NULL,
	[BRANCH_CODE] [nvarchar](20) NULL,
	[REPAIR_BILL_CODE] [nvarchar](20) NOT NULL,
	[MAKE_DATE] [datetime] NULL,
	[AUDIT_DATE] [datetime] NULL,
	[SHIFT_COMMENT] [nvarchar](300) NULL,
	[STATUS] [nvarchar](10) NULL,
	[SHOP_AUDIT_DATE] [datetime] NULL,
	[ITEM_CODE] [nvarchar](13) NOT NULL,
	[SHIFT_PRICE] [numeric](14, 4) NULL,
	[SHOP_SHIFT_QTY] [numeric](12, 2) NULL,
	[INPUT_PRICE] [numeric](14, 4) NULL,
 CONSTRAINT [PK__p_shift___1140614B2591068B] PRIMARY KEY CLUSTERED 
(
	[SHIFT_BILL_CODE] ASC,
	[REPAIR_BILL_CODE] ASC,
	[ITEM_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[p_shift_bill_ERP_bak]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[p_shift_bill_ERP_bak](
	[SHIFT_BILL_CODE] [nvarchar](20) NOT NULL,
	[BRANCH_CODE] [nvarchar](20) NULL,
	[REPAIR_BILL_CODE] [nvarchar](20) NOT NULL,
	[MAKE_DATE] [datetime] NULL,
	[AUDIT_DATE] [datetime] NULL,
	[SHIFT_COMMENT] [nvarchar](300) NULL,
	[STATUS] [nvarchar](10) NULL,
	[SHOP_AUDIT_DATE] [datetime] NULL,
	[ITEM_CODE] [nvarchar](13) NOT NULL,
	[SHIFT_PRICE] [numeric](14, 4) NULL,
	[SHOP_SHIFT_QTY] [numeric](12, 2) NULL,
	[INPUT_PRICE] [numeric](14, 4) NULL,
 CONSTRAINT [PK__p_shift_bak___1140614B2591068B] PRIMARY KEY CLUSTERED 
(
	[SHIFT_BILL_CODE] ASC,
	[REPAIR_BILL_CODE] ASC,
	[ITEM_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[P_SHOP_ITEM_OUTPUT]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[P_SHOP_ITEM_OUTPUT](
	[ITEM_CODE] [varchar](13) NOT NULL,
	[DEPT_CODE] [varchar](20) NOT NULL,
	[RETAIL_PRICE] [numeric](20, 4) NULL,
	[WHOLESALE_PRICE] [numeric](20, 4) NULL,
	[MEMBER_PRICE] [numeric](20, 4) NULL,
	[SHIFT_PRICE] [numeric](20, 4) NULL,
	[SALE_PROMOTION_PRICE] [numeric](20, 4) NULL,
	[REP_DISCOUNT_PRICE] [numeric](20, 4) NULL,
	[BUY_NUMBER] [numeric](20, 2) NULL,
	[ADD_MONEY] [numeric](20, 2) NULL,
	[IF_SHOP_ORDER] [varchar](2) NULL,
	[IF_SHOP_REPAIR] [varchar](2) NULL,
	[IF_ALLOW_PROMO] [varchar](10) NULL,
	[IF_ALLOW_UNDER_PRICE_S] [varchar](10) NULL,
	[IF_CHANGE_PRICE] [varchar](10) NULL,
	[IF_COMB_PROMO] [varchar](10) NULL,
	[ALLOW_START_DATE_S] [varchar](10) NULL,
	[ALLOW_END_DATE_S] [varchar](10) NULL,
	[MIN_PURCHASE_QTY] [numeric](20, 2) NULL,
	[MAX_STOCK] [numeric](20, 2) NULL,
	[MIN_STOCK] [numeric](20, 2) NULL,
	[REASONABLE_STOCK] [numeric](20, 2) NULL,
	[AVERAGE_SALE_DAY] [numeric](20, 2) NULL,
	[DEPT_FLAG] [varchar](10) NULL,
	[SHOP_SUPPLIER_CODE] [varchar](10) NULL,
	[SHIFT_SUPPLIER_CODE] [varchar](10) NULL,
	[SHOP_JOIN_RUN_RATE] [numeric](20, 4) NULL,
	[SEND_CLASS_T] [varchar](2) NULL,
	[IF_SHIFT_BREAK] [varchar](2) NULL,
	[ITEM_RUN_RATE] [numeric](20, 2) NULL,
	[INTO_TAX_RATE_S] [numeric](20, 2) NULL,
	[SALE_TAX_RATE_S] [numeric](20, 2) NULL,
	[STOP_INTO] [varchar](1) NULL,
	[STOP_SALE] [varchar](1) NULL,
	[OOS_TEMPORARY] [varchar](1) NULL,
	[CHARACTER_TYPE] [varchar](2) NULL,
	[DISPLAY_MODE] [varchar](100) NULL,
	[ITEM_ETAGERE_CODE] [varchar](30) NULL,
	[VALIDATE_FLAG] [varchar](2) NULL,
	[RETURN_ATTRIBUTE] [varchar](25) NULL,
	[c_disuse_date] [datetime] NULL,
	[c_introduce_date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[DEPT_CODE] ASC,
	[ITEM_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[p_shop_item_output_dc]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[p_shop_item_output_dc](
	[DEPT_CODE] [varchar](20) NULL,
	[ITEM_CODE] [varchar](20) NULL,
	[STOP_INTO] [varchar](2) NULL,
	[STOP_SALE] [varchar](2) NULL,
	[C_STATUS] [varchar](30) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SYS_DELIVERYSET]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SYS_DELIVERYSET](
	[Drq] [date] NOT NULL,
	[sFdbh] [varchar](20) NOT NULL,
	[sSpbh] [varchar](30) NOT NULL,
	[nRjxl] [money] NULL,
	[sPsfs] [varchar](20) NULL,
	[nXx] [money] NULL,
	[nSx] [money] NULL,
	[nZdcl] [money] NULL,
	[nZdcl_Offset] [money] NULL,
	[nPsbzs] [money] NULL,
	[nCgbzs] [money] NULL,
PRIMARY KEY CLUSTERED 
(
	[Drq] ASC,
	[sFdbh] ASC,
	[sSpbh] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[t_sdmdtable]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_sdmdtable](
	[slx] [varchar](20) NULL,
	[sfdbh] [varchar](10) NOT NULL,
	[sspbh] [varchar](20) NOT NULL,
	[id] [int] NULL,
	[zid] [int] NULL,
	[nday] [money] NULL,
PRIMARY KEY CLUSTERED 
(
	[sfdbh] ASC,
	[sspbh] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TMp_clkc_dr]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TMp_clkc_dr](
	[机构代码] [nvarchar](255) NULL,
	[门店代码] [nvarchar](255) NULL,
	[门店名称] [nvarchar](255) NULL,
	[区域] [nvarchar](255) NULL,
	[大店群组] [nvarchar](255) NULL,
	[业态] [nvarchar](255) NULL,
	[部门] [nvarchar](255) NULL,
	[处级] [nvarchar](255) NULL,
	[大类] [nvarchar](255) NULL,
	[中类] [nvarchar](255) NULL,
	[采购经理] [nvarchar](255) NULL,
	[商品编码] [nvarchar](255) NULL,
	[商品名称] [nvarchar](255) NULL,
	[商品状态] [nvarchar](255) NULL,
	[供应商编码] [nvarchar](255) NULL,
	[供应商名称] [nvarchar](255) NULL,
	[是否可退] [nvarchar](255) NULL,
	[库存数量] [float] NULL,
	[库存金额] [float] NULL,
	[停购时间] [datetime] NULL,
	[取数时间] [nvarchar](255) NULL,
	[停购时长] [nvarchar](255) NULL,
	[停购月份] [nvarchar](255) NULL,
	[清理计划时间] [nvarchar](255) NULL,
	[清理方案] [nvarchar](255) NULL,
	[是否列入90天调价计划] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tmp_Dclkcyy]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tmp_Dclkcyy](
	[dRq] [date] NOT NULL,
	[sSpbh] [varchar](13) NOT NULL,
	[sSpmc] [varchar](200) NULL,
	[sFl] [varchar](10) NULL,
	[sFlmc] [varchar](50) NULL,
	[nJj] [money] NULL,
	[nSj] [money] NULL,
	[nZdsl] [money] NULL,
	[nZgsl] [money] NULL,
	[nRjxl] [money] NULL,
	[dzhYhr] [date] NULL,
	[nCgsl] [money] NULL,
	[nDhsl] [money] NULL,
	[syy] [varchar](14) NOT NULL,
	[nKcsl] [money] NULL,
	[sSource] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[dRq] ASC,
	[sSpbh] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tmp_dczzyy]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
	[nkcsl] [money] NULL,
	[nrjxl] [money] NULL,
	[dYhrq] [date] NULL,
	[dDhrq] [date] NULL,
	[nCgsl] [money] NULL,
	[nDhsl] [money] NULL,
	[nzzts] [money] NULL,
	[syy] [varchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[drq] ASC,
	[sSpbh] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tmp_fdb]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tmp_fdb](
	[sfdbh] [varchar](20) NOT NULL,
	[sfdmc] [varchar](60) NULL,
	[syt] [varchar](200) NULL,
	[sbs] [varchar](20) NULL,
	[smdlx] [varchar](20) NULL,
	[sJylx] [varchar](30) NULL,
	[sJc] [varchar](60) NULL,
	[fix] [varchar](20) NULL,
	[dKyrq] [datetime] NULL,
	[sQy] [nvarchar](10) NULL,
	[sDq] [varchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tmp_gh_0325]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tmp_gh_0325](
	[sflbh] [nvarchar](255) NULL,
	[sflmc] [nvarchar](255) NULL,
	[nghs] [float] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tmp_Md_Sptz]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tmp_Md_Sptz](
	[分店编号] [nvarchar](255) NULL,
	[分店名称] [nvarchar](255) NULL,
	[商品编号] [nvarchar](255) NULL,
	[商品名称] [nvarchar](255) NULL,
	[建议] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tmp_MDGH_NEW]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tmp_MDGH_NEW](
	[sflmc] [nvarchar](255) NULL,
	[sfl] [nvarchar](255) NULL,
	[nghs] [float] NULL,
	[sbq] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tmp_MDGHS]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tmp_MDGHS](
	[sFlbh] [nvarchar](255) NULL,
	[nGhjyz] [money] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TMP_MDLKCYY]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TMP_MDLKCYY](
	[drq] [date] NOT NULL,
	[sFdbh] [varchar](10) NOT NULL,
	[sSpbh] [varchar](13) NOT NULL,
	[sSpmc] [varchar](100) NULL,
	[sFl] [varchar](8) NULL,
	[nZdsl] [money] NULL,
	[nZgsl] [money] NULL,
	[sZdbh] [varchar](10) NULL,
	[sSfkj] [varchar](10) NULL,
	[sPsfs] [varchar](10) NULL,
	[syy] [varchar](20) NULL,
	[nRjxl] [money] NULL,
	[nRjxse] [money] NULL,
	[dzhyhrq] [date] NULL,
	[nsl] [money] NULL,
PRIMARY KEY CLUSTERED 
(
	[drq] ASC,
	[sFdbh] ASC,
	[sSpbh] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tmp_mdspzzyy]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tmp_mdspzzyy](
	[drq] [date] NOT NULL,
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
	[nCgbzs] [money] NULL,
	[dzhdhr] [date] NULL,
	[dzhyhr] [date] NULL,
	[syy] [varchar](20) NULL,
	[sfwqzs] [varchar](10) NULL,
	[nbzzzts] [int] NULL,
	[sfcx] [varchar](10) NULL,
	[nYhsl] [money] NULL,
	[nDhsl] [money] NULL,
	[sSource] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[drq] ASC,
	[sfdbh] ASC,
	[sspbh] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TMP_PSBZSDB]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TMP_PSBZSDB](
	[商品编号] [nvarchar](255) NULL,
	[商品名称] [nvarchar](255) NULL,
	[分类] [nvarchar](255) NULL,
	[分类名称] [nvarchar](255) NULL,
	[配送方式] [nvarchar](255) NULL,
	[库位编号] [nvarchar](255) NULL,
	[拣货方式] [nvarchar](255) NULL,
	[维联试点门店最小配送包装] [nvarchar](255) NULL,
	[D咨询试点门店最小配送包装] [float] NULL,
	[配送包装数差异] [float] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tmp_sort_standard]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tmp_sort_standard](
	[drq] [date] NOT NULL,
	[sFlbh] [varchar](20) NOT NULL,
	[sFlmc] [varchar](100) NULL,
	[nkcje] [money] NULL,
	[nRjxscb] [money] NULL,
	[nPlzzts] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[drq] ASC,
	[sFlbh] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TMP_SPB_FD]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TMP_SPB_FD](
	[SSPBH] [varchar](13) NOT NULL,
	[SFDBH] [varchar](20) NOT NULL,
	[NRJXL] [money] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tmp_spb_fd30]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tmp_spb_fd30](
	[sfdbh] [varchar](10) NOT NULL,
	[sspbh] [varchar](20) NOT NULL,
	[nxssl] [money] NULL,
	[ncb] [money] NULL,
	[nxsje] [money] NULL,
PRIMARY KEY CLUSTERED 
(
	[sfdbh] ASC,
	[sspbh] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tmp_spflb]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tmp_spflb](
	[sflbh] [varchar](16) NOT NULL,
	[sflmc] [varchar](100) NULL,
	[nts] [float] NULL,
PRIMARY KEY CLUSTERED 
(
	[sflbh] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tmp_xs_qwl]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tmp_xs_qwl](
	[sfdbh] [varchar](10) NOT NULL,
	[sspbh] [varchar](10) NOT NULL,
	[drq] [datetime] NOT NULL,
	[nxsj] [money] NULL,
	[nxssl] [money] NULL,
	[nxsje] [money] NULL,
PRIMARY KEY CLUSTERED 
(
	[sfdbh] ASC,
	[sspbh] ASC,
	[drq] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tmp_ztdd]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tmp_ztdd](
	[sfdbh] [varchar](20) NULL,
	[sspbh] [varchar](20) NOT NULL,
	[ztsl] [float] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[V_D_PRICE_AND_STOCK]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[V_D_PRICE_AND_STOCK](
	[STORE_CODE] [varchar](10) NOT NULL,
	[ITEM_CODE] [varchar](13) NOT NULL,
	[UNIT_PRICE] [money] NULL,
	[MEMBER_PRICE] [money] NULL,
	[PROMO_PRICE] [money] NULL,
	[CURR_STOCK] [money] NULL,
	[C_PRICE_MEM_DISC] [money] NULL,
	[PT_IN] [money] NULL,
PRIMARY KEY CLUSTERED 
(
	[STORE_CODE] ASC,
	[ITEM_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[vendor]    Script Date: 2022/4/14 10:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[vendor](
	[gid] [varchar](10) NULL,
	[code] [varchar](10) NOT NULL,
	[name] [varchar](100) NULL,
	[shortname] [varchar](16) NULL,
	[address] [varchar](200) NULL,
	[type] [varchar](10) NULL,
	[wwwadr] [varchar](100) NULL,
	[nzq] [int] NULL,
	[memo] [varchar](max) NULL,
	[wwwadrl] [varchar](100) NULL,
	[days] [int] NULL,
	[ValidDay] [int] NULL,
	[if_unite] [varchar](2) NULL,
	[LowTempOrder] [varchar](100) NULL,
	[PurchaseAttr] [int] NULL,
	[install_date] [datetime] NULL,
	[last_change_date] [datetime] NULL,
	[shop_return_date] [varchar](30) NULL,
	[item_area_code] [nvarchar](100) NULL,
	[Nature] [varchar](20) NULL,
	[supplier_comment] [varchar](200) NULL,
	[business_template] [varchar](20) NULL,
	[n_direct_supply] [varchar](50) NULL,
	[n_no_direct_supply] [varchar](50) NULL,
	[grade] [nvarchar](20) NULL,
	[C_ACCOUNT_BANK] [nvarchar](40) NULL,
	[C_CNAPS] [nvarchar](30) NULL,
	[C_LINK_MAN] [nvarchar](50) NULL,
	[C_ACCOUNT_NO] [nvarchar](80) NULL,
	[nZq_LC] [int] NULL,
	[C_TOKEN] [varchar](4) NULL,
 CONSTRAINT [PK__vendor__1A14E395] PRIMARY KEY CLUSTERED 
(
	[code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


----- 各种措施落地跟踪
CREATE TABLE Tmp_Measures_list(
	Measure_Name varchar(200) Not NULL, -- 执行措施，90天处理，商品优化，高库存处理，停购商品处理等
	Measure_batch varchar(100), --措施的批次名称，比如90天计划的 2月，商品上架率的 某一期 20220425总部
	CreateTime datetime,--创建时间
	EndDate date,-- 增加一个截止时间，作为每批次的处理
	sFdbh varchar(50) NOT NULL,--门店
	sSpbh varchar(50) NOT NULL,-- 商品
	sSpmc varchar(300),-- 商品名称
	sAdvice_raw varchar(100) ,--给出的处理操作
	sAdvice_result varchar(100),-- 实际的执行结果
	PRIMARY KEY (Measure_Name,Measure_batch,sFdbh,sSpbh,CreateTime)
);

Create Table Tmp_TailCargo(
	sMonth varchar(20) not null,--清理计划时间
	Bdate date not null,--开始时间
	Edate date not null,-- 结束时间
	sFdbh varchar(20) not null,--分店
	sFdmc varchar(100),
	sSpbh Varchar(50) not null,--商品
	sSpmc varchar(200),
	nTjj money,-- 特进价
	nTsj money,-- 特价售价
	sManager varchar(50) ,--负责人
	PRIMARY KEY(sMonth,sFdbh,sSpbh)
);


Create Table Tmp_TailCargo_Suggest(
	drq date not null,--计算日期
	sMonth varchar(20) not null,--清理计划时间
	Bdate date not null,--开始时间
	Edate date not null,-- 结束时间
	sFdbh varchar(20) not null,--分店
	sSpbh Varchar(50) not null,--商品
	nPsj money,--当前门店配送价
	nLsj money,--当前门店售价
	nQckc money,-- 期初库存数量
	nDqkc money,-- 当前库存数量
	nZxssl money,--总销售数量
	nDays_remaining int,-- 剩余时间长度
	sZt varchar(100) not null,-- 当前处于的状态，已清退，未完成，已恢复采购，负库存等
	sstage varchar(200),--判断的时间，既采购定价，系统建议
	ndays_already int not null,--当前日期距开始时间的天数
	nsjjd money,-- 时间进度
	nkccljd money,--库存处理进度
	nCxj_last money,--最后促销价，至当前执行的或当前无计划，已经结束的最后的促销价
    ncxj_suggest money ,-- 建议价
	sSftj varchar(300),-- 是否需要调价进入下一阶段
	PRIMARY KEY(drq,sMonth,sFdbh,sSpbh)
);
