CareInsight Clinical Data WarehouseThis project is an end-to-end clinical data warehouse built using PostgreSQL and Power BI, modeled on ~2.7 million synthetic EHR records from Synthea.I designed a 3-layer ELT pipeline (Staging $\rightarrow$ Star Schema $\rightarrow$ Analytics Views) to transform raw clinical exports into clean dimensional models, tracking care gap timelines, patient safety risks, and operational performance.

##Architecture Overview

Raw CSVs (16 tables) ── staging schema ── dw schema (Star Schema) ── Layer 2 Views ── Power BI

Staging (staging): Ingestion layer that handles raw data types, casts timestamps/numeric values, and cleans empty strings across 16 source tables.

Dimensional Model (dw): Production star schema utilizing deterministic MD5 surrogate keys, dimension tables (dim_*), and transactional fact tables (fact_*).

Analytics Marts (dw.vw_*): SQL views built directly on the star schema. Moving business boundary rules and aggregations into PostgreSQL keeps the Power BI layer lean and minimizes the need for complex DAX.


##Key Clinical & Business Insights

#Hypertension Cohort Progression: 
Tracks patient care pathways from an initial elevated blood pressure lab reading (greater than or equal to 140/90 mmHg) to formal diagnosis and subsequent prescription start.

#Adverse Drug Event (ADE) Safety Alerts: 
Cross-references active prescriptions against patient allergy histories to flag high-risk drug-allergy interactions.

#Provider & Operational Productivity: 
Measures encounter throughput, average visit durations (in minutes), and revenue generation across visit types.

#Financial & Payer Leakage: 
Audits insurance reimbursement efficiency by comparing gross billed amounts, insurance coverage percentages, and out-of-pocket patient costs across payers.


##Data Profiling Note

During data validation, I discovered that all 321,528 encounter records in the Synthea export were assigned strictly to primary care providers (GENERAL PRACTICE), leaving the remaining specialist providers in the directory unlinked.To prevent skewed visual scales in Power BI when analyzing provider performance, I shifted the revenue throughput analysis to group by Encounter Class (Wellness, Ambulatory, Outpatient, Inpatient, Emergency, Urgent Care) rather than provider specialty.


##  Power BI Dashboard Pages

### Page 1: Executive Safety & Operational Overview
![Executive Overview](screenshots/executive_overview.png)

### Page 2: Hypertension Cohort Progression Matrix
![Cohort Progression Matrix](screenshots/cohort_progression_matrix.png)
