import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { AUTH_DISABLED, AUTH_CONFIG } from '../config/auth.config';

/**
 * JWT Auth Guard
 * - Bypasses auth when AUTH_DISABLED = true (development)
 * - Ready for real JWT implementation later
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();

    // ✅ DEVELOPMENT MODE: Bypass auth, inject fake user
    if (AUTH_DISABLED) {
      request.user = {
        id: AUTH_CONFIG.DEV_USER_ID,
        email: 'dev@salon.local',
        role: 'dev',
      };
      return true;
    }

    // ❌ PRODUCTION MODE: Real JWT validation
    // TODO: Implement real JWT verification when login is ready
    const token = this.extractToken(request);
    if (!token) {
      throw new UnauthorizedException('No token provided');
    }

    // Placeholder for real JWT logic
    // Example:
    // const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // request.user = decoded;

    throw new UnauthorizedException(
      'JWT auth not yet implemented. Set AUTH_DISABLED=true in auth.config.ts for development.',
    );
  }

  private extractToken(request: any): string | null {
    const authHeader = request.headers.authorization;
    if (!authHeader) return null;
    return authHeader.replace('Bearer ', '');
  }
}