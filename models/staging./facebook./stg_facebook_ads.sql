WITH source AS (

    SELECT *
    FROM {{ source('facebook', 'facebook_ads') }}

),

cleaned AS (

    SELECT
        *
    FROM source

)

SELECT *
FROM cleaned