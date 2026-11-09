%macro ds_splitvar(data=,out=&data.,var=,length=200,labelmode=SEQUENCE)
  /des='Split character variables into serveral sub variables, length of each of them no more than &length.';
%local nvars vlength vlabel _usednvars_;

*Get number of variables planned;
data _null_;
  if 0 then set &data.;
  nvars=int(vlength(&var.)/&length.)*2;
  call symputx('nvars',nvars);
  call symputx('vlength',vlength(&var.));
  call symputx('vlabel',vlabel(&var.));
run;
%if &vlength.<=&length. %then %return;

/*Ref: https://www.bilibili.com/read/cv30512583/*/
*Splitting;
data &out.;
  set &data. end=_eof_;

  _len_=length(&var.);
  array _dummy_[%eval(&nvars.+1)]$200. &var.0-&var.&nvars.;
  _usedlen_=1;
  if _len_>&length. then do _n_=1 to dim(_dummy_);
    _dummy_[_n_]=substrn(&var.,_usedlen_,&length.);
    if _usedlen_+&length.>_len_ then leave;

    *Text should be split between words to improve readability;
    _endpos_=findc(_dummy_[_n_],',.:;?! ','b');
    if _endpos_^=&length. and findc(substrn(&var.,_usedlen_+length(_dummy_[_n_]),1),',.:;?! ')^=1 
      then _dummy_[_n_]=substr(_dummy_[_n_],1,_endpos_);

    _usedlen_+length(_dummy_[_n_]);
    retain _usednvars_;
    if _n_>_usednvars_ then _usednvars_=_n_;
  end;
  else &var.0=&var.;
  if _eof_ then call symputx('_usednvars_',_usednvars_);
  drop _len_ _usedlen_ _endpos_ _usednvars_;
run;
%put INFO: &var was splitted into &var.0-&var.&_usednvars_..;

*Drop the variables who have not been used;
proc sql noprint;
  alter table &out. modify
  %do i=0 %to &_usednvars_.;
    %sysfunc(ifc(&i.=0,,%str(,))) &var&i.
    %if %upcase(&labelmode.)=SEQUENCE and &i.>0 %then label=%tslit(%quote(&vlabel.#&i.));
    %else label=%tslit(%quote(&vlabel.));
  %end;
  ;

  %if &_usednvars_.>0 %then %do;
    alter table &out. drop 
    %do i=&_usednvars_.+1 %to &nvars.;
      %sysfunc(ifc(&i.=&_usednvars_.+1,,%str(,))) &var&i.
    %end;
  %end;
  ;
quit;
%mend;
