/*
*Brief      : Compute descriptive statistics and hypothesis tests for quantitative variables
*Param(Req) : (DATA=)                Input dataset name
*Param(Req) : (OUT=_DATA_)           Output dataset name
*Param(Req) : (VAR=)                 Analysis variables and their order in the output, use a
                                     space as delimiter if there are multiple variables
*Param(Opt) : (BY=)                  BY-group variables, produce separate statistics for
                                     each BY group
*Param(Opt) : (CLASS=)               The variable whose values define the groups for the
                                     analysis and comparison, only one variable is supported
*Param(Opt) : (STATIS=N_NMISS MEAN_STD MEDIAN Q1_Q3 MIN_MAX)
              Statistics to display and their order in the output, following values are
              valid: N, NMISS, N_NMISS, MEAN, LCLM, UCLM, CLM, MEDIAN, Q1, Q3, MIN, MAX,
              MIN_MAX, SUM, STDDEV, STDERR, CV, MEAN_STD, Q1_Q3, MED_Q1_Q3, GM, GM_LCLM,
              GM_UCLM, GM_CLM, GM_STD, GM_STDDEV, GM_CV
*Param(Opt) : (CI_ALPHA=0.05)        Confidence level of LCLM, UCLM and CLM, between 0 and 1
*Param(Opt) : (MAXDEC=4)             The maximum number of decimal places of the statistics,
                                     between 0 and 9
*Param(Opt) : (TEST=NONE)            The method of hypothesis test between groups,
                                     following values are valid:
              NONE      : Not request tests
              AUTO      : Test normality first, then select PAR or NPAR per variable
              PAR       : Parametric test, t test for 2 groups and ANOVA for more than 2
              NPAR      : Nonparametric test, Wilcoxon for 2 groups and Kruskal-Wallis
                          for more than 2
*Param(Opt) : (TEST_ALPHA=0.05)      The significance level of the hypothesis test and of
                                     the normality decision when TEST=AUTO, between 0 and 1
*Param(Opt) : (TOTCLASSID=0)         Numeric index of the total group, used as the suffix of
                                     the TRT columns
*Param(Opt) : (TOTCLASSLAB=Total)    Label of the total group
*Param(Opt) : (RAWDECSOURCE=OVERALL) The way to compute the maximum number of raw decimal places 
                                     for each variable, following values are valid:
              OVERALL   : One maximum number of decimal places for all data
              BY        : One maximum number of decimal places for each BY group
*Param(Opt) : (MINMAXFMT=)           Display format of MIN, MAX and SUM; if blank, values are
                                     rounded to MAXDEC places
*Param(Opt) : (POSFMT=)              Display format of position statistics (mean, median,
                                     quartiles, confidence limits); if blank, it will be 24.d
                                     where d is maximum raw decimal places and no more than MAXDEC
*Param(Opt) : (SCAFMT=)              Display format of scale statistics (stddev, stderr); if 
                                     blank, it will be 24.d where d is maximum raw decimal places
                                     and no more than MAXDEC
*Param(Opt) : (CVFMT=16.2)           Display format of coefficient of variation
*Param(Opt) : (SHOWDENOM=Y)          Show (N=#) text in the class variable label, where # is
                                     n+nmiss, following values are valid: Y, N
*Param(Opt) : (DENOMDLM=@)           The character separating the class label and the (N=#) text
*Param(Opt) : (DEBUG=0)              Save or delete intermediate data sets when the macro exits:
              0         : Delete intermediate data sets
              1         : Save intermediate data sets
*Detail     : The output contains one observation per BY group, analysis variable and
              statistic. Class levels are transposed into columns named TRT<index>, and the
              total group is stored in TRT<TOTCLASSID>; each column label is the class label,
              with (N=#) appended when SHOWDENOM=Y
*Detail     : _VARIDX_, _VARNAM_ and _VARLAB_ identify the analysis variable; _STATIDX_,
              _STATNAM_ and _STATLAB_ identify the statistic; the TRT columns contain the
              formatted statistic values, and statistics that cannot be computed are shown
              as "N/A"
*Detail     : When TEST= is not NONE, _TESTV_, _TESTP_ and _TESTM_ store the test statistic,
              p value and method on the first observation of each analysis variable
*Detail     : ANOVA is performed by PROC NPAR1WAY with the ANOVA option, which gives the
              same result as PROC ANOVA but runs faster
*Note       : Only one variable is supported in CLASS=; when CLASS= is not specified, all
              observations are analyzed as one overall group and TEST= is forced to NONE
*Note       : The total group is generated automatically; TOTCLASSID= must not conflict with
              the numeric indices of the class levels
*Note       : Geometric statistics (GM*) are computed only when STATIS= requests them, and
              non-positive values are excluded from the log transformation
*Note       : AUTO selects the parametric or nonparametric test per analysis variable,
              according to whether the minimum normality p value is greater than or equal
              to TEST_ALPHA=
*Usage      : %stat_summaryn(data=sashelp.class,out=myout,class=sex,var=age)
*Dependency : %var_exist, %var_coexist, %ds_attr
*Version    : SAS 9.4M7
*History    : 2026-11-07, Luo Hao, Original version
*/

%macro stat_summaryn(data=,out=_data_,by=,class=,var=,statis=n_nmiss mean_std median q1_q3 min_max,
  ci_alpha=0.05,maxdec=4,test=NONE,test_alpha=0.05,totclassid=0,totclasslab=Total,rawdecsource=OVERALL,
  minmaxfmt=,posfmt=,scafmt=,cvfmt=16.2,showdenom=Y,denomdlm=@,debug=0)/minoperator;
%local errtext gm_needed all_statis custfmt stat i classnlevel;

/*1. Exception capture and handling*/
%if %superq(data)= %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,%str(()))))=0 %then %let errtext=ERROR: Input dataset %superq(data) does not exist.;
%else %if %superq(out)= %then %let errtext=ERROR: Parameter OUT= not specified.;
%else %if %superq(var)= %then %let errtext=ERROR: Parameter VAR= not specified.;
%else %if %var_coexist(data=&data.,var=&var.,type=N)=0 %then %let errtext=ERROR: At least one variable in parameter VAR= does not exist or is not numeric.;
%else %if (%sysevalf(&ci_alpha.>0) and %sysevalf(&ci_alpha.<1))=0 and %index(%upcase(&statis.),CLM) %then %let errtext=ERROR: Invalid value of CI_ALPHA=, expecting value between 0 and 1.;
%else %if %sysfunc(prxmatch(/^\d$/,%quote(&maxdec.)))=0 %then %let errtext=ERROR: Invalid value of MAXDEC=, expecting an integer between 0 and 9.;
%else %if (%upcase(&test.) in NONE AUTO PAR NPAR)=0 %then %let errtext=ERROR: Invalid value of TEST=, expecting one of the following: NONE, AUTO, PAR, NPAR.;
%else %if (%sysevalf(&test_alpha.>0) and %sysevalf(&test_alpha.<1))=0 and %upcase(&test.)^=NONE %then %let errtext=ERROR: Invalid value of TEST_ALPHA=, expecting value between 0 and 1.;
%else %if %sysfunc(prxmatch(/^\d+$/,%quote(&totclassid.)))=0 %then %let errtext=ERROR: Invalid value of TOTCLASSID=, expecting non-negative integer.;
%else %if %superq(totclasslab)= %then %let errtext=ERROR: Parameter TOTCLASSLAB= not specified.;
%else %if (%qupcase(&showdenom.) in Y N)=0 %then %let errtext=ERROR: Invalid value of SHOWDENOM=, expecting one of the following: Y, N.;
%else %if (%qupcase(&rawdecsource.) in OVERALL BY)=0 %then %let errtext=ERROR: Invalid value of RAWDECSOURCE=, expecting one of the following: OVERALL, BY.;
%else %if %superq(statis)= %then %let errtext=ERROR: Parameter STATIS= not specified.;
%else %if %ds_attr(data=&data.,attr=nlobsf)=0 %then %let errtext=ERROR: Dataset %superq(data) has 0 observations.;

%if %bquote(&errtext.)= %then %do;
  %do i=1 %to %sysfunc(countw(%superq(statis)));
    %if not(%upcase(%scan(&statis.,&i.,%str( ))) in (N NMISS N_NMISS MEAN LCLM UCLM CLM MEDIAN Q1 Q3 MIN MAX RANGE MIN_MAX SUM STDDEV STDERR VAR CV MEAN_STD Q1_Q3 MED_Q1_Q3 GM GM_LCLM GM_UCLM GM_CLM GM_STD GM_STDDEV GM_CV)) %then
      %let errtext=ERROR: Invalid value of STATIS=, expecting one of the following: N, NMISS, N_NMISS, MEAN, LCLM, UCLM, CLM, MEDIAN, Q1, Q3, MIN, MAX, RANGE, MIN_MAX, SUM, STDDEV, STDERR, VAR, CV, MEAN_STD, Q1_Q3, MED_Q1_Q3, GM, GM_LCLM, GM_UCLM, GM_CLM, GM_STD, GM_STDDEV, GM_CV.;
  %end;
%end;

%if %bquote(&errtext.)= and %quote(&by)^= %then %do;
  %if %var_coexist(data=&data.,var=&by.)=0 %then %let errtext=ERROR: At least one variable in parameter BY= not exist.;
%end;
%if %bquote(&errtext.)= and %quote(&class)^= %then %do;
  %if %sysfunc(countw(&class.))>1 %then %let errtext=ERROR: Parameter CLASS= only accepts one variable.;
  %else %if %var_exist(data=&data.,var=&class.)=0 %then %let errtext=ERROR: Variable %superq(class) not exist.;
%end;

%exception:
%if %bquote(&errtext.)^= %then %do;
  %put &errtext.;
  %abort cancel;
%end;

%let test=%upcase(&test.);
%let var=%upcase(%cmpres(&var.));
%let showdenom=%upcase(&showdenom.);
%if %index(%upcase(&statis.),GM) %then %let gm_needed=1;
%let all_statis=MEAN LCLM UCLM MEDIAN Q1 Q3 STDDEV STDERR VAR CV;
%if &gm_needed.=1 %then %let all_statis=&all_statis. GM GM_LCLM GM_UCLM GM_STDDEV GM_CV;

%let classnlevel=0;
%if &class.^= %then %do;
  proc summary data=&data. nway;
    where also missing(&class.)=0;
    class &class.;
    output out=stat_summaryn_class;
  run;
  %let classnlevel=&sysnobs.;
%end;

%if (&classnlevel. in 0 1) and &test.^=NONE %then %do;
  %let test=NONE;
  %put WARNING: Only one overall group is analysed, thus TEST= option will be forced to NONE;
%end;
%if &classnlevel.=0 %then %let class=_CLASS_;

/*2. Core processing*/
/*2.1 Data check*/
%if &by.^= %then %do;
  proc sort data=&data. out=stat_summaryn_sorted(keep=&by. &class. &var.);
    by &by.;
  run;
%end;

data stat_summaryn_dsin(keep=&by. _byidx_ &class. _varidx_ _varval_ _declen_ %if &gm_needed.=1 %then %str(_varval_log_);) 
     stat_summaryn_attr(keep=&var.);
  do until(_eof_);
    set %sysfunc(ifc(&by.^=,stat_summaryn_sorted,&data.)) end=_eof_;
    if 0 then output stat_summaryn_attr;
    %if &by.= %then %str(retain _byidx_ 1;);
    %else %do;
      by &by.;
      _byidx_+first.%scan(&by.,-1);
    %end;
    %if &classnlevel.=0 %then %str(retain _class_ 'Overall';);
    array _dummy_ &var.;
    do over _dummy_;
      _varidx_=_i_;
      _varval_=_dummy_;
      _declen_=lengthn(scan(put(_varval_,best.),2,'.'));
      %if &gm_needed.=1 %then %do;
        if _varval_>0 then _varval_log_=log(_varval_);
        else _varval_log_=.;
      %end;
      output stat_summaryn_dsin;
    end;
  end;
run;

proc sort data=stat_summaryn_dsin;
  by &by. _varidx_ &class.;
run;

/*2.2 Compute descriptive statistics*/
/*2.2.0 Judge custom format existence*/
proc contents data=stat_summaryn_dsin memtype=data out=stat_summaryn_contents(where=(upcase(name)="%upcase(&class.)")) noprint;
run;

proc sql noprint;
  select '1' into :custfmt from stat_summaryn_contents where format in (select fmtname from dictionary.formats where source='C');
quit;

/*2.2.1 Compute the maximum number of decimal places*/
proc summary data=stat_summaryn_dsin(drop=&by. _varval_: &class.) nway;
  %if %upcase(&rawdecsource.)=BY %then %str(by _byidx_;);
  class _varidx_;
  var _declen_;
  output out=stat_summaryn_dec max=_rawdec_;
run;

proc means data=stat_summaryn_dsin(drop=_declen_) alpha=&ci_alpha. noprint %if &custfmt.=1 %then completetypes;;
  by &by. _byidx_ _varidx_;
  class &class./%if &custfmt.=1 %then preloadfmt;;
  var _varval_;
  output out=stat_summaryn_summary n=__n nmiss=__nmiss mean=__mean stddev=__stddev median=__median
    lclm=__lclm uclm=__uclm q1=__q1 q3=__q3 min=__min max=__max stderr=__stderr cv=__cv sum=__sum
    range=__range var=__var;
run;

/*2.2.2 Compute geometric statistics (if needed)*/
%if &gm_needed.=1 %then %do;
  proc means data=stat_summaryn_dsin(keep=&by. _byidx_ _varidx_ &class. _varval_log_) alpha=&ci_alpha. noprint %if &custfmt.=1 %then completetypes;;
    by &by. _byidx_ _varidx_;
    class &class./%if &custfmt.=1 %then preloadfmt;;
    var _varval_log_;
    output out=stat_summaryn_gm n=__n_log mean=__mean_log stddev=__stddev_log lclm=__lclm_log uclm=__uclm_log;
  run;
%end;

/*2.3 Execute hypothesis test*/
%if &test.^=NONE %then %do;
  %if &test.=AUTO %then %do;
    /*2.3.1 Normality test (if needed)*/
    proc univariate data=stat_summaryn_dsin(where=(_varval_>.z) keep=_byidx_ _varidx_ &class. _varval_) noprint;
      by _byidx_ _varidx_ &class.;
      var _varval_;
      output out=stat_summaryn_norm probn=_probn_;
    run;
  %end;

  /*2.3.2 Get levels of class to decide parametric or nonparametric test*/
  data stat_summaryn_comb1(keep=_byidx_ _varidx_ _freq_ _minp_ _par_);
    do until(last._varidx_);
      merge stat_summaryn_summary(where=(_type_^=0) drop=_freq_) %if &test.=AUTO %then stat_summaryn_norm;;
      by _byidx_ _varidx_ &class.;
      _freq_=sum(_freq_,__n^=0);
      %if &test.=AUTO %then if _probn_>.z then _minp_=min(_minp_, _probn_);
      %else _minp_=1;;
    end;
    _par_=("&test."="PAR" or ("&test."="AUTO" and _minp_>=&test_alpha.));
  run;

  data stat_summaryn_pretest;
    merge stat_summaryn_dsin(drop=&by. _declen_) stat_summaryn_comb1(drop=_minp_);
    by _byidx_ _varidx_;
  run;

  /*2.3.3 Apply parametric hypothesis test*/
  /*2.3.3.1 t test*/
  ods select none;
  ods output ttests(nowarn)=stat_summaryn_test_t1 equality(nowarn)=stat_summaryn_test_t2;
  proc ttest data=stat_summaryn_pretest(where=(_freq_=2 and _varval_>.z) keep=_byidx_ _varidx_ &class. _varval_ _freq_ _par_);
    where _par_=1;
    by _byidx_ _varidx_;
    class &class.;
    var _varval_;
  run;
  ods output close;
  ods select all;

  %if %sysfunc(exist(stat_summaryn_test_t1)) %then %do;
    data stat_summaryn_test_t3;
      merge stat_summaryn_test_t1 stat_summaryn_test_t2;
      by _byidx_ _varidx_;
      if (probf<&test_alpha.)^=(method='Satterthwaite') then delete;
      _method_=ifc(method='Satterthwaite',"t' test",'t test');
    run;
  %end;

  /*2.3.3.2 and 2.3.4 ANOVA and nonparametric test in one pass*/
  proc npar1way data=stat_summaryn_pretest(where=(_varval_>.z) keep=_byidx_ _varidx_ &class. _varval_) noprint;
    by _byidx_ _varidx_;
    class &class.;
    var _varval_;
    output out=stat_summaryn_test_npar anova wilcoxon;
  run;
%end;

/*2.4 Combine and rearrange results*/
/*2.4.1 Generate index variables for CLASS=*/
proc summary data=stat_summaryn_summary(keep=&class.);
  class &class.;
  output out=stat_summaryn_class/levels;
run;

/*2.4.2 Combine all results*/
proc sql;
  create table stat_summaryn_comb2 as
  select a.*, b._rawdec_, c._level_ %if &gm_needed.=1 %then %str(, d.__n_log, d.__mean_log, d.__stddev_log, d.__lclm_log, d.__uclm_log);
  from stat_summaryn_summary(drop=_freq_) as a
  left join stat_summaryn_dec as b on a._varidx_=b._varidx_ %if %upcase(&rawdecsource.)=BY %then %str(and a._byidx_=b._byidx_);
  left join stat_summaryn_class as c on a.&class.=c.&class.
  %if &gm_needed.=1 %then %str(left join stat_summaryn_gm as d on a._byidx_=d._byidx_ and a._varidx_=d._varidx_ and a.&class.=d.&class.);
  order by a._byidx_, a._varidx_, a.&class.
  ;
quit;

%if &test.^=NONE %then %do;
  data stat_summaryn_comb3;
    merge stat_summaryn_comb2 stat_summaryn_comb1
      %if %sysfunc(exist(stat_summaryn_test_t3)) %then stat_summaryn_test_t3(keep=_byidx_ _varidx_ tvalue probt _method_ rename=(tvalue=_tvalue_ probt=_probt_));
      %if %sysfunc(exist(stat_summaryn_test_npar)) %then stat_summaryn_test_npar(rename=(_f_=_fvalue_ p_f=_probf_ p_kw=_p_kw_));;
    by _byidx_ _varidx_;
  run;
%end;

/*2.4.3 Rearrange results to be report-ready*/
data stat_summaryn_final;
  length _varnam_ _statnam_ _varlab_ $200.;
  if 0 then set stat_summaryn_attr;
  set &syslast.;

  _varnam_=upcase(choosec(_varidx_,"%sysfunc(tranwrd(&var.,%str( ),%str(%",%")))"));
  _varlab_=vlabelx(_varnam_);
  _clsidx_=ifn(_type_,_level_,&TOTCLASSID.);
  _clslab_=ifc(_type_,vvalue(&class.),"&TOTCLASSLAB.");
  %if %upcase(&showdenom.)=Y %then %str(_clslab_=trim(_clslab_)||"&denomdlm.(N="||cats(__n+__nmiss)||')'; );

  /*Eliminate the influence of floating-point errors*/
  array _dummy_ _numeric_;
  do over _dummy_;
    if missing(_dummy_)=0 then _dummy_=round(_dummy_,1e-9);
  end;

  /*Convert numeric statistics to character for report usage*/
  _posfmt_=ifc("&posfmt."='',cats('24.',min(_rawdec_+1,&maxdec.)),"&posfmt.");
  _scafmt_=ifc("&scafmt."='',cats('24.',min(_rawdec_+2,&maxdec.)),"&scafmt.");
  _cvfmt_="&cvfmt.-l";
  %if &gm_needed.=1 %then %do;  /*Geometric descriptive statistics*/
    if __mean_log   >.z then __gm        =exp(__mean_log);
    if __stddev_log >.z then __gm_stddev =exp(__stddev_log);
    if __stddev_log >.z then __gm_cv     =sqrt(exp(__stddev_log**2)-1)*100;
    if __lclm_log   >.z then __gm_lclm   =exp(__lclm_log);
    if __uclm_log   >.z then __gm_uclm   =exp(__uclm_log);
  %end;
  array _dummy1_ __%sysfunc(tranwrd(&all_statis.,%str( ),%str( __)));
  array _dummy2_ $50 __stat_%sysfunc(tranwrd(&all_statis.,%str( ),%str( __stat_)));
  do over _dummy1_;
    _statnam_=scan("&all_statis.",_i_);
    _fmtidx_=ifn(_statnam_ in('STDDEV','STDERR','VAR','GM_STDDEV'),2,ifn(_statnam_ in('CV','GM_CV'),3,1));
    if _dummy1_>.z then _dummy2_=putn(_dummy1_,choosec(_fmtidx_,_posfmt_,_scafmt_,_cvfmt_));
    else _dummy2_='N/A';
  end;

  /*Descriptive statistics from PROC MEANS*/
  __stat_n         =cats(__n);
  __stat_nmiss     =cats(__nmiss);
  %do _n_=1 %to 4;
    %let stat=%sysfunc(choosec(&_n_.,min,max,range,sum));
    if __&stat.>.z then 
      %if %quote(&minmaxfmt.)= %then __stat_&stat.=cats(round(__&stat.,1e-&maxdec.));
      %else __stat_&stat.=cats(put(__&stat.,&minmaxfmt.));;
    else __stat_&stat.='N/A';
  %end;
  __stat_n_nmiss   =cats(__stat_n,'(',__stat_nmiss,')');
  __stat_mean_std  =cats(__stat_mean,'(',__stat_stddev,')');
  __stat_clm       =catx(', ',__stat_lclm,__stat_uclm);
  __stat_q1_q3     =catx(', ',__stat_q1,__stat_q3);
  __stat_med_q1_q3 =cats(__stat_median,'(',__stat_q1_q3,')');
  __stat_min_max   =catx(', ',__stat_min,__stat_max);
  %if &gm_needed.=1 %then %do;
    __stat_gm_std  =cats(__stat_gm,'(',__stat_gm_stddev,')');
    __stat_gm_clm  =catx(', ',__stat_gm_lclm,__stat_gm_uclm);
  %end;

  %if &test.^=NONE %then %do;
    /*Result of hypothesis test*/
    array _dummy3_ _tvalue_ _fvalue_ _probt_ _probf_ z_wil _kw_ p2_wil _p_kw_;  /*Avoid uninitialized notes*/
    array _dummy4_ $200 _testm_ _method_;
    if _freq_>=2 and _par_=1 then do;
      _testv_  =ifn(_freq_=2,_tvalue_,_fvalue_);
      _testp_  =ifn(_freq_=2,_probt_,_probf_);
      _testm_  =ifc(_freq_=2,_method_,'ANOVA');
    end;
    else if _freq_>=2 and _par_=0 then do;
      _testv_  =ifn(_freq_=2,z_wil,_kw_);
      _testp_  =ifn(_freq_=2,p2_wil,_p_kw_);
      _testm_  =ifc(_freq_=2,'Wilcoxon','Kruskal-Wallis');
    end;
    if _testp_=. then do;
      _testv_=.N;
      _testp_=.N;
      _testm_='N/A';
    end;
    label _testv_='Statistics' _testp_='P value' _testm_='Method';
  %end;
  array _dummy5_ $200 __stat_%sysfunc(tranwrd(%cmpres(&statis.),%str( ),%str( __stat_)));
  do over _dummy5_;
    _statidx_=_i_;
    _statnam_=scan("%upcase(&statis.)",_i_);
    _statlab_=vlabel(_dummy5_);
    _statval_=left(_dummy5_);
    output;
  end;
  label _varidx_='Variable Index' _varnam_='Variable Name' _varlab_='Variable Label' _statlab_='Statistics Label'
    _statidx_='Statistics Index' _statnam_='Statistics Name' __stat_n='N' __stat_nmiss='Nmiss' __stat_sum='Sum'
    __stat_n_nmiss='n(miss)' __stat_mean='Mean' __stat_stddev='SD' __stat_mean_std='Mean(SD)'
    __stat_stderr='Standard Error' __stat_clm="%sysevalf(100-100*&ci_alpha.)% CI" __stat_q1_q3='Q1,Q3'
    __stat_lclm="%sysevalf(100-100*&ci_alpha.)% CI Lower" __stat_uclm="%sysevalf(100-100*&ci_alpha.)% CI Upper"
    __stat_min='Min' __stat_max='Max' __stat_q1='Q1' __stat_q3='Q3' __stat_range='Range' __stat_var='Variance'
    __stat_median='Median' __stat_med_q1_q3='Median(Q1,Q3)' __stat_min_max='Min,Max' __stat_cv='CV%'
    %if &gm_needed.=1 %then __stat_gm='Geomean' __stat_gm_stddev='GeoSD' __stat_gm_std='GMean±Std' __stat_gm_cv='GeoCV'
    __stat_gm_clm="GM %sysevalf(100-100*&ci_alpha.)% CI" __stat_gm_lclm="GM %sysevalf(100-100*&ci_alpha.)% CI Lower" 
    __stat_gm_uclm="GM %sysevalf(100-100*&ci_alpha.)% CI Upper"
;;
run;

proc sort data=stat_summaryn_final;
  by &by. _varidx_ _statidx_ _clsidx_;
run;

proc transpose data=stat_summaryn_final out=stat_summaryn_final_trans(drop=_name_) prefix=trt;
  by &by. _varidx_ _varnam_ _varlab_ _statidx_ _statnam_ _statlab_ %if &test.^=NONE %then _testv_ _testp_ _testm_;;
  var _statval_;
  id _clsidx_;
  idlabel _clslab_;
run;

data &out.;
  set stat_summaryn_final_trans;
  by &by. _varidx_;
  %if &test.^=NONE %then if first._varidx_=0 then call missing(_testv_,_testp_,_testm_);;
run;

/*3. Cleanup and exit*/
%if &debug.=0 %then %do;
  proc datasets nolist memtype=data;
    delete stat_summaryn_:;
  quit;
%end;
%mend;
