# 画图工具
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np 
pd.set_option('display.max_columns',1000)
pd.set_option('display.max_rows',500)
pd.set_option('display.width',1000)
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties 
font_set = FontProperties(fname=r"C:\windows\fonts\MicroSoft YaHei.ttc", size=12)
# %matplotlib inline 
# auto 弹出窗口 inline 默认，在当前页显示
#指定默认字体
plt.rcParams['font.sans-serif'] = ['SimHei']
plt.rcParams['font.family']='sans-serif'
#解决负号'-'显示为方块的问题
plt.rcParams['axes.unicode_minus'] = False

import math
import seaborn as sns
import warnings;warnings.filterwarnings(action='once')
import matplotlib as mpl

warnings.filterwarnings('ignore')

large=22;med=16;small=12;
params={'axes.titlesize':large,
        'legend.fontsize':med,
        'figure.figsize':(16,10),
        'axes.labelsize':med,
        'axes.titlesize':med,
        'xtick.labelsize':med,
        'ytick.labelsize':med,
        'figure.titlesize':large}
plt.rcParams.update(params)
plt.style.use('seaborn-whitegrid')
sns.set_style('white')


from ipywidgets import widgets,Button,Label
from statsmodels.tsa.seasonal import STL

from pyecharts.charts import Bar,Line
import pyecharts.options as opts
from pyecharts.globals import ThemeType
import xlsxwriter
from pandas import ExcelWriter


###################
def L_plot1(x,y):
        y=pd.DataFrame(y);
        L=(
                Line(init_opts=opts.InitOpts(width="1000px", height="300px",theme=ThemeType.LIGHT))
                .add_xaxis(x)
                
                .set_global_opts(
                        title_opts=opts.TitleOpts(title="季节性", subtitle=""),
                        xaxis_opts=opts.AxisOpts(axislabel_opts=opts.LabelOpts(rotate=-15),name='日期',type_="category",
                        ),
                        tooltip_opts=opts.TooltipOpts(trigger='axis'),
                        yaxis_opts=opts.AxisOpts(name='指标'),
                        datazoom_opts=[
                opts.DataZoomOpts(
                        is_realtime=True,
                        type_="slider",
                        range_start=0,
                        range_end=100,
                        # xaxis_index=[0, 1],
                )]
                        )
                
        )
        for i in range(len(y.columns)):
                tmp=y.columns[i]
                L.add_yaxis(tmp,y[tmp],color='red',label_opts=opts.LabelOpts(is_show=False),)
        return L.render_notebook()



# 双坐标图形
def L_plot1_twoaxis(x,y):
        y=pd.DataFrame(y);
        L=(
                Line(init_opts=opts.InitOpts(width="900px", height="400px",theme=ThemeType.LIGHT))
                .add_xaxis(x)
                .extend_axis(
                    yaxis=opts.AxisOpts(
                        type_="value",
                        name='',
                        position='right'
                    )
                )
                
                .set_global_opts(
                        title_opts=opts.TitleOpts(title="季节性", subtitle=""),
                        xaxis_opts=opts.AxisOpts(axislabel_opts=opts.LabelOpts(rotate=-15),name='日期',type_="category",
                        ),
                        tooltip_opts=opts.TooltipOpts(trigger='axis'),
                        yaxis_opts=opts.AxisOpts(name='指标'),
                        datazoom_opts=[
                opts.DataZoomOpts(
                        is_realtime=True,
                        type_="slider",
                        range_start=0,
                        range_end=100,
                        # xaxis_index=[0, 1],
                )]
                        )
                
        )
        for i in range(len(y.columns)):
                tmp=y.columns[i]
                tmp_y=0
                if i==0:
                    tmp_y=0
                else:
                    tmp_y=1
                L.add_yaxis(tmp,y[tmp],color='red',yaxis_index=tmp_y,label_opts=opts.LabelOpts(is_show=False),)
        return L.render_notebook()
    
