/*
*Name       : 生存分析图 - 模型信息
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
*Param      : YLOW=<var>,可选参数,Y 轴变量置信区间下限
*Param      : YUPP=<var>,可选参数,Y 轴变量置信区间上限
*Param      : CNSR=<var>,可选参数,删失散点标记
*Param      : ATX=<var>,必需参数,坐标轴表 X 轴变量
*Param      : ATV=<var>,必需参数,坐标轴表显示值
*Param      : ATCLS=<var>,可选参数,坐标轴表分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : ATTIT=<str>,可选参数,坐标轴表标题
*Note       : 有时, 你可能会希望将在图中加入模型信息. 这可以使用 entry 语句完成, 由于可添加的模
              型信息非常丰富, 本程序仅用于示例, 没有给出新的动态变量参数.
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

/*由于KM生存分析图的数据直接由过程步生成, 横轴刻度值列表需要在过程步中借助 atrisk= 选项指定,
置信区间需要在过程步中借助 cl 选项计算*/
ods select none;
ods output survivalplot=survivalplot homtests=homtests;
ods graphics;
proc lifetest data=tab1 plots=(survival(cl atrisk=(0 to 2800 by 400))); 
  time aval*cnsr(1);
  strata trt01pn;
  format trt01pn; *此过程步将分组变量的 formatted value 保留在输出数据集中, 移除分组变量的格式会让结果的排序更合理;
run;

ods output hazardratios=hazardratios;
proc phreg data=tab1;
  class trt01pn/ref=last;
  model aval*cnsr(1)=trt01pn;
  hazardratio trt01pn;
run;
ods output close;
ods select all;

data _null_;
  set homtests;
  if test='对数秩' then call symputx('chisq',put(chisq,8.3));
  if test='对数秩' then call symputx('prob',tranwrd(put(probchisq,pvalue6.3),'<.','<0.'));
run;

data _null_;
  set hazardratios;
  call symputx('hr_ci',cats(put(hazardratio,8.3),'(',put(waldlower,8.3),',',put(waldupper,8.3),')'));
run;

data tab2;
  set survivalplot;

  if survival>. then survival=survival*100;
  if censored>. then censored=censored*100;
  if sdf_lcl>. then sdf_lcl=sdf_lcl*100;
  if sdf_ucl>. then sdf_ucl=sdf_ucl*100;
run;

/*2. 定义绘图模板*/
proc template;
  define statgraph survival5;
  begingraph;
  dynamic x y class xmin xmax xinc ymin ymax yinc ylow yupp cnsr atx atv atcls attit;
  legenditem type=marker name="cnsr"/markerattrs=(color=black symbol=plus) label='Censored';
  layout lattice/rows=3 rowweights=(0.85 0.05 0.10);
    *图形主体;
    layout overlay/walldisplay=none
      xaxisopts=(label=eval(collab(x)) offsetmin=0.03 offsetmax=0.03 linearopts=(thresholdmin=1 thresholdmax=1
        viewmin=xmin viewmax=xmax tickvaluesequence=(start=xmin end=xmax increment=xinc)))
      yaxisopts=(label=eval(collab(y)) offsetmin=0.03 offsetmax=0.08 linearopts=(thresholdmin=1 thresholdmax=1
        viewmin=ymin viewmax=ymax minorticks=1 minortickcount=4 tickvaluesequence=(start=ymin end=ymax increment=yinc)));

      entry "Logrank Test: &chisq"    /autoalign=(topright) pad=(top=30px);
      entry "p-value: &prob"          /autoalign=(topright) pad=(top=50px);
      entry "HR(95%%CI): &hr_ci"      /autoalign=(topright) pad=(top=70px);
      stepplot x=x y=y/group=class index=class grouporder=ascending name="step";
      scatterplot x=x y=cnsr/group=class index=class grouporder=ascending markerattrs=(symbol=plus);
      bandplot x=x limitlower=ylow limitupper=yupp/group=class index=class type=step datatransparency=0.75;
      discretelegend "step" "cnsr"/location=inside autoalign=(topright) down=1 border=0 itemsize=(linelength=0.8cm);
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
ods rtf file="&_pgm_path_\survival5.rtf" image_dpi=300 style=htmlblue startpage=no; 
proc sgrender data=tab2 template=survival5;
  dynamic x="time" y="survival" class="stratumnum" cnsr="censored" ylow="sdf_lcl" yupp="sdf_ucl"
    xmin=0 xmax=2800 xinc=400 ymin=0 ymax=100 yinc=20
    atx="tatrisk" atv="atrisk" atcls="stratumnum" attit="No. of XXX";
  format time survival atrisk val_2mask. stratumnum cls_2mask.;
  label time='X 轴标签' survival='Y 轴标签';
run;

proc report data=sashelp.class style(report)={pretext="Title: survival5" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
