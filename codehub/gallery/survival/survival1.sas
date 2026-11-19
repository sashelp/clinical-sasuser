/*
*Name       : 生存分析图 - 基本样式
*Brief      : 生存分析图是 Kaplan-Meier 生存分析结果的可视化呈现. 其横轴为时间, 纵轴为事件概率.
              (通常将刻度范围设置为 0-100%). 它是阶梯图, 本质上是折线图的特殊形式——将折线图中的
              散点的Y轴值保持不变, X轴值向左或右平移, 直到临近的散点才停下来, 这对应生存数据中
              左删失和右删失的情况.
*Param      : X=<var>,必需参数,X 轴变量
*Param      : Y=<var>,必需参数,Y 轴变量
*Param      : CLASS=<var>,可选参数,分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : XMIN=<num>,可选参数,X 轴最小刻度值, 刻度值相关参数未指定时, 程序使用内部算法计算
*Param      : XMAX=<num>,可选参数,X 轴最大刻度值
*Param      : XINC=<num>,可选参数,X 轴分度值
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Param      : CNSR=<var>,可选参数,删失散点标记
*Note       : SAS 过程步 proc lifetest 会给出默认样式的 KM 生存分析图, 但通常无法满足复杂的样式
              需求. 程序员可通过 ods output 语句输出绘图数据, 然后自行绘制图形.
*Dependency : NULL
*Version    : SAS 9.4M7
*History    : 2026-11-19, 罗浩, 初稿
*/

/*1. 获取绘图数据*/
proc format;
  value val_2mask
  low-high='XX'
  ;
  value cls_2mask
  1='组别 1'
  2='组别 2'
  ;
run;

data tab1;
  set sashelp.bmt;
  where group in ('AML-Low Risk' 'AML-High Risk');

  trt01pn=whichc(group,'AML-Low Risk','AML-High Risk');
  aval=t;
  cnsr=1-status;    *0 stands for events, 1 stands for censor;
run;

/*由于KM生存分析图的数据直接由过程步生成, 横轴刻度值列表需要在过程步中借助 atrisk= 选项指定*/
ods select none;
ods output survivalplot=survivalplot;
ods graphics;
proc lifetest data=tab1 plots=(survival(atrisk=(0 to 2800 by 400))); 
  time aval*cnsr(1);
  strata trt01pn;
  format trt01pn; *此过程步将分组变量的 formatted value 保留在输出数据集中, 移除分组变量的格式会让结果的排序更合理;
run;
ods output close;
ods select all;

data tab2;
  set survivalplot;

  if survival>. then survival=survival*100;
  if censored>. then censored=censored*100;
run;

/*2. 定义绘图模板*/
proc template;
  define statgraph survival1;
  begingraph;
  dynamic x y class xmin xmax xinc ymin ymax yinc cnsr;
  legenditem type=marker name="cnsr"/markerattrs=(color=black symbol=plus) label='Censored';

  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) offsetmin=0.03 offsetmax=0.03 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=xmin viewmax=xmax tickvaluesequence=(start=xmin end=xmax increment=xinc)))
    yaxisopts=(label=eval(collab(y)) offsetmin=0.03 offsetmax=0.08 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=ymin viewmax=ymax minorticks=1 minortickcount=4 tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    stepplot x=x y=y/group=class index=class grouporder=ascending name="step";
    scatterplot x=x y=cnsr/group=class index=class grouporder=ascending markerattrs=(symbol=plus);
    discretelegend "step" "cnsr"/location=inside autoalign=(topright) down=1 border=0 itemsize=(linelength=0.8cm);

  endlayout;
  endgraph;
  end;
run;

/*3. 绘制图形*/
/*获取当前路径 - 开始*/
data _null_;
  length file $4096;
  if "%superq(sysincludefiledir)"^='' then file=catx('\',"%superq(sysincludefiledir)","%superq(sysincludefilename)"); /*静态包含模式*/
  else if getoption('sysin')^='' then file=getoption('sysin');  /*批处理模式*/
  else if find("&sysprocessmode",'DMS') then file=sysget('sas_execfilepath');  /*交互模式: DMS*/
  else if find("&sysprocessmode",'Server') then file=dequote(symget('_sasprogramfile'));  /*交互模式: EG/Studio*/
  if file^='' then call symputx('_pgm_path_',substr(file,1,findc(file,'/\','b')-1));
run;
%put 当前路径为: %superq(_pgm_path_);
/*获取当前路径 - 结束*/

ods _all_ close;
ods graphics on/reset=all outputfmt=png width=12cm height=9cm noborder;
ods rtf file="&_pgm_path_\survival1.rtf" image_dpi=300 style=htmlblue startpage=no; 
proc sgrender data=tab2 template=survival1;
  dynamic x="time" y="survival" class="stratumnum" cnsr="censored"
    xmin=0 xmax=2800 xinc=400 ymin=0 ymax=100 yinc=20;
  format time survival val_2mask. stratumnum cls_2mask.;
  label time='X 轴标签' survival='Y 轴标签';
run;

proc report data=sashelp.class style(report)={pretext="Title: survival1" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
