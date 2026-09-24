# Process_prioritization
An SQL-based analytical solution that automates the prioritization of critical business workflows using statistical percentiles and Euclidean distance.
# Operational Dashboard & Transaction Prioritization
This repository contains the SQL logic used to dynamically prioritize "Happy Path" transactions for Process Analysts. 

The code calculates statistical percentiles and Euclidean distance to isolate high-value transactions, preventing the loss of historical data caused by the native system's novelty score reset.

### Data Dictionary (Anonymized)

Due to corporate confidentiality, the original datasets cannot be shared[cite: 2]. The schema below represents the anonymized structure used for the statistical modeling[cite: 2]:

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `project_lead` | String | The manager assigned to oversee the project. |
| `client` | String | Identifier for the client (e.g., Client Alpha). |
| `project_name` | String | The specific process mapping project. |
| `project_key` | String | Unique alphanumeric code for the project. |
| `transaction_id` | Integer | Unique identifier for each recorded transaction. |
| `step_count` | Integer | The total number of steps recorded within the transaction. |
| `novelty_score` | Integer | Calculated variability metric representing transaction uniqueness. |
| `reviewed_at` | Date | Timestamp of when the transaction was reviewed. |
| `reviewed_by` | String | Email or name of the analyst who completed the review. |
| `happy_path` | String | The final calculated priority classification. |
