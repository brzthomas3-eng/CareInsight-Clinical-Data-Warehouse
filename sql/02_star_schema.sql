-- ============================================================================
-- CAREINSIGHT CDW - STAGE 2: STAR SCHEMA DIMENSIONAL MODEL
-- Purpose: Creates the dw schema, dimension tables, transactional fact 
--          tables, and populates surrogate keys via MD5 hashing.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS dw;

-- ----------------------------------------------------------------------------
-- DIMENSION TABLES
-- ----------------------------------------------------------------------------

-- Dimension: Patients
CREATE TABLE IF NOT EXISTS dw.dim_patients (
    patient_key TEXT PRIMARY KEY,
    patient_id TEXT,
    first_name TEXT,
    last_name TEXT,
    gender TEXT,
    birth_date DATE,
    death_date DATE,
    current_or_death_age INT,
    city TEXT,
    state TEXT
);

INSERT INTO dw.dim_patients
SELECT 
    MD5(id) AS patient_key,
    id AS patient_id,
    first AS first_name,
    last AS last_name,
    gender,
    birthdate::DATE AS birth_date,
    NULLIF(deathdate, '')::DATE AS death_date,
    COALESCE(
        EXTRACT(YEAR FROM AGE(NULLIF(deathdate, '')::DATE, birthdate::DATE)),
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthdate::DATE))
    )::INT AS current_or_death_age,
    city,
    state
FROM staging.staging_patients
ON CONFLICT (patient_key) DO NOTHING;


-- Dimension: Providers
CREATE TABLE IF NOT EXISTS dw.dim_providers (
    provider_key TEXT PRIMARY KEY,
    provider_id TEXT,
    provider_name TEXT,
    specialty TEXT,
    city TEXT,
    state TEXT
);

INSERT INTO dw.dim_providers
SELECT 
    MD5(id) AS provider_key,
    id AS provider_id,
    name AS provider_name,
    specialty,
    city,
    state
FROM staging.staging_providers
ON CONFLICT (provider_key) DO NOTHING;


-- Dimension: Payers
CREATE TABLE IF NOT EXISTS dw.dim_payers (
    payer_key TEXT PRIMARY KEY,
    payer_id TEXT,
    payer_name TEXT,
    city TEXT,
    state TEXT
);

INSERT INTO dw.dim_payers
SELECT 
    MD5(id) AS payer_key,
    id AS payer_id,
    name AS payer_name,
    city,
    state_headquartered AS state
FROM staging.staging_payers
ON CONFLICT (payer_key) DO NOTHING;


-- Dimension: Organizations
CREATE TABLE IF NOT EXISTS dw.dim_organizations (
    organization_key TEXT PRIMARY KEY,
    organization_id TEXT,
    organization_name TEXT,
    city TEXT,
    state TEXT
);

INSERT INTO dw.dim_organizations
SELECT 
    MD5(id) AS organization_key,
    id AS organization_id,
    name AS organization_name,
    city,
    state
FROM staging.staging_organizations
ON CONFLICT (organization_key) DO NOTHING;


-- ----------------------------------------------------------------------------
-- FACT TABLES
-- ----------------------------------------------------------------------------

-- Fact: Encounters
CREATE TABLE IF NOT EXISTS dw.fact_encounters (
    encounter_key TEXT PRIMARY KEY,
    patient_key TEXT,
    provider_key TEXT,
    payer_key TEXT,
    organization_key TEXT,
    encounter_class TEXT,
    encounter_start_timestamp TIMESTAMP,
    encounter_end_timestamp TIMESTAMP,
    total_claim_cost NUMERIC(12,2),
    insurance_covered_amount NUMERIC(12,2),
    patient_out_of_pocket_cost NUMERIC(12,2)
);

INSERT INTO dw.fact_encounters
SELECT 
    MD5(id) AS encounter_key,
    MD5(patient) AS patient_key,
    MD5(provider) AS provider_key,
    MD5(payer) AS payer_key,
    MD5(organization) AS organization_key,
    encounterclass AS encounter_class,
    start::TIMESTAMP AS encounter_start_timestamp,
    stop::TIMESTAMP AS encounter_end_timestamp,
    NULLIF(total_claim_cost, '')::NUMERIC(12,2) AS total_claim_cost,
    NULLIF(payer_coverage, '')::NUMERIC(12,2) AS insurance_covered_amount,
    (NULLIF(total_claim_cost, '')::NUMERIC(12,2) - NULLIF(payer_coverage, '')::NUMERIC(12,2)) AS patient_out_of_pocket_cost
FROM staging.staging_encounters
ON CONFLICT (encounter_key) DO NOTHING;


-- Fact: Diagnoses
CREATE TABLE IF NOT EXISTS dw.fact_diagnoses (
    diagnosis_fact_key TEXT PRIMARY KEY,
    patient_key TEXT,
    encounter_key TEXT,
    condition_code TEXT,
    condition_description TEXT,
    diagnosis_onset_date DATE
);

INSERT INTO dw.fact_diagnoses
SELECT 
    MD5(ROW_NUMBER() OVER ()::TEXT) AS diagnosis_fact_key,
    MD5(patient) AS patient_key,
    NULLIF(encounter, '') AS encounter_key,
    code AS condition_code,
    description AS condition_description,
    start::DATE AS diagnosis_onset_date
FROM staging.staging_conditions
ON CONFLICT (diagnosis_fact_key) DO NOTHING;


-- Fact: Prescriptions
CREATE TABLE IF NOT EXISTS dw.fact_prescriptions (
    prescription_fact_key TEXT PRIMARY KEY,
    patient_key TEXT,
    encounter_key TEXT,
    payer_key TEXT,
    medication_code TEXT,
    medication_name TEXT,
    prescription_start_date DATE,
    prescription_end_date DATE,
    total_cost NUMERIC(12,2)
);

INSERT INTO dw.fact_prescriptions
SELECT 
    MD5(ROW_NUMBER() OVER ()::TEXT) AS prescription_fact_key,
    MD5(patient) AS patient_key,
    NULLIF(encounter, '') AS encounter_key,
    NULLIF(payer, '') AS payer_key,
    code AS medication_code,
    description AS medication_name,
    start::DATE AS prescription_start_date,
    NULLIF(stop, '')::DATE AS prescription_end_date,
    NULLIF(totalcost, '')::NUMERIC(12,2) AS total_cost
FROM staging.staging_medications
ON CONFLICT (prescription_fact_key) DO NOTHING;


-- Fact: Allergies
CREATE TABLE IF NOT EXISTS dw.fact_allergies (
    allergy_fact_key TEXT PRIMARY KEY,
    patient_key TEXT,
    encounter_key TEXT,
    allergy_code TEXT,
    allergy_description TEXT,
    allergy_start_date DATE
);

INSERT INTO dw.fact_allergies
SELECT 
    MD5(ROW_NUMBER() OVER ()::TEXT) AS allergy_fact_key,
    MD5(patient) AS patient_key,
    NULLIF(encounter, '') AS encounter_key,
    code AS allergy_code,
    description AS allergy_description,
    start::DATE AS allergy_start_date
FROM staging.staging_allergies
ON CONFLICT (allergy_fact_key) DO NOTHING;


-- Fact: Lab Results / Observations
CREATE TABLE IF NOT EXISTS dw.fact_lab_results (
    lab_fact_key TEXT PRIMARY KEY,
    patient_key TEXT,
    encounter_key TEXT,
    loinc_code TEXT,
    lab_description TEXT,
    numeric_value NUMERIC(12,2),
    units TEXT,
    text_date TIMESTAMP
);

INSERT INTO dw.fact_lab_results
SELECT 
    MD5(ROW_NUMBER() OVER ()::TEXT) AS lab_fact_key,
    MD5(patient) AS patient_key,
    NULLIF(encounter, '') AS encounter_key,
    code AS loinc_code,
    description AS lab_description,
    NULLIF(value, '')::NUMERIC(12,2) AS numeric_value,
    units,
    date::TIMESTAMP AS text_date
FROM staging.staging_observations
ON CONFLICT (lab_fact_key) DO NOTHING;
