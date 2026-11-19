/*
*Name       : 折线图 - 坐标轴表(外置)
*Brief      : 作为一种图形元素, 坐标轴表可以在图形中嵌入数据表, 以补充绘图细节. 它常常和散点图、
              折线图或生存分析图联用, 用来显示图形主体的数据值, 甚至是第三维度的数据.
*Param      : X=<var>,必需参数,X 轴变量
*Param      : Y=<var>,必需参数,Y 轴变量
*Param      : CLASS=<var>,可选参数,分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : XMIN=<num>,可选参数,X 轴最小刻度值, 刻度值相关参数未指定时, 程序使用内部算法计算
*Param      : XMAX=<num>,可选参数,X 轴最大刻度值
*Param      : XINC=<num>,可选参数,X 轴分度值
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Param      : YLOW=<var>,可选参数,Y 轴误差棒下限
*Param      : YUPP=<var>,可选参数,Y 轴误差棒上限
*Param      : ATX=<var>,必需参数,坐标轴表 X 轴变量
*Param      : ATV=<var>,必需参数,坐标轴表显示值
*Param      : ATCLS=<var>,可选参数,坐标轴表分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : ATTIT=<str>,可选参数,坐标轴表标题
*Note       : 有时, 你可能会希望将坐标轴表外置, 以免让图形主体部分元素过多, 难以阅读.
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
  set sashelp.stocks;
  where year(date)=2005 and stock in('Intel','Microsoft');

  stockn=whichc(stock,'Intel','Microsoft');
  month=month(date);
  month_nofmt=month;   *本示例程序中需要对 X 轴变量 month 设置实值屏蔽格式 val_2mask., 因此用 month_nofmt 作为轴表 X 轴变量, 并且不对其设置格式;
run;

/*2. 定义绘图模板*/
proc template;
  define statgraph series4;
  begingraph;
  dynamic x y class xmin xmax xinc ymin ymax yinc ylow yupp atx atv atcls attit;
  layout lattice/rows=3 rowweights=(0.85 0.05 0.10);
    *图形主体;
    layout overlay/walldisplay=none
      xaxisopts=(label=eval(collab(x)) offsetmin=0.03 offsetmax=0.03 linearopts=(thresholdmin=1 thresholdmax=1
        viewmin=xmin viewmax=xmax tickvaluesequence=(start=xmin end=xmax increment=xinc)))
      yaxisopts=(label=eval(collab(y)) offsetmin=0.03 offsetmax=0.08 linearopts=(thresholdmin=1 thresholdmax=1
        viewmin=ymin viewmax=ymax minorticks=1 minortickcount=4 tickvaluesequence=(start=ymin end=ymax increment=yinc)));

      seriesplot x=x y=y/group=class index=class grouporder=ascending name="ser"
        groupdisplay=cluster clusterwidth=0.3 yerrorlower=ylow yerrorupper=yupp;
      scatterplot x=x y=y/group=class index=class grouporder=ascending name="sca"
        groupdisplay=cluster clusterwidth=0.3 markerattrs=(size=5.5pt);
      mergedlegend "ser" "sca"/location=inside autoalign=(topright) down=1 border=0 itemsize=(linelength=0.8cm);
    endlayout;

    *坐标轴表(标签);
    layout overlay/walldisplay=none;
      entry halign=left attit;
    endlayout;

    *坐标轴表(主体);
    layout overlay/walldisplay=none
      xaxisopts=(display=none offsetmin=0.03 offsetmax=0.03 linearopts=(thresholdmin=1 thresholdmax=1
        viewmin=xmin viewmax=xmax tickvaluesequence=(start=xmin end=xmax increment=xinc)))
      yaxisopts=(display=none);
      axistable x=atx value=atv/class=atcls colorgroup=atcls includemissingclass=0;
    endlayout;
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
ods rtf file="&_pgm_path_\series4.rtf" image_dpi=300 style=htmlblue startpage=no; 
proc sgrender data=tab1 template=series4;
  dynamic x="month" y="close" class="stockn" ylow="low" yupp="high" xmin=1 xmax=12 xinc=1
    atx="month_nofmt" atv="close" atcls="stockn" attit="No. of XXX";
  format month close val_2mask. stockn cls_2mask.;
  label month='X 轴标签' close='Y 轴标签';
run;

proc report data=sashelp.class style(report)={pretext="Title: series4" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
