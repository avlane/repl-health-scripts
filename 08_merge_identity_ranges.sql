/*
    08_merge_identity_ranges.sql
    Run on: the PUBLISHER of a merge publication, in the publication database.
    Lists articles with identity columns, the range sizes configured for them,
    and how much of the data type is left at the publisher.
    pub_identity_range  = range reserved for the publisher
    identity_range      = range handed to each subscriber
    threshold           = percent used before a new range is assigned
*/
SET NOCOUNT ON;

;WITH ids AS (
    SELECT  p.name AS publication,
            a.name AS article,
            OBJECT_SCHEMA_NAME(a.objid) AS schema_name,
            ic.name AS identity_column,
            TYPE_NAME(ic.system_type_id) AS data_type,
            a.pub_identity_range,
            a.identity_range,
            a.threshold,
            CONVERT(decimal(38, 0), ic.last_value) AS last_value,
            CASE ic.system_type_id
                 WHEN 48  THEN CONVERT(decimal(38, 0), 255)
                 WHEN 52  THEN CONVERT(decimal(38, 0), 32767)
                 WHEN 56  THEN CONVERT(decimal(38, 0), 2147483647)
                 WHEN 127 THEN CONVERT(decimal(38, 0), 9223372036854775807)
            END AS max_value
    FROM dbo.sysmergearticles AS a
    JOIN dbo.sysmergepublications AS p ON p.pubid = a.pubid
    JOIN sys.identity_columns AS ic ON ic.object_id = a.objid
)
SELECT  publication, article, schema_name, identity_column, data_type,
        pub_identity_range, identity_range, threshold, last_value, max_value,
        max_value - last_value AS values_left,
        CASE WHEN identity_range > 0
             THEN (max_value - last_value) / identity_range
        END AS subscriber_ranges_left,
        CONVERT(decimal(5, 2), 100.0 * last_value / max_value) AS pct_of_type_used
FROM ids
ORDER BY pct_of_type_used DESC;
