import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ArTryonController } from './ar-tryon.controller';
import {
  HairstyleService,
  BeardService,
  NailService,
  TryOnResultService,
  RecommendationService,
  ThreeDTryOnService,
  PremiumEntitlementService,
} from './services';
import {
  Hairstyle,
  Beard,
  Nail,
  TryOnResult,
  UserArPreference,
} from './entities';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Hairstyle,
      Beard,
      Nail,
      TryOnResult,
      UserArPreference,
    ]),
  ],
  controllers: [ArTryonController],
  providers: [
    HairstyleService,
    BeardService,
    NailService,
    TryOnResultService,
    RecommendationService,
    ThreeDTryOnService,
    PremiumEntitlementService,
  ],
  exports: [
    HairstyleService,
    BeardService,
    NailService,
    TryOnResultService,
    RecommendationService,
    ThreeDTryOnService,
    PremiumEntitlementService,
  ],
})
export class ArTryonModule {}
