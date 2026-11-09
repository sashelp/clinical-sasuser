/*
*Brief      : Map EPOCH from SDTM standard SE dataset to input dataset
*Param(Req) : (DATA=)                 Input dataset name
*Param(Req) : (SUBJECT=USUBJID)       Variable(s) to indentify subjects
*Param(Req) : (DTC=)                  Record date/time variable, character ISO8601 format 
*Param(Req) : (SE=SDTM.SE)            Standard SE dataset under SDTM model, should contain all subjects
*Param(Opt) : (OUT=&DATA.)            Output dataset name
*Detail     : The correspoding EPOCH of the same subject will be mapped if DTC meets one of the following:
              1. Later or on SESTDTC and prior to SEENDTC;
              2. Equal to the last SEENDTC;
              3. Later or on the last SESTDTC and the last SEENDTC is missing;
*Detail     : If DTC contains missing part, no imputation will be apply and non-missing part will be used 
              in mapping. If multiple EPOCH matched, the last one will be used
*Note       : Dataset specified by SE= should be a standard SE dataset under SDTM model, that means 
              SESTDTC, SEENDTC and EPOCH should be contained
*Usage      : See inner website
*Dependency : %var_exist, %var_coexist, %ds_attr
*Version    : SAS 9.4M7
*History    : 2026-11-09, Luo Hao, Original version
*/
%macro sdtm_epoch(data=,out=&data.,subject=usubjid,se=sdtm.se,dtc=)/des='Map EPOCH from SDTM standard SE dataset to input dataset';
%local errtext subjectquotedcomma;

/*1. Exception capture and handling*/
%if %quote(&data.)=%str() %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%else %if %quote(&se.)=%str() %then %let errtext=ERROR: Parameter SE= not specified.;
%else %if %sysfunc(exist(%qscan(&se.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&se.) not exist.;
%else %if %ds_attr(data=&se,attr=nlobsf)=0 %then %let errtext=ERROR: Dataset %quote(&se.) has 0 observation.;
%else %if %qupcase(%qscan(&data.,1,()))=%qupcase(%qscan(&se.,1,())) %then %let errtext=ERROR: Parameters DATA= and SE= refer to the same dataset.;
%else %if %quote(&subject.)=%str() %then %let errtext=ERROR: Parameter SUBJECT= not specified.;
%else %if %var_coexist(data=&data.,var=&subject.)=0 %then %let errtext=ERROR: At least one variable in parameter SUBJECT= not exist in dataset specified by DATA=;
%else %if %quote(&dtc.)=%str() %then %let errtext=ERROR: Parameter DTC= not specified.;
%else %if %var_exist(data=&data.,var=&dtc.,type=C)=0 %then %let errtext=ERROR: Variable %quote(&dtc.) not exist in dataset specified by DATA=;
%else %if %var_coexist(data=&se.,var=&subject.)=0 %then %let errtext=ERROR: At least one variable in parameter SUBJECT= not exist in dataset specified by SE=;
%else %if %var_coexist(data=&se.,var=sestdtc seendtc epoch)=0 %then %let errtext=ERROR: At least one variable of SESTDTC SEENDTC and EPOCH not exist in dataset specified by SE=;

%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

%let subjectquotedcomma="%sysfunc(tranwrd(%cmpres(&subject.),%str( ),%str(%",%")))";

/*2. Core processing*/
proc sort data=&se. out=sdtm_epoch1(keep=&subject. sestdtc seendtc epoch) presorted;
  by &subject. sestdtc;
run;

data &out.;
  if _n_=1 then do;
    if 0 then set sdtm_epoch1;
    declare hash _hash_(dataset:'sdtm_epoch1', multidata:'y');
    _hash_.definekey(&subjectquotedcomma.);
    _hash_.definedata(&subjectquotedcomma.,'sestdtc','seendtc','epoch');
    _hash_.definedone();
  end;

  set &data.;
  call missing(sestdtc,seendtc,epoch);

  if &dtc^='' then do;
    _rc_=_hash_.find();
    do while(_rc_=0);
      _rc_next_=_hash_.has_next(result: _hash_rst_);
      if ''<trim(sestdtc)<=:trim(&dtc)<:trim(seendtc) then leave;
      else if _rc_next_=0 and _hash_rst_=0 and trim(&dtc)=:trim(seendtc) then leave;
      else if _rc_next_=0 and _hash_rst_=0 and seendtc='' and ''<trim(sestdtc)<=:trim(&dtc) then leave;
      else if _rc_next_=0 and _hash_rst_=0 and trim(&dtc)>:trim(seendtc) then do;
        putlog "WAR" "NING: Row " _n_ +(-1) ": %upcase(&dtc) is later than the last SEENDTC.";
        call missing(sestdtc,seendtc,epoch);
      end;
      else call missing(sestdtc,seendtc,epoch);
      _rc_=_hash_.find_next();
    end;
  end;
  drop _rc_ _rc_next_ _hash_rst_;
run;

/*3. Cleanup and exit*/
proc delete data=sdtm_epoch1;
run;
%mend;
