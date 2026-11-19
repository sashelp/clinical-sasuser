/*
*Brief      : Combine a parent domain dataset and a supp domain dataset to a full domain dataset
*Param(Req) : (PARENT=SDTM.&DOMAIN.)        Parent domain dataset name
*Param(Req) : (SUBJECT=USUBJID)             Variable(s) to indentify subjects
*Param(Opt) : (SUPP=SDTM.SUPP&DOMAIN.)      Supplemental domain dataset name
*Param(Opt) : (DOMAIN=)                     Domain name
*Param(Opt) : (OUT=&DOMAIN.)                Output dataset name
*Detail     : Dataset of PARENT= will be copied as output dataset if SUPP= not specified or 
              Supplemental domain dataset has 0 observation, does not exist or all SUBJECT=
              values are missing
*Note       : Parent domain dataset must be sorted by &SUBJECT. and id variable(if applicable), 
              where ID variable is the value of IDVAR of Supplemental domain dataset
*Note       : Supplemental domain dataset must be sorted by &SUBJECT., IDVAR and IDVARVAL
*Usage      : See inner website
*Dependency : %var_coexist, %var_attr
*Version    : SAS 9.4M7
*History    : 2026-07-08, Luo Hao, Original version
*History    : 2026-09-15, Luo Hao, Use PROC DATASETS to replace PROC DELETE so NOWARN option 
              could be used to compress WARNING message when no middle dataset generated
*History    : 2026-11-07, Luo Hao, Add if-then structure incase &idvar. is a character variable;
              Add SUBJECT= parameter to allow both USUBJID and SUBJID as key variables
*/
%macro sdtm_fulldomain(domain=,parent=sdtm.&domain.,subject=usubjid,supp=sdtm.supp&domain.,out=&domain.)/des='Merge SDTM.XX and SDTM.SUPPXX';
%local errtext idvar;

/*1. Exception capture and handling*/
%if %quote(&domain.)=%str() %then %let errtext=ERROR: Parameter DOMAIN= not specified.;
%else %if %quote(&parent.)=%str() %then %let errtext=ERROR: Parameter PARENT= not specified.;
%else %if %sysfunc(exist(%qscan(&parent.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&parent.) not exist.;
%else %if %var_coexist(data=&parent.,var=&subject.)=0 %then %let errtext=ERROR: At least one of SUBJECT= variables does not exist in PARENT dataset.;
%else %if %quote(&supp.)^=%str() %then %do;
  %if %sysfunc(exist(%qscan(&supp.,1,()))) %then %do;
    %if %var_coexist(data=&supp.,var=&subject.)=0 %then %let errtext=ERROR: At least one of SUBJECT= variables does not exist in SUPP dataset.;
    %else %if %var_coexist(data=&supp.,var=IDVAR IDVARVAL QVAL QNAM QLABEL)=0 %then
      %let errtext=ERROR: At least one of required variables(IDVAR IDVARVAL QVAL QNAM QLABEL) not exist in SUPP dataset.;
  %end;
%end;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
%if %quote(&supp.)=%str() or %sysfunc(exist(%qscan(&supp.,1,())))=0 %then %do;
  /*2.1 SUPP not specified or not exist: copy &parent. as result*/
  data &out.;
    set &parent.;
  run;
%end;
%else %do;
  proc transpose data=&supp. out=sdtm_fulldomain1(where=(missing(%scan(&subject.,1,%str( )))=0));
    by &subject. idvar idvarval;
    var qval;
    id qnam;
    idlabel qlabel;
  run;

  /*2.2 SUPP is empty or all SUBJECT values are missing: copy &parent. as result*/
  %if &sysnobs.=0 %then %do;
    data &out.;
      set &parent.;
    run;
  %end;
  %else %do;
    proc sql noprint;
      select distinct idvar into :idvar trimmed from sdtm_fulldomain1;
    quit;

    %if %quote(&idvar.)^=%str() %then %do;
      data sdtm_fulldomain1;
        set sdtm_fulldomain1;
        %if %var_attr(data=&parent.,var=&idvar.,attr=type)=N %then %str(&idvar.=input(idvarval,best.););
        %else %str(&idvar.=idvarval;);
      run;

      proc sort data=sdtm_fulldomain1;
        by &subject. &idvar.;
      run;
    %end;

    data &out.;
      merge &parent. sdtm_fulldomain1(drop=_name_ %if %var_coexist(data=sdtm_fulldomain1,var=_label_) %then %str(_label_););
      by &subject. &idvar.;
    run;
  %end;
%end;

/*3. Cleanup and exit*/
proc datasets mtype=data nowarn nolist;
  delete sdtm_fulldomain1;
quit;
%mend;
