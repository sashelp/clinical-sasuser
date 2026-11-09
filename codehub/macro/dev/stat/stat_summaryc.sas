/*
*Brief      : Compute frequencies, percentages and hypothesis tests for categorical variables
*Param(Req) : (DATA=)                Input dataset name
*Param(Req) : (OUT=_DATA_)           Output dataset name
*Param(Req) : (VAR=)                 Analysis variables and their order in the output, use a
                                     space as delimiter if there are multiple variables
*Param(Opt) : (BY=)                  BY-group variables, compute separate statistics for
                                     each BY group
*Param(Opt) : (CLASS=)               The variable whose values define the groups for the
                                     analysis and comparison, only one variable is supported
*Param(Opt) : (PERCENT=COL)          The basis of percentage calculation, following values are valid:
              COL       : Percent within the class level (column percent)
              ROW       : Percent within the analysis level (row percent)
              TOTAL     : Percent of the overall total
              NONE      : Not request percentages
*Param(Opt) : (TEST=NONE)            The method of hypothesis test between subgroups,
                                     following values are valid:
              NONE      : Not request tests
              CHISQ     : Chi-square test, Fisher's exact test is applied automatically
                          when a chi-square warning occurs
              FISHER    : Fisher's exact test
              CMH       : Cochran-Mantel-Haenszel test
              RC        : R*C general association test
*Param(Opt) : (TEST0FREQ=N)          Involves levels with 0 frequency to hypothesis test,
                                     following values are valid: Y, N
*Param(Opt) : (ALPHA=0.05)           The significance level of the hypothesis test, between 0 and 1
*Param(Opt) : (TOTCLASSID=0)         The class ID assigned to the total group
*Param(Opt) : (TOTCLASSLAB=Total)    The class label of the total group
*Param(Opt) : (TOTLEVELID=99)        The level ID assigned to the total level
*Param(Opt) : (TOTLEVELLAB=Total)    The level text of the total level
*Param(Opt) : (TOTLEVELSTAT=NNMISS)  The statistics of the total level, following values are valid:
              N         : Number only, displayed as N
              NNMISS    : Number and number of missing values, displayed as N(NMISS)
              NPERCENT  : Number and percent, displayed as N(PERCENT), format of percent is controlled
                          by PCTFMT= option
*Param(Opt) : (PCTDENOM=N)           The denominator of percentage, following values are valid:
              TOTAL     : Include missing values in the denominator
              N         : Use non-missing observations as the denominator
*Param(Opt) : (SHOWDENOM=Y)          Show (N=#) text in the class variable label,
                                     following values are valid: Y, N
*Param(Opt) : (DENOMDLM=@)           The character separating the class text and the (N=#) text
*Param(Opt) : (PCTFMT=8.1)           Format for displaying percentages
*Param(Opt) : (DEBUG=0)              Save or delete intermediate data sets when the macro exits:
              0         : Delete intermediate data sets
              1         : Save intermediate data sets
*Detail     : The output contains one observation per BY group, analysis variable and
              analysis level. Class levels are transposed into columns named TRT<ID>, where
              ID is the class level index or the class ID of the total level (TOTCLASSID=);
              each column label is the class level label, with (N=#) appended when SHOWDENOM=Y
*Detail     : _VARNAM_ and _VARLAB_ identify the analysis variable, _VARLVLIDX_ and
              _VARLVL_ identify the displayed analysis level, _STATIDX_ and _STATLAB_
              identify the statistic type (n or n(%) or n(nmiss)), and the TRT columns contain
              the statistic text
*Detail     : When TEST= is not NONE, _TESTV_, _TESTP_ and _TESTM_ store the test statistic,
              p value and method on the first observation of each analysis variable
*Detail     : When CLASS= is not specified, all observations are analyzed as one overall
              class; when an analysis variable has a custom format, all levels defined by
              the format are included even if they are not observed
*Note       : Only one variable is supported in CLASS=; when CLASS= is not specified, or has only
              one nonmissing level, all observations are analyzed as one overall group and TEST=
              is forced to NONE
*Note       : Fisher's exact test is applied automatically when TEST=CHISQ and the
              chi-square warning happens
*Note       : Errors may happen when TOTCLASSID= and TOTLEVELID= are specified with
              inappropriate values, because they must not conflict with the class level
              index and the total level index
*Usage      : %stat_summaryc(data=sashelp.class,out=myout,class=sex,var=age)
*Dependency : %var_exist, %var_coexist, %ds_attr
*Version    : SAS 9.4M7
*History    : 2026-11-07, Luo Hao, Original version
*/

%macro stat_summaryc(data=,out=_data_,by=,class=,var=,percent=col,test=NONE,test0freq=N,alpha=0.05,pctdenom=N,pctfmt=8.1,
  totclassid=0,totclasslab=Total,totlevelid=99,totlevellab=Total,totlevelstat=NNMISS,showdenom=Y,denomdlm=@,debug=0)/minoperator;
%local errtext nvars varcomma varquotedcomma classnlevel custfmt clstype;

/*1. Exception capture and handling*/
%if %quote(&data.)= %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %superq(data) not exist.;
%else %if %ds_attr(data=&data.,attr=nlobsf)=0 %then %let errtext=ERROR: Dataset %superq(data) has 0 observations.;
%else %if %quote(&out.)= %then %let errtext=ERROR: Parameter OUT= not specified.;
%else %if %quote(&var.)= %then %let errtext=ERROR: Parameter VAR= not specified.;
%else %if %var_coexist(data=&data.,var=&var.)=0 %then %let errtext=ERROR: At least one variable in parameter VAR= not exist.;
%else %if (%qupcase(&percent.) in COL ROW TOTAL NONE)=0 %then %let errtext=ERROR: Invalid value of PERCENT=, expecting one of the following: COL, ROW, TOTAL, NONE.;
%else %if (%qupcase(&pctdenom.) in TOTAL N)=0 %then %let errtext=ERROR: Invalid value of PCTDENOM=, expecting one of the following: TOTAL, N.;
%else %if (%qupcase(&test.) in NONE CHISQ FISHER CMH RC)=0 %then %let errtext=ERROR: Invalid value of TEST=, expecting one of the following: NONE, CHISQ, FISHER, CMH, RC.;
%else %if %sysfunc(prxmatch(/^\d+$/,%quote(&totclassid.)))=0 %then %let errtext=ERROR: Invalid value of TOTCLASSID=, expecting non-negative integer.;
%else %if %sysfunc(prxmatch(/^\d+$/,%quote(&totlevelid.)))=0 %then %let errtext=ERROR: Invalid value of TOTLEVELID=, expecting non-negative integer.;
%else %if (%qupcase(&totlevelstat.) in N NNMISS NPERCENT)=0 %then %let errtext=ERROR: Invalid value of TOTLEVELSTAT=, expecting one of the following: N, NPERCENT, NNMISS.;
%else %if (%qupcase(&showdenom.) in Y N)=0 %then %let errtext=ERROR: Invalid value of SHOWDENOM=, expecting one of the following: Y, N.;
%else %if (&debug. in 0 1)=0 %then %let errtext=ERROR: Invalid value of DEBUG=, expecting one of the following: 0, 1.;

%if %bquote(&errtext.)= and %qupcase(&test.)^=NONE %then %do;
  %if (%qupcase(&test0freq.) in Y N)=0 %then %let errtext=ERROR: Invalid value of TEST0FREQ=, expecting one of the following: Y, N.;
  %if %sysevalf(&alpha.<0) or %sysevalf(&alpha.>1) %then %let errtext=ERROR: Invalid value of ALPHA=, expecting value between 0 and 1.;
%end;

%if %bquote(&errtext.)= and %quote(&by)^= %then %do;
  %if %var_coexist(data=&data.,var=&by.)=0 %then %let errtext=ERROR: At least one variable in parameter BY= not exist.;
%end;

%if %bquote(&errtext.)= and %quote(&class)^= %then %do;
  %if %var_exist(data=&data.,var=&class.)=0 %then %let errtext=ERROR: Variable %superq(class) not exist.;
%end;

%exception:
%if %bquote(&errtext.)^= %then %do;
  %put &errtext.;
  %abort cancel;
%end;

%let var=%upcase(&var.);
%if %quote(&class.)^= %then %let class=%upcase(&class.);
%let percent=%upcase(&percent.);
%let showdenom=%upcase(&showdenom.);
%let totlevelstat=%upcase(&totlevelstat.);
%let test=%upcase(&test.);
%let test0freq=%upcase(&test0freq.);
%let pctdenom=%upcase(&pctdenom.);

%let nvars=%sysfunc(countw(%quote(&var.)));
%let varcomma=%sysfunc(tranwrd(%cmpres(&var.),%str( ),%str(,)));
%let varquotedcomma="%sysfunc(tranwrd(%cmpres(&var.),%str( ),%str(%",%")))";

%let classnlevel=0;
%if &class.^= %then %do;
  proc summary data=&data. nway;
    where also missing(&class.)=0;
    class &class.;
    output out=stat_summaryc_class;
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
  proc sort data=&data. out=stat_summaryc_sorted(keep=&by. &class. &var.);
    by &by.;
  run;
%end;

data stat_summaryc_dsin(keep=&by. _byidx_ &class. &var.);
  set %sysfunc(ifc(&by.^=,stat_summaryc_sorted,&data.));
  %if &by.= %then %str(retain _byidx_ 1;);
  %else %do;
    by &by.;
    _byidx_+first.%scan(&by.,-1);
  %end;
  %if &classnlevel.=0 %then %str(retain _class_ 'Overall';);
run;

/*2.2 Use preloadfmt skill to compute frequency*/
proc contents data=stat_summaryc_dsin memtype=data out=stat_summaryc_contents(where=(upcase(name) in("&class.",&varquotedcomma.))) noprint;
run;

proc sql noprint;
  select '1' into :custfmt from stat_summaryc_contents where format in (select fmtname from dictionary.formats where source='C');
  select type into :clstype from stat_summaryc_contents where upcase(name)="&class.";
quit;

proc summary data=stat_summaryc_dsin chartype %if &custfmt.=1 %then completetypes;;
  by &by. _byidx_;
  class &class. &var. /missing %if &custfmt.=1 %then preloadfmt;;
  types &class.*(&var.) &var.;
  output out=stat_summaryc_weight;
run;

/*2.3 Compute percentages*/
ods select none;
ods output crosstabfreqs=stat_summaryc_freqs;
proc freq data=stat_summaryc_weight(where=(missing(&class.)=0));
  by &by. _byidx_;
  tables (&var.)*&class.;
  weight _freq_/zeros;
run;

/*2.4 Compute hypothesis tests*/
%if &test.^=NONE %then %do;
  ods output %sysfunc(ifc(&test.=CHISQ,chisq,%sysfunc(ifc(&test.=FISHER,fishersexact,cmh))))(nowarn)=stat_summaryc_&test.;
  proc freq data=stat_summaryc_weight(where=(missing(&class.)=0));
    by _byidx_;
    tables (&var.)*&class./nowarn alpha=&alpha.
      %if &test.=CHISQ %then chisq(warn=output);
      %else %if &test.=FISHER %then fisher;
      %else %if &test. in CMH RC %then cmh;;
    weight _freq_ %if &test0freq.=Y %then /zeros;;
  run;

  data stat_summaryc_test(index=(_test_=(_byidx_ _varnam_)));
    length _byidx_ 8 _varnam_ $200. _testv_ _testp_ 8 _testm_ $200.;
    label _testv_='Statistics' _testp_='P value' _testm_='Method';
    keep _byidx_ _varnam_ _testv_ _testp_ _testm_;
    call missing(of _all_);
    %if %sysfunc(exist(stat_summaryc_&test.)) %then %do;
      set stat_summaryc_&test.;
      %if &test.=FISHER %then %str(where name1='XP2_FISH';);
      %else %do;
        by _byidx_ table notsorted;
        if %sysfunc(ifc(&test.=RC,last,first)).table;
      %end;

      _varnam_=upcase(ifc("%sysfunc(getoption(locale))"="ZH_CN",scan(compress(table,'-','nk'),-1,' -'),scan(table,1,' -')));
      _testv_=%sysfunc(ifc(&test.=FISHER,.N,value));
      _testp_=%sysfunc(ifc(&test.=FISHER,nvalue1,prob));
      %if &test. in CHISQ FISHER %then _testm_="%sysfunc(propcase(&test.))";
      %else %if &test.=RC %then _testm_='R*C';
      %else _testm_="&test.";;
      %if &test.=CHISQ %then %do;
        if warning=1 then do;
          _subl_=dosubl(catt('
            proc freq data=stat_summaryc_weight(where=(_byidx_=',_byidx_,' and cmiss(&class.,',_varnam_,')=0)) noprint;
              tables '||trim(_varnam_),'*&class./fisher nowarn alpha=&alpha.;
              weight _freq_ %if &test0freq.=Y %then %do; /zeros %end;;
              output out=stat_summaryc_fisher_',_byidx_,'_',_varnam_,' fisher;
            run;
          '));
          _did_=open(cat('stat_summaryc_fisher_',_byidx_,'_',_varnam_));
          if _did_ then do;
            _rc_=fetch(_did_);
            _testv_=.N;
            _testp_=getvarn(_did_,varnum(_did_,'xp2_fish'));
            _testm_="Fisher";
            _did_=close(_did_);
          end;
        end;
      %end;
    %end;
  run;
%end;

ods output close;
ods select all;

/*2.5 Compute N and Nmiss*/
proc summary data=stat_summaryc_freqs;
  class &class.;
  output out=stat_summaryc_class(index=(&class.) drop=_freq_)/levels;
run;

data stat_summaryc_nmiss(index=(_nmiss_=(_byidx_ &class. _varidx_)) keep=_byidx_ &class. _varidx_ _freq_);
  set stat_summaryc_weight;
  where cmiss(&varcomma.)=&nvars.;
  _varidx_=find(substr(_type_,2),'1');
run;

/*2.6 Combine all results*/
data stat_summaryc_result;
  set stat_summaryc_freqs;
  by &by. table notsorted;

  length _clslab_ _varnam_ _varlab_ _varlvl_ _statlab_ $200.;
  set stat_summaryc_class(rename=(_type_=_freqtype_)) keys=&class.;
  if _freqtype_^=0 then do;
    _clsidx_=_level_;
    _clslab_=%sysfunc(ifc(&clstype.=1,strip(vvalue(&class.)),vvalue(&class.)));
  end;
  else do;
    _clsidx_=&totclassid.;
    _clslab_="&totclasslab";
  end;

  _varnam_=upcase(ifc("%sysfunc(getoption(locale))"="ZH_CN",scan(compress(table,'-','nk'),-1,' -'),scan(table,1,' -')));
  _varlab_=vlabelx(_varnam_);
  _varidx_=whichc(_varnam_,&varquotedcomma.);

  _varlvl_=trim(vvaluex(_varnam_));
  _varlvlidx_+(_varlvl_^=lag(_varlvl_));
  if first.table then do;
    _varlvlidx_=1;
    %if &test.^=NONE %then %do;
      set stat_summaryc_test keys=_test_;
      if _iorc_^=0 then do;
        _testv_=.N;
        _testp_=.N;
        _testm_="N/A";
        _error_=0;
      end;
    %end;
  end;

  set stat_summaryc_nmiss keys=_nmiss_;
  if _iorc_^=0 then do;
    _error_=0;
    _freq_=0;
  end;

  if _type_^=:'0' then do;
    _statidx_=1;
    _statlab_='n(%)';
    %if &percent. in COL ROW %then %str(_statpct_=ifn(_freqtype_,&percent.percent,percent););
    %else %if &percent.=TOTAL %then %str(_statpct_=percent;);
    %if &percent.=COL and &pctdenom.=TOTAL %then %str(if _statpct_ and _freq_ then _statpct_=frequency/round(frequency/_statpct_*100+_freq_)*100;);
    %if &percent.=NONE %then %do;
      _statval_=cats(frequency);
      _statlab_='n';
    %end;
    %else %str(_statval_=cats(frequency,'(',ifc(_statpct_>.z,put(_statpct_,&pctfmt.),'N/A'),')'););
  end;
  else do;
    _varlvlidx_=&totlevelid.;
    _varlvl_="&totlevellab";
    _statidx_=2;
    %if &totlevelstat.=NPERCENT %then %do;
      _statlab_='n(%)';
      _statval_=cats(frequency,'(',ifc(percent>.z,put(percent,&pctfmt.),'N/A'),')');
    %end;
    %else %if &totlevelstat.=NNMISS %then %do;
      _statlab_='n(nmiss)';
      _statval_=cats(frequency,'(',ifn(_iorc_=0,_freq_,0),')');
    %end;
    %else %if &totlevelstat.=N %then %do;
      _statlab_='n';
      _statval_=cats(frequency);
    %end;
    %if &showdenom.=Y %then %str(if _byidx_=1 and _varidx_=1 then call symputx(cats('NTRT',_clsidx_),sum(frequency,_freq_)););
  end;
  label _varidx_='Variable Index' _varnam_='Variable Name' _varlab_='Variable Label' _varlvl_='Variable Level' _varlvlidx_='Variable Level Index'
    _statlab_='Statistics Label' _statidx_='Statistics Index';
run;

%if &showdenom.=Y %then %do;
  data stat_summaryc_result;
    modify stat_summaryc_result;
    _clslab_=trim(_clslab_)||"&denomdlm.(N="||symget(cats('NTRT',_clsidx_))||")";
  run;
%end;

proc sort data=stat_summaryc_result;
  by &by. _varidx_ _varlvlidx_ _statidx_;
run;

/*2.7 Restruct as one record per by-group per analysis variable per analysis level*/
proc transpose data=stat_summaryc_result out=stat_summaryc_final_trans(drop=_name_) prefix=trt;
  by &by. _varidx_ _varnam_ _varlab_ _varlvlidx_ _varlvl_ _statidx_ _statlab_  %if &test.^=NONE %then _testv_ _testp_ _testm_;;
  var _statval_;
  id _clsidx_;
  idlabel _clslab_;
run;

data &out.;
  set stat_summaryc_final_trans;
  by &by. _varidx_;
  %if &test.^=NONE %then if first._varidx_=0 then call missing(_testv_,_testp_,_testm_);;
run;

/*3. Cleanup and exit*/
%if &debug.=0 %then %do;
  proc datasets nolist memtype=data;
    delete stat_summaryc_:;
  quit;
%end;
%mend;
