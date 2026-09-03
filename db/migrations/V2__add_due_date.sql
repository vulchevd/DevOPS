-- Additive, nullable — safe to apply ahead of the code that starts reading
-- it (expand/contract: this is the "expand" half). See docs/architecture.md
-- for the rollback approach.
ALTER TABLE tasks ADD COLUMN due_date DATE NULL;
