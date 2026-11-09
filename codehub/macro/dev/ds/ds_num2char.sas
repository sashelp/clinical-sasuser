/*
*Brief      : Convert numeric variables to character variables
*Param(Req) : (DATA=)           Dataset name
*Param(Opt) : (OUT=&DATA.)      Output dataset name
*Param(Opt) : (VAR=)            Numeric variables
*Param(Opt) : (VALUE=FORMATTED) Control how to convert numeric variables, following values are vaild:
              FORMATTED:   Return the formmated(external) values. If no format has been assigned to a
                           class variable, then the default format, BEST12., is used
              INTERNAL:    Return the internal values
*Param(Opt) : (MISSING=NULL)    Control how to convert missing values, following values are vaild:
              NULL:        Return null as missing values
              ASIS:        Return the asis(formmated) values, like ".", ".A", etc.
*Detail     : After conversation, the variable order differs from that before conversation, and the 
              variables obtained from the conversation will be placed after all the original variables
*Note       : Specified names(_eof_, _chr_, _num_, __tmp:) and variable names of input dataset are used
              together, avoid name clashes or the macro will fail
*Note       : If you want to convert all numeric variables, use %ds_varlist(data=&data,type=n) as value
              of VAR= option
*Usage      : See inner website
*Dependency : %var_coexist, %ds_varlist
*Version    : SAS 9.4M7
*History    : 2026-10-23, Luo Hao, Original version
*History    : 2026-10-28, Luo Hao, Fix issue: add /minoperator option so VALUE= and MISSING=
              parameter validation (IN operator) works correctly
*/
%macro ds_num2char(data=,out=&DATA.,var=,value=FORMATTED,missing=NULL)/minoperator;
%local errtext nvarlist _n_ nvar outlib outds;
/*1. Exception capture and handling*/
%if %quote(&data.)=%str() %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%else %if %quote(&out.)=%str() %then %let errtext=ERROR: Parameter OUT= not specified.;
%else %if %var_coexist(data=&data.,var=&var.)=0 %then %let errtext=ERROR: At least one of VAR= variables does not exist.;
%else %if (%qupcase(&value.) in FORMATTED INTERNAL)=0 %then %let errtext=ERROR: Parameter VALUE= has invalid value, expecting one of: FORMATTED, INTERNAL.;
%else %if (%qupcase(&missing.) in ASIS NULL)=0 %then %let errtext=ERROR: Parameter MISSING= has invalid value, expecting one of: ASIS, NULL.;
%else %do;
  %let nvar=%sysfunc(countw(&var.,,s));
  %let nvarlist=%ds_varlist(data=&data.,type=N);
  %do _n_=1 %to &nvar.;
    %if %sysfunc(findw(&nvarlist.,%scan(&var.,&_n_,%str( )),,is))=0 %then %let errtext=ERROR: Variable %scan(&var.,&_n_,%str( )) is not numeric.;
  %end;
%end;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%if %index(%scan(%quote(&out),1,()),.) %then %do;
  %let outlib=%scan(%quote(&out),1,.);
  %let outds=%scan(%scan(%quote(&out),1,()),2,.);
%end;
%else %do;
  %let outlib=work;
  %let outds=%scan(%quote(&out),1,());
%end;

data &out.;
  if _n_=1 then do;
    array _num_ &var.;
    array _chr_$200 __tmp1-__tmp&nvar.;
    call execute('proc datasets nolist lib=&outlib.; modify &outds.;');
    do over _num_;
      call execute('rename '||trim(vname(_chr_))||'='||trim(vname(_num_))||';');
      call execute('label '||cats(vname(_num_),'=',quote(trim(vlabel(_num_)),"'"),';'));
    end;
    call execute(';quit;');
  end;

  do until(_eof_);
    set &data. end=_eof_;
    do over _num_;
      %if %upcase(&value.)=FORMATTED %then %str(_chr_=strip(vvalue(_num_)););
      %else %if %upcase(&value.)=INTERNAL %then %str(_chr_=cats(_num_););
      %if %upcase(&missing.)=NULL %then %str(if missing(_num_) then _chr_='';);
    end;
    output;
    drop &var.;
  end;
run;
%mend;
