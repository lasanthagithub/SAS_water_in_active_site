/* Multiple plots in one layout. In GTL */
%let drive = F;
%let path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\All_plots\MultiPlots;
libname mltplt "&path.";

%let DTP_path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\DTP_analysis\working;
%let DCV_path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\DCV_analysis\working;
%let EFP_path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\EFP_analysis\working;
%let EPP_path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\EPP_analysis\working;
%let MAP_path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\MAP_analysis;
%let MVP_path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\MVP_analysis;
%let ODM_path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\ODM_analysis;
%let OMT_path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\OMT_analysis_test;
%let TMT_path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\TMT_analysis\working;
%let VMT_path = &drive.:\OneDrive\SAS_work\MD_SAS_analysis\VMT_analysis\working;

libname DTPlib "&DTP_path";
libname DCVlib "&DCV_path";
libname EFPlib "&EFP_path";
libname EPPlib "&EPP_path";
libname MAPlib "&MAP_path";
libname MVPlib "&MVP_path";
libname ODMlib "&ODM_path";
libname OMTlib "&OMT_path";
libname TMTlib "&TMT_path";
libname VMTlib "&VMT_path";

%let sufixex = lshg;


%let lignms = DTP DCV EFP EPP MAP MVP ODM OMT TMT VMT;

%let lengt = 10;
%let nuObs = 10;


%let all_rms_names =;

* This macro finds the length of a given delimiter separated list;
%macro get_length(valst, sepr);
    %let valst = %qtrim(&valst);
    %*if %length(valst) ne 0 %then ;
    %if &valst ne '' %then
        %do;
             %let i = 1;
             %let varnm = %scan(&valst, &i, %str(&sepr));
             %do %until (&varnm=);
                 %let varnm = %scan(&valst, &i, %str(&sepr));
                    
                 %let i = %eval(&i+1);
                 %*put &i;               
             %end;
         %let i = %eval(&i - 2); %* to adjust;
         %end;
      %else
           %let i = 0;        
       &i;
%mend get_length;
/*===============================================================================*/
%macro get_selected_RMS_nams();

    %do i = 1 %to &lengt;
        
        %let num =;
        %let ligID = %scan(&lignms, &i, %str( ));
        %*put &ligID; 
        %let rms_names =;
        proc sql  outobs = &nuObs. noprint;
            select varname, count(*) into: rms_names separated by " " ,: num 
            from &ligID.lib.&ligID._rms_prsnt_or_not3_stat
            /*where N > 0 */
            order by N descending;
        quit;
        %*put &num;

        %let temp_nms = ;
        %if /*(&rms_names ^=)*/ &num > 0 %then
            %do;
                %let d = 1;
                %let varnm = %scan(&rms_names, &d, %str( ));

                %do %until (&varnm =);
                    %let varnm = %scan(&rms_names, &d, %str( ));
                    %if (&varnm ^=) %then
                        %do;
                            %*put &ligID &varnm;
                            %if &d = 1 %then
                                %let temp_nms = &ligID..&varnm as &ligID.&d;
                            %else
                                %let temp_nms = &temp_nms., &ligID..&varnm as &ligID.&d;
                            %let d = %eval(&d+1);
                        %end;                   
                %end;
            %end;
/*
        %do j = 1 %to &nurms;  

        %end;

        %*put &rms_names; */
        %if &i = 1 and &num > 0 %then 
            %let all_rms_names =&temp_nms;
        %else %if &num > 0 %then           
            %let all_rms_names = &all_rms_names,&temp_nms;
        %put &ligID &num; 
    %end;

    %put Only above conpounds have proximal waters within 5A (check for compus < 0);
    %put So, collective plots should be drawn only to those;
     

%mend get_selected_RMS_nams;

%get_selected_RMS_nams;
%put &all_rms_names;



/*===============================================================================*/
%macro make_full_join();

    %let select_line1 =;
    %let select_line2 =;
    %let select_line3 =;
    %let from_line =;
    %let lig_prev =;
    %do i = 1 %to &lengt;
        %let lig = %scan(&lignms., &i., %str( ));

        %if &i < &lengt %then
            %do; 
                %let select_line1 = &select_line1. %str(&lig..Real_TS,);
                %*let select_line2 = &select_line2. %str(&lig..&lig._RMS1,&lig..&lig._RMS2,&lig..&lig._RMS3,&lig..&lig._RMS4,);
                %*let select_line3 = &select_line3. %str(YX&lig.1P1_DASER199OG,);
            %end;
        %else %if &i = &lengt %then
            %do;
                %let select_line1 = &select_line1. %str(&lig..Real_TS);
                %*let select_line2 = &select_line2. %str(&lig..&lig._RMS1,&lig..&lig._RMS2,&lig..&lig._RMS3,&lig..&lig._RMS4);
                %*let select_line3 = &select_line3. %str(YX&lig.1P1_DASER199OG);
            %end;
        %if &i = 1 %then 
            %do;
                %let lig_prev =  &lig;
                %let from_line = &from_line. %str(&lig.lib.&lig._rms_presnt_or_not3 &lig. full outer join );
            %end;
        %else %if &i > 1 and &i < &lengt %then
            %do;
                %let from_line = &from_line. %str(&lig.lib.&lig._rms_presnt_or_not3 &lig. on &lig_prev..Real_TS = &lig..Real_TS full outer join );
                %*let lig_prev =  &lig;
            %end;
        %else %if &i = &lengt %then
            %let from_line = &from_line. %str(&lig.lib.&lig._rms_presnt_or_not3 &lig. on &lig_prev..Real_TS = &lig..Real_TS;);
            
    %end;

    proc sql;
         create table all_OP_wat_rms_sel as
         select coalesce(&select_line1) as Real_TS_fs, calculated Real_TS_fs *0.1 as Real_TS ,&all_rms_names
         from &from_line.;
   quit;

%mend make_full_join;

/*===============================================================================*/

%make_full_join;


/*===============================================================================*/

proc template ;
    define style styles.mystyle1; parent = styles.HTMLBlue;
        style GraphFonts /
            'GraphValueFont' = ("<MTserif>, Times New Roman", 8pt)
            'GraphLabelFont' = ("<MTserif>, Times New Roman", 10pt, bold)
            'GraphTitleFont' = ("<MTserif>, Times New Roman", 10pt, bold)
            'GraphDataFont' = ("<MTserif>, Times New Roman", 8pt)
            'NodeLabelFont' = ("<MTserif>, Times New Roman", 8pt)
            
            "GraphAnnoFont" = ("<MTserif>, Times New Roman", 8pt)
            "GraphUnicodeFont" = ("<MTserif>, Times New Roman", 8pt)
            "GraphLabel2Font" = ("<MTserif>, Times New Roman", 8pt)
            "GraphFootnoteFont" = ("<MTserif>, Times New Roman", 8pt)
            "GraphTitle1Font" = ("<MTserif>, Times New Roman", 8pt)
            "NodeTitleFont" = ("<MTserif>, Times New Roman", 8pt)
            "NodeInputLabelFont" = ("<MTserif>, Times New Roman", 8pt)
            "NodeDetailFont" = ("<MTserif>, Times New Roman", 8pt);
/*
            */


         /*style GraphDataDefault / linethickness = 2px;*/
         /*style GraphAxisLines / linethickness = 2px;*/
         /*style GraphWalls / lineThickness = 2px FrameBorder = on;*/
         /*style graphdata1 / linestyle = 1 ContrastColor = white;*/
         /*style graphdata2 / linestyle = 1 ContrastColor = black;*/
    end; 
run;


ods graphics on /reset = all width = 5.9 in height = 8 in  border=off  
        imagename = "All_OP_water_dist_1" imagefmt= png  ANTIALIASMAX=102900;
ods pdf style = mystyle1 file = "&path\All_OP_water_dist_1.pdf" dpi=300;

ods html style = mystyle1 path = "&path" gpath = "&path" /*(url="png/")*/ 
        file = "All_OP_water_dist_html_1.htm" dpi=300;
options orientation = portrait; 


proc template;
    define statgraph mltplt.lattice4;
        begingraph;

                
            layout lattice /columns=2 rows = 4 columngutter=3px rowgutter=3px
                        columndatarange=unionall /*rowdatarange=unionall*/;

                columnaxes;
                    columnaxis / display=(ticks tickvalues /*label*/) /*label = 'Time Step (x 100 fs)'*/; * first column;
                    columnaxis / display=(ticks tickvalues /*label*/) /*label = 'Time Step (x 100 fs)'*/; * second column;
                endcolumnaxes;

                rowaxes;
                    rowaxis / display=(ticks /*tickvalues label*/) /*label = ""*/;
                    rowaxis / display=(ticks /*tickvalues label*/) /*label = ""*/;
                    rowaxis / display=(ticks /*tickvalues label*/) /*label = ''*/;
                    rowaxis / display=(ticks /*tickvalues label*/) /*label = ''*/;                 
                    rowaxis / display=(ticks /*tickvalues label*/) /*label = ''*/;
                endrowaxes;


                sidebar / align=left;
                    entry "Proximal water molecules" / textattrs = (size = 10pt) rotate=90;
                endsidebar;


                sidebar / align=bottom;
                    entry "Time Step (ps)" / textattrs = (size = 10pt);
                endsidebar;

                *entry halign = left "Density"/ valign = center rotate= 90;


                

                layout overlay  / yaxisopts=(type=discrete display= none) /*xaxisopts=(display= none )*/;                   
                    seriesplot x= Real_TS y = DCV1 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = DCV2 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = DCV3 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = DCV4 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = DCV5 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = DCV6 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = DCV7 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = DCV8 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = DCV9 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = DCV10 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    entry halign=left "DCV" /valign=top border=false;
                endlayout;

                layout overlay  / /*xaxisopts=(display= none )*/yaxisopts=(type=discrete display= none);;
                    
                    seriesplot x= Real_TS y = DTP1 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = DTP2 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

               *     seriesplot x= Real_TS y = DTP3 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
               *     seriesplot x= Real_TS y = DTP4 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

               *     seriesplot x= Real_TS y = DTP5 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
               *     seriesplot x= Real_TS y = DTP6 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

               *     seriesplot x= Real_TS y = DTP7 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

               *     seriesplot x= Real_TS y = DTP8 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

               *     seriesplot x= Real_TS y = DTP9 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

               *     seriesplot x= Real_TS y = DTP10 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);


                    entry halign=left "DTP" /valign=top border=false;

                endlayout;

                *layout overlay  / yaxisopts=(type=discrete display= none)/*xaxisopts=(display= none )*/; 
                *    seriesplot x= Real_TS y = EDF1 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                *    seriesplot x= Real_TS y = EDF2 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = EDF3 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                *    seriesplot x= Real_TS y = EDF4 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = EDF5 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                *    seriesplot x= Real_TS y = EDF6 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = EDF7 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = EDF8 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = EDF9 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = EDF10 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                *    entry halign=left "EDF" /valign=top border=false;
                *endlayout;

                *layout overlay  /yaxisopts=(type=discrete display= none) /*xaxisopts=(display= none )*/;
                *    seriesplot x= Real_TS y = ETP1 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                *    seriesplot x= Real_TS y = ETP2 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = ETP3 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                *    seriesplot x= Real_TS y = ETP4 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = ETP5 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                *    seriesplot x= Real_TS y = ETP6 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = ETP7 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = ETP8 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = ETP9 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = ETP10 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                *     entry halign=left "ETP" /valign=top border=false;
                *endlayout;

                layout overlay  /yaxisopts=(type=discrete display= none) /*xaxisopts=(display= none )*/;
                    seriesplot x= Real_TS y = MAP1 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = MAP2 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = MAP3 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = MAP4 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = MAP5 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = MAP6 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = MAP7 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = MAP8 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = MAP9 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = MAP10 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    entry halign=left "MAP" /valign=top border=false;
                endlayout;

                layout overlay  /yaxisopts=(type=discrete display= none) /*xaxisopts=(display= none )*/;
                    seriesplot x= Real_TS y = MVP1 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = MVP2 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = MVP3 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = MVP4 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = MVP5 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                *    seriesplot x= Real_TS y = MVP6 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = MVP7 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = MVP8 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = MVP9 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                *    seriesplot x= Real_TS y = MVP10 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    entry halign=left "MVP" /valign=top border=false;
                endlayout;

                layout overlay  /yaxisopts=(type=discrete display= none) /*xaxisopts=(display= none )*/;
                    seriesplot x= Real_TS y = ODM1 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = ODM2 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = ODM3 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = ODM4 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = ODM5 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = ODM6 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = ODM7 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = ODM8 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = ODM9 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

               *     seriesplot x= Real_TS y = ODM10 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    entry halign=left "ODM" /valign=top border=false;
                endlayout;

                layout overlay  / yaxisopts=(type=discrete display= none)/*xaxisopts=(display= none )*/;
                    seriesplot x= Real_TS y = OMT1 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = OMT2 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = OMT3 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = OMT4 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = OMT5 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = OMT6 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = OMT7 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = OMT8 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = OMT9 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = OMT10 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    entry halign=left "OMT" /valign=top border=false;
                endlayout;

                layout overlay  / yaxisopts=(type=discrete display= none)/*xaxisopts=(display= none )*/;
                    seriesplot x= Real_TS y = TMT1 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = TMT2 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = TMT3 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = TMT4 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = TMT5 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = TMT6 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = TMT7 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = TMT8 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = TMT9 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = TMT10 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    entry halign=left "TMT" /valign=top border=false;
                endlayout;

                layout overlay  /yaxisopts=(type=discrete display= none) /*xaxisopts=(display= none )*/;
                    seriesplot x= Real_TS y = VMT1 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = VMT2 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = VMT3 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = VMT4 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = VMT5 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    seriesplot x= Real_TS y = VMT6 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = VMT7 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = VMT8 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = VMT9 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);

                    seriesplot x= Real_TS y = VMT10 / /*legendlabel='S_O-ND.NE-O_OP' name= "density4"*/
                            lineattrs=(pattern=solid thickness=3 color = green);
                    entry halign=left "VMT" /valign=top border=false;
                endlayout;



            endlayout;

        endgraph;
    end; /*multyplot1*/
run;


proc sgrender data = All_op_wat_rms_sel template = mltplt.lattice4;

run; 

ods graphics on /reset = all;
ods pdf close;
ods html close;
