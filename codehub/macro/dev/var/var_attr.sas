/*
*Brief      : Get variable attribute value
*Param(Req) : (DATA=)  Dataset name
*Param(Req) : (VAR=)   Variable name
*Param(Req) : (ATTR=)  Variable attribute name, following values are vaild:
              NUM       : Variable's position
              NAME      : Variable's name
              TYPE      : Variable's type
              LENGTH    : Variable's length
              FORMAT    : Variable's format
              INFORMAT  : Variable's informat
              LABEL     : Variable's label
*Param(Opt) : NULL
*Detail     : NULL
*Note       : NULL
*Usage      : See inner website
*Dependency : %var_exist
*Version    : SAS 9.4M7
*History    : 2025-12-25, Luo Hao, Original version
*History    : 2026-07-22, Luo Hao, Remove debug code
*History    : 2026-10-29, Luo Hao, Update documentation: DATA= only accepts dataset, view is not supported
*/
%macro var_attr(data=,var=,attr=)/minoperator;
%local errtext _did_ varnum result;

/*1. Exception capture and handling*/
%if %var_exist(data=&data.,var=&var.)=0 %then %let errtext=ERROR: Variable %quote(&var.) not exist.;
%else %if %quote(&attr.)=%str() %then %let errtext=ERROR: Parameter ATTR= not specified.;
%else %if (%qupcase(&attr.) in NUM NAME TYPE LENGTH FORMAT INFORMAT LABEL)=0 %then 
  %let errtext=ERROR: Parameter ATTR= has invalid value, expecting one of: NUM, NAME, TYPE, LENGTH, FORMAT, INFORMAT, LABEL.;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%let _did_=%sysfunc(open(&data.));
%if &_did_.^=0 %then %do;
  %let varnum=%sysfunc(varnum(&_did_.,%quote(&var.)));
  %if %upcase(&attr.)=NUM %then %let result=&varnum.;
  %else %do;
    %if %upcase(&attr.)=LENGTH %then %let result=%sysfunc(varlen(&_did_.,&varnum.));
    %else %if %upcase(&attr.)=FORMAT %then %let result=%sysfunc(varfmt(&_did_.,&varnum.));
    %else %if %upcase(&attr.)=INFORMAT %then %let result=%sysfunc(varinfmt(&_did_.,&varnum.));
    %else %let result=%sysfunc(var&attr.(&_did_.,&varnum.));
  %end;
  %let _did_=%sysfunc(close(&_did_.));
%end;
%else %do;
  %let errtext=%sysfunc(sysmsg());
  %goto exception;
%end;
&result.
%mend;
