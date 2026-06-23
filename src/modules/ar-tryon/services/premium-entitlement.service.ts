import {
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { VerifyPremiumPurchaseDto } from '../dto/premium-entitlement.dto';

@Injectable()
export class PremiumEntitlementService {
  private readonly entitlements = new Map<string, Set<string>>();

  constructor(private config: ConfigService) {}

  verifyAndGrant(dto: VerifyPremiumPurchaseDto) {
    const mockEnabled =
      this.config.get<string>('PREMIUM_PAYMENT_MOCK_ENABLED') === 'true';

    if (dto.developmentMock) {
      if (!mockEnabled) {
        throw new UnauthorizedException(
          'Development payment verification is disabled.',
        );
      }
      return this.grant(dto.userId, dto.featureIds, 'development_mock');
    }

    throw new ServiceUnavailableException(
      'Production receipt verification is not configured. Connect Google Play Developer API, App Store Server API, or an approved payment-provider webhook before granting entitlement.',
    );
  }

  getForUser(userId: string) {
    return {
      userId,
      featureIds: [...(this.entitlements.get(userId) ?? new Set<string>())],
    };
  }

  private grant(userId: string, featureIds: string[], verifiedBy: string) {
    const current = this.entitlements.get(userId) ?? new Set<string>();
    featureIds.forEach((feature) => current.add(feature));
    this.entitlements.set(userId, current);
    return {
      userId,
      featureIds: [...current],
      verified: true,
      verifiedBy,
    };
  }
}

