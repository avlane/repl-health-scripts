/*
    08_merge_identity_ranges.sql
    Run on: the PUBLISHER of a merge publication, in the publication database.
    Lists articles with identity columns and the range sizes configured for them.
    pub_identity_range  = range reserved for the publisher
    identity_range      = range handed to each subscriber
    threshold           = percent used before a new range is assigned
*/
SET NOCOUNT ON;

SELECT  p.name AS publication,
        a.name AS article,
        OBJECT_SCHEMA_NAME(a.objid) AS schema_name,
        ic.name AS identity_column,
        TYPE_NAME(ic.system_type_id) AS data_type,
        a.pub_identity_range,
        a.identity_range,
        a.threshold,
        ic.last_value
FROM dbo.sysmergearticles AS a
JOIN dbo.sysmergepublications AS p ON p.pubid = a.pubid
JOIN sys.identity_columns AS ic ON ic.object_id = a.objid
ORDER BY p.name, a.name;
