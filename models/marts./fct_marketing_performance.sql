{{ config(materialized='table') }}

WITH facebook AS (

    SELECT
        'facebook' AS platform,
        CAST(s.ad_date AS DATE) AS ad_date,
        CAST(a.campaign_id AS STRING) AS campaign_id,
        c.campaign_name,
        CAST(s.ad_id AS STRING) AS ad_id,
        a.ad_name,
        ac.ad_currency_code AS currency,
        CAST(s.ad_spend AS DECIMAL(18, 4)) AS spend,
        TRY_CAST(s.ad_impressions AS BIGINT) AS impressions,
        TRY_CAST(s.ad_clicks AS BIGINT) AS clicks

    FROM {{ ref('stg_facebook_ads_stats') }} s

    LEFT JOIN {{ ref('stg_facebook_ads') }} a
        ON s.ad_id = a.ad_id
        AND s.account_id = a.account_id

    LEFT JOIN {{ source('facebook', 'facebook_campaigns') }} c
        ON a.campaign_id = c.campaign_id

    LEFT JOIN {{ source('facebook', 'new_acccount') }} ac
        ON s.account_id = ac.account_id

),

snapchat_ads AS (

    SELECT
        ad_id,
        ad_group_id,
        ad_name
    FROM {{ source('snapchat', 'snapchat_ads_ad_history_new_ad_names') }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ad_id
        ORDER BY ad_detail_updated_at DESC NULLS LAST
    ) = 1

),

snapchat_adgroups AS (

    SELECT
        ad_group_id,
        campaign_id
    FROM {{ source('snapchat', 'snapchat_ads_adgroup_history_new_ad_group_names') }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ad_group_id
        ORDER BY ad_group_updated_at DESC NULLS LAST
    ) = 1

),

snapchat AS (

    SELECT
        'snapchat' AS platform,
        CAST(s.ad_date AS DATE) AS ad_date,
        CAST(g.campaign_id AS STRING) AS campaign_id,
        c.campaign_name,
        CAST(s.ad_detail_id AS STRING) AS ad_id,
        a.ad_name,
        s.ad_currency_code AS currency,
        TRY_CAST(s.ad_spend AS DECIMAL(18, 4)) AS spend,
        TRY_CAST(s.ad_impressions AS BIGINT) AS impressions,
        TRY_CAST(s.ad_clicks AS BIGINT) AS clicks

    FROM {{ source('snapchat', 'snapchat_ads_stats') }} s

    LEFT JOIN snapchat_ads a
        ON s.ad_detail_id = a.ad_id

    LEFT JOIN snapchat_adgroups g
        ON a.ad_group_id = g.ad_group_id

    LEFT JOIN {{ source('snapchat', 'snapchat_ads_campaign_history_new_campaign_names') }} c
        ON g.campaign_id = c.campaign_id

),

combined AS (

    SELECT * FROM facebook
    UNION ALL
    SELECT * FROM snapchat

)

SELECT
    *,
    ROUND(clicks * 1.0 / NULLIF(impressions, 0), 4) AS ctr,
    ROUND(spend / NULLIF(clicks, 0), 4) AS cpc,
    ROUND(spend * 1000.0 / NULLIF(impressions, 0), 4) AS cpm

FROM combined