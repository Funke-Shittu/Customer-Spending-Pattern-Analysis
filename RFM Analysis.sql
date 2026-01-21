WITH RFM_Info AS (
    SELECT 
        s.CustomerID,
        -- Calculate Days Since Last Purchase
        DATEDIFF(DAY, MAX(s.OrderDate), (SELECT MAX(OrderDate) FROM vSales)) AS Days_Since_Last_Purchase,
        -- Count Unique Orders
        COUNT(DISTINCT s.SalesOrderID) AS Num_of_Orders,
        -- Total Sales per Customer
        SUM(s.Revenue) AS Sales
    FROM vSales s
    WHERE s.StatusType = 'Shipped'
    GROUP BY s.CustomerID
),
RFM_SCORES AS (
    SELECT 
        RFM_Info.CustomerID,
        RFM_Info.Days_Since_Last_Purchase,
        RFM_Info.Num_of_Orders,
        RFM_Info.Sales,
        -- Assign Recency, Frequency, and Monetary Scores (Higher is Better)
        NTILE(5) OVER (ORDER BY RFM_Info.Days_Since_Last_Purchase DESC) AS Recency_Score, -- More recent = higher score
        NTILE(5) OVER (ORDER BY RFM_Info.Num_of_Orders) AS Frequency_Score, -- More orders = higher score
        NTILE(5) OVER (ORDER BY RFM_Info.Sales) AS Monetary_Score -- More sales = higher score
    FROM RFM_Info),
RFM AS (
	SELECT CustomerID,
        Days_Since_Last_Purchase,
        Num_of_Orders,
        Sales,
        Recency_Score,
        Frequency_Score,
        Monetary_Score,
		CONCAT(Recency_Score,
        Frequency_Score,
        Monetary_Score) AS Recency_Frequency_Monetary_Score
	FROM RFM_SCORES
),
RFM_SEGMENTS AS (
    SELECT 
        CustomerID,
        Days_Since_Last_Purchase,
        Num_of_Orders,
        Sales,
        Recency_Score,
        Frequency_Score,
        Monetary_Score,
		Recency_Frequency_Monetary_Score,
        CASE 
            -- 1. Champions
            WHEN Recency_Frequency_Monetary_Score
                IN ('555', '554', '544', '545', '454', '455', '445') THEN 'Champions'
            
            -- 2. Loyal
            WHEN Recency_Frequency_Monetary_Score
		    IN ('543', '444', '435', '355', '354', '345', '344', '335') THEN 'Loyal'
            
            -- 3. Potential Loyalist
            WHEN  Recency_Frequency_Monetary_Score
                IN ('553', '551', '552', '541', '542', '533', '532', '531', '452', '451', '442', '441', '431', '453', '433', '432', '423', '353', '352', '351', '342', '341', '333', '323') THEN 'Potential Loyalist'
            
            -- 4. New Customers
            WHEN  Recency_Frequency_Monetary_Score
                IN ('512', '511', '422', '421', '412', '411', '311') THEN 'New Customers'
            
            -- 5. Promising
            WHEN Recency_Frequency_Monetary_Score  IN ('525', '524', '523', '522', '521', '515', '514', '513', '425', '424', '413', '414', '415', '315', '314', '313') THEN 'Promising'
            
            -- 6. Need Attention
            WHEN Recency_Frequency_Monetary_Score IN ('535', '534', '443', '434', '343', '334', '325', '324') THEN 'Need Attention'
            
            -- 7. About to Sleep
            WHEN Recency_Frequency_Monetary_Score  IN ('331', '321', '312', '221', '213', '231', '241', '251') THEN 'About to Sleep'
            
            -- 8. Cannot Lose Them But Losing
            WHEN Recency_Frequency_Monetary_Score IN ('155', '154', '144', '214', '215', '115', '114', '113') THEN 'Cannot Lose Them But Losing'
            
            -- 9. At Risk
            WHEN Recency_Frequency_Monetary_Score   IN ('255', '254', '245', '244', '253', '252', '243', '242', '235', '234', '225', '224', '153', '152', '145', '143', '142', '135', '134', '133', '125', '124') THEN 'At Risk'
            
            -- 10. Hibernating Customers
            WHEN Recency_Frequency_Monetary_Score IN ('332', '322', '233', '232', '223', '222', '132', '123', '122', '212', '211') THEN 'Hibernating Customers'
            
            -- 11. Lost Customers
            WHEN Recency_Frequency_Monetary_Score  IN ('111', '112', '121', '131', '141', '151') THEN 'Lost Customers'
            
            -- Default case for any unmatched scores
            ELSE 'Unclassified'
        END AS Customer_Segment
    FROM RFM
)
-- Final result with customer details
SELECT 
    rs.CustomerID,
    c.CustName,
    rs.Days_Since_Last_Purchase,
    rs.Num_of_Orders,
    rs.Sales,
    rs.Recency_Score,
    rs.Frequency_Score,
    rs.Monetary_Score,
    rs.Recency_Frequency_Monetary_Score,
    rs.Customer_Segment,
    -- Additional customer demographics
    c.YearlyIncome,
    c.Education,
    c.Occupation
FROM RFM_SEGMENTS rs
JOIN vCustomer c ON rs.CustomerID = c.CustomerID
ORDER BY rs.Sales DESC;