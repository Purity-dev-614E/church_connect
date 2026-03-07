# Backend: Removed Members (with justification)

The app allows **Admin**, **Super Admin**, **Root**, and **Regional Manager** to remove members from a group. Removal requires a **reason** and is listed under a "Removed Members" tab.

## API Endpoints

### 1. Remove member with reason

**`POST /api/groups/:groupId/members/:userId/remove`**

- **Body**: `{ "reason": "string" }` (required)
- **Auth**: Required; only group admin, super admin, root, or regional manager (for groups in their region)
- **Effect**: Remove the user from the group and store the removal record (user_id, group_id, reason, removed_at, removed_by)
- **Response**: 200 or 204 on success

### 2. List removed members for a group

**`GET /api/groups/:groupId/removed-members`**

- **Response**: JSON array of removed-member objects, e.g.:
  ```json
  [
    {
      "user_id": "uuid",
      "full_name": "John Doe",
      "email": "john@example.com",
      "reason": "Relocated",
      "removed_at": "2025-02-20T12:00:00Z",
      "removed_by_name": "Admin User"
    }
  ]
  ```
- **Auth**: Required; same roles as above

## Data model (suggestion)

- **Table**: `group_removed_members` or equivalent  
  - `group_id`, `user_id`, `reason`, `removed_at`, `removed_by` (user id or name)
- When removing: delete (or soft-delete) membership and insert into this table.

## Who can remove

- **Admin**: Can remove from their own group(s)
- **Super Admin / Root**: Can remove from any group
- **Regional Manager**: Can remove from groups in their region

Enforce these rules in the backend for both endpoints.
