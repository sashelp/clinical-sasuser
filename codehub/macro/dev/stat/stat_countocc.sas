/*
*Brief      : Compute number of subjects and number of events for occurrence data
*Param(Req) : (DATA=)               Input dataset name
*Param(Req) : (DENOM=&data)         Dataset for computing denominator
*Param(Req) : (OUT=_DATA_)          Output dataset name
*Param(Req) : (CLASS=)              Variable whose values define subgroups for the analysis
*Param(Req) : (CODE=)               Coding variables in occurrence data
*Param(Req) : (SUBJECT=USUBJID)     ID variable to count subjects
*Param(Req) : (SORTCLASSNUM=0)      Serial number of subgroup to sort result
*Param(Req) : (PCTFMT=8.1)          Format for displaying percentages
*Param(Opt) : (UNCODE=UNCODED)      Text to impute missing value of CODE= variables 
*Param(Opt) : (TOTCODELAB=_TOTAL_)  Text to display on cumulative row of CODE= variables 
*Param(Opt) : (TEST=NONE)           Hypothesis test to test difference between subgroups,
                                    following values are vaild:
              NONE    : Not request tests
              CHISQ   : Request chi-square tests
              FISHER  : Request Fisher's exact tests
              AUTO    : For each test, try chi-square test firstly, then use Fisher's exact
                        test instead if chi-square warning happens
*Param(Req) : (DEBUG=0)             Save or delete intermediate datasets when macro exits
                                    following values are vaild:
              0        : Delete intermediate datasets
              1        : Save intermediate datasets
*Detail     : The number of subjects is number of unique subjects(specified by SUBJECT=)
              of the current code combination, the number of events is number of occurence
              of the current code combination
*Detail     : Output dataset is sorted by number of subjects of code variable 1, name 
              of code variable 1, then number of subjects of code variable 2, name of
              code variable 2 and so on. When sorting by number of subjects, you can 
              specify sort by which subgroup by SORTCLASSNUM= option
*Detail     : In all levels of one code, the total level always sorted as first level, the 
              uncoded level always sorted as last level
*Note       : Only one class variable is supported in CLASS= option
*Note       : Multiple variables can be specified in CODE= option with space as delimiter,
              like: AEBODSYS AEDECOD or ATC1 ATC2 ATC3
*Usage      : See inner website
*Dependency : %var_exist, %var_coexist, %ds_attr
*Version    : SAS 9.4M7
*History    : 2026-01-16, Luo Hao, Original version
*History    : 2026-10-29, Luo Hao, Add PCTFMT= option to control the format of percentage output
*History    : 2026-11-09, Luo Hao, Add DEBUG= option to save intermediate datasets for debug
*/

%macro stat_countocc(data=,out=_data_,denom=&data,code=,class=,subject=USUBJID,uncode=UNCODED,totcodelab=_TOTAL_,
  test=NONE,sortclassnum=0,pctfmt=8.1,debug=0)/minoperator;
%local errtext ncode code_sortvar classnlevel _denos_;
/*1. Exception capture and handling*/
%if %quote(&data.)= %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%else %if %quote(&out.)= %then %let errtext=ERROR: Parameter OUT= not specified.;
%else %if %quote(&denom.)= %then %let errtext=ERROR: Parameter DENOM= not specified.;
%else %if %sysfunc(exist(%qscan(&denom.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&denom.) not exist.;
%else %if %quote(&class.)= %then %let errtext=ERROR: Parameter CLASS= not specified.;
%else %if %var_exist(data=&data.,var=&class.)=0 %then %let errtext=ERROR: Variable %quote(&class.) not exist in dataset specified by DATA=.;
%else %if %var_exist(data=&denom.,var=&class.)=0 %then %let errtext=ERROR: Variable %quote(&class.) not exist in dataset specified by DENOM=.;
%else %if %quote(&code.)= %then %let errtext=ERROR: Parameter CODE= not specified.;
%else %if %var_coexist(data=&data.,var=&code.)=0 %then %let errtext=ERROR: At least one variable in parameter CODE= not exist.;
%else %if %quote(&subject.)= %then %let errtext=ERROR: Parameter SUBJECT= not specified.;
%else %if %var_exist(data=&data.,var=&subject.)=0 %then %let errtext=ERROR: Variable %quote(&subject.) not exist in dataset specified by DATA=.;
%else %if %var_exist(data=&denom.,var=&subject.)=0 %then %let errtext=ERROR: Variable %quote(&subject.) not exist in dataset specified by DENOM=.;
%else %if %quote(&test.)= %then %let errtext=ERROR: Parameter TEST= not specified.;
%else %if (%qupcase(&test.) in NONE CHISQ FISHER AUTO)=0 %then %let errtext=ERROR: Parameter TEST= has invalid value, expecting one of: AUTO, CHISQ, FISHER, NONE.;
%else %if %quote(&debug.)= %then %let errtext=ERROR: Parameter DEBUG= not specified.;
%else %if (&debug. in 0 1)=0 %then %let errtext=ERROR: Invalid value of DEBUG=, expecting one of the following: 0, 1.;
%else %if %ds_attr(data=&data.,attr=nlobsf)=0 %then %let errtext=ERROR: Dataset %quote(&data.) has 0 observations.;
%else %if %ds_attr(data=&denom.,attr=nlobsf)=0 %then %let errtext=ERROR: Dataset %quote(&denom.) has 0 observations.;

%exception:
%if %bquote(&errtext.)^= %then %do;
  %put &errtext.;
  %abort cancel;
%end;

%let code=%cmpres(&code.);
%let ncode=%sysfunc(countw(&code.));
%let code_sortvar=%sysfunc(prxchange(s/(\w+)/_$1_type_ $1/,-1,&code.));

/*2. Core processing*/
data stat_countocc_data;
  set &data.;
  %do i=1 %to &ncode.;
    if %scan(&code.,&i.)='' then %scan(&code.,&i.)="&uncode";
    if _n_=1 then do;
      if lengthn("&uncode")>vlength(%scan(&code.,&i.)) then putlog "WARNING: Parameter UNCODE= greater than %upcase(%scan(&code.,&i.)), truncation will occur and cause unstable results.";
    end;
  %end;
  output;
  %do i=1 %to &ncode.;
    %scan(&code.,-&i.)="&totcodelab";
    if _n_=1 then do;
      if lengthn("&totcodelab")>vlength(%scan(&code.,-&i.)) then putlog "WARNING: Parameter TOTCODELAB= greater than %upcase(%scan(&code.,-&i.)), truncation will occur and cause unstable results.";
    end;
    output;
  %end;
run;

proc sql noprint;
  create table stat_countocc_freq as select
    %do i=1 %to &ncode.;
      %let this_code=%scan(&code.,&i.);
      ifn(a.&this_code.="&totcodelab",1,ifn(a.&this_code.^="&uncode",2,3)) as _&this_code._type_, a.&this_code., 
    %end;
    b.&class.,
    count(distinct c.&subject.) as _n_subject_, count(c.&subject.) as _n_event_
  from (select distinct %sysfunc(tranwrd(&code.,%str( ),%str(,))) from stat_countocc_data) as a
  cross join (select distinct &class. from &denom. where missing(&class.)=0) as b
  left join stat_countocc_data as c on %sysfunc(prxchange(%quote(s/(\w+)/a.$1=c.$1 and/),-1,&code.)) b.&class.=c.&class.
  group by 1 %do i=2 %to %eval(2*&ncode.+1); ,&i. %end;
  ;

  select &class., count(distinct &subject.) into :class1-, :_denos_ separated by ','
  from &denom. where missing(&class.)=0 group by &class.;
  %let classnlevel=&sqlobs.;
quit;

%if %upcase(&test.)^=NONE and &classnlevel.>1 %then %do;
  %let test=%upcase(&test.);
  data stat_countocc_test_prepare;
    do _n_=1 by 1 until(last.%scan(&code.,-1));
      set stat_countocc_freq;
      by &code_sortvar.;
      _status_=1;
      output;
      array _deno_[&classnlevel.]_temporary_(&_denos_.);
      _status_=0;
      _n_subject_=_deno_[_n_]-_n_subject_;
      output;
    end;
  run;

  proc freq data=stat_countocc_test_prepare noprint;
    by &code_sortvar.;
    tables _status_*&class./chisq(warn=output) fisher nowarn;
    weight _n_subject_/zeros;
    output out=stat_countocc_chisq chisq fisher;
  run;

  data stat_countocc_test(keep=&code_sortvar. _testv_ _testp_ _testm_);
    if 0 then set stat_countocc_freq(keep=&code_sortvar.);
    set stat_countocc_chisq;
    if "&test."='FISHER' or ("&test."='AUTO' and warn_pchi=1) then do;
      _testv_=.N;
      _testp_=xp2_fish;
      _testm_=cats('Fisher');
    end;
    else if "&test."='CHISQ' or ("&test."='AUTO' and warn_pchi=0) then do;
      _testv_=_pchi_;
      _testp_=p_pchi;
      _testm_='Chisq';
    end;
    label _testv_='Statistics' _testp_='P value' _testm_='Method';
  run;
%end;
%else %if %upcase(&test.)^=NONE %then %put WARNING: No statistics are computed because %quote(&class.) has fewer than 2 nonmissing levels.;

data stat_countocc_result(drop=_n_subject_ _n_event_ &class.);
  do _n_=1 by 1 until(last.%scan(&code.,-1));
    set stat_countocc_freq;
    by &code_sortvar.;

    array _ns_[0:&classnlevel.] ns0-ns&classnlevel.;
    array _ne_[0:&classnlevel.] ne0-ne&classnlevel.;
    array _deno_[0:&classnlevel.]_temporary_(%sysfunc(sum(&_denos_.)),&_denos_.);
    array _np_[0:&classnlevel.] np0-np&classnlevel.;
    array _nsp_[0:&classnlevel.]$20 nsp0-nsp&classnlevel.;
    _ns_[_n_]=_n_subject_;
    _ne_[_n_]=_n_event_;
    _np_[_n_]=_n_subject_/_deno_[_n_]*100;
    _nsp_[_n_]=cats(_ns_[_n_],'(',put(_np_[_n_],&pctfmt.),')');
  end;

  %if %upcase(&test.)^=NONE and &classnlevel.>1 %then %do;
    do until(last.%scan(&code.,-1));
      set stat_countocc_test;
      by &code_sortvar.;
    end;
  %end;

  _ns_[0]=sum(of _ns_[*]);
  _ne_[0]=sum(of _ne_[*]);
  _np_[0]=_ns_[0]/_deno_[0]*100;
  _nsp_[0]=cats(_ns_[0],'(',put(_np_[0],&pctfmt.),')');

  %do i=1 %to %eval(&ncode.-1);
    retain _%scan(&code.,&i.)_ns_;
    if %scan(&code.,%eval(&i.+1))="&totcodelab" then _%scan(&code.,&i.)_ns_=_ns_[&sortclassnum.];
  %end;
  _%scan(&code.,-1)_ns_=_ns_[&sortclassnum.];
  label %do i=1 %to &classnlevel.;
    ns&i.="Number of Subjects of %superq(class&i)" ne&i.="Number of Events of %superq(class&i)"
    np&i.="Percent of Subjects of %superq(class&i)" nsp&i.="Number and Percent of Subjects of %superq(class&i)"
  %end;
  ns0="Number of Subjects" ne0="Number of Events" np0="Percent of Subjects" nsp0="Number and Percent of Subjects";
run; 


proc sort out=&out.;
  by %do i=1 %to &ncode.;
       %let this_code=%scan(&code.,&i.);
       _&this_code._type_ descending _&this_code._ns_ &this_code.
     %end;;
run;

/*3. Cleanup and exit*/
%if &debug.=0 %then %do;
  proc datasets nolist memtype=data;
    delete stat_countocc:;
  quit;
%end;
%mend;
