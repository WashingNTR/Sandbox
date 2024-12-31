DECLARE @FromDate AS DATETIME = '20240101 00:00:00';
DECLARE @ToDate AS DATETIME   = '20240630 23:59:59';
 
CREATE TABLE #AirfiDataTypes (KeyName  NVARCHAR(MAX), KeyValue INT);
INSERT INTO #AirfiDataTypes
VALUES ('Unknown', 0),
       ('Purchase', 1),
	   ('StockMutation', 2),
	   ('Form', 3),
	   ('LegSubscription', 4),
	   ('StockConfirmation', 5);
 
CREATE TABLE #ReconStates (KeyName  NVARCHAR(MAX), KeyValue INT, Chronology INT);
INSERT INTO #ReconStates
VALUES ('None', 0, 0),
       ('Scheduled', 1, 1),
	   ('Queued', 2, 2),
	   ('InProgress', 3, 3),
	   ('Failed', 4, 8),
	   ('Done', 5, 9),
	   ('Unscheduled', 6, 4),
	   ('Processed', 7, 5),
	   ('RouteToCompute', 8, 6),
	   ('FailedToComputeRoute', 9, 7);
 
CREATE TABLE #ErrorTypes (KeyName  NVARCHAR(MAX), KeyValue INT);
INSERT INTO #ErrorTypes
VALUES ('Technical', 0),
       ('Default', 1),
	   ('WinrestConfiguration', 100),
	   ('NotificationContent', 200),
	   ('NotificationJsonData', 201),
	   ('AlreadyProcessed', 202),
	   ('BadDataType', 203),
	   ('Airfi', 300),
	   ('AirfiID', 301),
	   ('Barset', 400),
	   ('BarsetStockMouvementComputation', 401),
	   ('Flight', 500),
	   ('Flightkey', 501),
	   ('FlightAirportDeparture', 502),
	   ('FlightAirportDestination', 503),
	   ('Crew', 600),
	   ('Catalog', 700),
	   ('CatalogMenuDefinition', 701),
	   ('CatalogMenuSectionDefinition', 702),
	   ('InnerCatalogMenuCategoryDetail', 703),
	   ('CatalogProductDefinition', 704),
	   ('InnerCatalogProductCategoryDetail', 705),
	   ('Customer', 800),
	   ('Cashbag', 900),
	   ('CashbagDrop', 901);
 
-- Statistics
;WITH Notifications AS
(
	SELECT Id
	FROM AirfiPurchaseRaw Notifications
	WHERE ReceptionDate >= @FromDate 
	  AND ReceptionDate <= @ToDate 
	  AND IsForTesting = 0
	  and DataType = 1 
)
 
SELECT 
	CAST(#ReconStates.KeyValue AS NVARCHAR(MAX)) + '-' + #ReconStates.KeyName [NotificationState],
	COUNT(Notifications.Id) [Volume],
	ROUND(COUNT(Notifications.Id) * 100 / CAST((SELECT COUNT(*) FROM Notifications) AS float), 2) [Proportion (%)],
	SUM(IIF(AirfiPurchaseRaw.WorkerInstanceId IS NOT NULL AND AirfiPurchaseRaw.WorkerInstanceId LIKE 'sche-%', 1, 0)) [Scheduling],
	SUM(IIF(AirfiPurchaseRaw.WorkerInstanceId IS NOT NULL AND AirfiPurchaseRaw.WorkerInstanceId LIKE 'proc-%', 1, 0)) [Processing],
	SUM(IIF(AirfiPurchaseRaw.WorkerInstanceId IS NOT NULL AND AirfiPurchaseRaw.WorkerInstanceId LIKE 'comp-%', 1, 0)) [Computing]
FROM Notifications
INNER JOIN AirfiPurchaseRaw ON AirfiPurchaseRaw.Id = Notifications.Id
INNER JOIN #ReconStates ON #ReconStates.KeyValue = AirfiPurchaseRaw.ReconState
GROUP BY #ReconStates.KeyName, #ReconStates.KeyValue, #ReconStates.Chronology
ORDER BY #ReconStates.Chronology
 
-- Errors
 
;WITH FailedNotifications AS
(
	SELECT Id
	FROM AirfiPurchaseRaw
	WHERE ReceptionDate >= @FromDate 
		AND ReceptionDate <= @ToDate
		AND ErrorType IS NOT NULL
		AND IsForTesting = 0
	    and DataType = 1 
)
 
SELECT
	#ErrorTypes.KeyName [Error],
	COUNT(AirfiPurchaseRaw.Id) [Volume],
	ROUND(COUNT(FailedNotifications.Id) * 100 / CAST((SELECT COUNT(*) FROM FailedNotifications) AS float), 2) [Proportion (%)]
FROM AirfiPurchaseRaw
INNER JOIN FailedNotifications ON FailedNotifications.Id = AirfiPurchaseRaw.Id
INNER JOIN #ErrorTypes ON #ErrorTypes.KeyValue = ErrorType
where DataType = 1 
GROUP BY ErrorType, #ErrorTypes.KeyName
ORDER BY [Volume] DESC
 
-- Clean Tables
 
DROP TABLE #AirfiDataTypes
DROP TABLE #ReconStates
DROP TABLE #ErrorTypes