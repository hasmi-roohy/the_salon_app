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
exports.HairstyleService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const hairstyle_entity_1 = require("../entities/hairstyle.entity");
let HairstyleService = class HairstyleService {
    constructor(hairstyleRepository) {
        this.hairstyleRepository = hairstyleRepository;
    }
    async create(createHairstyleDto) {
        const hairstyle = this.hairstyleRepository.create(createHairstyleDto);
        return this.hairstyleRepository.save(hairstyle);
    }
    async findAll(query) {
        const queryBuilder = this.hairstyleRepository.createQueryBuilder('hairstyle');
        if (query.category) {
            queryBuilder.andWhere('hairstyle.category = :category', {
                category: query.category,
            });
        }
        if (query.faceShape) {
            queryBuilder.andWhere("hairstyle.metadata->>'faceShapeCompatibility' ILIKE :faceShape", {
                faceShape: `%${query.faceShape}%`,
            });
        }
        queryBuilder.andWhere('hairstyle.isActive = :isActive', { isActive: true });
        queryBuilder.orderBy('hairstyle.trialCount', 'DESC');
        const limit = parseInt(query.limit || '10', 10);
        queryBuilder.limit(limit);
        return queryBuilder.getMany();
    }
    async findById(id) {
        const hairstyle = await this.hairstyleRepository.findOne({ where: { id } });
        if (!hairstyle) {
            throw new common_1.NotFoundException(`Hairstyle with ID ${id} not found`);
        }
        return hairstyle;
    }
    async update(id, updateHairstyleDto) {
        const hairstyle = await this.findById(id);
        Object.assign(hairstyle, updateHairstyleDto);
        return this.hairstyleRepository.save(hairstyle);
    }
    async delete(id) {
        const result = await this.hairstyleRepository.delete(id);
        if (result.affected === 0) {
            throw new common_1.NotFoundException(`Hairstyle with ID ${id} not found`);
        }
    }
    async incrementTrialCount(id) {
        await this.hairstyleRepository.increment({ id }, 'trialCount', 1);
    }
    async findByFaceShape(faceShape) {
        return this.hairstyleRepository
            .createQueryBuilder('hairstyle')
            .where("hairstyle.metadata->>'faceShapeCompatibility' ILIKE :faceShape", {
            faceShape: `%${faceShape}%`,
        })
            .andWhere('hairstyle.isActive = :isActive', { isActive: true })
            .orderBy('hairstyle.trialCount', 'DESC')
            .limit(10)
            .getMany();
    }
    async getPopular(limit = 5) {
        return this.hairstyleRepository.find({
            where: { isActive: true },
            order: { trialCount: 'DESC' },
            take: limit,
        });
    }
};
exports.HairstyleService = HairstyleService;
exports.HairstyleService = HairstyleService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(hairstyle_entity_1.Hairstyle)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], HairstyleService);
//# sourceMappingURL=hairstyle.service.js.map