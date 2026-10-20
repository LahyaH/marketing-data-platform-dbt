WITH source AS (

    SELECT *
    FROM {{ source('facebook', 'facebook_ads_stats') }}

),

cleaned AS (

    SELECT
        ad_id,
        account_id,
        CAST(ad_spend AS DECIMAL(18, 2)) AS ad_spend,
        TRY_CAST(ad_impressions AS BIGINT) AS ad_impressions,
        TRY_CAST(ad_clicks AS BIGINT) AS ad_clicks,
        ad_date
    FROM source

)

SELECT *
FROM cleaned
