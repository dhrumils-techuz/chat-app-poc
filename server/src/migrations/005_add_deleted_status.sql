-- Add 'deleted' to message_status CHECK constraint for "delete for me" feature.
-- The existing constraint only allows ('sent', 'delivered', 'read').
ALTER TABLE message_status DROP CONSTRAINT IF EXISTS message_status_status_check;
ALTER TABLE message_status ADD CONSTRAINT message_status_status_check
  CHECK (status IN ('sent', 'delivered', 'read', 'deleted'));
