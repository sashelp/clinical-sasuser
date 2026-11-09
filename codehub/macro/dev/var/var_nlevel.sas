/*
*Brief      : Get number of levels of specified variable
*Param(Req) : (DATA=)  Dataset name (dataset only, view is not supported)
*Param(Req) : (VAR=)   Variable name
*Param(Opt) : (INCLUDEMISSING=N)  Whether to include missing values in the level count,
              following values are valid:
              N : Missing values are excluded
              Y : Missing values are included. Character missing values count as one level;
                  for numeric variables, ordinary missing (.) and each special missing
                  value (.A-.Z, ._) count as separate levels
*Detail     : Returns the number of distinct values of VAR= in DATA=. For character
              variables, values that differ only by trailing blanks are treated as one
              level. Formats do not affect the count.
*Note       : DATA= is read observation by observation with macro FETCH, processing time
              is proportional to the number of observations and levels
*Note       : For numeric variables, values are compared by their character representation
              returned by GETVARN; differences beyond the displayed precision are not
              distinguished
*Usage      : See inner website
*Dependency : %var_exist
*Version    : SAS 9.4M7
*History    : 2026-11-01, Luo Hao, Original version
*/
%macro var_nlevel(data=,var=,includemissing=N)/minoperator;
%local errtext _did_ _varpos_ _vartype_ _nlevel_ _k_ _dup_ _value_ _skip_ _hasmiss_;

/*1. Exception capture and handling*/
%if %quote(&data.)=%str() %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%else %if %quote(&var.)=%str() %then %let errtext=ERROR: Parameter VAR= not specified.;
%else %if %sysfunc(nvalid(%quote(&var.),%sysfunc(getoption(validvarname))))=0 %then %let errtext=ERROR: %quote(&var.) is invalid variable name.;
%else %if %quote(&includemissing.)=%str() %then %let errtext=ERROR: Parameter INCLUDEMISSING= has invalid value, expecting one of: N, Y.;
%else %if (%qupcase(&includemissing.) in N Y)=0 %then %let errtext=ERROR: Parameter INCLUDEMISSING= has invalid value, expecting one of: N, Y.;
%else %if %var_exist(data=&data.,var=&var.)=0 %then %let errtext=ERROR: Variable %quote(&var.) not exist.;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%let _did_=%sysfunc(open(&data.));
%if &_did_.^=0 %then %do;
  %let _varpos_=%sysfunc(varnum(&_did_.,%quote(&var.)));
  %let _vartype_=%sysfunc(vartype(&_did_.,&_varpos_.));
  %let _nlevel_=0;
  %let _hasmiss_=0;
  %do %while(%sysfunc(fetch(&_did_.))=0);
    %let _skip_=0;
    %if &_vartype_.=C %then %do;
      %let _value_=%qsysfunc(trim(%qsysfunc(getvarc(&_did_.,&_varpos_.))));
      %if %length(%superq(_value_))=0 or %superq(_value_)=%str( ) %then %do;
        %let _skip_=1;
        %let _hasmiss_=1;
      %end;
    %end;
    %else %do;
      %let _value_=%qsysfunc(getvarn(&_did_.,&_varpos_.));
      %if %length(%superq(_value_))=1 and %index(.ABCDEFGHIJKLMNOPQRSTUVWXYZ_,%upcase(%superq(_value_)))>0 %then %do;
        %if %upcase(&includemissing.)=N %then %let _skip_=1;
        %else %let _value_=#M#&_value_.;
      %end;
    %end;
    %if &_skip_.=0 %then %do;
      %let _dup_=0;
      %do _k_=1 %to &_nlevel_.;
        %if %superq(_seen_&_k_.)=%superq(_value_) %then %let _dup_=1;
      %end;
      %if &_dup_.=0 %then %do;
        %let _nlevel_=%eval(&_nlevel_.+1);
        %let _seen_&_nlevel_.=&_value_.;
      %end;
    %end;
  %end;
  %if &_hasmiss_.=1 and %upcase(&includemissing.)=Y %then %let _nlevel_=%eval(&_nlevel_.+1);
  %let _did_=%sysfunc(close(&_did_.));
%end;
%else %do;
  %let errtext=%sysfunc(sysmsg());
  %goto exception;
%end;
&_nlevel_.
%mend;
