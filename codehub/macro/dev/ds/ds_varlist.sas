/*
*Brief      : Get variable list of specified dataset
*Param(Req) : (DATA=)     Dataset name
*Param(Opt) : (TYPE=)     Variable type to filter variable names, following values are vaild:
              C   : Character
              N   : Numeric
*Param(Opt) : (PATTERN=)  Regular expression to filter variable names
*Detail     : Variable names are returned in their raw case, use %upcase() or %lowcase
              to the return value to get upcase or lowercase value
*Note       : NULL
*Usage      : See inner website
*Dependency : NULL
*Version    : SAS 9.4M7
*History    : 2025-12-25, Luo Hao, Original version
*History    : 2026-11-09, Luo Hao, Update documentation: DATA= only accepts dataset, view is not supported
*/
%macro ds_varlist(data=,type=,pattern=);
%local errtext _did_ _n_ pat varname result;

/*1. Exception capture and handling*/
%if %quote(&data.)=%str() %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%else %if %sysfunc(prxmatch(/^$|^[cn]$/i,%quote(&type.)))=0 %then %let errtext=ERROR: Parameter TYPE= has invalid value, expecting one of: C, N.;
%else %if %bquote(&pattern.)^=%str() %then %do;
  %let pat=%sysfunc(prxparse(%bquote(&pattern.)));
  %if %nrbquote(&pat.)=%qsysfunc(getoption(missing)) %then %let errtext=ERROR: Parameter PATTERN= specified invalid regular expression.;
%end;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%let _did_=%sysfunc(open(&data.));
%if &_did_.^=0 %then %do;
  %do _n_=1 %to %sysfunc(attrn(&_did_.,nvars));
    %let varname=%qsysfunc(varname(&_did_.,&_n_.));
    %if %str(&type.)=%str() or %upcase(&type.)=%sysfunc(vartype(&_did_.,&_n_.)) %then %do;
      %if %bquote(&pattern.)=%str() %then %let result=&result. &varname.;
      %else %if %sysfunc(prxmatch(&pat.,&varname.)) %then %let result=&result. &varname.;
    %end;
  %end;
  %let _did_=%sysfunc(close(&_did_.));
%end;
%else %do;
  %let errtext=%sysfunc(sysmsg());
  %goto exception;
%end;
&result.
%mend;
