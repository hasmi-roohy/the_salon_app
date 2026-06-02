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
exports.BeardService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const beard_entity_1 = require("../entities/beard.entity");
let BeardService = class BeardService {
    constructor(beardRepository) {
        this.beardRepository = beardRepository;
    }
    async create(createBeardDto) {
        const beard = this.beardRepository.create(createBeardDto);
        return this.beardRepository.save(beard);
    }
    async findAll(query) {
        const queryBuilder = this.beardRepository.createQueryBuilder('beard');
        if (query.style) {
            queryBuilder.andWhere('beard.style = :style', { style: query.style });
        }
        if (query.faceShape) {
            queryBuilder.andWhere("beard.metadata->>'faceShapeCompatibility' ILIKE :faceShape", {
                faceShape: `%${query.faceShape}%`,
            });
        }
        queryBuilder.andWhere('beard.isActive = :isActive', { isActive: true });
        queryBuilder.orderBy('beard.trialCount', 'DESC');
        const limit = parseInt(query.limit || '10', 10);
        queryBuilder.limit(limit);
        return queryBuilder.getMany();
    }
    async findById(id) {
        const beard = await this.beardRepository.findOne({ where: { id } });
        if (!beard) {
            throw new common_1.NotFoundException(`Beard with ID ${id} not found`);
        }
        return beard;
    }
    async update(id, updateBeardDto) {
        const beard = await this.findById(id);
        Object.assign(beard, updateBeardDto);
        return this.beardRepository.save(beard);
    }
    async delete(id) {
        const result = await this.beardRepository.delete(id);
        if (result.affected === 0) {
            throw new common_1.NotFoundException(`Beard with ID ${id} not found`);
        }
    }
    async incrementTrialCount(id) {
        await this.beardRepository.increment({ id }, 'trialCount', 1);
    }
    async findByFaceShape(faceShape) {
        return this.beardRepository
            .createQueryBuilder('beard')
            .where("beard.metadata->>'faceShapeCompatibility' ILIKE :faceShape", {
            faceShape: `%${faceShape}%`,
        })
            .andWhere('beard.isActive = :isActive', { isActive: true })
            .orderBy('beard.trialCount', 'DESC')
            .limit(10)
            .getMany();
    }
    async getByStyle(style) {
        return this.beardRepository.find({
            where: { style, isActive: true },
            order: { trialCount: 'DESC' },
        });
    }
    async getPopular(limit = 5) {
        return this.beardRepository.find({
            where: { isActive: true },
            order: { trialCount: 'DESC' },
            take: limit,
        });
    }
};
exports.BeardService = BeardService;
exports.BeardService = BeardService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(beard_entity_1.Beard)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], BeardService);
//# sourceMappingURL=beard.service.js.map