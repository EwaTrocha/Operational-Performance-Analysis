--1. Work Order query 

SELECT 
  workorder.WorkOrderID,
  product.ProductID,
  category.Name as ProductCategory,
  product.Name as ProductName,
  workorder.StockedQty, 
  product.StandardCost,
  ROUND(workorder.StockedQty * product.StandardCost,2) as TotalCost,
  product.ListPrice,
  product.DaysToManufacture,
--  ROUND(product.ListPrice * workorder.StockedQty,0) as TotalListedPrice,
--  product.MakeFlag,
  workorder.StartDate,
  workorder.EndDate,  
  workorder.DueDate,
--  product.SellEndDate


FROM tc-da-1.adwentureworks_db.workorder as workorder
    LEFT JOIN `tc-da-1.adwentureworks_db.product` as product
    ON product.ProductID = workorder.ProductID
    LEFT JOIN tc-da-1.adwentureworks_db.productsubcategory as category
    ON product.ProductSubcategoryID = category.ProductSubcategoryID

-- products that are produced in house
WHERE MakeFlag = 1 
-- filter out products with Price =0.00 which means they are used to build other produces ex.parts for bikes
  AND product.ListPrice != 0
  AND product.StandardCost != 0

--helping lines for data validation
--AND DATETIME_TRUNC(EndDate,DAY) =  DATETIME('2001-08-20') 
  
-- AND product.ProductID = 707
--  AND category.Name = 'Road Frames'



--2.Purchase Order
SELECT  
  purchase_detail.PurchaseOrderDetailID,
  vendor.VendorID,
  purchase_detail.ProductID,
  purchase_detail.OrderQty,
	purchase_detail.UnitPrice,
	purchase_detail.LineTotal,
	purchase_detail.ReceivedQty,
	purchase_detail.RejectedQty,
	purchase_detail.StockedQty,
  purchares_order.OrderDate,
  purchares_order.ShipDate,
  DATETIME_DIFF(purchares_order.ShipDate,purchares_order.OrderDate,DAY) as DaysToShip,
  product_vendor.AverageLeadTime,
  purchase_detail.DueDate,
  vendor.Name as VendorName,
  product.Name as ProductName,
  product.Standardcost,
  product.ListPrice,
  vendor.ActiveFlag



FROM `tc-da-1.adwentureworks_db.purchaseorderdetail` as purchase_detail
  LEFT JOIN `tc-da-1.adwentureworks_db.purchaseorderheader` as purchares_order
  ON  purchase_detail.PurchaseOrderID = purchares_order.PurchaseOrderID
  LEFT JOIN tc-da-1.adwentureworks_db.vendor as vendor
  ON purchares_order.VendorID = vendor.VendorID
  LEFT JOIN tc-da-1.adwentureworks_db.product as product
  ON purchase_detail.ProductID = product.ProductID
  LEFT JOIN tc-da-1.adwentureworks_db.productvendor as product_vendor
  ON purchares_order.VendorID = product_vendor.VendorID
  AND purchase_detail.ProductID = product_vendor.ProductID
  
-- showing only ativley using vendors
WHERE vendor.ActiveFlag = 1



--3. Sales
WITH product_name as (
    SELECT product.ProductID as ProductID,
      product.Name as ProductName,
      product.StandardCost as StandardCost,
      product_subcategory.Name as SubcategoryName
    FROM `tc-da-1.adwentureworks_db.product` as product
    LEFT JOIN tc-da-1.adwentureworks_db.productsubcategory as product_subcategory
    ON product.ProductSubcategoryID = product_subcategory.ProductSubcategoryID
)


SELECT
  
  DISTINCT(sales_order.ProductID),
  sales_header.OrderDate,
  product_name.ProductName,
--  product_name.StandardCost,
--  sales_order.UnitPrice,
  SUM(sales_order.OrderQty) as OrderQty,
  SUM(product_name.StandardCost * sales_order.OrderQty) as StandardCostTotal,
--  sales_order.UnitPriceDiscount,
  SUM(sales_order.LineTotal) as LineTotal,
--  product_name.SubcategoryName,


FROM tc-da-1.adwentureworks_db.salesorderdetail as sales_order
  INNER JOIN product_name
  ON product_name.ProductID = sales_order.ProductID
  INNER JOIN tc-da-1.adwentureworks_db.salesorderheader as sales_header
  ON sales_order.SalesOrderID = sales_header.SalesOrderID

--WHERE sales_order.ProductID = 717

GROUP BY 
  sales_order.ProductID,
 sales_header.OrderDate,
 product_name.ProductName
 
 
 
 --4. Inventory
 
 SELECT inventory.ProductId,
  inventory.Quantity,
  product.StandardCost,
  (inventory.Quantity*product.StandardCost) AS TotalCost,
  product.SellEndDate

FROM `tc-da-1.adwentureworks_db.productinventory` as inventory
INNER JOIN tc-da-1.adwentureworks_db.product as product 
ON inventory.ProductID = product.ProductID

-- filtering out products with StandardCost = 0 which are products stored for assembley 
WHERE product.StandardCost != 0
--  AND product.SellEndDate IS NOT NULL


--5. Scrapped Reason

SELECT 
  workorder.WorkOrderID,
  workorder.ProductID,
  product.Name,
  workorder.OrderQty,
  workorder.StockedQty,
  workorder.ScrappedQty,
  product.StandardCost,
  workorder.ScrappedQty * product.StandardCost as StandardCostTotal,
  location.Name as Location,
--  orderrouting.ScheduledStartDate,
--	orderrouting.ActualStartDate,
  scrapreason.Name as ScrapReason,
  orderrouting.ScheduledEndDate,
	orderrouting.ActualEndDate
--  workorder.DueDate

FROM `tc-da-1.adwentureworks_db.workorder`  as workorder
  INNER JOIN tc-da-1.adwentureworks_db.workorderrouting as orderrouting
  ON workorder.WorkOrderID = orderrouting.WorkOrderID
  LEFT JOIN tc-da-1.adwentureworks_db.scrapreason as scrapreason
  ON workorder.ScrapReasonID = scrapreason.ScrapReasonID
  LEFT JOIN tc-da-1.adwentureworks_db.location as location
  ON orderrouting.LocationID = location.LocationID
  LEFT JOIN tc-da-1.adwentureworks_db.product as product
  ON workorder.ProductID = product.ProductID

-- helping lines for data validation
--WHERE workorder.ScrappedQty != 0
--WHERE workorder.DueDate = orderrouting.ScheduledEndDate
ORDER BY workorder.ScrappedQty DESC