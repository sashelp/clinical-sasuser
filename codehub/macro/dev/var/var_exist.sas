/*
*Brief      : Judge variable exists or not
*Param(Req) : (DATA=)  Dataset name (dataset only, view is not supported)
*Param(Req) : (VAR=)   Variable name
*Param(Opt) : (TYPE=ALL) Variable type to verify, following values are vaild:
              ALL       : Any type
              C         : Character type
              N         : Numeric type
*Detail     : Returns 1 if the variable exists and is of the type specified by
              TYPE=, or 0 if not.
*Note       : NULL
*Usage      : See inner website
*Dependency : NULL
*Version    : SAS 9.4M7
*History    : 2025-12-25, Luo Hao, Original version
*History    : 2026-10-29, Luo Hao, Update documentation: DATA= only accepts dataset, view is not supported
*History    : 2026-11-02, Luo Hao, Add TYPE= parameter to verify variable type
*/
%macro var_exist(data=,var=,type=ALL);
%local errtext _did_ result;

/*1. Exception capture and handling*/
%if %quote(&data.)=%str() %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%else %if %quote(&var.)=%str() %then %let errtext=ERROR: Parameter VAR= not specified.;
%else %if %sysfunc(nvalid(%quote(&var.),%sysfunc(getoption(validvarname))))=0 %then %let errtext=ERROR: %quote(&var.) is invalid variable name.;
%else %if %qupcase(&type.)^=ALL and %qupcase(&type.)^=C and %qupcase(&type.)^=N %then %let errtext=ERROR: Parameter TYPE= has invalid value, expecting one of: ALL, C, N.;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%let type=%upcase(&type.);
%let _did_=%sysfunc(open(&data.));
%if &_did_.^=0 %then %do;
  %let result=%sysfunc(varnum(&_did_.,%quote(&var.)));
  %if &result.>0 %then %do;
    %if &type.^=ALL and %upcase(%sysfunc(vartype(&_did_.,&result.)))^=&type. %then %let result=0;
    %else %let result=1;
  %end;
  %let _did_=%sysfunc(close(&_did_.));
%end;
%else %do;
  %let errtext=%sysfunc(sysmsg());
  %goto exception;
%end;
&result.
%mend;
