/*
*Name       : 折线图 - 群体血药浓度时间图(灰度)
*Brief      : <简介>
*Param      : X=<var>,必需参数,X 轴变量
*Param      : Y=<var>,必需参数,Y 轴变量
*Param      : CLASS=<var>,可选参数,分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : XMIN=<num>,可选参数,X 轴最小刻度值, 刻度值相关参数未指定时, 程序使用内部算法计算
*Param      : XMAX=<num>,可选参数,X 轴最大刻度值
*Param      : XINC=<num>,可选参数,X 轴分度值
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Note       : 丢弃色彩, 仅靠灰度区分个体, 进一步聚焦群体趋势
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

data fake_adpc;
  call streaminit(4399);
  do i=1 to 24;
    do j=1 to 12;
      atptn=choosen(j,0,0.25,0.5,0.75,1,2,4,6,8,10,12,24);
      
      trt01pn=1;
      subjid=put(trt01pn*1e3+i,z4.);
      par1=choosen(j,0,51,128,192,220,249,195,219,181,149,60,7);
      par2=choosen(j,0,15,30,29,40,61,59,77,54,35,22,3);
      aval=rand('normal',par1,par2);
      output;

      trt01pn=2;
      subjid=put(trt01pn*1e3+i,z4.);
      par1=choosen(j,0,62,145,266,297,337,344,416,341,256,102,11);
      par2=choosen(j,0,28,64,92,130,139,144,150,136,67,40,4);
      aval=rand('normal',par1,par2);
      output;
    end;
  end;
  drop i j par1 par2;
run;

proc sort data=fake_adpc out=tab1;
  by subjid atptn;
run;

*生成灰色尺度颜色列表;
proc sql noprint;
  select count(distinct subjid) into :n_subjects trimmed from tab1;
quit;

data _null_;
  length color_list $1680;
  do i=1 to &n_subjects.;
    color=cats('gray',put((i-1)*int(192/&n_subjects.),hex2.));
    color_list=catx('',color_list,color);
  end;
  call symputx('color_list',color_list);
run;
*生成完毕;

/*2. 定义绘图模板*/
proc template;
  define statgraph series16;
  begingraph/datacontrastcolors=(&color_list.);
  dynamic x y class xmin xmax xinc ymin ymax yinc;
  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) offsetmin=0.03 offsetmax=0.03 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=xmin viewmax=xmax tickvaluesequence=(start=xmin end=xmax increment=xinc)))
    yaxisopts=(label=eval(collab(y)) offsetmin=0.03 offsetmax=0.08 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=ymin viewmax=ymax minorticks=1 minortickcount=4 tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    seriesplot x=x y=y/group=class grouporder=ascending name="ser"
      groupdisplay=cluster clusterwidth=0.3 lineattrs=(pattern=solid);

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
option nobyline;
ods graphics on/reset=all outputfmt=png width=12cm height=9cm noborder;
ods rtf file="&_pgm_path_\series16.rtf" image_dpi=300 style=htmlblue startpage=no; 
proc sgrender data=tab1 template=series16;
  dynamic x="atptn" y="aval" class="subjid" xmin=0 xmax=24 xinc=3;
  format atptn aval val_2mask. trt01pn cls_2mask.;
  label atptn='X 轴标签' aval='Y 轴标签';
run;

proc report data=sashelp.class style(report)={pretext="Title: series16" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
