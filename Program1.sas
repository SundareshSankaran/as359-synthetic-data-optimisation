/****************************************************************************** 

AGGREGATION OPTIMIZATION FOR DM - EXAMPLE PROGRAM 

BALANCING FOR RACE

This program allows users to ensure that synthetically generated data at a more 
granular level is selected to be in alignment with 
known reference data which described desired state at a higher level. 

Given a synthetically generated dataset with any number of key value variables,
this program uses SAS Optimization logic to ensure that when the resulting variables
are aggregated up to that higher level, it is within a certain range of the
known aggregated values in the reference table. 

This ensures more confidence in the generated dataset when using it for downstream
analytics. This example is meant only for sum aggregations.
Additionally, this program assumes some margin of error for the aggregated sum from 
the synthetic dataset (for example, it is acceptable if the reference value is 100 
and the optimized synthetic data's aggregatio for the same value is 101). 
This margin of error can be adjusted by users very easily, 
and if no error is desired (the known and synthetic aggregations are equal) 
that can be set as well.


********************************************************************************/;

/****************************************************************************** 
Define Libnames - I use parquet files to take advantage of the recent DuckDB access engine on Viya
********************************************************************************/;

libname sdtmsynt "/mnt/viya-share/data/as-359/data/synthetic";
libname dde duckdb database=":memory:mydb";
libname dd duckdb file_type="parquet" file_path = "/mnt/viya-share/data/as-359/data/synthetic" database=":memory:mydb";


/****************************************************************************** 
Formatting on DM datasets (synthesized from the CDISC piliot study)
********************************************************************************/;

data dd.DM_NEW (replace=yes DROP= RFSTDTC_1 RFENDTC_1 RFXSTDTC_1 RFXENDTC_1
                                    RFICDTC_1 RFPENDTC_1 DTHDTC_1 DMDTC_1);
    set dd.DM (rename = (RFSTDTC = RFSTDTC_1 RFENDTC = RFENDTC_1 
                         RFXSTDTC = RFXSTDTC_1 RFXENDTC = RFXENDTC_1
                         RFICDTC = RFICDTC_1 RFPENDTC = RFPENDTC_1
                         DTHDTC = DTHDTC_1 DMDTC = DMDTC_1));
    length RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC DTHDTC DMDTC 8.;
    format RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC DTHDTC DMDTC yymmdd10.;
    informat RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC DTHDTC DMDTC yymmdd10.;
    RFSTDTC = input(RFSTDTC_1, yymmdd10.);
    RFENDTC = input(RFENDTC_1, yymmdd10.);
    RFXSTDTC = input(RFXSTDTC_1, yymmdd10.);
    RFXENDTC = input(RFXENDTC_1, yymmdd10.);
    RFICDTC = input(RFICDTC_1, yymmdd10.);
    RFPENDTC = input(RFPENDTC_1, yymmdd10.);
    DTHDTC = input(DTHDTC_1, yymmdd10.);
    DMDTC = input(DMDTC_1, yymmdd10.);
run;


/****************************************************************************** 
Create a macro list of RACE variable levels
/******************************************************************************/; 

proc sql noprint;
	select distinct RACE
	into :race_list separated by '|'
	from dd.DM_NEW;
run;

%put NOTE: &race_list.;


/****************************************************************************** 
Create a macro that takes the list of groups, creates unique datasets named for
those groups, and splits the original dataset into the respective dataset. 
Then the optimization algorithm is run against each by group dataset.

This tactic can be adopted for most categorical variables.
********************************************************************************/;

%macro write_by_group (lib=dd, tableName=DM_NEW, OPT_VAR = RACE);

/* Defines the indicator macro and the macro for the length of the loop 
(i and n respectively) */

    %local i in group;
	%let n = %sysfunc(countw(&race_list., %str(|)));;

    %put NOTE: &n. groups found.;


	%do i = 1 %to &n.;
		/* Pulls the group value, if missing sets to missing */
    	%let group  = %scan(&race_list., &i., %str(|));
    	%if %length(&group.) = 0 %then %let group = _missing_;
		

/****************************************************************************** 
Creates the dataset for the sub-group in the SAS library of choice.
********************************************************************************/;
        
    	data DDE.DM_&i. (replace=yes);
      		set &lib..&tableName.;
      		where &OPT_VAR. = "&group.";
            UniqueID=USUBJID;
    	run;
/****************************************************************************** 
Creates the dataset for the sub-group in the SAS library of choice.
********************************************************************************/;

		/* Pulls the known reference aggregation values and stores them in macro variables */
		%let val1agg = 500;
        %let val2agg = 70;

		/* Prints the macro aggregation variables to the log */
		%put &val1agg; 
		%put &val2agg; 


		proc optmodel;
    	/* Read data into parameters */
    		set<str> RACE;
            str USUBJID{RACE};

/****************************************************************************** 
Creates the dataset for the sub-group in the SAS library of choice.
********************************************************************************/;
    		read data DDE.DM_&i. into RACE=[USUBJID];

		/* Decision variables */
    		var x{RACE} binary;

			/* Objective: maximize values */
    		max TotalValue = sum{i in RACE} x[i];

    	/* Constraints */
/****************************************************************************** 
Creates the dataset for the sub-group in the SAS library of choice.
********************************************************************************/;
        /* Margin of Errors are defined with constraints so .98 and 1.02 for example means a 5 percent margin of error in either direction */
    		con VAL1Limit: .98*&val1agg. <= sum{i in RACE} x[i] <= 1.02*&val1agg.;

    		solve;

/****************************************************************************** 
Creates the dataset for the sub-group in the SAS library of choice.
********************************************************************************/;	
		/* Output the selected observation IDs and the binary to a dataset named for the sub-group being processed */
			create data DDE.opt_&i.(replace=yes rename = (i=USUBJID)) from [i] x  ;
		quit;
  	%end;
%mend;


/* Call Macro */
%write_by_group(lib=dd);

/* APPEND the results of all the optimization runs */

data dd.Example_1_final_selection;
    set dde.opt_1 dde.opt_2 dde.opt_3 dde.opt_4;
run;
