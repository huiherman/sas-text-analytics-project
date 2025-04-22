/*Q4 - How many records were returned from the scoring dataset for the employee concept rule? */

/* Select the count of records from the specified table where the concept equals "BANK_EMPLOYEE" */

proc sql;
SELECT count(*) as Records
from sascas1.out_concepts
where _concept_ = "_BANK_EMPLOYEE_";

/*Q5 - How many unique complaint_ids matched the fact/predicate rule in the scoring table?*/

/* Count the number of unique complaint IDs in the out_facts table */

proc sql;
    select count(distinct complaint_id) as Unique_Count
    from SASCAS1.out_facts;
quit;

/* Q6 - What is the breakdown (percentages) of sentiment on the score complaints dataset?*/

/* Use PROC FREQ to show the breakdown of sentiment */
proc freq data=sascas1.out_sent;
   /* Display frequency and percentage of sentiment */
   tables _sentiment_ / nocum;
   title "Breakdown of Sentiment Scores";

/* Q7 - What is the sentiment by Company?*/

/* Use PROC FREQ to show the breakdown of companies */

proc freq data=joined_data_2; /*joined_data_2 is the ABT table*/
  tables Company*_sentiment_; /* Display frequency and percentage of companies */
title "Breakdown of Companies"; 

/* Q8 - What is the accuracy, precision, and recall on the model, based upon this subset of data?*/

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

/* Creating the metrics table using PROC SQL:
   This block of code calculates four key metrics (TP, FP, FN, TN) related to data classification accuracy:
   - TP (True Positives): Counts the number of times the predicted result is 1 (positive) and the actual result is also 1.
   - FP (False Positives): Counts the number of times the predicted result is NULL (no prediction) while the actual result is 1.
   - FN (False Negatives): Counts the number of times the predicted result is 1 (positive) while the actual result is 0.
   - TN (True Negatives): Counts the number of times the predicted result is NULL while the actual result is 0.
If both conditions are met, it returns 1 (indicating one count of the condition).
Otherwise, it returns 0.
   The results are stored in a new table named 'metrics'.
*/

proc sql;
    create table metrics as
    select
        sum(case when validated._result_Id_ = 1 and validated.Actual = 1 then 1 else 0 end) as TP,  /* True Positives */
        sum(case when validated._result_Id_ is null and validated.Actual = 1 then 1 else 0 end) as FP,  /* False Positives */
        sum(case when validated._result_Id_ = 1 and validated.Actual = 0 then 1 else 0 end) as FN,  /* False Negatives */
        sum(case when validated._result_Id_ is null and validated.Actual = 0 then 1 else 0 end) as TN   /* True Negatives */
    from validated;
quit;

/* Calculating Accuracy, Precision, and Recall:
   After creating the metrics table, this block calculates three key performance metrics:
   - Accuracy: The proportion of correctly identified positives and negatives among all cases.
   - Precision: The proportion of correctly identified positive cases among all positive predictions.
   - Recall: The proportion of correctly identified positive cases among all actual positive cases.
   These calculated values are printed to the console.
*/

data results;
    set metrics;
    Accuracy = (TP + TN) / (TP + TN + FP + FN);
    Precision = TP / (TP + FP);
    Recall = TP / (TP + FN);
	Accuracy = round(Accuracy, 0.01);
    Precision = round(Precision, 0.01);
    Recall = round(Recall, 0.01);
    put "Accuracy: " Accuracy;
    put "Precision: " Precision;
    put "Recall: " Recall;
run;

/* Transposing and Printing Results:
   The calculated accuracy, precision, and recall values are transposed for better readability.
   The transposed table 'transposed_results' is printed to display the metrics in a vertical format.
*/

proc transpose data=results out=transposed_results;
run;

proc report data=transposed_results nowd noheader;
run;
 



 