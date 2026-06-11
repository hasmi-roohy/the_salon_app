import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Hairstyle } from '../entities/hairstyle.entity';
import { Beard } from '../entities/beard.entity';
import { Nail } from '../entities/nail.entity';
import { UserArPreference } from '../entities/user-ar-preference.entity';
import { GetRecommendationsDto } from '../dto';

@Injectable()
export class RecommendationService {
  // ✅ FIX #6: Safe field mapping instead of dynamic strings
  private readonly fieldMap = {
    hairstyle: 'preferredHairstyles',
    beard: 'preferredBeards',
    nail: 'preferredNails',
  };

  constructor(
    @InjectRepository(Hairstyle)
    private hairstyleRepository: Repository<Hairstyle>,
    @InjectRepository(Beard)
    private beardRepository: Repository<Beard>,
    @InjectRepository(Nail)
    private nailRepository: Repository<Nail>,
    @InjectRepository(UserArPreference)
    private userPreferenceRepository: Repository<UserArPreference>,
  ) {}

  async getRecommendations(userId: string, query: GetRecommendationsDto) {
    const userPreference = await this.userPreferenceRepository.findOne({
      where: { userId },
    });

    const faceShape = query.faceShape || userPreference?.faceAnalysis?.faceShape;

    let hairstyles: Hairstyle[] = [];
    let beards: Beard[] = [];
    let nails: Nail[] = [];

    if (!query.type || query.type === 'hairstyle') {
      hairstyles = await this.getHairstyleRecommendations(
        faceShape,
        userPreference?.preferredHairstyles,
      );
    }

    if (!query.type || query.type === 'beard') {
      beards = await this.getBeardRecommendations(
        faceShape,
        userPreference?.preferredBeards,
      );
    }

    if (!query.type || query.type === 'nail') {
      nails = await this.getNailRecommendations(
        userPreference?.preferredNails,
      );
    }

    return {
      hairstyles,
      beards,
      nails,
      basedOnFaceShape: faceShape,
      personalized: !!userPreference,
    };
  }

  // ✅ FIX #4: Add fallback recommendations when face shape has no matches
  private async getHairstyleRecommendations(
    faceShape: string,
    userPreferred: string[] = [],
  ): Promise<Hairstyle[]> {
    let query = this.hairstyleRepository.createQueryBuilder('hairstyle');

    if (faceShape) {
      query = query.where(
        "hairstyle.metadata->>'faceShapeCompatibility' ILIKE :faceShape",
        { faceShape: `%${faceShape}%` },
      );
    }

    let recommended = await query
      .andWhere('hairstyle.isActive = :isActive', { isActive: true })
      .orderBy('hairstyle.trialCount', 'DESC')
      .limit(10)
      .getMany();

    // 🔄 FALLBACK: If no results for face shape, return popular hairstyles
    if (recommended.length === 0) {
      recommended = await this.hairstyleRepository.find({
        where: { isActive: true },
        order: { trialCount: 'DESC' },
        take: 10,
      });
    }

    // Boost user's preferred hairstyles to top
    if (userPreferred && userPreferred.length > 0) {
      const preferred = recommended.filter((h) =>
        userPreferred.includes(h.id),
      );
      const others = recommended.filter((h) => !userPreferred.includes(h.id));
      return [...preferred, ...others];
    }

    return recommended;
  }

  // ✅ FIX #4: Add fallback recommendations when face shape has no matches
  private async getBeardRecommendations(
    faceShape: string,
    userPreferred: string[] = [],
  ): Promise<Beard[]> {
    let query = this.beardRepository.createQueryBuilder('beard');

    if (faceShape) {
      query = query.where(
        "beard.metadata->>'faceShapeCompatibility' ILIKE :faceShape",
        { faceShape: `%${faceShape}%` },
      );
    }

    let recommended = await query
      .andWhere('beard.isActive = :isActive', { isActive: true })
      .orderBy('beard.trialCount', 'DESC')
      .limit(10)
      .getMany();

    // 🔄 FALLBACK: If no results for face shape, return popular beards
    if (recommended.length === 0) {
      recommended = await this.beardRepository.find({
        where: { isActive: true },
        order: { trialCount: 'DESC' },
        take: 10,
      });
    }

    if (userPreferred && userPreferred.length > 0) {
      const preferred = recommended.filter((b) =>
        userPreferred.includes(b.id),
      );
      const others = recommended.filter((b) => !userPreferred.includes(b.id));
      return [...preferred, ...others];
    }

    return recommended;
  }

  private async getNailRecommendations(
    userPreferred: string[] = [],
  ): Promise<Nail[]> {
    const query = this.nailRepository.createQueryBuilder('nail');

    const recommended = await query
      .where('nail.isActive = :isActive', { isActive: true })
      .orderBy('nail.trialCount', 'DESC')
      .limit(10)
      .getMany();

    if (userPreferred && userPreferred.length > 0) {
      const preferred = recommended.filter((n) =>
        userPreferred.includes(n.id),
      );
      const others = recommended.filter((n) => !userPreferred.includes(n.id));
      return [...preferred, ...others];
    }

    return recommended;
  }

  async saveUserAnalysis(
    userId: string,
    faceAnalysis: {
      faceShape?: string;
      skinTone?: string;
      faceWidth?: number;
      faceLength?: number;
      jawlineWidth?: number;
    },
  ): Promise<UserArPreference> {
    let preference = await this.userPreferenceRepository.findOne({
      where: { userId },
    });

    if (!preference) {
      preference = this.userPreferenceRepository.create({ userId });
    }

    preference.faceAnalysis = faceAnalysis;
    return this.userPreferenceRepository.save(preference);
  }

  // ✅ FIX #6: Use safe fieldMap instead of dynamic string
  async addToPreferred(
    userId: string,
    type: 'hairstyle' | 'beard' | 'nail',
    styleId: string,
  ): Promise<UserArPreference> {
    let preference = await this.userPreferenceRepository.findOne({
      where: { userId },
    });

    if (!preference) {
      preference = this.userPreferenceRepository.create({ userId });
    }

    const fieldName = this.fieldMap[type];

    if (!preference[fieldName]) {
      preference[fieldName] = [];
    }

    if (!preference[fieldName].includes(styleId)) {
      preference[fieldName].push(styleId);
    }

    return this.userPreferenceRepository.save(preference);
  }

  // ✅ FIX #2: Throw error if preference not found + use safe fieldMap
  async removeFromPreferred(
    userId: string,
    type: 'hairstyle' | 'beard' | 'nail',
    styleId: string,
  ): Promise<UserArPreference> {
    const preference = await this.userPreferenceRepository.findOne({
      where: { userId },
    });

    // 🔴 FIX: Throw error instead of returning undefined
    if (!preference) {
      throw new NotFoundException(
        `User preference not found for user ${userId}`,
      );
    }

    // ✅ FIX #6: Use safe fieldMap instead of dynamic string
    const fieldName = this.fieldMap[type];

    preference[fieldName] = (preference[fieldName] || []).filter(
      (id) => id !== styleId,
    );

    return this.userPreferenceRepository.save(preference);
  }
}