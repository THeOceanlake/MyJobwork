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
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[??????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[??????] [nvarchar](255) NULL,
	[??????] [nvarchar](255) NULL,
	[??????] [nvarchar](255) NULL,
	[??????] [nvarchar](255) NULL,
	[??????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[???????????????] [nvarchar](255) NULL,
	[???????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [float] NULL,
	[????????????] [float] NULL,
	[????????????] [datetime] NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[??????????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????90???????????????] [nvarchar](255) NULL
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
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[??????] [nvarchar](255) NULL
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
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[??????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????] [nvarchar](255) NULL,
	[????????????????????????????????????] [nvarchar](255) NULL,
	[D????????????????????????????????????] [float] NULL,
	[?????????????????????] [float] NULL
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


----- ????????????????????????
CREATE TABLE Tmp_Measures_list(
	Measure_Name varchar(200) Not NULL, -- ???????????????90??????????????????????????????????????????????????????????????????
	Measure_batch varchar(100), --??????????????????????????????90???????????? 2???????????????????????? ????????? 20220425??????
	CreateTime datetime,--????????????
	EndDate date,-- ???????????????????????????????????????????????????
	sFdbh varchar(50) NOT NULL,--??????
	sSpbh varchar(50) NOT NULL,-- ??????
	sSpmc varchar(300),-- ????????????
	sAdvice_raw varchar(100) ,--?????????????????????
	sAdvice_result varchar(100),-- ?????????????????????
	PRIMARY KEY (Measure_Name,Measure_batch,sFdbh,sSpbh,CreateTime)
);

Create Table Tmp_TailCargo(
	sMonth varchar(20) not null,--??????????????????
	Bdate date not null,--????????????
	Edate date not null,-- ????????????
	sFdbh varchar(20) not null,--??????
	sFdmc varchar(100),
	sSpbh Varchar(50) not null,--??????
	sSpmc varchar(200),
	nTjj money,-- ?????????
	nTsj money,-- ????????????
	sManager varchar(50) ,--?????????
	PRIMARY KEY(sMonth,sFdbh,sSpbh)
);


Create Table Tmp_TailCargo_Suggest(
	drq date not null,--????????????
	sMonth varchar(20) not null,--??????????????????
	Bdate date not null,--????????????
	Edate date not null,-- ????????????
	sFdbh varchar(20) not null,--??????
	sSpbh Varchar(50) not null,--??????
	nPsj money,--?????????????????????
	nLsj money,--??????????????????
	nQckc money,-- ??????????????????
	nDqkc money,-- ??????????????????
	nZxssl money,--???????????????
	nDays_remaining int,-- ??????????????????
	sZt varchar(100) not null,-- ??????????????????????????????????????????????????????????????????????????????
	sstage varchar(200),--????????????????????????????????????????????????
	ndays_already int not null,--????????????????????????????????????
	nsjjd money,-- ????????????
	nkccljd money,--??????????????????
	nCxj_last money,--??????????????????????????????????????????????????????????????????????????????????????????
    ncxj_suggest money ,-- ?????????
	sSftj varchar(300),-- ????????????????????????????????????
	PRIMARY KEY(drq,sMonth,sFdbh,sSpbh)
);

------ ????????????????????????????????????????????????????????????
Create table Tmp_StopList(
	drq date not null,-- ????????????????????????????????????
	sFdbh Varchar(20) not null,-- ??????
	sSpbh Varchar(300) not null,
	STOP_INTO varchar(10),
	nKcsl  money,
	nkcje  money,
	PRIMARY KEY (drq,sFdbh,sspbh)
);
/*
delete from Tmp_StopList where drq=CONVERT(date,GETDATE()-1);
  insert into Tmp_StopList(drq,sFdbh,sSpbh,STOP_INTO,nKcsl,nKcje)
  select b.drq,b.sfdbh,b.sspbh,a.STOP_INTO,b.nkcsl,b.nKcje from
   DappSource_Dw.dbo.tmp_kclsb  b  
  left join   DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT a on a.DEPT_CODE=b.sfdbh and a.ITEM_CODE=b.sspbh
  join DappSource_Dw.dbo.goods c on a.ITEM_CODE=c.code 
  where 1=1 and   b.drq=CONVERT(date,GETDATE()-1) and a.Dept_code='018425' and ( a.STOP_INTO<>'N'  or a.STOP_INTO is null or a.DEPT_CODE is null    )
   and a.CHARACTER_TYPE='N' and b.nkcsl>0 and a.c_introduce_date is not null  and  (( c.sort>'20' and c.sort<'40') or (
  LEFT(c.sort,4) in ('1105','1307','1406') ))
and LEFT(c.sort,4)<>'2201' ;
*/


------ ???????????????????????????????????????????????????????????????????????????
Create Table Tmp_Autosp_Exlist(
	drq date not null,
	sFdbh Varchar(20) not null,
	sSpbh Varchar(20) not null,
	sFlbh varchar(20) not null,
	sGys varchar(20) not null,
	sTag varchar(50) not null,
	PRIMARY Key(drq,sfdbh,sspbh,sTag)
);
/*
select a.sfdbh,b.sflbh into #zdbhfl
from [122.147.10.200].dappsource.dbo.sys_deliverysort a,
 DappSource_Dw.dbo.tmp_spflb b where 1=1 and ((  b.sflbh like a.sflbh+'%' and LEN(b.sflbh)=8)
or ( left(b.sflbh,4) in ('1309','2103','2104')) );

-- drop table #Base_sp
select a.DEPT_CODE sFdbh,a.ITEM_CODE sSpbh,d.name sspmc,d.sort sPlbh,a.SHOP_SUPPLIER_CODE sgys ,
case when a.SEND_CLASS_T='01' then '??????' when a.SEND_CLASS_T='02' then '??????'
when a.SEND_CLASS_T='03' then '????????????' when a.SEND_CLASS_T='04' then '????????????' end spsfs
into #Base_sp
from DappSource_Dw.dbo.P_SHOP_ITEM_OUTPUT a
join DappSource_Dw.dbo.goods d on a.ITEM_CODE=d.code
join #zdbhfl c on a.DEPT_CODE=c.sfdbh and d.sort=c.sflbh 
where 1=1 and      a.STOP_INTO='N'
 and a.STOP_SALE='N' and a.VALIDATE_FLAG='Y' and a.CHARACTER_TYPE='N' and (( d.sort>'20' and d.sort<'40') or (
LEFT(d.sort,4) in ('1105','1307','1406') ))  
and LEFT(d.sort,4)<>'2201';

select * into #tmp_exgys from [122.147.10.200].DAppSource.dbo.Sys_DeliveryGysEx


select * into #tmp_exsfl from [122.147.10.200].DAppSource.dbo.Sys_DeliverySortEx

select * into #tmp_exsp from [122.147.10.200].DAppSource.dbo.Sys_DeliverySpEx 
where  begindate<GETDATE() and enddate>GETDATE() and nFlag=1 ;

select * into #tmp_exsp_cold from [122.147.10.200].DAppSource.dbo.Sys_DeliverySpEx_cold 
where  begindate<GETDATE() and enddate>GETDATE() and nFlag=1 ;

select * into #Tmp_tihi from [122.147.10.200].DAppSource.dbo.t_tihi;


select * into #Tmp_bhfd from [122.147.10.200].DAppSource.dbo.Sys_DeliveryFd;

-- ??????
insert into DappSource_Dw.dbo.Tmp_Autosp_Exlist(drq,sFdbh,sSpbh,sFlbh,sGys,sTag)
select CONVERT(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sPlbh,a.sgys,'?????????????????????' from #Base_sp a 
join #tmp_exgys b on a.sgys=b.sgys  where 1=1;

select CONVERT(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sPlbh,a.sgys,'??????????????????'  from #Base_sp a 
join #tmp_exsfl b on a.sFdbh=b.sfdbh and  a.sPlbh like b.sflbh+'%'  where 1=1;

select CONVERT(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sPlbh,a.sgys,'??????????????????' from #Base_sp a 
join #tmp_exsp b on a.sSpbh=b.sspbh   where 1=1;

select CONVERT(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sPlbh,a.sgys,'??????????????????' from #Base_sp a 
join #tmp_exsp_cold b on a.sSpbh=b.sspbh   where 1=1;


select CONVERT(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sPlbh,a.sgys,'???????????????'  from #Base_sp a
left join #5 b on a.sspbh=b.SIZE_DESC
where 1=1  and a.sPsfs='??????' and b.SIZE_DESC is null ;

select CONVERT(date,GETDATE()) drq,a.sFdbh,a.sSpbh,a.sPlbh,a.sgys,'??????????????????'  from 
#Base_sp a  left join #Tmp_bhfd b on a.sFdbh=b.sfdbh
where 1=1 and b.sfdbh is null;
*/


 


