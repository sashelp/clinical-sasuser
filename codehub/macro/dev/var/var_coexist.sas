/*
*Brief      : Judge multiple variables coexist or not
*Param(Req) : (DATA=)               Dataset name
*Param(Req) : (VAR=)                Multiple variable names
*Param(Req) : (RESULTTYPE=BOOLEAN)  Type of result, following values are vaild:
              BOOLEAN   : Boolean numeric value, macro returns 1 if all variables
                          coexist and match TYPE=, or 0 if any variable does not
                          exist or has a different type
              POSITION  : Variable position, macro returns 1 if all variables
                          coexist and match TYPE=, or -i if the ith variable is
                          the first variable that does not exist or has a
                          different type
*Param(Opt) : (TYPE=ALL)            Variable type to verify, following values are vaild:
              ALL       : Any type
              C         : Character type
              N         : Numeric type
*Detail     : Returns 1 if multiple variables coexist and match TYPE=, or
              non-positive value if not.
*Note       : NULL
*Usage      : See inner website
*Dependency : NULL
*Version    : SAS 9.4M7
*History    : 2025-12-25, Luo Hao, Original version
*History    : 2026-10-28, Luo Hao, Update documentation: DATA= only accepts dataset, view is not supported
*History    : 2026-11-02, Luo Hao, Add TYPE= parameter to verify variable type
*/
%macro var_coexist(data=,var=,resulttype=boolean,type=ALL)/minoperator;
%local errtext _did_ _n_ result;

/*1. Exception capture and handling*/
%if %quote(&data.)= %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%else %if %quote(&var.)= %then %let errtext=ERROR: Parameter VAR= not specified.;
%else %if %quote(&resulttype.)= %then %let errtext=ERROR: Parameter RESULTTYPE= not specified.;
%else %if (%qupcase(&resulttype.) in BOOLEAN POSITION)=0 %then %let errtext=ERROR: Parameter RESULTTYPE= has invalid value, expecting one of: BOOLEAN, POSITION.;
%else %if %qupcase(&type.)^=ALL and %qupcase(&type.)^=C and %qupcase(&type.)^=N %then %let errtext=ERROR: Parameter TYPE= has invalid value, expecting one of: ALL, C, N.;

%exception:
%if %bquote(&errtext.)^= %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%let type=%upcase(&type.);
%let _did_=%sysfunc(open(&data.));
%if &_did_.^=0 %then %do;
  %let _n_=1;
  %do %while(%qscan(&var.,&_n_.,%str( ),q)^= and &result.^=0);
    %let result=%sysfunc(varnum(&_did_.,%qscan(&var.,&_n_.,%str( ),q)));
    %if &result.>0 %then %do;
      %if &type.^=ALL and %upcase(%sysfunc(vartype(&_did_.,&result.)))^=&type. %then %let result=0;
      %else %let result=1;
    %end;
    %let _n_=%eval(&_n_.+1);
  %end;
  %let _did_=%sysfunc(close(&_did_.));
%end;
%else %do;
  %let errtext=%sysfunc(sysmsg());
  %goto exception;
%end;
%if %upcase(&resulttype.)=BOOLEAN %then %sysevalf(&result.,boolean);
%else %sysevalf(-(&result.=0)*&_n_.+1)
%mend;
