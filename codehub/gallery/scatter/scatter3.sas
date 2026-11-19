/*
*Name       : 散点图 - 气泡图
*Brief      : 可根据指定变量的值自动调整散点标记大小, 用于说明第三个维度的信息.
*Param      : X=<var>,必需参数,X 轴变量
*Param      : Y=<var>,必需参数,Y 轴变量
*Param      : SIZE=<var>,可选参数,散点标记大小的映射变量, 未指定时, 变更散点标记大小
*Param      : CLASS=<var>,可选参数,分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : XMIN=<num>,可选参数,X 轴最小刻度值, 刻度值相关参数未指定时, 程序使用内部算法计算
*Param      : XMAX=<num>,可选参数,X 轴最大刻度值
*Param      : XINC=<num>,可选参数,X 轴分度值
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Note       : 此类图形容易产生重叠, 设置恰当的透明度可获得更好的显示效果
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
  set sashelp.class;
  sexn=whichc(sex,'M','F');
run;

/*2. 定义绘图模板*/
proc template;
  define statgraph scatter3;
  begingraph;
  dynamic x y size class xmin xmax xinc ymin ymax yinc;
  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) offsetmin=0.03 offsetmax=0.03 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=xmin viewmax=xmax tickvaluesequence=(start=xmin end=xmax increment=xinc)))
    yaxisopts=(label=eval(collab(y)) offsetmin=0.03 offsetmax=0.08 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=ymin viewmax=ymax minorticks=1 minortickcount=4 tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    scatterplot x=x y=y/sizeresponse=size markerattrs=(symbol=circlefilled) datatransparency=0.6
      sizemin=8px sizemax=24px group=class index=class grouporder=ascending name="sca";
    discretelegend "sca"/location=inside autoalign=(topright) down=1 border=0;

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
ods rtf file="&_pgm_path_\scatter3.rtf" image_dpi=300 style=htmlblue startpage=no;
proc sgrender data=tab1 template=scatter3;
  dynamic x="height" y="weight" class="sexn" size="age";
  format height weight val_2mask. sexn cls_2mask.;
  label height='X 轴标签' weight='Y 轴标签';
run;

proc report data=sashelp.class style(report)={pretext="Title: scatter3" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
