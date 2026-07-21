-- ============================================================================
-- CAREINSIGHT CDW - STAGE 3: LAYER 2 ANALYTICS VIEWS
-- Purpose: Pre-computes clinical care gap pathways, patient safety alerts,
--          provider throughput, and financial claim leakage for Power BI.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View 1: Clinical Safety - Hypertension Cohort Progression
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW dw.vw_hypertension_cohort_progression AS
WITH first_diagnosis AS (
    SELECT 
        patient_key,
        MIN(diagnosis_onset_date) AS diagnosis_date
    FROM dw.fact_diagnoses
    WHERE condition_code IN ('59621000', '38341003')
    GROUP BY patient_key
),
elevated_bp AS (
    SELECT 
        l.patient_key,
        MIN(l.text_date) AS elevated_bp_date
    FROM dw.fact_lab_results l
    JOIN first_diagnosis fd ON l.patient_key = fd.patient_key
    WHERE ((l.loinc_code = '8480-6' AND l.numeric_value >= 140)
       OR (l.loinc_code = '8462-4' AND l.numeric_value >= 90))
      AND l.text_date <= fd.diagnosis_date
    GROUP BY l.patient_key
),
first_prescription AS (
    SELECT 
        fp.patient_key,
        MIN(fp.prescription_start_date) AS rx_date
    FROM dw.fact_prescriptions fp
    JOIN first_diagnosis fd ON fp.patient_key = fd.patient_key
    WHERE fp.prescription_start_date >= fd.diagnosis_date
    GROUP BY fp.patient_key
)
SELECT 
    p.patient_key,
    p.first_name,
    p.last_name,
    p.current_or_death_age AS age,
    p.gender,
    ebp.elevated_bp_date,
    fd.diagnosis_date,
    fp.rx_date,
    (fd.diagnosis_date::DATE - ebp.elevated_bp_date::DATE) AS days_to_diagnosis,
    (fp.rx_date::DATE - fd.diagnosis_date::DATE) AS days_to_prescription
FROM dw.dim_patients p
JOIN first_diagnosis fd ON p.patient_key = fd.patient_key
LEFT JOIN elevated_bp ebp ON p.patient_key = ebp.patient_key
LEFT JOIN first_prescription fp ON p.patient_key = fp.patient_key;


-- ----------------------------------------------------------------------------
-- View 2: Clinical Safety - Medication Allergy Safety Alerts
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW dw.vw_medication_allergy_safety_alerts AS
SELECT DISTINCT
    p.patient_key,
    p.first_name,
    p.last_name,
    p.current_or_death_age AS age,
    p.gender,
    COALESCE(a.allergy_description, 'No Documented Allergy') AS documented_allergy,
    fp.medication_name AS prescribed_medication,
    fp.prescription_start_date,
    CASE 
        WHEN a.allergy_description IS NOT NULL THEN 'HIGH RISK: Adverse Drug Event Flag'
        ELSE 'LOW RISK: Standard Prescription'
    END AS alert_severity
FROM dw.fact_prescriptions fp
JOIN dw.dim_patients p ON fp.patient_key = p.patient_key
LEFT JOIN dw.fact_allergies a ON p.patient_key = a.patient_key;


-- ----------------------------------------------------------------------------
-- View 3: Operations - Provider Utilization & Productivity Performance
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS dw.vw_provider_utilization_performance;

CREATE VIEW dw.vw_provider_utilization_performance AS
SELECT 
    pr.provider_key,
    pr.provider_name,
    pr.specialty,
    COALESCE(fe.encounter_class, 'Unassigned') AS encounter_class,
    COUNT(fe.encounter_key) AS total_encounters,
    COUNT(DISTINCT fe.patient_key) AS unique_patients_treated,
    ROUND(AVG(EXTRACT(EPOCH FROM (fe.encounter_end_timestamp - fe.encounter_start_timestamp)) / 60.0), 2) AS avg_encounter_duration_minutes,
    COALESCE(SUM(fe.total_claim_cost), 0.00) AS total_revenue_generated
FROM dw.dim_providers pr
LEFT JOIN dw.fact_encounters fe ON pr.provider_key = fe.provider_key
GROUP BY pr.provider_key, pr.provider_name, pr.specialty, fe.encounter_class;


-- ----------------------------------------------------------------------------
-- View 4: Financials - Payer Claim Leakage & Coverage Analysis
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW dw.vw_payer_claim_leakage AS
SELECT 
    pa.payer_key,
    pa.payer_name,
    COUNT(fe.encounter_key) AS total_claims,
    SUM(fe.total_claim_cost) AS gross_billed_amount,
    SUM(fe.insurance_covered_amount) AS total_insurance_payout,
    SUM(fe.patient_out_of_pocket_cost) AS total_patient_out_of_pocket,
    ROUND((SUM(fe.insurance_covered_amount) / NULLIF(SUM(fe.total_claim_cost), 0) * 100), 2) AS insurance_coverage_pct,
    ROUND(AVG(fe.patient_out_of_pocket_cost), 2) AS avg_patient_out_of_pocket_per_visit
FROM dw.dim_payers pa
LEFT JOIN dw.fact_encounters fe ON pa.payer_key = fe.payer_key
GROUP BY pa.payer_key, pa.payer_name;
