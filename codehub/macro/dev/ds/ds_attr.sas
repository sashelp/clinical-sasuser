/*
*Brief      : Get SAS dataset attribute value
*Param(Req) : (DATA=)   Dataset name
*Param(Req) : (ATTR=)   Dataset attribute name, following values are vaild:
              See SAS system function ATTRC() and ATTRN()
*Param(Opt) : NULL
*Detail     : NULL
*Note       : If you want to get number of observations of the dataset, try:
              ATTR=NOBS, in most situation
              ATTR=NLOBS, when input dataset was modified with REMOVE statement 
              ATTR=NLOBSF, when input dataset includes WHERE= dataset option
*Usage      : See inner website
*Dependency : NULL
*Version    : SAS 9.4M7
*History    : 2025-12-25, Luo Hao, Original version
*History    : 2026-11-07, Luo Hao, Update documentation: DATA= only accepts dataset, view is not supported
*/
%macro ds_attr(data=,attr=)/minoperator;
%local errtext _did_ funcname result;

/*1. Exception capture and handling*/
%if %quote(&data.)=%str() %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%else %if %quote(&attr.)=%str() %then %let errtext=ERROR: Parameter ATTR= not specified.;
%else %if (%qupcase(&attr.) in 
  CHARSET COMPRESS DATAREP ENCODING ENCRYPT ENGINE LABEL LIB MEM MODE MTYPE SORTEDBY SORTLVL SORTSEQ TYPE
  ALTERPW ANOBS ANY ARAND ARWU AUDIT AUDIT_DATA AUDIT_BEFORE AUDIT_ERROR CRDTE ICONST INDEX ISINDEX
  ISSUBSET LRECL LRID MAXGEN MAXRC MODTE NDEL NEXTGEN NLOBS NLOBSF NOBS NVARS PW RADIX READPW
  REUSE TAPE WHSTMT WRITEPW)=0 
%then %let errtext=ERROR: Parameter ATTR= has invalid value, expecting valid attribute value of system function attrn() or attrc().;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%let _did_=%sysfunc(open(&data.));
%if &_did_.^=0 %then %do;
  %if (%qupcase(&attr.) in CHARSET COMPRESS DATAREP ENCODING ENCRYPT ENGINE LABEL LIB MEM MODE 
    MTYPE SORTEDBY SORTLVL SORTSEQ TYPE) %then %let funcname=attrc;
  %else %let funcname=attrn;
  %let result=%qsysfunc(&funcname.(&_did_.,&attr.));
  %let _did_=%sysfunc(close(&_did_.));
%end;
%else %do;
  %let errtext=%sysfunc(sysmsg());
  %goto exception;
%end;
&result.
%mend;
