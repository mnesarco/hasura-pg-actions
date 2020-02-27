-- Hasura PgActions
-- This script creates infrastructure to map
-- Hasura GraphQL Mutations to Postgresql functions (ie plpgsql)
-- @author: Frank D. martinez M. https://github.com/mnesarco/
-- @see https://mnesarco.github.io/blog/2020/02/25/hasura-postgresql-function-as-mutation
--

-- Table: hpga_action
-- This table contains the list of exported functions.
-- Each id in this table exposes a function with the following signature:
--  action_{id}(call_id bigint, organization_id text, user_id text, request jsonb) RETURNS jsonb
CREATE TABLE hpga_action(
    id text not null primary key
);

-- Table: hpga_action_journal
-- This table tracks action calls and it is used by Hasura
-- to track the mutation.
CREATE TABLE hpga_action_journal(
    id bigserial primary key,
    ts timestamp not null default now(),
    organization_id text,
    user_id text not null,
    action_id text not null references hpga_action(id),
    request jsonb not null,
    response jsonb not null
);

-- Trigger: hpga_dispatcher
--    Dispatch actions to the actual functions based on hpga_action_journal.action_id.
--    Important: Due to postgresql limitations about transaction handling in triggers,
--               any exception raised from the function will propagate to the caller
--               and the transaction will be rolled back.
CREATE OR REPLACE FUNCTION hpga_dispatcher_trigger() 
RETURNS trigger AS $BODY$
DECLARE
    response jsonb;
BEGIN
    EXECUTE 'SELECT action_' || NEW.action_id || '($1, $2, $3, $4)' 
        INTO response
        USING NEW.id, NEW.organization_id, NEW.user_id, NEW.request;
    NEW.response = response;
    RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

CREATE TRIGGER hpga_dispatcher
    BEFORE INSERT
    ON hpga_action_journal
    FOR EACH ROW
    EXECUTE PROCEDURE hpga_dispatcher_trigger();