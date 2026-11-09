/*
*Brief      : Get file attribute value
*Param(Req) : (FILE=)   Full path of a file, including file name
*Param(Req) : (ATTR=)   File attribute name, following values are vaild:
              *Windows:
                FILENAME    : File name
                RECFM       : Record format
                LRECL       : Record length
                FILESIZE    : File size(bytes)
                CRDTM       : Created time in local format
                MODTM       : Last modified time in local format
              *Linux:
                FILENAME    : File name
                FILESIZE    : File size(bytes)
                MODTM       : Last modified time in local format
                OWNER       : File owner
                GROUPNAME   : Group name that file owner belongs to
                PERMISSION  : File permissions
*Param(Opt) : NULL
*Detail     : SAS enviroment variables are supported to used in FILE= option
*Note       : Only Windows and Linux OS are supported
*Note       : Null value will be returned if use SAS 9.4M7 unicode session and Windows OS
              with FILE= contains Chinese character and ATTR= is FILESIZE, CRDTM or MODTM.
              It is a known bug and has been reported to SAS Support Center.
*Usage      : See inner website
*Dependency : NULL
*Version    : SAS 9.4M7
*History    : 2025-12-30, Luo Hao, Original version
*History    : 2026-11-02, Luo Hao, Add ATTRLIST to %local statement
*/
%macro file_attr(file=,attr=);
%local errtext attrlist foptnum _fref_ _fid_ result;

/*1. Exception capture and handling*/
%if %quote(&file.)=%str() %then %let errtext=ERROR: Parameter FILE= not specified.;
%else %if %sysfunc(fileexist(&file.))=0 %then %let errtext=ERROR: File %quote(&file.) not exist.;
%else %if %index(&sysscp.,WIN)=0 and %index(&sysscp.,LIN)=0 %then %let errtext=ERROR: Macro &sysmacroname. called by unsupported operation system.;
%else %do;
  %if %index(&sysscp.,WIN) %then %let attrlist=FILENAME, RECFM, LRECL, FILESIZE, MODTM, CRDTM;
  %else %if %index(&sysscp.,LIN) %then %let attrlist=FILENAME, FILESIZE, MODTM, OWNER, GROUPNAME, PERMISSION;
  %if %sysfunc(prxmatch(/^$|^(?:%sysfunc(tranwrd(%quote(&attrlist.),%str(, ),|)))$/i,%quote(&attr.)))=0 %then %let errtext=ERROR: Parameter ATTR= has invalid value, expecting one of: &attrlist..;
  %else %let foptnum=%sysfunc(whichc(%upcase(&attr.),&attrlist.));
%end;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%let _fref_=%sysfunc(filename(_dummy_,&file.));
%let _fid_=%sysfunc(fopen(&_dummy_.));
%if &_fid_.^=0 %then %do;
  %let result=%qsysfunc(finfo(&_fid_.,%sysfunc(foptname(&_fid_.,&foptnum.))));
  %let _fid_=%sysfunc(fclose(&_fid_.));
%end;
%else %do;
  %let errtext=%sysfunc(sysmsg());
  %goto exception;
%end;
%let _fref_=%sysfunc(filename(_dummy_));
&result.
%mend;
