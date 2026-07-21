-- ============================================================================
-- CAREINSIGHT CDW - STAGE 1: STAGING SCHEMA & RAW LANDING TABLES
-- Purpose: Creates the staging schema and standardizes data ingestion
--          for 16 raw EHR Synthea tables.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS staging;

-- 1. Patients Landing Table
CREATE TABLE IF NOT EXISTS staging.staging_patients (
    id TEXT,
    birthdate TEXT,
    deathdate TEXT,
    ssn TEXT,
    drivers TEXT,
    passport TEXT,
    prefix TEXT,
    first TEXT,
    last TEXT,
    suffix TEXT,
    maiden TEXT,
    marital TEXT,
    race TEXT,
    ethnicity TEXT,
    gender TEXT,
    birthplace TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    county TEXT,
    fips TEXT,
    zip TEXT,
    lat TEXT,
    lon TEXT,
    healthcare_expenses TEXT,
    healthcare_coverage TEXT,
    income TEXT
);

-- 2. Encounters Landing Table
CREATE TABLE IF NOT EXISTS staging.staging_encounters (
    id TEXT,
    start TEXT,
    stop TEXT,
    patient TEXT,
    organization TEXT,
    provider TEXT,
    payer TEXT,
    encounterclass TEXT,
    code TEXT,
    description TEXT,
    base_encounter_cost TEXT,
    total_claim_cost TEXT,
    payer_coverage TEXT,
    reasoncode TEXT,
    reasondescription TEXT
);

-- 3. Providers Landing Table
CREATE TABLE IF NOT EXISTS staging.staging_providers (
    id TEXT,
    organization TEXT,
    name TEXT,
    gender TEXT,
    specialty TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    lat TEXT,
    lon TEXT,
    encounters TEXT,
    procedures TEXT
);

-- 4. Payers Landing Table
CREATE TABLE IF NOT EXISTS staging.staging_payers (
    id TEXT,
    name TEXT,
    address TEXT,
    city TEXT,
    state_headquartered TEXT,
    zip TEXT,
    phone TEXT,
    amount_covered TEXT,
    amount_uncovered TEXT,
    revenue TEXT,
    covered_encounters TEXT,
    uncovered_encounters TEXT,
    covered_medications TEXT,
    uncovered_medications TEXT,
    covered_procedures TEXT,
    uncovered_procedures TEXT,
    unique_customers TEXT,
    qols_avg TEXT
);

-- 5. Organizations Landing Table
CREATE TABLE IF NOT EXISTS staging.staging_organizations (
    id TEXT,
    name TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    lat TEXT,
    lon TEXT,
    phone TEXT,
    revenue TEXT,
    utilization TEXT
);

-- 6. Diagnoses Landing Table
CREATE TABLE IF NOT EXISTS staging.staging_conditions (
    start TEXT,
    stop TEXT,
    patient TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT
);

-- 7. Prescriptions Landing Table
CREATE TABLE IF NOT EXISTS staging.staging_medications (
    start TEXT,
    stop TEXT,
    patient TEXT,
    payer TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT,
    base_cost TEXT,
    payer_coverage TEXT,
    dispenses TEXT,
    totalcost TEXT,
    reasoncode TEXT,
    reasondescription TEXT
);

-- 8. Allergies Landing Table
CREATE TABLE IF NOT EXISTS staging.staging_allergies (
    start TEXT,
    stop TEXT,
    patient TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT
);

-- 9. Lab Results / Observations Landing Table
CREATE TABLE IF NOT EXISTS staging.staging_observations (
    date TEXT,
    patient TEXT,
    encounter TEXT,
    category TEXT,
    code TEXT,
    description TEXT,
    value TEXT,
    units TEXT,
    type TEXT
);

-- 10. Procedures Landing Table
CREATE TABLE IF NOT EXISTS staging.staging_procedures (
    date TEXT,
    patient TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT,
    base_cost TEXT,
    reasoncode TEXT,
    reasondescription TEXT
);
