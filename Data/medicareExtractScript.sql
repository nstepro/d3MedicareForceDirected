
-- GET TOP SPECIALTIES
DECLARE @specialtyCosts TABLE (
	Specialty VARCHAR(400)
	, totalCost NUMERIC(24,2)
	, costRank INT
)
INSERT INTO @specialtyCosts
SELECT Specialty
	, SUM(Submitted_Total) AS totalCost
	, ROW_NUMBER() OVER (ORDER BY SUM(Submitted_Total) DESC) AS costRank
FROM Payments_2012
GROUP BY Specialty


-- GET NODES
DECLARE @nodes TABLE (
	HCPCS_Description VARCHAR(400)
	, Specialty VARCHAR(400)
	, averageCost NUMERIC(24,2)
	, totalCost NUMERIC(24,2)
	, totalServices NUMERIC(24,2)
	, likelihood NUMERIC(24,2)
	, summaryInd BINARY
)
INSERT INTO @nodes
SELECT x.HCPCS_Description
	, x.Specialty
	, x.averageCost
	, x.totalCost
	, x.totalServices
	, x.likelihood
	, x.summaryInd
FROM (	
	SELECT SUM(Submitted_Total)/SUM(p.Services) averageCost
		, SUM(Submitted_Total) AS totalCost
		, SUM(p.Services) AS totalServices
		, LOG(SUM(p.Services)) AS likelihood
		, Specialty
		, p.HCPCS_Description AS HCPCS_Description
		, ROW_NUMBER() OVER (PARTITION BY Specialty ORDER BY SUM(p.Services) DESC) AS totalRank
		, 0 AS summaryInd
	FROM Payments_2012 p
	WHERE NOT EXISTS (
		SELECT 1
		FROM #specialtyCosts sc
		WHERE sc.Specialty = p.Specialty
		AND sc.costRank > 15
	)
	GROUP BY Specialty, HCPCS_Description
) x
WHERE x.totalRank <= 10


INSERT INTO @nodes
SELECT 'All ' + x.Specialty AS HCPCS_Description
	, x.Specialty
	, SUM(x.totalCost)/SUM(x.totalServices) AS averageCost
	, SUM(x.totalCost) AS totalCost
	, SUM(x.totalServices) AS totalServices
	, LOG(SUM(x.totalServices)) AS likelihood
	, 1 AS summaryInd
FROM @nodes x
GROUP BY x.Specialty

-- GET LINKS
DECLARE @links TABLE (
	source VARCHAR(400)
	, target VARCHAR(400)
	, Specialty VARCHAR(400)
	, likelihood NUMERIC(24,2)
)
INSERT INTO @links
SELECT 'All ' + x.Specialty AS source
	, x.HCPCS_Description AS target
	, x.Specialty
	, likelihood AS value
FROM @nodes x
WHERE x.summaryInd = 0

-- OUTPUT
SELECT * FROM @nodes
SELECT * FROM @links