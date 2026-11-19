/*
*Brief      : Adjust the length of character variables of input library to the optimal length
*Param(Req) : (LIBRARY=)        Library name
*Param(Opt) : (DELFMT=Y)        Delete format of character variables, following values are vaild:
              Y:    Delete current format and use $n. as new format, where n is the best length
              N:    Keep current format
*Param(Opt) : (DELINFMT=Y)      Remove informat of character variables, following values are vaild:
              Y:    Delete current informat and use $n. as new informat, where n is the best length
              N:    Keep current informat
*Param(Opt) : (SUPP_POLICY=FDA) Policy to treat dataset with SUPP as prefix, following values are vaild:
              CDE:  Set length of character variables to maximum used length in all datasets of library
              FDA:  Set length of character variables to maximum used length in the current dataset
*Detail     : CAUTION! This macro will modify input library irreversibly
*Detail     : This macro was designed to satisfy clinical trial data submission
              (LINK: https://www.nmpa.gov.cn/xxgk/ggtg/ypggtg/ypqtggtg/20200720171201514.html)
              (LINK: https://www.fda.gov/media/88173/download)
*Note       : Specified dataset name(lib_univarlen1) will be used, avoid name clashes
              or the original file with the same name will be overwritten and cannot
              be recovered.
*Usage      : See inner website
*Dependency : %ds_zipvarlen
*Version    : SAS 9.4M7
*History    : 2025-12-25, Luo Hao, Original version
*History    : 2026-05-22, Luo Hao, Add parameter: delfmt=Y,delinfmt=Y
*History    : 2026-09-23, Luo Hao, Add parameter: supp_policy=FDA
*History    : 2026-10-29, Luo Hao, Fix issue: add /minoperator option so VALUE= and MISSING=
              parameter validation (IN operator) works correctly
*/
%macro lib_zipvarlen(library=,delfmt=Y,delinfmt=Y,supp_policy=FDA)/minoperator;
%local errtext;
/*1. Exception capture and handling*/
%if %quote(&library.)=%str() %then %let errtext=ERROR: Parameter LIBRARY= not specified.;
%else %if %sysfunc(libref(%quote(&library.)))^=0 %then %let errtext=ERROR: Library %quote(&library.) not exist.;
%else %if (%qupcase(&delfmt.) in N Y)=0 %then %let errtext=ERROR: Parameter DELFMT= has invalid value, expecting one of: N, Y.;
%else %if (%qupcase(&delinfmt.) in N Y)=0 %then %let errtext=ERROR: Parameter DELINFMT= has invalid value, expecting one of: N, Y.;
%else %if (%qupcase(&supp_policy.) in CDE FDA)=0 %then %let errtext=ERROR: Parameter SUPP_POLICY= has invalid value, expecting one of: CDE, FDA.;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
/*2.1 Using single dataset to modify length independently*/
data _null_;
  set sashelp.vstable;
  where libname="%upcase(&library.)";
  call execute('%ds_zipvarlen(data=&library..'||trim(memname)||',delfmt=&delfmt.,delinfmt=&delinfmt.)');
run;

/*2.2 Using all dataset to modify length jointly*/
proc sql;
  create table lib_univarlen1 as 
  select memname, name, length, max(length) as max_length
  from dictionary.columns
  where libname="%upcase(&library.)" and type='char' 
    %if %upcase(&supp_policy.)=FDA %then %str(and substrn(memname,1,4)^='SUPP');
  group by name
  order by memname
  ;
quit;

data _null_;
  set lib_univarlen1;
  where length<max_length;
  by memname;

  if first.memname then call execute('proc sql;alter table &library..'||trim(memname));
  call execute('modify '||trim(name)||' char('||cats(max_length)||')'
    %if %upcase(&delfmt.)=Y %then %str(||' format=$'||cats(max_length)||'.'); 
    %if %upcase(&delinfmt.)=Y %then %str(||' informat=$'||cats(max_length)||'.'); 
  );
  if last.memname then call execute(';quit;');
run;

/*3. Exit*/
proc delete data=lib_univarlen1;
run;
%mend;
