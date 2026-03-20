/// Utilities for handling roles and permission equivalence in the app.
class RoleUtils {
  /// Canonical role value for the root user (bypasses RBAC).
  static const String rootRole = 'root';

  /// Returns a lowercase normalized role string for reliable comparisons.
  static String normalize(String? role) {
    final value = (role ?? '').trim().toLowerCase();
    if (value.isEmpty) return '';

    // Normalize common variants
    if (value == 'super admin' || value == 'superadmin') return 'super_admin';
    if (value == 'regional_manager' || value == 'regionalmanager')
      return 'regional manager';
    return value;
  }

  /// Map any alias/label to the canonical DB role value.
  /// For regional leadership labels, this returns 'regional manager'.
  static String mapToDbRole(String? role) {
    final r = normalize(role);
    if (isRoot(r)) return rootRole;
    if (isRegionalLeadership(r)) return 'regional manager';
    return r;
  }

  /// Returns true if the role is root. Root users bypass all RBAC and have full access.
  static bool isRoot(String? role) {
    return normalize(role) == rootRole;
  }

  /// Returns true if the role is super admin (canonical 'super_admin').
  static bool isSuperAdmin(String? role) {
    return normalize(role) == 'super_admin';
  }

  /// Returns true if the role is any of the regional leadership roles which
  /// share the same rights as a regional manager at the app level.
  static bool isRegionalLeadership(String? role) {
    final r = normalize(role);
    return r == 'regional manager' ||
        r == 'regional cordinator' || // original provided spelling
        r == 'regional coordinator' || // common spelling
        r == 'regional focal person';
  }

  /// Returns true if the role is admin (group leader)
  static bool isAdmin(String? role) {
    return normalize(role) == 'admin';
  }

  /// Returns true if the role is admin or higher (admin, super admin, root)
  static bool isAdminOrAbove(String? role) {
    final r = normalize(role);
    return isAdmin(r) || isSuperAdmin(r) || isRoot(r);
  }

  /// Returns true if the role can create leadership events
  static bool canCreateLeadershipEvents(String? role) {
    final r = normalize(role);
    return isRoot(r) || isSuperAdmin(r) || isRegionalLeadership(r);
  }
}
