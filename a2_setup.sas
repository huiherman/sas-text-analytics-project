
/* 1 - Concept Score Code */

/*****************************************************************
* SAS Visual Text Analytics
* Concepts Score Code
*
* Modify the following macro variables to match your needs.
* The liti_binary_caslib and liti_binary_table_name variables
* should have already been set to the location of the concepts
* binary table for the associated SAS Visual Text Analytics project.
****************************************************************/

/* specifies CAS library information for the CAS table that you would like to score. You must modify the value to provide the name of the library that contains the table to be scored. */
%let input_caslib_name = "casuser";

/* specifies the CAS table you would like to score. You must modify the value to provide the name of the input table, such as "MyTable". Do not include an extension. */
%let input_table_name = "ASSIGN2SCORE";

/* specifies the column in the CAS table that contains a unique document identifier. You must modify the value to provide the name of the document identifer column in the table. */
%let key_column = "Complaint_ID";

/* specifies the column in the CAS table that contains the text data to score. You must modify the value to provide the name of the text column in the table. */
%let document_column = "Consumer_complaint_narrative";

/* specifies the CAS library to write the score output tables. You must modify the value to provide the name of the library that will contain the output tables that the score code produces. */
%let output_caslib_name = "casuser";

/* specifies the concepts output CAS table to produce */
%let output_concepts_table_name = "out_concepts";

/* specifies the facts output CAS table to produce */
%let output_facts_table_name = "out_facts";

/* specifies the CAS library information for the LITI binary table. This should be set automatically to the CAS library for the associated SAS Visual Text Analytics project. */
%let liti_binary_caslib = "Analytics_Project_c661a767-2e81-439a-a7d4-7ac908e4b8cf";

/* specifies the name of the LITI binary table. This should be set automatically to the Concepts node model table for the associated SAS Visual Text Analytics project. */
%let liti_binary_table_name = "4471e655-703c-4244-a9a6-00a4cacf7de9_CONCEPT_BINARY";

/* specifies the hostname for the CAS server. This should be set automatically to the host for the associated SAS Visual Text Analytics project. */
%let cas_server_hostname = "sas-cas-server-default-client";

/* specifies the port for the CAS server. This should be set automatically to the host for the associated SAS Visual Text Analytics project. */
%let cas_server_port = 5570;

/* creates a session */
cas sascas1 host=&cas_server_hostname port=&cas_server_port uuidmac=sascas1_uuid;
libname sascas1 cas sessref=sascas1 datalimit=all;

/* calls the scoring action */
proc cas;
    session sascas1;
    loadactionset "textRuleScore";

    action applyConcept;
        param
            model={caslib=&liti_binary_caslib, name=&liti_binary_table_name}
            table={caslib=&input_caslib_name, name=&input_table_name}
            docId=&key_column
            text=&document_column
            casOut={caslib=&output_caslib_name, name=&output_concepts_table_name, replace=TRUE}
            factOut={caslib=&output_caslib_name, name=&output_facts_table_name, replace=TRUE}
        ;
    run;
quit;

/* 2 - Sentiment Score Code */

/*****************************************************************
* SAS Visual Text Analytics
* Sentiment Score Code
*
* Modify the following macro variables to match your needs.
****************************************************************/

/* specifies CAS library information for the CAS table that you would like to score. You must modify the value to provide the name of the library that contains the table to be scored. */
%let input_caslib_name = "casuser";


/* specifies the CAS table you would like to score. You must modify the value to provide the name of the input table, such as "MyTable". Do not include an extension. */
%let input_table_name = "ASSIGN2SCORE";

/* specifies the column in the CAS table that contains a unique document identifier. You must modify the value to provide the name of the document identifer column in the table. */
%let key_column = "Complaint_ID";

/* specifies the column in the CAS table that contains the text data to score. You must modify the value to provide the name of the text column in the table. */
%let document_column = "Consumer_complaint_narrative";

/* specifies the CAS library to write the score output tables. You must modify the value to provide the name of the library that will contain the output tables that the score code produces. */
%let output_caslib_name = "casuser";

/* specifies the sentiment output CAS table to produce */
%let output_sentiment_table_name = "out_sent";

/* specifies the matches output CAS table to produce */
%let output_matches_table_name = "out_sent_matches";

/* specifies the features output CAS table to produce */
%let output_features_table_name = "out_sent_features";

/* specifies the language of the associated SAS Visual Text Analytics project. This should be set automatically to the language you selected when you created your project. */
%let language = "ENGLISH";

/* specifies the hostname for the CAS server. This should be set automatically to the host for the associated SAS Visual Text Analytics project. */
%let cas_server_hostname = "sas-cas-server-default-client";

/* specifies the port for the CAS server. This should be set automatically to the host for the associated SAS Visual Text Analytics project. */
%let cas_server_port = 5570;

/* creates a session */
cas sascas1 host=&cas_server_hostname port=&cas_server_port;
libname sascas1 cas sessref=sascas1 datalimit=all;

/* calls the scoring action */
proc cas;
    session sascas1;
    loadactionset "sentimentAnalysis";

    action applySent;
        param
            table={caslib=&input_caslib_name, name=&input_table_name}
            docId=&key_column
            text=&document_column
            language=&language
            casOut={caslib=&output_caslib_name, name=&output_sentiment_table_name, replace=TRUE}
            matchOut={caslib=&output_caslib_name, name=&output_matches_table_name, replace=TRUE}
            featureOut={caslib=&output_caslib_name, name=&output_features_table_name, replace=TRUE}
        ;
    run;
quit;

/* 3 - Sort and Remove */

proc sort data=sascas1.out_facts nodupkey out=factNoDup ;
by complaint_id ;
run;

data clean_fact;
set factNoDup;
keep complaint_id _fact_;
run;

proc sort data=sascas1.out_sent nodupkey out=sentimentNoDup ;
by complaint_id ;
run;

data clean_sentiment;
set sentimentNoDup;
keep complaint_id _sentiment_;
run;

/* 4 - Joining Step 1 */

/* Creating a joined table using PROC SQL:
   - Combines data from two tables (ASSIGN2SCORE and factNoDup) using a LEFT JOIN.
   - Keeps all records from ASSIGN2SCORE (even if no match in factNoDup).
   - Joins the tables on the common field 'complaint_id'.
   - If a record from ASSIGN2SCORE has no match in factNoDup, the result will have NULL values for factNoDup columns.
   - The output table 'joined_data_1' contains all records from ASSIGN2SCORE and matching records from factNoDup.
*/

proc sql;
    CREATE TABLE joined_data_1 AS  /* Specify the output table name */
    SELECT * 
    FROM SASCAS1.ASSIGN2SCORE AS a
    LEFT JOIN factNoDup AS f 
        ON a.complaint_id = f.complaint_id /* joining ASSIGN2SCORE and FACT SCORE with the key complaint_id */

;

/* 5 - Joining Step 2 */

/* Creating a joined table using PROC SQL:
   - Combines data from two tables (joined_data_1 and sentimentNoDup) using a LEFT JOIN.
   - Keeps all records from joined_data_1 (even if no match in sentimentNoDup).
   - Joins the tables on the common field 'complaint_id'.
   - If a record from joined_data_1 has no match in sentimentNoDup, the result will have NULL values for sentimentNoDup columns.
   - The output table 'joined_data_2' contains all records from joined_data_1 and matching records from sentimentNoDup.
*/

proc sql;
    CREATE TABLE joined_data_2 AS  /* Specify the output table name */
    SELECT * 
    FROM joined_data_1 AS b
    LEFT JOIN sentimentNoDup AS s
        ON b.complaint_id = s.complaint_id /* joining ASSIGN2SCORE and SENTIMENT SCORE with the key complaint_id */
;

/* 6 - Validating the joined table */

/* Creating a validated table using PROC SQL:
   - Combines data from two tables (joined_data_2 and ASSIGN2VALIDATE) using an INNER JOIN.
   - Keeps only the records where complaint_id matches in both tables.
   - Joins on the common field 'complaint_id'.
   - Selects specific columns: complaint_id, _result_Id_, _sentiment_, and Actual.
   - The output table 'validated' contains matched records from both tables.
*/

proc sql;
	CREATE TABLE validated AS  /* Specify the output table name */
    SELECT s.complaint_id, s._result_Id_, s._sentiment_, v.Actual
    FROM joined_data_2 AS s
    INNER JOIN SASCAS1.ASSIGN2VALIDATE AS v
        ON s.complaint_id = v.complaint_id /* joining ASSIGN2SCORE and ASSIGN2VALIDATE with the key complaint_id */
;
