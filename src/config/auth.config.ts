/**
 * Auth Configuration
 * Toggle AUTH_DISABLED for development
 * Set to false when JWT is ready
 */

export const AUTH_CONFIG = {
  // ✅ Set to true for MVP development (no auth required)
  // ❌ Set to false when JWT login is implemented
  DISABLED: true,

  // Fake user for development
  DEV_USER_ID: 'dev-user-001',
};

export const AUTH_DISABLED = AUTH_CONFIG.DISABLED;