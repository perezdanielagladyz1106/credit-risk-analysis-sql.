CREATE DATABASE credit_risk_project
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE credit_risk_project;

CREATE TABLE credit_risk_import (
    person_age VARCHAR(50),
    person_income VARCHAR(50),
    person_home_ownership VARCHAR(50),
    person_emp_length VARCHAR(50),
    loan_intent VARCHAR(50),
    loan_grade VARCHAR(50),
    loan_amnt VARCHAR(50),
    loan_int_rate VARCHAR(50),
    loan_status VARCHAR(50),
    loan_percent_income VARCHAR(50),
    cb_person_default_on_file VARCHAR(50),
    cb_person_cred_hist_length VARCHAR(50)
);

-- CSV-Pfad vor der Ausführung anpassen.
-- Import über den MySQL-Client mit --local-infile=1 ausführen.

LOAD DATA LOCAL INFILE
'C:/Users/DanielaOliverPerez/Downloads/credit_risk_dataset.csv'
INTO TABLE credit_risk_import
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    person_age,
    person_income,
    person_home_ownership,
    person_emp_length,
    loan_intent,
    loan_grade,
    loan_amnt,
    loan_int_rate,
    loan_status,
    loan_percent_income,
    cb_person_default_on_file,
    cb_person_cred_hist_length
);

-- Vorschau der importierten Daten
SELECT *
FROM credit_risk_import
LIMIT 5;

-- Fehlende Werte prüfen

SELECT
    SUM(person_emp_length IS NULL
        OR TRIM(person_emp_length) = '')
        AS fehlende_beschaeftigungsdauer,
    SUM(loan_int_rate IS NULL
        OR TRIM(loan_int_rate) = '')
        AS fehlende_zinssaetze
FROM credit_risk_import;

-- Tabelle mit passenden Datentypen erstellen
CREATE TABLE credit_risk_raw (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    person_age INT,
    person_income DECIMAL(12,2),
    person_home_ownership VARCHAR(20),
    person_emp_length DECIMAL(6,1),
    loan_intent VARCHAR(30),
    loan_grade CHAR(1),
    loan_amnt DECIMAL(12,2),
    loan_int_rate DECIMAL(5,2),
    loan_status TINYINT,
    loan_percent_income DECIMAL(5,2),
    cb_person_default_on_file CHAR(1),
    cb_person_cred_hist_length INT
);

-- Importierte Daten übernehmen:
-- Leerwerte in NULL umwandeln und Zeilenumbrüche entfernen
INSERT INTO credit_risk_raw (
    person_age,
    person_income,
    person_home_ownership,
    person_emp_length,
    loan_intent,
    loan_grade,
    loan_amnt,
    loan_int_rate,
    loan_status,
    loan_percent_income,
    cb_person_default_on_file,
    cb_person_cred_hist_length
)
SELECT
    CAST(NULLIF(TRIM(person_age), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(person_income), '') AS DECIMAL(12,2)),
    TRIM(person_home_ownership),
    CAST(NULLIF(TRIM(person_emp_length), '') AS DECIMAL(6,1)),
    TRIM(loan_intent),
    TRIM(loan_grade),
    CAST(NULLIF(TRIM(loan_amnt), '') AS DECIMAL(12,2)),
    CAST(NULLIF(TRIM(loan_int_rate), '') AS DECIMAL(5,2)),
    CAST(NULLIF(TRIM(loan_status), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(loan_percent_income), '') AS DECIMAL(5,2)),
    TRIM(cb_person_default_on_file),
    CAST(
        NULLIF(TRIM(REPLACE(cb_person_cred_hist_length, '\r', '')), '')
        AS UNSIGNED
    )
FROM credit_risk_import;

-- Warnungen unmittelbar nach der Übernahme prüfen
SHOW WARNINGS LIMIT 10;


-- Anzahl und fehlende Werte kontrollieren
SELECT
    COUNT(*) AS anzahl_rohdaten,
    SUM(person_emp_length IS NULL) AS fehlende_beschaeftigungsdauer,
    SUM(loan_int_rate IS NULL) AS fehlende_zinssaetze
FROM credit_risk_raw;

SELECT
    COUNT(*) AS anzahl_rohdaten,
    SUM(person_emp_length IS NULL) AS fehlende_beschaeftigungsdauer,
    SUM(loan_int_rate IS NULL) AS fehlende_zinssaetze
FROM credit_risk_raw;

-- Bereinigte Sicht erstellen
CREATE OR REPLACE VIEW credit_risk_clean AS
SELECT *
FROM credit_risk_raw
WHERE person_age BETWEEN 18 AND 100
  AND (
      person_emp_length IS NULL
      OR (
          person_emp_length <= 60
          AND person_emp_length <= person_age - 14
      )
  );

-- Bereinigung kontrollieren
SELECT
    (SELECT COUNT(*) FROM credit_risk_raw) AS anzahl_rohdaten,
    COUNT(*) AS anzahl_bereinigte_daten,
    (SELECT COUNT(*) FROM credit_risk_raw) - COUNT(*)
        AS ausgeschlossene_datensaetze
FROM credit_risk_clean;

-- Gesamtübersicht der Kredite und Ausfälle
SELECT
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_ausfaelle,
    ROUND(AVG(loan_status) * 100, 2) AS ausfallquote_prozent
FROM credit_risk_project.credit_risk_clean;

-- Ausfallquote nach Kreditklasse
SELECT
    loan_grade AS kreditklasse,
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_ausfaelle,
    ROUND(AVG(loan_status) * 100, 1) AS ausfallquote_prozent
FROM credit_risk_project.credit_risk_clean
GROUP BY loan_grade
ORDER BY loan_grade;

-- Ausfallquote nach früherem Zahlungsausfall
SELECT
    CASE
        WHEN cb_person_default_on_file = 'Y' THEN 'Ja'
        WHEN cb_person_default_on_file = 'N' THEN 'Nein'
        ELSE 'Unbekannt'
    END AS frueherer_zahlungsausfall,
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_ausfaelle,
    ROUND(AVG(loan_status) * 100, 1) AS ausfallquote_prozent
FROM credit_risk_project.credit_risk_clean
GROUP BY cb_person_default_on_file
ORDER BY cb_person_default_on_file;

-- Ausfallquote nach Wohnstatus
SELECT
    person_home_ownership AS wohnstatus,
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_ausfaelle,
    ROUND(AVG(loan_status) * 100, 1) AS ausfallquote_prozent
FROM credit_risk_project.credit_risk_clean
GROUP BY person_home_ownership
ORDER BY ausfallquote_prozent DESC;

-- Ausfallquote nach Verhältnis von Kreditbetrag zu Jahreseinkommen
SELECT
    CASE
        WHEN loan_percent_income > 0.30 THEN 'Über 30 %'
        ELSE 'Bis einschließlich 30 %'
    END AS kredit_einkommens_verhaeltnis,
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_ausfaelle,
    ROUND(AVG(loan_status) * 100, 1) AS ausfallquote_prozent
FROM credit_risk_project.credit_risk_clean
GROUP BY
    CASE
        WHEN loan_percent_income > 0.30 THEN 'Über 30 %'
        ELSE 'Bis einschließlich 30 %'
    END
ORDER BY ausfallquote_prozent DESC;

-- Durchschnittlicher Zinssatz nach Kreditklasse
SELECT
    loan_grade AS kreditklasse,
    COUNT(*) AS kredite_gesamt,
    COUNT(loan_int_rate) AS zinssaetze_vorhanden,
    SUM(loan_int_rate IS NULL) AS zinssaetze_fehlend,
    ROUND(AVG(loan_int_rate), 2) AS durchschnittlicher_zinssatz
FROM credit_risk_project.credit_risk_clean
GROUP BY loan_grade
ORDER BY loan_grade;

-- Kreditbetrag und Kreditvolumen nach Kreditklasse
SELECT
    loan_grade AS kreditklasse,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(loan_amnt), 2) AS durchschnittlicher_kreditbetrag,
    ROUND(SUM(loan_amnt), 2) AS gesamtes_kreditvolumen,
    ROUND(SUM(loan_amnt) / 1000000, 2) AS kreditvolumen_in_millionen
FROM credit_risk_project.credit_risk_clean
GROUP BY loan_grade
ORDER BY loan_grade;

-- Durchschnittlicher Kreditbetrag nach Kreditklasse
SELECT 
    loan_grade AS kreditklasse,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(loan_amnt), 0) AS durchschnittlicher_kreditbetrag
FROM
    credit_risk_project.credit_risk_clean
GROUP BY loan_grade
ORDER BY loan_grade;

-- Kredite der Klassen D–G mit einem
-- Kredit-Einkommens-Verhältnis über 30 %

SELECT
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(loan_status) * 100, 1) AS ausfallquote_prozent,
    ROUND(SUM(loan_amnt) / 1000000, 1)
        AS kreditvolumen_in_millionen
FROM credit_risk_project.credit_risk_clean
WHERE loan_grade IN ('D', 'E', 'F', 'G')
  AND loan_percent_income > 0.30;

-- Identische Merkmalskombinationen prüfen
SELECT COALESCE(SUM(anzahl - 1), 0) AS moegliche_duplikate
FROM (
    SELECT COUNT(*) AS anzahl
    FROM credit_risk_project.credit_risk_clean
    GROUP BY
        person_age,
        person_income,
        person_home_ownership,
        person_emp_length,
        loan_intent,
        loan_grade,
        loan_amnt,
        loan_int_rate,
        loan_status,
        loan_percent_income,
        cb_person_default_on_file,
        cb_person_cred_hist_length
    HAVING COUNT(*) > 1
) AS doppelte_merkmalskombinationen;

-- Vorschlag zur Überwachungsintensität
SELECT
    ueberwachungsintensitaet,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(loan_status) * 100, 1) AS ausfallquote_prozent
FROM (
    SELECT
        loan_status,
        CASE
            WHEN loan_grade IN ('D', 'E', 'F', 'G')
              OR loan_percent_income > 0.30
              OR cb_person_default_on_file = 'Y'
                THEN 'Hoch'
            WHEN loan_grade IN ('B', 'C')
                THEN 'Mittel'
            ELSE 'Niedrig'
        END AS ueberwachungsintensitaet
    FROM credit_risk_project.credit_risk_clean
) AS einstufung
GROUP BY ueberwachungsintensitaet
ORDER BY FIELD(
    ueberwachungsintensitaet,
    'Niedrig', 'Mittel', 'Hoch'
);

SELECT COUNT(*) AS anzahl_importdaten
FROM credit_risk_project.credit_risk_import;

SELECT
    COUNT(*) AS anzahl_rohdaten,
    SUM(person_emp_length IS NULL) AS fehlende_beschaeftigungsdauer,
    SUM(loan_int_rate IS NULL) AS fehlende_zinssaetze
FROM credit_risk_project.credit_risk_raw;