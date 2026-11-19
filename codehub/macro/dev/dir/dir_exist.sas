/*
*Brief      : Judge directory exists or not
*Param(Req) : (DIR=)    Full directory
*Param(Opt) : NULL
*Detail     : Returns 1 if the directory exist, or 0 if not.
*Detail     : SAS enviroment variables are supported to be used in DIR= option
*NOTE       : OS enviroment variables are NOT supported to be used in DIR= option
*NOTE       : There is no need to enclose directory in quotation marks. Macro will
              remove outer matching quotation marks even if you specified a pair
*Usage      : See inner website
*Dependency : NULL
*Version    : SAS 9.4M7
*History    : 2025-12-30, Luo Hao, Original version
*History    : 2026-01-15, Luo Hao, Apply %qsysfunc() to dequote(&dir.) to mask 
              special characters
*History    : 2026-11-09, Luo Hao, Fix issue: Add _dref_ as local macro variable
*/
%macro dir_exist(dir=);
%local errtext _did_ _dref_ result;

/*1. Exception capture and handling*/
%if %quote(&dir.)=%str() %then %let errtext=ERROR: Parameter DIR= not specified.;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%let _dref_=%sysfunc(filename(_dummy_,%qsysfunc(dequote(&dir.))));
%let _did_=%sysfunc(dopen(&_dummy_.));
%if &_did_.^=0 %then %do;
  %let result=1;
  %let _did_=%sysfunc(dclose(&_did_.));
%end;
%else %let result=0;
%let _dref_=%sysfunc(filename(_dummy_));
&result.
%mend;
