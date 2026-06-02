"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RecommendationService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const hairstyle_entity_1 = require("../entities/hairstyle.entity");
const beard_entity_1 = require("../entities/beard.entity");
const nail_entity_1 = require("../entities/nail.entity");
const user_ar_preference_entity_1 = require("../entities/user-ar-preference.entity");
let RecommendationService = class RecommendationService {
    constructor(hairstyleRepository, beardRepository, nailRepository, userPreferenceRepository) {
        this.hairstyleRepository = hairstyleRepository;
        this.beardRepository = beardRepository;
        this.nailRepository = nailRepository;
        this.userPreferenceRepository = userPreferenceRepository;
    }
    async getRecommendations(userId, query) {
        const userPreference = await this.userPreferenceRepository.findOne({
            where: { userId },
        });
        const faceShape = query.faceShape || userPreference?.faceAnalysis?.faceShape;
        let hairstyles = [];
        let beards = [];
        let nails = [];
        if (!query.type || query.type === 'hairstyle') {
            hairstyles = await this.getHairstyleRecommendations(faceShape, userPreference?.preferredHairstyles);
        }
        if (!query.type || query.type === 'beard') {
            beards = await this.getBeardRecommendations(faceShape, userPreference?.preferredBeards);
        }
        if (!query.type || query.type === 'nail') {
            nails = await this.getNailRecommendations(userPreference?.preferredNails);
        }
        return {
            hairstyles,
            beards,
            nails,
            basedOnFaceShape: faceShape,
            personalized: !!userPreference,
        };
    }
    async getHairstyleRecommendations(faceShape, userPreferred = []) {
        let query = this.hairstyleRepository.createQueryBuilder('hairstyle');
        if (faceShape) {
            query = query.where("hairstyle.metadata->>'faceShapeCompatibility' ILIKE :faceShape", { faceShape: `%${faceShape}%` });
        }
        const recommended = await query
            .andWhere('hairstyle.isActive = :isActive', { isActive: true })
            .orderBy('hairstyle.trialCount', 'DESC')
            .limit(10)
            .getMany();
        if (userPreferred && userPreferred.length > 0) {
            const preferred = recommended.filter((h) => userPreferred.includes(h.id));
            const others = recommended.filter((h) => !userPreferred.includes(h.id));
            return [...preferred, ...others];
        }
        return recommended;
    }
    async getBeardRecommendations(faceShape, userPreferred = []) {
        let query = this.beardRepository.createQueryBuilder('beard');
        if (faceShape) {
            query = query.where("beard.metadata->>'faceShapeCompatibility' ILIKE :faceShape", { faceShape: `%${faceShape}%` });
        }
        const recommended = await query
            .andWhere('beard.isActive = :isActive', { isActive: true })
            .orderBy('beard.trialCount', 'DESC')
            .limit(10)
            .getMany();
        if (userPreferred && userPreferred.length > 0) {
            const preferred = recommended.filter((b) => userPreferred.includes(b.id));
            const others = recommended.filter((b) => !userPreferred.includes(b.id));
            return [...preferred, ...others];
        }
        return recommended;
    }
    async getNailRecommendations(userPreferred = []) {
        const query = this.nailRepository.createQueryBuilder('nail');
        const recommended = await query
            .where('nail.isActive = :isActive', { isActive: true })
            .orderBy('nail.trialCount', 'DESC')
            .limit(10)
            .getMany();
        if (userPreferred && userPreferred.length > 0) {
            const preferred = recommended.filter((n) => userPreferred.includes(n.id));
            const others = recommended.filter((n) => !userPreferred.includes(n.id));
            return [...preferred, ...others];
        }
        return recommended;
    }
    async saveUserAnalysis(userId, faceAnalysis) {
        let preference = await this.userPreferenceRepository.findOne({
            where: { userId },
        });
        if (!preference) {
            preference = this.userPreferenceRepository.create({ userId });
        }
        preference.faceAnalysis = faceAnalysis;
        return this.userPreferenceRepository.save(preference);
    }
    async addToPreferred(userId, type, styleId) {
        let preference = await this.userPreferenceRepository.findOne({
            where: { userId },
        });
        if (!preference) {
            preference = this.userPreferenceRepository.create({ userId });
        }
        const fieldName = `preferred${type.charAt(0).toUpperCase() + type.slice(1)}s`;
        if (!preference[fieldName]) {
            preference[fieldName] = [];
        }
        if (!preference[fieldName].includes(styleId)) {
            preference[fieldName].push(styleId);
        }
        return this.userPreferenceRepository.save(preference);
    }
    async removeFromPreferred(userId, type, styleId) {
        const preference = await this.userPreferenceRepository.findOne({
            where: { userId },
        });
        if (preference) {
            const fieldName = `preferred${type.charAt(0).toUpperCase() + type.slice(1)}s`;
            if (preference[fieldName]) {
                preference[fieldName] = preference[fieldName].filter((id) => id !== styleId);
            }
            return this.userPreferenceRepository.save(preference);
        }
        return preference;
    }
};
exports.RecommendationService = RecommendationService;
exports.RecommendationService = RecommendationService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(hairstyle_entity_1.Hairstyle)),
    __param(1, (0, typeorm_1.InjectRepository)(beard_entity_1.Beard)),
    __param(2, (0, typeorm_1.InjectRepository)(nail_entity_1.Nail)),
    __param(3, (0, typeorm_1.InjectRepository)(user_ar_preference_entity_1.UserArPreference)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], RecommendationService);
//# sourceMappingURL=recommendation.service.js.map