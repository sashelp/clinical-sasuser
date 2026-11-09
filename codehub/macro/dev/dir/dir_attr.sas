/*
*Brief      : Get directory attribute value
*Param(Req) : (DIR=)    Full directory
*Param(Req) : (ATTR=)   Directory attribute name, following values are vaild:
              *Windows:
                DIRECTORY   : Full directory
                NMEMS       : Number of members
              *Linux:
                DIRECTORY   : Full directory
                NMEMS       : Number of members
                OWNER       : Directory owner
                GROUPNAME   : Group name that directory owner belongs to
                PERMISSION  : Directory permissions
*Param(Opt) : NULL
*Detail     : SAS enviroment variables are supported to used in DIR= option
*NOTE       : OS enviroment variables are NOT supported to be used in DIR= option
*NOTE       : Only Windows and Linux OS are supported
*NOTE       : There is no need to enclose directory in quotation marks. Macro will 
              remove outer matching quotation marks even if you specified a pair
*Usage      : See inner website
*Dependency : %dir_exist
*Version    : SAS 9.4M7
*History    : 2025-12-30, Luo Hao, Original version
*History    : 2026-01-15, Luo Hao, Apply %qsysfunc() to dequote(&dir.) to mask 
              special characters
*History    : 2026-11-02, Luo Hao, Add exception capture: Parameter ATTR= not specified
*/
%macro dir_attr(dir=,attr=);
%local errtext attrlist doptnum _dref_ _did_ result;

/*1. Exception capture and handling*/
%if %dir_exist(dir=&dir.)=0 %then %let errtext=ERROR: Directory %quote(&dir.) not exist.;
%else %if %index(&sysscp.,WIN)=0 and %index(&sysscp.,LIN)=0 %then %let errtext=ERROR: Macro &sysmacroname. called by unsupported operation system.;
%else %do;
  %if %quote(&attr.)= %then %let errtext=ERROR: Parameter ATTR= not specified.;
  %else %if %index(&sysscp.,WIN) %then %let attrlist=DIRECTORY, NMEMS;
  %else %if %index(&sysscp.,LIN) %then %let attrlist=DIRECTORY, OWNER, GROUPNAME, PERMISSION, NMEMS;
  %if %sysfunc(prxmatch(/^$|^(?:%sysfunc(tranwrd(%quote(&attrlist.),%str(, ),|)))$/i,%quote(&attr.)))=0 %then %let errtext=ERROR: Parameter ATTR= has invalid value, expecting one of: &attrlist..;
  %else %let doptnum=%sysfunc(whichc(%upcase(&attr.),&attrlist.));
%end;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%let _dref_=%sysfunc(filename(_dummy_,%qsysfunc(dequote(&dir.))));
%let _did_=%sysfunc(dopen(&_dummy_.));
%if &_did_.^=0 %then %do;
  %if %upcase(&attr.)=NMEMS %then %let result=%sysfunc(dnum(&_did_.));
  %else %let result=%qsysfunc(dinfo(&_did_.,%sysfunc(doptname(&_did_.,&doptnum.))));
  %let _did_=%sysfunc(dclose(&_did_.));
%end;
%else %do;
  %let errtext=%sysfunc(sysmsg());
  %goto exception;
%end;
%let _dref_=%sysfunc(filename(_dummy_));
&result.
%mend;
