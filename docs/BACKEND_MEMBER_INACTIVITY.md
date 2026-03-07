# Backend: Member & Group Inactivity Rules

---

## Group Inactivity

A group is flagged as **inactive** if it has not registered an event within **1.5 months (45 days)** from the last event.

- **No events at all** → inactive
- **Last event > 45 days ago** → inactive
- **Last event ≤ 45 days ago** → active

Implemented in `GroupActivityService`; used for the group status badge and Active/Inactive filter in Super Admin Group Management.

---

## Member Inactivity

The app applies these rules to mark members as inactive based on consecutive missed events.

## Rules

1. **6 consecutive events missed without apology** → mark as inactive
2. **12 consecutive events missed** (with or without apology) → mark as inactive

"Consecutive" means from the **most recent event backward** in time.  
"Without apology" = attendance record exists with `is_present: false` and `apology` is null or empty.  
"With apology" = attendance record exists with `is_present: false` and `apology` is non-empty.

## Frontend Behavior

- `MemberActivityService.computeMembersToMarkInactive(groupId)` computes which members meet the rules.
- After marking attendance, the app calls `checkAndMarkInactiveAfterAttendance(groupId)`.
- That method calls `PUT /api/groups/:groupId/members/:userId/status` with body `{ "is_active": false }` for each member to mark.

## Backend Implementation Checklist

### 1. Mark-Inactive Endpoint

- [ ] **`PUT /api/groups/:groupId/members/:userId/status`**
  - Accepts body: `{ "is_active": boolean }`
  - Updates the member's active status for that group (or the user's global status if you use that).
  - Require auth; only group admins, regional managers, or super admins should be allowed.
  - Return 200 on success.

Alternative: if you store status on the user, you could use `PATCH /api/users/:userId` with `{ "is_active": false }` instead. The frontend is wired to the group-member endpoint above.

### 2. Activity Status Computation

Your analytics APIs (`getSuperAdminMemberActivityStatus`, `getAdminGroupMemberActivityStatus`, etc.) should use the same rules when computing active/inactive counts:

- For each member, get their attendance for the group's past events (ordered by event date desc).
- Walk from the most recent event backward:
  - If present: reset both streaks.
  - If absent without apology: increment no-apology streak and total streak.
  - If absent with apology: reset no-apology streak, increment total streak.
- Mark as inactive if no-apology streak ≥ 6 **or** total streak ≥ 12.

### 3. Where to Store Status

- **Option A**: `group_members` table – add `is_active` (or `status`) per group membership.
- **Option B**: `users` table – add `is_active` at user level (applies across groups).
- **Option C**: Compute on the fly – no storage; active/inactive is derived from attendance when analytics are requested. The mark-inactive endpoint would then be optional (e.g. for notifications or reports).

### 4. Re-activation

If a member attends an event after being marked inactive, consider:
- Automatically setting them back to active when they are marked present.
- Or requiring an admin to manually re-activate.

---

## Quick Reference: Thresholds

| Condition                          | Threshold | Action      |
|-----------------------------------|-----------|-------------|
| Consecutive absences, no apology | 6         | Mark inactive |
| Consecutive absences, any        | 12        | Mark inactive |
