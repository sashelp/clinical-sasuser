/*
*Name       : 散点图 - Parkes 误差网格图(I 型糖尿病)
*Brief      : Parkes 误差网格图由 Joan L. Parkes 在2000年发布, 它一种临床上的数学评估工具, 用于
              评估家用血糖测量仪与参考方法相比的一致性。横轴为参考方法的血糖测量值, 纵轴为测试
              设备的血糖测量值, 单位均为 mg/dL。ISO15197:2013 标准规定, 至少99%的测试结果, 均应
              位于 Parkers 误差网格图的 A 区和 B 区, 且至少95%的测试结果, 均应位于 A 区域.
*Param      : X=<var>,必需参数,参考方法血糖值
*Param      : Y=<var>,必需参数,测试方法血糖值
*Param      : GRIDX=<var>,必需参数,误差网格线 X 轴变量
*Param      : GRIDY=<var>,必需参数,误差网格线 Y 轴变量
*Param      : LABX=<var>,必需参数,区域标签 X 轴变量
*Param      : LABY=<var>,必需参数,区域标签 Y 轴变量
*Param      : CLASS=<var>,可选参数,误差网格区域变量
*Param      : XMIN=<num>,可选参数,X 轴最小刻度值
*Param      : XMAX=<num>,可选参数,X 轴最大刻度值
*Param      : XINC=<num>,可选参数,X 轴分度值
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Note       : 对图中各元素的解释, 参见 <a href="https://www.bilibili.com/opus/972452119913168914
              " target="_blank">绘制 Parkes 误差网格图</a>
*Note       : 当前程序使用 proc ginside 步骤判断散点所在区域, 此步骤属于 SAS/GRAPH 模块, 如果此模
              块不可用, 可以改用 <a href="https://www.bilibili.com/opus/972452119913168914
              " target="_blank">绘制 Parkes 误差网格图</a> 中参考文献3提供的其它方式
*Dependency : SAS/GRAPH
*Version    : SAS 9.4M7
*History    : 2026-11-19, 罗浩, 初稿
*/

/*1. 获取绘图数据*/
data tab1;
  call streaminit(4399);
  do i=1 to 300;
    randno=put(i,z3.);
    realval=rand('uniform',5,400);
    testval=realval+rand('normal',0,realval/7);
    refval=realval+rand('normal',0,realval/7);
    output;
  end;
  drop i realval;
run;

/*Parkes 误差网格多边形坐标*/
data parkes_map;
  infile datalines truncover dlm=' ,|';
  input subarea :$20. @;
  area=scan(subarea,1,'_');
  do until(x=.);
    input x y @;
    if not missing(x) then output;
  end;
  datalines;
E_Upper 0,550|0,150|35,155|50,550
D_Upper 0,100|25,100|50,125|80,215|125,550|50,550|35,155|0,150
C_Upper 0,60|30,60|50,80|70,110|260,550|125,550|80,215|50,125|25,100|0,100
B_Upper 0,50|30,50|140,170|280,380|430,550|260,550|70,110|50,80|30,60|0,60
A_Both 0,0|50,0|50,30|170,145|385,300|550,450|550,550|430,550|280,380|140,170|30,50|0,50
B_Lower 120,0|120,30|260,130|550,250|550,450|385,300|170,145|50,30|50,0
C_Lower 250,0|250,40|550,150|550,250|260,130|120,30|120,0
D_Lower 250,0|250,40|550,150|550,0
;

/*区域标签坐标*/
data labels;
  input area :$1. labx laby;
  datalines;
E 25 475
D 80 475
C 175 475
B 275 450
A 350 400
A 390 350
B 430 270
C 450 150
D 450 50
;

/*判断散点所在区域*/
proc ginside map=parkes_map data=tab1(rename=(refval=x testval=y)) out=points;
  id subarea area;
run;

/*将网格、标签和散点整理为一个 GTL 绘图数据集*/
data plotdata;
  length plotkind $8;
  set parkes_map(in=ingrid)
      labels(in=inlabel)
      points(in=inpoint);
  if ingrid then do;
    plotkind='GRID';
    gridx=x;
    gridy=y;
  end;
  else if inlabel then plotkind='LABEL';
  else if inpoint then do;
    plotkind='POINT';
    refval=x;
    testval=y;
  end;
run;

/*2. 定义绘图模板*/
proc template;
  define statgraph scatter6;
  begingraph/datacontrastcolors=(vipk papb vigb cxfe8463 cx339ca8);
  dynamic x y class xmin xmax xinc ymin ymax yinc gridx gridy labx laby;

  layout overlay / walldisplay=none aspectratio=1
    xaxisopts=(label=eval(collab(x)) offsetmin=0 offsetmax=0.03 griddisplay=on
      linearopts=(thresholdmin=1 thresholdmax=1 viewmin=xmin viewmax=xmax tickvaluesequence=(start=xmin end=xmax increment=xinc)))
    yaxisopts=(label=eval(collab(y)) offsetmin=0 offsetmax=0.03 griddisplay=on
      linearopts=(thresholdmin=1 thresholdmax=1 viewmin=ymin viewmax=ymax tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    scatterplot x=x y=y / group=class grouporder=ascending name='sca' markerattrs=(symbol=circlefilled size=4pt);
    seriesplot x=gridx y=gridy / group=subarea lineattrs=(color=black pattern=shortdash);
    lineparm x=0 y=0 slope=1 /lineattrs=(color=black thickness=2 pattern=dash);
    textplot x=labx y=laby text=area /display=(fill) textattrs=(color=black weight=bold size=10pt) fillattrs=(color=lightgray);

    discretelegend 'sca' / location=inside autoalign=(topright) down=1 border=0 title='区域' backgroundcolor=lightgray opaque=1;
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
ods graphics on/reset=all outputfmt=png width=12cm height=12cm noborder;
ods rtf file="&_pgm_path_\scatter6.rtf" image_dpi=300 style=htmlblue startpage=no;
proc sgrender data=plotdata template=scatter6;
  dynamic x='refval' y='testval' class='area'
    xmin=0 xmax=500 xinc=100 ymin=0 ymax=500 yinc=100 gridx='gridx' gridy='gridy' labx='labx' laby='laby';
  label refval='参考方法 (mg/dL)' testval='测试方法 (mg/dL)';
run;

proc report data=sashelp.class
    style(report)={pretext='Title: scatter6' just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
