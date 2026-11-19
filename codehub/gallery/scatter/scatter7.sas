/*
*Name       : 散点图 - 海氏法则图
*Brief      : 海氏法则图用于评价药物性肝损伤风险. 横轴为峰值 ALT 或 AST 相对于正常值上限(ULN)的
              倍数, 纵轴为峰值总胆红素相对于正常值上限(ULN)的倍数, 两轴均使用对数刻度, 并按治疗
              组区分散点.
*Param      : X=<var>,必需参数,峰值 ALT 或 AST 相对于 ULN 的倍数
*Param      : Y=<var>,必需参数,峰值 TBIL 相对于 ULN 的倍数
*Param      : CLASS=<var>,可选参数,治疗组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : XMIN=<num>,可选参数,X 轴最小刻度值
*Param      : XMAX=<num>,可选参数,X 轴最大刻度值
*Param      : XINC=<num>,可选参数,对数 X 轴未使用此参数
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,对数 Y 轴未使用此参数
*Note       : 海氏法则图通常以 ALT 或 AST 峰值超过 3×ULN 且 TBIL 峰值超过 2×ULN 作为重要参考区域.
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
  call streaminit(4399);
  do i=1 to 2;
    do j=1 to 100;
      do k=1 to 3;
        do v=0 to 4;

          subjid=put(i*1000+j,z4.);
          trt01pn=i;
          trt01p=choosec(trt01pn,'组别1','组别2');
          paramn=k;
          param=choosec(paramn,'丙氨酸氨基转移酶','天门冬氨酸氨基转移酶','总胆红素');
          paramcd=choosec(paramn,'ALT','AST','TBIL');
          avisitn=v;
          avisit=cats('Week',avisitn);
          if avisitn=0 then areltpt='给药前';
          else areltpt='给药后';
          if paramcd='ALT' then aval=rand('uniform',choosen(avisitn+1,5,4,6,4,7),choosen(avisitn+1,41,82,123,98,96));
          else if paramcd='AST' then aval=rand('uniform',choosen(avisitn+1,11,12,10,11,12),choosen(avisitn+1,40,58,55,49,82));
          else if paramcd='TBIL' then aval=rand('uniform',choosen(avisitn+1,6.2,3.4,2.6,3.1,4.51),choosen(avisitn+1,26.4,31.13,66.7,39,25.7));
          anrhi=choosen(paramn,40,40,21);
          output;

        end;
      end;
    end;
  end;
run;

proc sql noprint;
  create table tab2 as 
  select a.subjid, a.trt01pn, a.trt01p
    , max(b.aval/b.anrhi) as alstr
    , max(c.aval/c.anrhi) as tbilr
  from (select distinct subjid, trt01pn, trt01p from tab1) as a
  left join tab1(where=(areltpt='给药后' and paramcd in('ALT' 'AST'))) as b on a.subjid=b.subjid
  left join tab1(where=(areltpt='给药后' and paramcd in('TBIL'))) as c on a.subjid=c.subjid
  group by a.subjid, a.trt01pn, a.trt01p
  ;
quit;

/*2. 定义绘图模板*/
proc template;
  define statgraph scatter7;
  begingraph;
  dynamic x y class xmin xmax xinc ymin ymax yinc;
  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) offsetmin=0.03 offsetmax=0.03 type=log logopts=(thresholdmin=1 thresholdmax=1 
      viewmin=xmin viewmax=xmax minortickcount=8 minorticks=1))
    yaxisopts=(label=eval(collab(y)) offsetmin=0.03 offsetmax=0.08 type=log logopts=(thresholdmin=1 thresholdmax=1
      viewmin=ymin viewmax=ymax minortickcount=8 minorticks=1));

    scatterplot x=x y=y/group=class index=class grouporder=ascending name="sca"
      filledoutlinedmarkers=1 markeroutlineattrs=(color=white) markerattrs=(size=8px symbol=circlefilled);
    referenceline x=3/curvelabel="3×ULN" lineattrs=(pattern=shortdash) curvelabellocation=inside curvelabelposition=min;
    referenceline y=2/curvelabel="2×ULN" lineattrs=(pattern=shortdash) curvelabellocation=inside curvelabelposition=min;

    discretelegend "sca"/location=inside autoalign=(topright) down=1 border=0 itemsize=(linelength=0.8cm);

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
ods rtf file="&_pgm_path_\scatter7.rtf" image_dpi=300 style=htmlblue startpage=no;
proc sgrender data=tab2 template=scatter7;
  dynamic x="alstr" y="tbilr" class="trt01pn" xmin=0.1 xmax=10 ymin=0.1 ymax=10;
  format trt01pn cls_2mask.;
  label alstr="Peak ALT or AST(×ULN)" tbilr="TBIL(×ULN)";
run;

proc report data=sashelp.class
    style(report)={pretext='Title: scatter7' just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
