-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi,
		SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC;

-- 1. b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

--Filtering all claims reported and having them grouped by npi
WITH sum_total_claims AS (SELECT npi,
									SUM(total_claim_count) AS total_claims
							FROM prescription
							GROUP BY npi
							ORDER BY total_claims DESC)
--Combining CTE with prescriber table to get specifc info on prescribers with most total claims
SELECT nppes_provider_first_name,
		nppes_provider_last_org_name,
		specialty_description,
		total_claims
FROM prescriber
		LEFT JOIN sum_total_claims
		USING(npi)
ORDER BY total_claims DESC NULLS LAST;

-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description,
		SUM(total_claim_count) AS total_claims
--LEFT JOINING with prescriber to make sure ALL prescription data is pulled and matched with npi
FROM prescription
		LEFT JOIN prescriber
		USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;

-- 2. b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description,
		SUM(total_claim_count) AS total_claims
--LEFT JOINING with prescriber to make sure ALL prescription data is pulled and matched with npi
--LEFT JOINING with drug to pull in all data from that data
FROM prescription
		LEFT JOIN prescriber
		USING(npi)
		LEFT JOIN drug
		ON prescription.drug_name=drug.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC;

-- 2. c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description,
		SUM(total_claim_count) AS total_claims
FROM prescriber
		FULL JOIN prescription
		USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;

-- 2. d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

--Total claims grouped by specialty_description
WITH specialty_total AS (SELECT specialty_description,
									SUM(total_claim_count) AS total_claims
						FROM prescriber
								LEFT JOIN prescription
								USING(npi)
						GROUP BY specialty_description),
--Total opioid claims grouped by specialty_description						
	specialty_opioid_total AS (SELECT specialty_description,
										SUM(total_claim_count) AS total_opioid_claims
								FROM prescriber
									LEFT JOIN prescription
									USING(npi)
									LEFT JOIN drug
									ON prescription.drug_name=drug.drug_name
								WHERE opioid_drug_flag = 'Y'
								GROUP BY specialty_description)
SELECT specialty_description,
		ROUND(SUM(total_opioid_claims)/SUM(total_claims),5) * 100 AS perc_opioid_claims
FROM specialty_opioid_total
		LEFT JOIN specialty_total
		USING(specialty_description)
GROUP BY specialty_description
ORDER BY perc_opioid_claims DESC;

-- 3. a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name,
		SUM(total_drug_cost::money) AS total_drug_cost
FROM drug
	LEFT JOIN prescription
	USING(drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC NULLS LAST;

-- 3. b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT generic_name,
		SUM(total_drug_cost::money)/SUM(total_day_supply) AS total_drug_cost_per_day
FROM drug
	LEFT JOIN prescription
	USING(drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost_per_day DESC NULLS LAST;

-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
FROM drug

-- 4. b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
WITH drug_types AS (SELECT drug_name,
							CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
							WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
							ELSE 'neither' END AS drug_type
					FROM drug)
SELECT drug_type,
		SUM(total_drug_cost::money) AS total_drug_cost
FROM prescription
		LEFT JOIN drug_types
		USING(drug_name)
GROUP BY drug_type
ORDER BY total_drug_cost DESC;

-- 5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
		LEFT JOIN fips_county
		USING(fipscounty)
WHERE state = 'TN';

-- 5. b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname,
		SUM(population) AS total_pop
FROM cbsa
		LEFT JOIN population
		USING(fipscounty)
WHERE population IS NOT NULL
GROUP BY cbsaname
ORDER BY total_pop DESC;

-- 5. c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT county,
		population
FROM fips_county
		LEFT JOIN population
		USING(fipscounty)
WHERE fipscounty NOT IN
			(SELECT DISTINCT fipscounty
			FROM cbsa)
ORDER BY population DESC NULLS LAST;

-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT *
FROM prescription
WHERE total_claim_count > 3000

-- 6. b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name,
		total_claim_count,
		opioid_drug_flag
FROM prescription
		LEFT JOIN drug
		USING(drug_name)
WHERE total_claim_count > 3000

-- 6. c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT nppes_provider_first_name,
		nppes_provider_last_org_name,
		drug_name,
		total_claim_count,
		opioid_drug_flag
FROM prescription
		LEFT JOIN drug
		USING(drug_name)
		LEFT JOIN prescriber
		ON prescription.npi=prescriber.npi
WHERE total_claim_count > 3000

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

--Query to get all combos of npi/drug_name
WITH npi_drug_combo AS (SELECT npi,
								drug_name
						FROM prescriber
								CROSS JOIN drug
						WHERE specialty_description = 'Pain Management'
								AND nppes_provider_city = 'NASHVILLE'
								AND opioid_drug_flag = 'Y')
SELECT npi_drug_combo.npi,
		npi_drug_combo.drug_name,
		COALESCE(total_claim_count, 0) AS total_claim_count
--RIGHT JOINING with previous query to make sure all combos are included in final report
--JOINING on two conditons to make sure npi and drug_name combo stay together
FROM prescription
		RIGHT JOIN npi_drug_combo
		ON prescription.npi=npi_drug_combo.npi
		AND prescription.drug_name=npi_drug_combo.drug_name
ORDER BY total_claim_count DESC;
-- 7. c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.


--BONUS--
-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(npi)
FROM prescriber
WHERE npi NOT IN
			(SELECT DISTINCT npi
			FROM prescription)

-- 2.a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

--Query that included total claims for drugs grouped by drug_name
WITH top_drugs_fp AS (SELECT drug_name,
								SUM(total_claim_count) AS total_claims
						FROM prescriber
							INNER JOIN prescription
							USING(npi)
						WHERE specialty_description = 'Family Practice'
						GROUP BY drug_name)
SELECT generic_name,
		SUM(total_claims) AS total_claims
FROM drug
		INNER JOIN top_drugs_fp
		USING(drug_name)
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

-- 2.b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
WITH top_drugs_c AS (SELECT drug_name,
								SUM(total_claim_count) AS total_claims
						FROM prescriber
							INNER JOIN prescription
							USING(npi)
						WHERE specialty_description = 'Cardiology'
						GROUP BY drug_name)
SELECT generic_name,
		SUM(total_claims) AS total_claims
FROM drug
		INNER JOIN top_drugs_c
		USING(drug_name)
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

-- 2.c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

WITH top_drugs_c_fp AS (SELECT drug_name,
								SUM(total_claim_count) AS total_claims
						FROM prescriber
							INNER JOIN prescription
							USING(npi)
						WHERE specialty_description = 'Cardiology'
					 			OR specialty_description = 'Family Practice'
						GROUP BY drug_name)
SELECT generic_name,
		SUM(total_claims) AS total_claims
FROM drug
		INNER JOIN top_drugs_c_fp
		USING(drug_name)
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
-- 3.a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT npi,
		SUM(total_claim_count) AS total_claims,
		nppes_provider_city AS city
FROM prescriber
		LEFT JOIN prescription
		USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC NULLS LAST;

-- 3.b. Now, report the same for Memphis.

SELECT npi,
		SUM(total_claim_count) AS total_claims,
		nppes_provider_city AS city
FROM prescriber
		LEFT JOIN prescription
		USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC NULLS LAST;

-- 3.c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
SELECT npi,
		SUM(total_claim_count) AS total_claims,
		nppes_provider_city AS city
FROM prescriber
		LEFT JOIN prescription
		USING(npi)
WHERE nppes_provider_city IN ('MEMPHIS', 'NASHVILLE', 'KNOXVILLE', 'CHATTANOOGA')
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC NULLS LAST;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT county,
		deaths AS overdose_deaths
FROM fips_county
		LEFT JOIN overdoses
		USING(fipscounty)
WHERE deaths >
		(SELECT AVG(deaths)
		FROM overdoses)
ORDER BY overdose_deaths DESC;

-- 5.a. Write a query that finds the total population of Tennessee.
SELECT state,
		SUM(population) AS total_pop
FROM fips_county
		LEFT JOIN population
		USING(fipscounty)
WHERE state = 'TN'
GROUP BY state;

-- 5.b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT county,
		population,
		ROUND(population/(SELECT SUM(population) AS total_pop
					FROM fips_county
						LEFT JOIN population
						USING(fipscounty)
					WHERE state = 'TN') * 100, 4) AS perc_tn_pop
FROM fips_county
		LEFT JOIN population
		USING(fipscounty)
WHERE state = 'TN'
ORDER BY perc_tn_pop DESC NULLS LAST;



