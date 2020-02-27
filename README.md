# hasura-pg-actions
Short script to enable hasura to call postgresql functions (read/write) as mutations.

Please read the reference article: https://mnesarco.github.io/blog/2020/02/25/hasura-postgresql-function-as-mutation

## Map mutations:

```graphql
mutation CallPgAction {
  insert_hpga_action_journal(
    objects: {
        action_id: "test", 
        request: { greeting: "Hello " }
    }) {
    returning {
      response
    }
  }
}
```

## To PosthreSQL functions:

```sql
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
```

## A picture is worth a thousand words

![ref](https://mnesarco.github.io/images/hasura-action-pg.png)