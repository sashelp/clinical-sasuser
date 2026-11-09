/*
*Brief      : Adjust the length of character variables of input dataset to the optimal length
*Param(Req) : (DATA=)           Dataset name
*Param(Opt) : (DELFMT=Y)        Delete format of character variables, following values are vaild:
              Y:   Delete current format and use $n. as new format, where n is the best length
              N:   Keep current format
*Param(Opt) : (DELINFMT=Y)      Remove informat of character variables, following values are vaild:
              Y:   Delete current informat and use $n. as new informat, where n is the best length
              N:   Keep current informat
*Detail     : CAUTION! This macro will modify input dataset irreversibly
*Note       : Specified names(_eof_, _chr_, _len_, _zip_) and variable names
              of input dataset are used together, avoid name clashes or the 
              macro will fail
*Usage      : See inner website
*Dependency : %ds_attr, %ds_varlist
*Version    : SAS 9.4M7
*History    : 2025-12-31, Luo Hao, Original version
*History    : 2026-01-29, Luo Hao, Fix issue: Macro doesn't process dataset with 0 observation
*History    : 2026-02-24, Luo Hao, Optimize: Use DOW-Loop to accelerate data step
*History    : 2026-11-09, Luo Hao, Fix issue: Drop macro variable i, add _n_ as local macro variable
*/
%macro ds_zipvarlen(data=,delfmt=Y,delinfmt=Y)/minoperator;
%local errtext _did_ _n_ nobs cvarlist cvarcount;
/*1. Exception capture and handling*/
%if %quote(&data.)=%str() %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%else %if (%qupcase(&delfmt.) in N Y)=0 %then %let errtext=ERROR: Parameter DELFMT= has invalid value, expecting one of: N, Y.;
%else %if (%qupcase(&delinfmt.) in N Y)=0 %then %let errtext=ERROR: Parameter DELINFMT= has invalid value, expecting one of: N, Y.;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%let nobs=%ds_attr(data=&data.,attr=nobs);
%let cvarlist=%ds_varlist(data=&data.,type=c);
%if %bquote(&cvarlist.)^=%str() %then %let cvarcount=%sysfunc(countw(&cvarlist.));
%else %let cvarcount=0;

%if &nobs.>0 and &cvarcount.>0 %then %do;
  data _null_;
    do until(_eof_);
      set &data. end=_eof_;
      array _chr_ _character_;
      array _len_ [&cvarcount.]_temporary_;
      array _zip_ [&cvarcount.]_temporary_;
      do _n_=1 to dim(_chr_);
        if length(_chr_[_n_])>_len_[_n_] then _len_[_n_]=length(_chr_[_n_]);
        if _eof_ and _len_[_n_]<vlength(_chr_[_n_]) then _zip_[_n_]=1;
      end;
    end;

    if n(of _zip_[*]) then do;
      call execute("proc sql;alter table &data.");
      do _n_=1 to dim(_chr_);
        if _zip_[_n_] then call execute('modify '||trim(vname(_chr_[_n_]))||' char('||cats(_len_[_n_])||')'
        %if %upcase(&delfmt.)=Y %then %str(||' format=$'||cats(_len_[_n_])||'.'); 
        %if %upcase(&delinfmt.)=Y %then %str(||' informat=$'||cats(_len_[_n_])||'.'); 
        );
      end;
      call execute(';quit;');
    end;
    else putlog "NOTE: There are no variables whose lengths need to be modified.";
  run;
%end;
%else %if &nobs.=0 and &cvarcount.>0 %then %do;
  proc sql;
    alter table &data.
    %do _n_=1 %to &cvarcount.;
      modify %scan(&cvarlist.,&_n_.,%str( )) char(1) 
        %if %upcase(&delfmt.)=Y %then %str(format=$1.);
        %if %upcase(&delinfmt.)=Y %then %str(informat=$1.);
    %end;
    ;
  quit;
%end;
%else %put NOTE: Dataset %quote(&data.) contains none character variables.;
%mend;
