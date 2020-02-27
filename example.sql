-- test example function
-- request: { name }
-- result: { greetings }
CREATE OR REPLACE FUNCTION action_test(id bigint, org text, usr text, request jsonb)
RETURNS jsonb AS $func$
DECLARE 
    result jsonb;
BEGIN

    -- You can do write operations
    CREATE TABLE my_dummy_table ( id integer not null primary key, greeting text );
    INSERT INTO my_dummy_table (id,greeting)
        SELECT x.id, request->>'greeting' || ' ' || x.id
        FROM (SELECT * FROM generate_series(1,10) as id) x;

    -- You can return any jsonb object
    SELECT jsonb_agg(t) INTO result 
    FROM my_dummy_table t;

    -- Clean
    DROP TABLE my_dummy_table;

    RETURN result;

END;
$func$
LANGUAGE plpgsql VOLATILE;

-- make it accesible from the mutation
INSERT INTO hpga_action VALUES ('test');