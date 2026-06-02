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
exports.NailService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const nail_entity_1 = require("../entities/nail.entity");
let NailService = class NailService {
    constructor(nailRepository) {
        this.nailRepository = nailRepository;
    }
    async create(createNailDto) {
        const nail = this.nailRepository.create(createNailDto);
        return this.nailRepository.save(nail);
    }
    async findAll(query) {
        const queryBuilder = this.nailRepository.createQueryBuilder('nail');
        if (query.design) {
            queryBuilder.andWhere('nail.design = :design', { design: query.design });
        }
        if (query.nailShape) {
            queryBuilder.andWhere("nail.metadata->>'nailShape' = :nailShape", {
                nailShape: query.nailShape,
            });
        }
        queryBuilder.andWhere('nail.isActive = :isActive', { isActive: true });
        queryBuilder.orderBy('nail.trialCount', 'DESC');
        const limit = parseInt(query.limit || '10', 10);
        queryBuilder.limit(limit);
        return queryBuilder.getMany();
    }
    async findById(id) {
        const nail = await this.nailRepository.findOne({ where: { id } });
        if (!nail) {
            throw new common_1.NotFoundException(`Nail with ID ${id} not found`);
        }
        return nail;
    }
    async update(id, updateNailDto) {
        const nail = await this.findById(id);
        Object.assign(nail, updateNailDto);
        return this.nailRepository.save(nail);
    }
    async delete(id) {
        const result = await this.nailRepository.delete(id);
        if (result.affected === 0) {
            throw new common_1.NotFoundException(`Nail with ID ${id} not found`);
        }
    }
    async incrementTrialCount(id) {
        await this.nailRepository.increment({ id }, 'trialCount', 1);
    }
    async findByDesign(design) {
        return this.nailRepository.find({
            where: { design, isActive: true },
            order: { trialCount: 'DESC' },
        });
    }
    async findByNailShape(nailShape) {
        return this.nailRepository
            .createQueryBuilder('nail')
            .where("nail.metadata->>'nailShape' = :nailShape", { nailShape })
            .andWhere('nail.isActive = :isActive', { isActive: true })
            .orderBy('nail.trialCount', 'DESC')
            .getMany();
    }
    async getPopular(limit = 5) {
        return this.nailRepository.find({
            where: { isActive: true },
            order: { trialCount: 'DESC' },
            take: limit,
        });
    }
};
exports.NailService = NailService;
exports.NailService = NailService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(nail_entity_1.Nail)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], NailService);
//# sourceMappingURL=nail.service.js.map