/*
*Brief      : Compute sample rate, rate confidence limit, rate difference and its confidence limit 
*Param(Req) : (DATA=)               Input dataset name
*Param(Req) : (OUT=_DATA_)          Output dataset name
*Param(Req) : (CLASS=)              A variable who define subgroups for the analysis
*Param(Req) : (VAR=)                An analysis variable
*Param(Req) : (LEVEL=)              Specifies the variable level(formatted value)
*Param(Opt) : (BY=)                 Variables who define separate analyses of observations in groups 
*Param(Opt) : (SMETHOD=EXACT)       Type of single sample rate confidence limit
                                    following values are vaild:
              ALL       : Requests AC, BLAKER, EXACT, JEFFREYS, LR, LOGIT, MIDP, WALD and WILSON confidence limits 
              NONE      : Not request confidence limits 
              AC        : Requests Agresti-Coull confidence limits 
              BLAKER    : Requests Blaker confidence limits 
              EXACT     : Requests exact (Clopper-Pearson) confidence limits  
              JEFFREYS  : Requests Jeffreys confidence limits 
              LR        : Requests likelihood ratio confidence limits  
              LOGIT     : Requests logit confidence limits 
              MIDP      : Requests exact mid-p confidence limits
              WALD      : Requests Wald confidence limits
              WILSON    : Requests Wilson (score) confidence limits
*Param(Opt) : (SALPHA=0.05)         Sets confidence level for single sample rate confidence limits 
*Param(Opt) : (DMETHOD=WALD)        Type of rate difference confidence limit
                                    following values are vaild:
              ALL       : Requests AC, EXACT, HA, MN, NEWCOMBE and WALD confidence limits 
              NONE      : Not request confidence limits 
              AC        : Requests Agresti-Caffo confidence limits 
              EXACT     : Requests exact confidence limits 
              HA        : Requests Hauck-Anderson confidence limits 
              MN        : Requests Miettinen-Nurminen confidence limits 
              NEWCOMBE  : Requests Newcombe confidence limits 
              WALD      : Requests Wald confidence limits 
*Param(Opt) : (DALPHA=0.05)         Sets confidence level for rate difference confidence limits 
*Param(Opt) : (DEBUG=0)             Save or delete intermediate datasets when macro exits
                                    following values are vaild:
              0         : Delete intermediate datasets
              1         : Save intermediate datasets
*Detail     : This macro calculates confidence limits in the assumption of binomial distribution
*Detail     : The LEVEL= option should be specified with formatted value and quoted, so macro
              will calculate binomial proportion for the specified level
*Detail     : If the value of DMETHOD= option is not NONE, rate differences and corresponding 
              confidence limits for any 2 subgroups will be calculated. For both frequencies of
              2 groups are all 0 or 100, manual calculation will be use, else PROC FREQ will
              be use. When use manual calculation, EXACT confidence limits are not avaliable
*Note       : One and only one class variable is supported in CLASS= option
*Note       : One and only one analysis variable is supported in VAR= option
*Note       : If the analytical variable in the input dataset has only one level, you will need
              to increase this to two levels by assigning a format to the analytical variable
*Usage      : See inner website
*Dependency : %var_exist, %var_coexist, %ds_attr
*Version    : SAS 9.4M7
*History    : 2026-08-21, Luo Hao, Original version
*History    : 2026-11-09, Luo Hao, Add exception capture: Input dataset has 0 observations
*/

%macro stat_rateci(data=,out=_data_,by=,class=,var=,level=,smethod=exact,salpha=0.05,dmethod=wald,dalpha=0.05,debug=0)/minoperator;
%local errtext owncustomformat bycomma bycomma_a levelnumber classlist;
/*1. Exception capture and handling*/
%if %quote(&data.)= %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %superq(data) not exist.;
%else %if %ds_attr(data=&data.,attr=nlobsf)=0 %then %let errtext=ERROR: Dataset %quote(&data.) has 0 observations.;
%else %if %quote(&out.)= %then %let errtext=ERROR: Parameter OUT= not specified.;
%else %if %quote(&class.)= %then %let errtext=ERROR: Parameter CLASS= not specified.;
%else %if %var_exist(data=&data.,var=&class.)=0 %then %let errtext=ERROR: Variable %superq(class) not exist.;
%else %if %quote(&var.)= %then %let errtext=ERROR: Parameter VAR= not specified.;
%else %if %var_exist(data=&data.,var=&var.)=0 %then %let errtext=ERROR: Variable %superq(var) not exist.;
%else %if %qsysfunc(first(&level.))^=%str(%') and %qsysfunc(first(&level.))^=%str(%") 
  %then %let errtext=ERROR: Parameter LEVEL= must be specified as formatted value of %superq(var), and surrounded by quotes.;
%else %if %quote(&smethod.)= %then %let errtext=ERROR: Parameter SMETHOD= not specified.;
%else %if %quote(&dmethod.)= %then %let errtext=ERROR: Parameter DMETHOD= not specified.;
%else %if (&debug. in 0 1)=0 %then %let errtext=ERROR: Invalid value of DEBUG=, expecting one of the following: 0, 1.;
%else %if %quote(&by)^= %then %do;
  %if %var_coexist(data=&data.,var=&by.)=0 %then %let errtext=ERROR: At least one variable in parameter BY= not exist.;
%end;

%if %bquote(&errtext.)= %then %do;
  %if %qupcase(&smethod.)=NONE and %qupcase(&dmethod.)=NONE %then %let errtext=ERROR: No computation since both values of SMETHOD= and DMETHOD= are NONE.;
  %if %qupcase(&smethod.)^=NONE %then %do;
    %do i=1 %to %sysfunc(countw(&smethod.));
      %if not(%upcase(%scan(&smethod.,&i.,%str( ))) in (ALL NONE AC BLAKER EXACT JEFFREYS LR LOGIT MIDP WALD WILSON)) %then
        %let errtext=ERROR: Invalid value of SMETHOD=, expecting one of the following: ALL, NONE, AC, BLAKER, EXACT, JEFFREYS, LR, LOGIT, MIDP, WALD, WILSON.;
    %end;
    %if %sysevalf(&salpha.<0) or %sysevalf(&salpha.>1) %then %let errtext=ERROR: Invalid value of SALPHA=, expecting value between 0 and 1.;
  %end;
  %if %qupcase(&dmethod.)^=NONE %then %do;
    %do i=1 %to %sysfunc(countw(&dmethod.));
      %if not(%upcase(%scan(&dmethod.,&i.,%str( ))) in (ALL NONE AC EXACT HA MN NEWCOMBE WALD)) %then
        %let errtext=ERROR: Invalid value of dmethod=, expecting one of the following: ALL, NONE, AC, EXACT, HA, MN, NEWCOMBE, WALD.;
    %end;
    %if %sysevalf(&dalpha.<0) or %sysevalf(&dalpha.>1) %then %let errtext=ERROR: Invalid value of dalpha=, expecting value between 0 and 1.;
  %end;
%end;

%if %bquote(&errtext.)= %then %do;
  data _null_;
    do until(_eof_=1 or _n_>3);
      set &data. end=_eof_;
      array _par_[3] $32767 _temporary_;
      if strip(vvalue(&var.)) not in _par_ then do;
        _par_[_n_]=strip(vvalue(&var.));
        _n_+1;
      end;
    end;
    if cmiss(of _par_[*])^=1 then call symputx('errtext',"ERROR: &var. has more or less than 2 levels.");
    else if (&level. in _par_)=0 then call symputx('errtext',"ERROR: Value of LEVEL= option not exist in analysis variable.");
    stop;
  run;
%end;

%exception:
%if %bquote(&errtext.)^= %then %do;
  %put &errtext.;
  %abort cancel;
%end;

%let bycomma=%sysfunc(tranwrd(%cmpres(&by.),%str( ),%str(,)));
%let bycomma_a=%sysfunc(tranwrd(%cmpres(&by.),%str( ),%str(,a.)));
%let smethod=%upcase(&smethod.);
%if &smethod.=ALL %then %let smethod=AC BLAKER EXACT JEFFREYS LR LOGIT MIDP WALD WILSON;
%let dmethod=%upcase(&dmethod.);
%if &dmethod.=ALL %then %let dmethod=AC EXACT HA MN NEWCOMBE WALD;

/*2. Core processing*/
/*2.1 Compute frequency*/
/*2.1.1 Data check*/
%if %quote(&by.)^= %then %do;
  proc sort data=&data. out=stat_rateci_inds;
    by &by.;
  run;
%end;
%else %do;
  data stat_rateci_inds;
    set &data.;
  run;
%end;

/*2.1.2 If analysis variable owns custom format, use preloadfmt skill to compute frequency*/
/*    else use SQL to compute frequency*/
proc contents data=stat_rateci_inds out=stat_rateci_varattr(where=(upcase(name)="%upcase(&var.)")) noprint;
run;

proc sql noprint;
  select '1' into :owncustomformat from stat_rateci_varattr 
  where format in (select fmtname from dictionary.formats where source='C');
quit;

%if &owncustomformat.=1 %then %do;
  proc summary data=stat_rateci_inds nway completetypes;
    by &by.;
    class &class. &var./preloadfmt;
    output out=stat_rateci_freq /levels;
  run;
%end;
%else %do;
  proc sql noprint;
    create table stat_rateci_freq as 
    %if %quote(&by.)^= %then %do;
      select a.*, b.*, c.*, count(d.&var.) as _freq_
      from (select distinct &bycomma. from stat_rateci_inds) as a
      cross join (select distinct &class. from stat_rateci_inds) as b
      cross join (select distinct &var. from stat_rateci_inds where &var. is not missing) as c
      left join stat_rateci_inds as d on b.&class.=d.&class. and c.&var.=d.&var.
      %do i=1 %to %sysfunc(countw(&by.));
        and a.%scan(&by.,&i.,%str( ))=d.%scan(&by.,&i.,%str( ))
      %end;
      group by a.&bycomma_a., b.&class., c.&var.
      order by &bycomma., &class.
      ;
    %end;
    %else %do;
      select b.*, c.*, count(d.&var.) as _freq_
      from (select distinct &class. from stat_rateci_inds) as b
      cross join (select distinct &var. from stat_rateci_inds where &var. is not missing) as c
      left join stat_rateci_inds as d on b.&class.=d.&class. and c.&var.=d.&var.
      group by b.&class., c.&var.
      order by &class.
      ;
    %end;
  quit;
%end;

/*2.2 Compute single sample proportion and confidence limits*/
%if &smethod.=NONE %then %goto riskdiff;
proc freq data=stat_rateci_freq noprint;
  by &by. &class.;
  tables &var./bin(level=&level. cl=(&smethod.) outlevel) alpha=&salpha. nowarn;
  weight _freq_/zeros;
  output out=stat_rateci_single1 bin;
run;

data stat_rateci_single2(where=(_cl_l_>.));
  set stat_rateci_single1;

  array _l_ L_AC_BIN L_BK_BIN XL_BIN L_J_BIN L_LR_BIN L_LG_BIN L_MP_BIN L_BIN L_W_BIN;
  array _u_ U_AC_BIN U_BK_BIN XU_BIN U_J_BIN U_LR_BIN U_LG_BIN U_MP_BIN U_BIN U_W_BIN;
  array _m_[9]$200. _temporary_('Agresti-Coull','Blaker','Exact','Jeffreys','Likelihood Ratio','Logit','Mid-p','Wald','Wilson'); 
  do _n_=1 to dim(_m_);
    _method_=_m_[_n_];
    _cl_l_=_l_[_n_];
    _cl_u_=_u_[_n_];
    output;
  end;
  keep &by. &class.--_bin_ _method_ _cl_l_ _cl_u_;
run;

/*2.3 Compute pairwise sample proportion difference and confidence limits*/
%riskdiff:
%if &dmethod.=NONE %then %goto combine;
/*2.3.1 Make pairs*/
proc sql;
  create table stat_rateci_classpair as
  select distinct a.&class., b.&class. as ref_&class. 
  from stat_rateci_freq a, stat_rateci_freq b where a.&class.^=b.&class.;
quit;

data stat_rateci_pairwise(drop=_did_);
  if 0 then set stat_rateci_freq;
  set stat_rateci_classpair(drop=ref_&class.)
      stat_rateci_classpair(in=_ref_ rename=(ref_&class.=&class.) drop=&class.) nobs=_nobs_;
  if vtype(&class.)='N' then _did_=open(cats('stat_rateci_freq(where=(&class.=',&class.,'))'));
  else _did_=open(cats('stat_rateci_freq(where=(&class.=''',&class.,'''))'));
  if _did_ then do;
    _pair_=ifn(_ref_,ceil(_n_-_nobs_/2),_n_);
    call set(_did_);
    do while(fetch(_did_)=0);
      output;
    end;
    _did_=close(_did_);
  end;
run;

proc sort data=stat_rateci_pairwise;
  by _pair_ &by. &var.;
run;

/*2.3.2 Compute rate difference by proc freq*/
data _null_;
  set stat_rateci_pairwise(obs=3);
  if cats(vvalue(&var.))=&level. then call symputx('levelnumber',ceil(_n_/2));
run;

ods select none;
ods output pdiffcls=stat_rateci_diff1;
proc freq data=stat_rateci_pairwise order=data;
  by _pair_ &by.;
  tables &class.*&var./riskdiff(cl=(&dmethod.) column=&levelnumber.) alpha=&dalpha.;
  %if %index(&dmethod.,EXACT) %then %str(exact riskdiff;);
  weight _freq_/zeros;
run;
ods output close;
ods select all;

data stat_rateci_diff2;
  set stat_rateci_diff1;
  set stat_rateci_classpair point=_pair_;
run;

/*2.3.3 Compute rate difference formulas(Only for both frequencies of 2 groups are all 0 or 100)*/
/*2.3.3.1 Merge frequency of different groups for pairwise comparision*/
data stat_rateci_diff_manual1;
  do until(last.&class.);
    set stat_rateci_freq;
    by &by. &class.;
    if strip(vvalue(&var.))=&level. then _s1_=_freq_;
    _n1_=sum(_n1_,_freq_);
  end;
  keep &by. &class. _n1_ _s1_;
run;

proc sql noprint;
  create table stat_rateci_diff_manual2 as 
  select a.*, b.&class. as ref_&class., b._s1_ as _s2_, b._n1_ as _n2_
  from stat_rateci_diff_manual1 as a
  left join stat_rateci_diff_manual1 as b on 1=1 %if &by.^= %then %do i=1 %to %sysfunc(countw(&by.));
    and a.%scan(&by.,&i.,%str( ))=b.%scan(&by.,&i.,%str( ))
  %end;
    and a.&class.^=b.&class.
  order by %if &by.^= %then %str(&bycomma.,); &class., ref_&class.
  ;
quit;

%if %sysfunc(prxmatch(/\b(?:AC|HA|MN|NEWCOMBE|WALD)\b/,&dmethod.)) %then %do;
  /*2.3.3.2 Calculate the risk differences between groups and confidence limits*/
  data stat_rateci_diff_manual3;
    set stat_rateci_diff_manual2;
    where (_s1_=0 and _s2_=0) or (_s1_=_n1_ and _s2_=_n2_);

    *Move all float computation into one data step to avoid round-off error;
    _ps1_=_s1_/_n1_;
    _ps2_=_s2_/_n2_;
    _d_=_ps1_-_ps2_;
    _z_=probit(1-&dalpha./2);
    _se_=sqrt(_ps1_*(1-_ps1_)/_n1_+_ps2_*(1-_ps2_)/_n2_);

    length _method_ $200.;
    %if %index(&dmethod.,AC) %then %do;
      _method_='Agresti-Caffo';
      call missing(_cl_l_,_cl_u_);
      _ps1_bar_=(_s1_+1)/(_n1_+2);
      _ps2_bar_=(_s2_+1)/(_n2_+2);
      _d_bar_=_ps1_bar_-_ps2_bar_;
      _se_bar_=sqrt(_ps1_bar_*(1-_ps1_bar_)/(_n1_+2)+_ps2_bar_*(1-_ps2_bar_)/(_n2_+2));
      _cl_l_=_d_bar_-_z_*_se_bar_;
      _cl_u_=_d_bar_+_z_*_se_bar_;
      output;
    %end;

    %if %index(&dmethod.,HA) %then %do;
      _method_='Hauck-Anderson';
      call missing(_cl_l_,_cl_u_);
      if _n1_>1 and _n2_>1 then do;
        _c_=1/(2*min(_n1_,_n2_));
        _se_bar_=sqrt(_ps1_*(1-_ps1_)/(_n1_-1)+_ps2_*(1-_ps2_)/(_n2_-1));
        _cl_l_=_d_-(_c_+_z_*_se_bar_);
        _cl_u_=_d_+(_c_+_z_*_se_bar_);
      end;
      output;
    %end;

    %if %index(&dmethod.,MN) %then %do;
      _method_='Miettinen-Nurminen';
      call missing(_cl_l_,_cl_u_);
      if _s1_+_s2_>1 then do;
        _den_=(_s1_+_s2_)/(_s1_+_s2_-1);
        _cl_l_=0-_z_**2/_n1_*_den_/(1+_z_**2/_n1_*_den_);
        _cl_u_=0+_z_**2/_n2_*_den_/(1+_z_**2/_n2_*_den_);
      end;
      output;
    %end;

    %if %index(&dmethod.,NEWCOMBE) %then %do;
      _method_='Newcombe';
      call missing(_cl_l_,_cl_u_);
      *Start - Binomial wilson confidence limits;
      _wil_ps1_=(_ps1_+_z_**2/(2*_n1_))/(1+_z_**2/_n1_);
      _wil_se1_=sqrt((_ps1_*(1-_ps1_)+_z_**2/(4*_n1_))/_n1_)/(1+_z_**2/_n1_);
      _wil_l1_=_wil_ps1_-_z_*_wil_se1_;
      _wil_u1_=_wil_ps1_+_z_*_wil_se1_;
      
      _wil_ps2_=(_ps2_+_z_**2/(2*_n2_))/(1+_z_**2/_n2_);
      _wil_se2_=sqrt((_ps2_*(1-_ps2_)+_z_**2/(4*_n2_))/_n2_)/(1+_z_**2/_n2_);
      _wil_l2_=_wil_ps2_-_z_*_wil_se2_;
      _wil_u2_=_wil_ps2_+_z_*_wil_se2_;
      *End - Binomial wilson confidence limits;
      
      _cl_l_=_d_-sqrt((_ps1_-_wil_l1_)**2+(_wil_u2_-_ps2_)**2);
      _cl_u_=_d_+sqrt((_wil_u1_-_ps1_)**2+(_ps2_-_wil_l2_)**2);
      output;
    %end;

    %if %index(&dmethod.,WALD) %then %do;
      _method_='Wald';
      call missing(_cl_l_,_cl_u_);
      _cl_l_=_d_-_z_*_se_;
      _cl_u_=_d_+_z_*_se_;
      output;
    %end;
  run;
%end;

/*2.4. Combine all results*/
%combine:
%if &dmethod.^=NONE %then %let classlist=&class. ref_&class.;
%else %let classlist=&class.;
data &out.;
  retain &by. &classlist. _method_ _prop_ _alpha_ _cl_l_ _cl_u_;
  length _method_ $200.;
  call missing(_method_,_prop_,_alpha_,_cl_l_,_cl_u_,_z_,_single_);
  set %if &smethod.^=NONE %then %str(stat_rateci_single2(rename=(_bin_=_prop_) in=_single_));
      %if &dmethod.^=NONE %then %str(stat_rateci_diff2(rename=(riskdifference=_prop_ type=_method_ lowercl=_cl_l_ uppercl=_cl_u_)));
      %if %sysfunc(exist(stat_rateci_diff_manual3)) %then %str(stat_rateci_diff_manual3(rename=(_d_=_prop_)));
      ;

  if _prop_>. then _prop_=_prop_*100;
  else _prop_=.;
  if _cl_l_>. then _cl_l_=_cl_l_*100;
  else _cl_l_=.;
  if _cl_u_>. then _cl_u_=_cl_u_*100;
  else _cl_u_=.;
  _alpha_=ifn(_single_,&salpha.,&dalpha.);
  _source_=ifc(_z_,'MANUAL','PROC FREQ');
  keep &by. &classlist. _method_ _prop_ _alpha_ _cl_l_ _cl_u_ _source_;
  label _prop_='Rate and Rate Difference' _alpha_='Alpha' _cl_l_='Confidence Limit Lower' _cl_u_='Confidence Limit Upper';
run;

proc sort data=&out.;
  by &by. &classlist. _method_;
run;

/*3. Cleanup and exit*/
%if &debug.=0 %then %do;
  proc datasets nolist memtype=data;
    delete stat_rateci_:;
  quit;
%end;
%mend;
