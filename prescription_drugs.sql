--  1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
Select npi,
		SUM(total_claim_count) AS total_num_claims
From prescription
GROUP BY npi
ORDER BY total_num_claims DESC
LIMIT 1;
--1881634483 / 99707


--  1. b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
Select npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name, 
		specialty_description,
		SUM(total_claim_count) AS total_claim_count
From prescriber 
	INNER JOIN prescription 
	USING(npi) 
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY total_claim_count DESC;
-- Bruce Pendley / Family Practice / 99707


-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?
Select specialty_description,
		SUM(total_claim_count) AS total_num_claims
From prescriber
	INNER JOIN prescription 
	USING(npi)
Group By specialty_description
ORDER BY total_num_claims DESC;
-- Family Practice / 9752347


-- 2. b. Which specialty had the most total number of claims for opioids?
Select specialty_description,
		SUM(total_claim_count) AS total_num_claims
From prescriber AS p
		INNER JOIN prescription AS p2
		USING(npi)
		INNER JOIN drug
		ON p2.drug_name=drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
Group BY specialty_description
ORDER BY total_num_claims DESC;
-- Nurse Practitioner / 900845


-- 2. c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
Select specialty_description,
		SUM(total_claim_count) AS total_num_claims
From prescriber 
	FULL JOIN prescription 
	USING (npi)
Group BY specialty_description
ORDER BY total_num_claims DESC;


-- 2. d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
Select specialty_description,
		SUM(total_claim_count),
		SUM(total_claim_count)
From prescriber AS p
	LEFT JOIN prescription AS p2
	USING(npi)
	LEFT JOIN drug AS d
	ON p2.drug_name=d.drug_name
GROUP BY specialty_description

-- 3. a. Which drug (generic_name) had the highest total drug cost?
Select generic_name,
		SUM(total_drug_cost::money) AS total_drug_cost
From drug
	INNER JOIN prescription
	USING(drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC;

--Average cost per drug
Select generic_name,
		SUM(total_drug_cost::money)/COUNT(total_drug_cost) AS avg_drug_cost
From drug
	INNER JOIN prescription
	USING(drug_name)
GROUP BY generic_name
ORDER BY avg_drug_cost DESC;

-- 3. b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
Select generic_name,
		ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS total_cost_day
From drug
	INNER JOIN prescription
	USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost_day DESC;

	
-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
Select drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
From drug


-- 4. b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
Select drug_type,
		SUM(total_drug_cost)::money AS total_drug_cost
From 
	(Select drug_name,
			CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
	From drug) AS drugs_2
		INNER JOIN prescription AS p
		ON drugs_2.drug_name=p.drug_name
GROUP BY drug_type
ORDER BY total_drug_cost DESC;

-- 5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
Select COUNT(DISTINCT cbsa)
From cbsa
	INNER JOIN fips_county
	USING(fipscounty)
WHERE state = 'TN'

-- 5. b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
Select cbsaname,
		SUM(population) AS total_pop
From cbsa
	INNER JOIN population
	USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC;


-- 5. c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
Select county AS county_name,
		population
From fips_county
		INNER JOIN population
		USING(fipscounty)
WHERE fipscounty NOT IN
	(Select fipscounty
	From cbsa)
ORDER BY population DESC;

-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
Select *
From prescription
WHERE total_claim_count > 3000
ORDER BY total_claim_count DESC;

-- 6. b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
Select claims.*,
		CASE WHEN d.opioid_drug_flag = 'Y' THEN 'yes'
			WHEN d.opioid_drug_flag = 'N' THEN 'no'
			ELSE 'n/a' END AS opioid_drug
From 
	(Select *
	From prescription
	WHERE total_claim_count > 3000
	ORDER BY total_claim_count DESC) AS claims
		INNER JOIN drug AS d
		USING(drug_name)
ORDER BY total_claim_count DESC;

-- 6. c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
Select nppes_provider_first_name,
		nppes_provider_last_org_name,
		claims_2.*
From 
	(Select claims.*,
		CASE WHEN d.opioid_drug_flag = 'Y' THEN 'yes'
			WHEN d.opioid_drug_flag = 'N' THEN 'no'
			ELSE 'n/a' END AS opioid_drug
	From 
		(Select *
		From prescription
		WHERE total_claim_count > 3000
		ORDER BY total_claim_count DESC) AS claims
			INNER JOIN drug AS d
			USING(drug_name)
		ORDER BY total_claim_count DESC) AS claims_2
			INNER JOIN prescriber AS p
			ON p.npi=claims_2.npi

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.


-- 7. a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi,
		drug_name
FROM prescriber
	CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	
-- 7. b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
-- 7. c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT npi.npi,
		npi.drug_name,
	--COALESCE fills in NULL values with 0 (must alias column)
		COALESCE(total_claim_count, 0) AS total_num_claims
--Filtering data to include all combinations of drugs/npi that meet certain criteria
FROM (SELECT npi,
			drug_name
	FROM prescriber
		CROSS JOIN drug
	WHERE specialty_description = 'Pain Management'
		AND nppes_provider_city = 'NASHVILLE'
		AND opioid_drug_flag = 'Y') AS npi
		--LEFT JOINING with prescription to KEEP all data from previous filter
			LEFT JOIN prescription
			ON prescription.npi=npi.npi
			AND prescription.drug_name=npi.drug_name
--BONUS--
-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(npi)
FROM prescriber
--Filtering to see which npi(prescriber) does not apppear in full list of npi in prescritpion
WHERE npi NOT IN
	(SELECT DISTINCT npi
	FROM prescription);
	
-- 2.a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name,
		SUM(total_claim_count) AS total_claims
FROM prescriber
--Combining data from prescription and drug
	INNER JOIN (SELECT *
				FROM prescription
					LEFT JOIN drug
					USING(drug_name)) AS drugs
	ON prescriber.npi=drugs.npi
WHERE specialty_description ILIKE 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;


-- 2.b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name,
		SUM(total_claim_count) AS total_claims
FROM prescriber
--Combining data from prescription and drug
	INNER JOIN (SELECT *
				FROM prescription
					LEFT JOIN drug
					USING(drug_name)) AS drugs
	ON prescriber.npi=drugs.npi
WHERE specialty_description ILIKE 'Cardiology'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

-- 2.c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT generic_name,
		SUM(total_claim_count) AS total_claims
FROM prescriber
--Combining data from prescription and drug
	INNER JOIN (SELECT *
				FROM prescription
					LEFT JOIN drug
					USING(drug_name)) AS drugs
	ON prescriber.npi=drugs.npi
WHERE specialty_description ILIKE 'Cardiology'
	OR specialty_description ILIKE 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
-- 3.a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT p.npi,
		SUM(total_claim_count) AS total_num_claims,
		nppes_provider_city
FROM prescriber AS p
	LEFT JOIN prescription AS p2
	USING(npi)
WHERE nppes_provider_city ILIKE 'Nashville'
GROUP BY npi, nppes_provider_city
ORDER BY total_num_claims DESC NULLS LAST;


-- 3.b. Now, report the same for Memphis.
SELECT p.npi,
		SUM(total_claim_count) AS total_num_claims,
		nppes_provider_city
FROM prescriber AS p
	LEFT JOIN prescription AS p2
	USING(npi)
WHERE nppes_provider_city ILIKE 'Memphis'
GROUP BY npi, nppes_provider_city
ORDER BY total_num_claims DESC NULLS LAST;

-- 3.c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
SELECT p.npi,
		SUM(total_claim_count) AS total_num_claims,
		nppes_provider_city
FROM prescriber AS p
	LEFT JOIN prescription AS p2
	USING(npi)
WHERE nppes_provider_city ILIKE 'Memphis'
		OR nppes_provider_city ILIKE 'Nashville'
		OR nppes_provider_city ILIKE 'Knoxville'
		OR nppes_provider_city ILIKE 'Chattanooga'
GROUP BY npi, nppes_provider_city
ORDER BY total_num_claims DESC NULLS LAST;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT county,
		deaths AS num_of_deaths
FROM fips_county AS fc
		INNER JOIN overdoses AS od
		USING(fipscounty)
WHERE deaths >
		(SELECT AVG(deaths) 
		FROM overdoses)
ORDER BY num_of_deaths;

-- 5.a. Write a query that finds the total population of Tennessee.
SELECT SUM(population)
FROM fips_county
	LEFT JOIN population
	USING(fipscounty)
WHERE state = 'TN'
-- 5.b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
SELECT county,
		population AS county_pop,
		population/(SELECT SUM(population)
					FROM fips_county
						LEFT JOIN population
						USING(fipscounty)
						WHERE state = 'TN') * 100 AS perc_pop_tn
FROM population
	LEFT JOIN fips_county 
	USING(fipscounty)
WHERE state = 'TN'
ORDER BY perc_pop_tn DESC;

	

	
	