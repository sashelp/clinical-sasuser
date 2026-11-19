%let prog_path=C:\Users\sasuser\OneDrive\project\clinical-sasuser\codehub\gallery;
%let html_path=C:\Users\sasuser\OneDrive\project\clinical-sasuser\sashelp\gallery;
%let tmpl_detail=C:\Users\sasuser\OneDrive\project\clinical-sasuser\sashelp\assets\tmpl_gallery_detail.html;
%let tmpl_index=C:\Users\sasuser\OneDrive\project\clinical-sasuser\sashelp\assets\tmpl_gallery_index.html;


/*1. 获取 HTML 模板内容*/
%macro txt2sas(file=,encoding=utf8,out=,var=content,varlen=4096,process=);
filename _dummy_ "&file" encoding=&encoding.;
data &out.;
  fid=fopen('_dummy_');
  if fid then do;
    length &var. $&varlen.;
    do while(fread(fid)=0);
      fget=fget(fid,&var.,&varlen.);
      %unquote(&process.);
      output;
    end;
    fid=fclose(fid);
  end;
  drop fid fget;
run;
%mend;

%txt2sas(file=&tmpl_detail,out=h_detail);
%txt2sas(file=&tmpl_index,out=h_index);


/*2. 获取图像文件目录、程序文件目录和程序文件中的属性信息*/
data filelist1;
  filref=filename('_dummy_',"&prog_path");
  did=dopen('_dummy_');
  if did then do;
    do i=1 to dnum(did);
      category=dread(did,i);
      filref2=filename('_dummy2_',"&prog_path\"||trim(category));
      did2=dopen('_dummy2_');
      if did2 then do;
        do j=1 to dnum(did2);
          filename=dread(did2,j);
          filepath=catx('\',"&prog_path",category,filename);
          name=scan(filename,1,'.');
          ext=scan(filename,2,'.');
          if upcase(ext) in ('RTF' 'GIF') then output;
        end;
        did2=dclose(did2);
      end;

    end;
    did=dclose(did);
  end;
run;

proc sort sortseq=linguistic(numeric_collation=on);
  by category name;
run;

*获取程序文件中的文件头部注释内容(以单行"/*"开始, 以单行"*/"结束);
data filelist2;
  set filelist1(keep=category filepath filename name ext);

  pname=cats(name,'.sas');
  fileexist=fileexist(catx('\',"&prog_path",category,pname));
  if fileexist;   *仅保存有对应 SAS 程序的图像文件;

  filref=filename('_dummy_',catx('\',"&prog_path",category,pname));
  fid=fopen('_dummy_');
  if fid then do;
    length content $4096;
    do while(fread(fid)=0);
      fget=fget(fid,content,4096);
      if content^='/*' and content^='*/' then output;
      else if content='*/' then leave;
    end;
    fid=fclose(fid);
  end;
run;

*从注释内容中提取属性信息(属性信息行以 *ATTR: VALUE 模式存储, VALUE 可能存在换行);
data filelist3;
  set filelist2;

  if content^=:'*' then delete;
  do i=_n_+1 to rec;
    set filelist2(keep=content rename=(content=tmp_content))nobs=rec point=i;
    if tmp_content=:'*' then leave;
    else content=catx(trimn(''),content,tmp_content);
  end;

  length attr $16. value $4096.;
  attr=upcase(scan(content,1,'*:'));
  value=left(substr(content,findc(content,':')+1));
run;


/*3. 从 RTF 文件中提取 PNG 文件, 然后为图像文件添加水印并另存为网页资源*/
proc template;
  define statgraph overlay;
  begingraph;
  dynamic back front;
    layout overlay/walldisplay=none;
      drawimage back /drawspace=graphpercent height=100 scale=fit;
      drawimage front /drawspace=graphpercent height=100 scale=fit;
    endlayout;
  endgraph;
  end;
run;

data filelist4;
  set filelist3;
  by name notsorted;

  gname=ifc(upcase(ext)='RTF',catx('.',name,'png'),filename);
  if last.name then do;
    *从 RTF 文件中提取第一张图片, 另存为 PNG 文件;
    if upcase(ext)='RTF' then do;
      rc=filename('_rtf_',trim(filepath));
      rc=filename('_png_',"%sysfunc(pathname(work))\"||trim(gname),,'recfm=n');
      rtf_id=fopen('_rtf_');
      png_id=fopen('_png_','o',,'b');

      length rtf $4096;
      do while(fread(rtf_id)=0);
        fget=fget(rtf_id,rtf,4096);
        if find(rtf,"\pict\pngblip","t") then do; /*获取图片尺寸*/
          patw=prxparse("/\\picwgoal(\d+)/");
          path=prxparse("/\\pichgoal(\d+)/");
          if prxmatch(patw,trim(rtf)) then width=round(input(prxposn(patw,1,trim(rtf)),best.)/567,0.1);  /*RTF使用缇(twip)作为图片尺寸单位,1 inch=1440 twip,1 cm=567 twip*/
          if prxmatch(path,trim(rtf)) then height=round(input(prxposn(path,1,trim(rtf)),best.)/567,0.1);
        end;
        if find(lag(rtf),"\pict\pngblip","t") then png+1;
        if png=1 and findc(rtf,"{}\;","t") then png=0;

        if png=1 then do i=1 to length(rtf) by 2;
          char=byte(input(substr(rtf,i,2),hex2.));
          fput=fput(png_id,char);
          fwrite=fwrite(png_id);
        end;

        if lag(png)=1 and png=0 then leave;
      end;

      rtf_id=fclose(rtf_id);
      png_id=fclose(png_id);
    end;

    *为图像文件添加水印;
    call execute('
      ods _all_ close;
      ods graphics on/reset=all outputfmt=png width='||cats(width)||'cm height='||cats(height)||'cm noborder imagename="'||trim(name)||'";
      ods listing gpath="'||catx('\',"&html_path",category)||'" image_dpi=300 style=htmlblue; 
      proc sgrender data=sashelp.class template=overlay;
        dynamic back="'||trim(ifc(upcase(ext)='RTF',"%sysfunc(pathname(work))\"||trim(gname),filepath))||'"
                front="&tmpl_index\..\watermark.png";
      run;
      ods listing close;
      ods graphics off;
    ');
  end;
run;


/*4. 生成 HTML 正式内容*/
/*4.1 生成 index 页面*/
data _null_;
  set h_index;
  file "&html_path\index.html" encoding=utf8;

  if cats(content)='$$ALLGRAPH$$' then do i=1 to rec;
    set filelist4(keep=category name gname pname attr value) nobs=rec point=i;
    if attr^='NAME' then continue;
    if category^=lag(category) then do;
      coln=0;
      category_zh=scan(value,1,' -');
      put '<div class="col4"></div>'/;
      put /'<h2><a name="' category+(-1) '">' category_zh+(-1) '</a></h2><hr/>';
    end;

    coln+1;
    gdesc=strip(ksubstr(value,kfind(value,'-')+1));
    put '<div class="col' coln+(-1) '">';
    put '<div class="graph">';
    put '<p><a href="./' category+(-1) '/' name+(-1) '.html"><img src="' category+(-1) '/' gname+(-1) '" alt="' gname+(-1) '"></a></p>';
    put '<p><a href="../../CodeHub/Gallery/prog/' category+(-1) '/' pname+(-1) '">' gdesc+(-1) '</a></p>';
    put '</div>';
    put '</div>';

    if coln=3  then do;
      put '<div class="col4"></div>'/;
      coln=0;
    end;
  end;
  else put content;
run;

/*4.2 生成 detail 页面*/
data _null_;
  set filelist4;
  by name notsorted;

  if last.name then call execute('
    data _null_;
      set h_detail;
      file "&html_path\'||catx('\',category,name)||'.html" encoding=utf8;

      old_content=content;
      if find(content,"$$") and strip(content) not in ("$$PARAM$$" "$$HISTORY$$") then do;
        content=tranwrd(content,"$$PFILE$$","../../../codehub/gallery/'||catx("/",category,pname)||'");
        content=tranwrd(content,"$$GFILE$$","'||trim(gname)||'");
        content=tranwrd(content,"$$PNAME$$","'||trim(pname)||'");
        content=tranwrd(content,"$$GNAME$$","'||trim(gname)||'");
        do i=1 to rec;
          set filelist3(keep=name attr value)nobs=rec point=i;
          if name="'||trim(name)||'" then content=tranwrd(content,"$$"||trim(attr)||"$$",trim(value));
        end;
        put content;
      end;
      else if find(content,"$$") then do i=1 to rec;
        set filelist3(keep=name attr value)nobs=rec point=i;
        if name="'||trim(name)||'" and find(old_content,attr,"t") then do;
          value_esc=prxchange(''s/<(.*?)>/<code>&lt;$1&gt;<\/code>/'',-1,trim(value));
          content="<tr><td>"||trim(prxchange("s/,/<\/td><td>/",2,value_esc))||"</td></tr>";
          put content;
        end;
      end;
      else put content;
    run;
  ');
run;
