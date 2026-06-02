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
exports.TryOnResultService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const try_on_result_entity_1 = require("../entities/try-on-result.entity");
const uuid_1 = require("uuid");
let TryOnResultService = class TryOnResultService {
    constructor(tryOnResultRepository) {
        this.tryOnResultRepository = tryOnResultRepository;
    }
    async save(userId, saveDto) {
        const result = this.tryOnResultRepository.create({
            userId,
            ...saveDto,
        });
        return this.tryOnResultRepository.save(result);
    }
    async findByUserId(userId, query) {
        const limit = parseInt(query.limit || '20', 10);
        const offset = parseInt(query.offset || '0', 10);
        return this.tryOnResultRepository.find({
            where: { userId },
            order: { createdAt: 'DESC' },
            take: limit,
            skip: offset,
            relations: ['hairstyle', 'beard', 'nail'],
        });
    }
    async findById(id) {
        const result = await this.tryOnResultRepository.findOne({
            where: { id },
            relations: ['hairstyle', 'beard', 'nail'],
        });
        if (!result) {
            throw new common_1.NotFoundException(`Try-on result with ID ${id} not found`);
        }
        return result;
    }
    async delete(id) {
        const result = await this.tryOnResultRepository.delete(id);
        if (result.affected === 0) {
            throw new common_1.NotFoundException(`Try-on result with ID ${id} not found`);
        }
    }
    async share(id, shareDto) {
        const result = await this.findById(id);
        const shareToken = (0, uuid_1.v4)();
        result.isShared = true;
        result.shareToken = shareToken;
        await this.tryOnResultRepository.save(result);
        return {
            shareToken,
            shareUrl: `${process.env.APP_URL}/ar/shared/${shareToken}`,
        };
    }
    async findByShareToken(shareToken) {
        const result = await this.tryOnResultRepository.findOne({
            where: { shareToken, isShared: true },
            relations: ['hairstyle', 'beard', 'nail'],
        });
        if (!result) {
            throw new common_1.NotFoundException('Shared result not found');
        }
        return result;
    }
    async getStats(userId) {
        const results = await this.tryOnResultRepository.find({
            where: { userId },
            relations: ['hairstyle', 'beard', 'nail'],
        });
        const hairstyleCount = {};
        const beardCount = {};
        const nailCount = {};
        results.forEach((r) => {
            if (r.hairstyle) {
                hairstyleCount[r.hairstyle.name] =
                    (hairstyleCount[r.hairstyle.name] || 0) + 1;
            }
            if (r.beard) {
                beardCount[r.beard.name] = (beardCount[r.beard.name] || 0) + 1;
            }
            if (r.nail) {
                nailCount[r.nail.name] = (nailCount[r.nail.name] || 0) + 1;
            }
        });
        const getMostUsed = (obj) => {
            return Object.keys(obj).reduce((a, b) => obj[a] > obj[b] ? a : b);
        };
        return {
            totalTrials: results.length,
            mostUsedHairstyle: Object.keys(hairstyleCount).length > 0
                ? getMostUsed(hairstyleCount)
                : undefined,
            mostUsedBeard: Object.keys(beardCount).length > 0
                ? getMostUsed(beardCount)
                : undefined,
            mostUsedNail: Object.keys(nailCount).length > 0
                ? getMostUsed(nailCount)
                : undefined,
        };
    }
};
exports.TryOnResultService = TryOnResultService;
exports.TryOnResultService = TryOnResultService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(try_on_result_entity_1.TryOnResult)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], TryOnResultService);
//# sourceMappingURL=tryon-result.service.js.map