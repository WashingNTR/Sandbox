SELECT
    CatalogProducts.Id AS CatalogProductId,
    CatalogProducts.[Name] AS CatalogProductName,
    ID.ItemId,
    CC.[Name] AS CatalogCategory,
    Items.Id AS ItemId,
    Items.[Name] AS ItemName,
    CatalogPrices.[Value] AS Price,
    Currencies.[CodeIso] AS Currency,
	AVG(ID.UnitPrice) [AvgUnitPrice],
    CASE
        WHEN CC.[Name] IN ('ACCESSOIRES', 'LOGOTES', 'COSMETIQUES', 'PARFUMS', 'BIJOUX', 'MONTRES', 'ELECTRONIQUES')
            THEN 'DUTY FREE'
        ELSE 'F&B'
    END AS Cat_Produits
FROM CatalogProducts
INNER JOIN CatalogCategoryDetails CCD ON CCD.ProductId = CatalogProducts.Id
INNER JOIN CatalogCategories CC ON CC.Id = CCD.CategoryId
INNER JOIN Catalogs C ON C.Id = CC.CatalogId
INNER JOIN Items ON Items.Id = CatalogProducts.ItemId
INNER JOIN ItemGroups ON Items.GroupID = Itemgroups.Id
INNER JOIN CatalogPrices ON CatalogPrices.CategoryDetailId = CCD.Id
INNER JOIN Currencies ON Currencies.Id = CatalogPrices.CurrencyId
INNER JOIN ItemDetails ID ON ID.ItemId = Items.Id
WHERE C.CustomerId = '7840' AND Currencies.[CodeIso] != 'KRW' -- 'KRW' pour retirer les CrewCafe 
 
GROUP BY 
    CatalogProducts.Id,
    CatalogProducts.[Name],
    ID.ItemId,
    CC.[Name],
    Items.Id,
    Items.[Name],
    CatalogPrices.[Value],
    Currencies.[CodeIso],
    CASE
        WHEN CC.[Name] IN ('ACCESSOIRES', 'LOGOTES', 'COSMETIQUES', 'PARFUMS', 'BIJOUX', 'MONTRES', 'ELECTRONIQUES')
            THEN 'DUTY FREE'
        ELSE 'F&B'
    END;