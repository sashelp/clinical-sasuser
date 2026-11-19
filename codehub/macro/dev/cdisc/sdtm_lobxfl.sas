/*
*Brief      : Generate the baseline flag variable for an SDTM dataset
*Param(Req) : (DATA=)                 Input dataset name
*Param(Req) : (VAR=&DOMAIN.ORRES)     Variable used to judge whether a record is non-missing
*Param(Req) : (DTC=&DOMAIN.DTC)       Record date/time variable, character ISO8601 format
*Param(Req) : (BLFL=&DOMAIN.LOBXFL)   Baseline flag variable name to create
*Param(Opt) : (DOMAIN=)               Domain name
*Param(Opt) : (OUT=&DATA.)            Output dataset name
*Param(Opt) : (BY=&DOMAIN.TESTCD)     Additional variable(s) to group records within a
                                      subject, e.g. LBTESTCD for LB; one baseline flag is
                                      derived for each BY group. If not specified, one
                                      baseline flag is derived for each subject
*Param(Opt) : (SUBJECT=USUBJID)       Subject identifier, only one variable is accepted
*Param(Opt) : (RFDTC=SDTM.DM.RFXSTDTC) Reference date/time of first study drug
                                      administration, following forms are valid:
                                      LIB.DATASET.VARIABLE : variable of an existing dataset
                                      DATASET.VARIABLE     : variable of a WORK dataset
                                      VARIABLE             : variable of the input dataset
*Detail     : For each BY group, records satisfying all conditions below are sorted by
              DTC=, and the last (latest) record is flagged as BLFL='Y' while all other
              records keep a blank BLFL=:
              (1) VAR= is not missing. For a numeric variable, missing and special
                  missing values are excluded; for a character variable, blank, NA,
                  ND and UK are excluded
              (2) DTC= is not missing and its value is on or before RFDTC=
*Detail     : Records with missing DTC= or missing RFDTC= are not eligible, because
              they can not be confirmed as prior to first study drug administration
*Note       : DTC= and RFDTC= are compared as character strings with the truncated
              comparison operator, so ISO8601 partial dates are compared on their
              common prefix, and a date-only value is comparable with the date part
              of a date/time value
*Note       : If several eligible records share the latest DTC=, records are sorted by
              SUBJECT=, BY= and order in input dataset, the last record in sort order is flagged
*Note       : The output dataset is sorted by SUBJECT= and BY=; working variables
              _RFDTC_ are kept for traceability
*Usage      : See inner website
*Dependency : %var_exist, %var_coexist, %var_attr
*Version    : SAS 9.4M7
*History    : 2026-11-07, Luo Hao, Original version
*/
%macro sdtm_lobxfl(data=,out=&data.,domain=,var=&domain.orres,dtc=&domain.dtc,by=&domain.testcd,subject=usubjid,
  rfdtc=sdtm.dm.rfxstdtc,blfl=&domain.lobxfl)/des='Generate baseline flag for SDTM dataset';
%local errtext rflib rfds rfvar npart _cond_;

/*1. Exception capture and handling*/
%if %quote(&data.)=%str() %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%else %if %quote(&out.)=%str() %then %let errtext=ERROR: Parameter OUT= not specified.;
%else %if %quote(&var.)=%str() %then %let errtext=ERROR: Parameter VAR= not specified.;
%else %if %var_exist(data=&data.,var=&var.)=0 %then %let errtext=ERROR: Variable %quote(&var.) not exist in dataset %quote(&data.).;
%else %if %quote(&dtc.)=%str() %then %let errtext=ERROR: Parameter DTC= not specified.;
%else %if %var_exist(data=&data.,var=&dtc.,type=C)=0 %then %let errtext=ERROR: Variable %quote(&dtc.) not exist or is not character in dataset %quote(&data.).;
%else %if %quote(&blfl.)=%str() %then %let errtext=ERROR: Parameter BLFL= not specified.;
%else %if %sysfunc(nvalid(%quote(&blfl.),%sysfunc(getoption(validvarname))))=0 %then %let errtext=ERROR: %quote(&blfl.) is invalid variable name.;
%else %if %quote(&subject.)=%str() %then %let errtext=ERROR: Parameter SUBJECT= not specified.;
%else %if %var_coexist(data=&data.,var=&subject.)=0 %then %let errtext=ERROR: At least one of SUBJECT= variables does not exist. in dataset %quote(&data.).;
%else %if %quote(&rfdtc.)=%str() %then %let errtext=ERROR: Parameter RFDTC= not specified.;
%else %if %sysfunc(countw(&rfdtc.,%str(.)))>3 %then %let errtext=ERROR: Parameter RFDTC= has invalid value, expecting LIB.DATASET.VARIABLE, DATASET.VARIABLE or VARIABLE.;

/*1.1 Validate BY= variables, only when BY= is specified*/
%if %bquote(&errtext.)=%str() and %quote(&by.)^=%str() %then %do;
  %if %var_coexist(data=&data.,var=&by.)=0 %then %let errtext=ERROR: At least one variable in parameter BY= not exist in dataset %quote(&data.).;
%end;

/*1.2 Parse and validate RFDTC=*/
%if %bquote(&errtext.)=%str() %then %do;
  %let npart=%sysfunc(countw(&rfdtc.,%str(.)));
  %if &npart.=3 %then %do;
    %let rflib=%qscan(&rfdtc.,1,%str(.));
    %let rfds=%qscan(&rfdtc.,2,%str(.));
    %let rfvar=%qscan(&rfdtc.,3,%str(.));
  %end;
  %else %if &npart.=2 %then %do;
    %let rflib=work;
    %let rfds=%qscan(&rfdtc.,1,%str(.));
    %let rfvar=%qscan(&rfdtc.,2,%str(.));
  %end;
  %else %let rfvar=%qscan(&rfdtc.,1,%str(.));

  %if %quote(&rflib.)^=%str() %then %do;
    %if %sysfunc(exist(&rflib..&rfds.))=0 %then %let errtext=ERROR: Dataset %quote(&rflib..&rfds.) not exist.;
    %else %if %var_exist(data=&rflib..&rfds.,var=&rfvar.,type=C)=0 %then
      %let errtext=ERROR: Variable %quote(&rfvar.) not exist or is not character in dataset %quote(&rflib..&rfds.).;
    %else %if %var_coexist(data=&rflib..&rfds.,var=&subject.)=0 %then
      %let errtext=ERROR: At least one of SUBJECT= variables does not exist. in dataset &rflib..&rfds..;
  %end;
  %else %if %var_exist(data=&data.,var=&rfvar.,type=C)=0 %then
    %let errtext=ERROR: Variable %quote(&rfvar.) not exist or is not character in dataset %quote(&data.).;
%end;

%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
/*2.1 Read the reference date of first study drug administration and the date part
      of the record date/time*/
data sdtm_lobxfl1;
  set &data.;
  length _dtc_ _rfdtc_ $19;
  %if %var_exist(data=&data.,var=&blfl.) %then %str(&blfl.='';);
  %if %quote(&rflib.)^=%str() %then %do;
    if _n_=1 then do;
      if 0 then set &rflib..&rfds.(keep=&subject. &rfvar.);
      dcl hash h(dataset:"&rflib..&rfds.");
      h.definekey("&subject.");
      h.definedata("&rfvar.");
      h.definedone();
    end;
    _rfdtc_='';
    if h.find()=0 then _rfdtc_=substrn(&rfvar.,1,findc(&rfvar.,,'bd'));
  %end;
  %else %str(_rfdtc_=substrn(&rfvar.,1,findc(&rfvar.,,'bd')););
  _dtc_=substrn(&dtc.,1,findc(&dtc.,,'bd'));
run;

/*2.2 Sort by subject, BY variables and record date/time, and flag the latest
      eligible record of each BY group*/
%if %var_attr(data=&data.,var=&var.,attr=TYPE)=N %then %let _cond_=&var.>.z and ''<trim(_dtc_)<=:trim(_rfdtc_);
%else %let _cond_=&var. not in ('' 'NA' 'ND' 'UK') and ''<trim(_dtc_)<=:trim(_rfdtc_);

proc sort data=sdtm_lobxfl1 equals;
  by &subject. &by. _dtc_;
run;

data sdtm_lobxfl2;
  set sdtm_lobxfl1;
  where &_cond_.;
  by &subject. &by.;
  %if %quote(&by.)^=%str() %then if last.%scan(&by.,-1,%str( )) then &blfl.='Y';
  %else if last.%scan(&subject.,-1,%str( )) then &blfl.='Y';;
run;

/*2.3 Combine the flagged records with the records that are not eligible*/
data &out.;
  set sdtm_lobxfl1(where=(not(&_cond_.))) sdtm_lobxfl2;
  by &subject. &by.;
  drop _dtc_ %if %quote(&rflib.)^=%str() %then &rfvar.;;
run;

/*3. Cleanup and exit*/
proc delete data=sdtm_lobxfl1 sdtm_lobxfl2;
run;
%mend;
