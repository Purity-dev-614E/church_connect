# Backend RBAC & Security Checklist

Use this list so backend enforcement matches the app’s role hierarchy and RBAC.  
**Root (developer) > Super Admin (e.g. CEO) > Regional Manager > Admin (Group Leader) > User.**

---

## 1. Role updates (who can set/change roles)

- [ ] **Only Root can set or change the `root` role**
  - Reject if requester is not `root` and payload sets `role = 'root'` (create or update).
  - Prevents Super Admin (or anyone) from promoting to Root via API.

- [ ] **Only Root can set or change the `super_admin` role**
  - Reject if requester is not `root` and payload sets `role = 'super_admin'` (or equivalent).
  - Prevents Super Admin from promoting themselves or another to Super Admin.

- [ ] **Never trust role from the client for authorization**
  - Resolve “current user” from auth token/session and load their role from your DB (or auth metadata). Use that for all permission checks.

- [ ] **Optional: prevent self-role escalation**
  - Reject requests where the authenticated user is changing their own role to a higher-privilege role (e.g. user → admin, super_admin → root) unless the requester is Root.

---

## 2. Allowed role values

- [ ] **Validate `role` on create/update**
  - Allow only: `root`, `super_admin`, `regional manager` (and any canonical aliases you use), `admin`, `user`.
  - Reject unknown values and trim/normalize (e.g. `super admin` → `super_admin`) so DB stays consistent.

---

## 3. Data access (per role)

- [ ] **Root**
  - Can read/write all users, groups, regions, events, attendance, etc. (full access or bypass RLS).

- [ ] **Super Admin**
  - Can read (and where appropriate write) all regions, groups, users, events.
  - Cannot change Root or another Super Admin’s role (enforced by your role-update rules above).

- [ ] **Regional Manager**
  - Can only access data for their assigned region(s) (and groups under those regions).
  - Cannot change Root, Super Admin, or other Regional Managers’ roles.

- [ ] **Admin (Group Leader)**
  - Can only access their assigned group(s) (members, events, etc.).

- [ ] **User**
  - Can read (and maybe limited write) only their own profile and their group (e.g. events, attendance) as needed by the app.

---

## 4. Critical operations by role

- [ ] **Create / update / delete groups**
  - Allow: Root, Super Admin; optionally Regional Manager for groups in their region; Admin only if your design allows (app currently allows root/super_admin/admin for create).

- [ ] **Assign group admin**
  - Allow: Root, Super Admin, Regional Manager (for groups in their region). Deny others.

- [ ] **Create / update / delete events (per group)**
  - Allow: Root and Super Admin for any group; Admin for their group only.

- [ ] **Create / update / delete regions**
  - Typically: Root and Super Admin only.

- [ ] **User/role management (list users, update user, assign to group/region)**
  - Root: full.
  - Super Admin: full except cannot set/change `root` or `super_admin`.
  - Regional Manager: only users in their region(s), and cannot set Root/Super Admin/Regional Manager roles.

---

## 5. Auth & identity

- [ ] **Role is loaded server-side**
  - From your users/profiles table (or auth provider metadata) using the authenticated user id. Never use a role from the request body for authorization.

- [ ] **Sensitive endpoints require auth**
  - All role changes, group/region/event CRUD, and user updates are behind auth and check role.

---

## 6. Optional but recommended

- [ ] **Audit log for role changes**
  - Log: who changed whose role, from what to what, when. Especially for `root` and `super_admin`.

- [ ] **Rate limiting**
  - On login, role change, and bulk user/group operations.

- [ ] **Consistent role casing/normalization**
  - Store one canonical value (e.g. `super_admin`, `regional manager`) so API and app stay in sync with `RoleUtils` and `UserModel.fromJson`.

---

## Quick reference: who can change whom

| Target role       | Root can change? | Super Admin can change? |
|-------------------|------------------|--------------------------|
| Root              | Yes              | No                       |
| Super Admin       | Yes              | No                       |
| Regional Manager  | Yes              | Yes                      |
| Admin             | Yes              | Yes                      |
| User              | Yes              | Yes                      |

Enforce the “Super Admin can change?” column in your role-update API (and any admin UI that calls it).
