/*
*Brief      : Get member list of specified library
*Param(Req) : (LIBRARY=)  Library name
*Param(Opt) : (TYPE=)     Variable type to filter member names, following values are vaild:
              DATA      : SAS dataset
              VIEW      : SAS view
              CATALOG   : SAS catalog
              ITEMSTOR  : SAS item store
              MDDB      : SAS specialized data storage facility
*Param(Opt) : (PATTERN=)  Regular expression to filter member names
*Detail     : Member names are returned in upcase
*Note       : NULL
*Usage      : See inner website
*Dependency : NULL
*Version    : SAS 9.4M7
*History    : 2025-12-25, Luo Hao, Original version
*History    : 2026-11-09, Luo Hao, Fix issue: add /minoperator option so TYPE=
              parameter validation (IN operator) works correctly
*/
%macro lib_memlist(library=,type=,pattern=)/minoperator;
%local errtext dict _did_ pat stop memname result;

/*1. Exception capture and handling*/
%if %quote(&library.)=%str() %then %let errtext=ERROR: Parameter LIBRARY= not specified.;
%else %if %sysfunc(libref(%quote(&library.)))^=0 %then %let errtext=ERROR: Library %quote(&library.) not exist.;
%if %bquote(&errtext.)=%str() and %quote(&type.)^=%str() %then %do;
  %if (%qupcase(&type.) in DATA VIEW CATALOG ITEMSTOR MDDB)=0 %then
    %let errtext=ERROR: Parameter TYPE= has invalid value, expecting one of: DATA, VIEW, CATALOG, ITEMSTOR, MDDB.;
%end;
%if %bquote(&errtext.)=%str() and %bquote(&pattern.)^=%str() %then %do;
  %let pat=%sysfunc(prxparse(%bquote(&pattern.)));
  %if %nrbquote(&pat.)=%qsysfunc(getoption(missing)) %then %let errtext=ERROR: Parameter PATTERN= specified invalid regular expression.;
%end;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%if &type.=%str() %then %let _did_=%sysfunc(open(sashelp.vmember(where=(libname="%upcase(&library.)"))));
%else %let _did_=%sysfunc(open(sashelp.vmember(where=(libname="%upcase(&library.)" and memtype="%upcase(&type.)"))));
%if &_did_.^=0 %then %do;
  %do %while(%sysfunc(fetch(&_did_.))=0); 
    %let memname=%sysfunc(getvarc(&_did_.,2));
    %if %bquote(&pattern.)=%str() %then %let result=&result. &memname.;
    %else %if %sysfunc(prxmatch(&pat.,&memname.)) %then %let result=&result. &memname.;
  %end;
  %let _did_=%sysfunc(close(&_did_.));
%end;
%else %do;
  %let errtext=%sysfunc(sysmsg());
  %goto exception;
%end;
&result.
%mend;
