-- ==============================================================================
-- Operational Dashboard - Transaction Prioritization Logic
-- Description: Calculates statistical percentiles and Euclidean distance 
-- to dynamically identify the "Happy Path" per project.
-- ==============================================================================

WITH calculated_data AS (
    SELECT 
        project_key,
        project_name,
        transaction_id,
        step_count,
        novelty_score,
        
        -- 1. Calculate Measures (Partitioned by project to avoid cross-project noise)
        PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY step_count) 
            OVER (PARTITION BY project_key) AS median_s,
        STDEV(CAST(step_count AS FLOAT)) 
            OVER (PARTITION BY project_key) AS stdev_s,
        MAX(CAST(novelty_score AS FLOAT)) 
            OVER (PARTITION BY project_key) AS max_n,
        STDEV(CAST(novelty_score AS FLOAT)) 
            OVER (PARTITION BY project_key) AS stdev_n,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY step_count) 
            OVER (PARTITION BY project_key) AS p25_s,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY step_count) 
            OVER (PARTITION BY project_key) AS p75_s,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY novelty_score) 
            OVER (PARTITION BY project_key) AS p25_n,
        PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY novelty_score) 
            OVER (PARTITION BY project_key) AS median_n,
        COUNT(*) OVER (PARTITION BY project_key) AS project_row_count
    FROM mock_transactions_data
),

-- 2. Calculate Euclidean Distance & Assign Base Categories
scored AS (
    SELECT 
        project_key,
        project_name,
        transaction_id,
        step_count,
        novelty_score,
        project_row_count,
        
        -- Distance Formula
        SQRT(
            2 * SQUARE((CAST(step_count AS FLOAT) - median_s) / NULLIF(stdev_s, 0)) + 
                SQUARE((CAST(novelty_score AS FLOAT) - max_n) / NULLIF(stdev_n, 0))
        ) AS distance,
        
        -- Initial Category Logic
        CASE 
            WHEN step_count < p25_s AND novelty_score < p25_n THEN 'Low Steps - Low Novelty'
            WHEN step_count > p75_s THEN 
                CASE WHEN novelty_score > median_n THEN 'High Steps - High Novelty'
                     ELSE 'High Steps - Low Novelty' END
            ELSE 'General'
        END AS base_category
    FROM calculated_data
),

-- 3. Rank the 'General' transactions by closest distance
ranked AS (
    SELECT 
        *,
        CASE WHEN base_category = 'General' 
             THEN ROW_NUMBER() OVER (
                    PARTITION BY project_key, base_category 
                    ORDER BY distance ASC)
             ELSE NULL 
        END AS general_rank
    FROM scored
)

-- 4. Final Output: Extract the actual "Happy Path"
SELECT 
    project_key,
    project_name,
    transaction_id,
    step_count,
    novelty_score,
    CASE
        WHEN base_category = 'General' 
             AND general_rank <= CASE WHEN project_row_count > 100 THEN 7 ELSE 10 END
             AND distance IS NOT NULL
        THEN 'Happy Path'
        ELSE base_category
    END AS final_category 
FROM ranked
ORDER BY project_key, final_category;
