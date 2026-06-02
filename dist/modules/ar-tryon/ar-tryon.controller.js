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
var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ArTryonController = void 0;
const common_1 = require("@nestjs/common");
const services_1 = require("../services");
const dto_1 = require("../dto");
let ArTryonController = class ArTryonController {
    constructor(hairstyleService, beardService, nailService, tryOnResultService, recommendationService) {
        this.hairstyleService = hairstyleService;
        this.beardService = beardService;
        this.nailService = nailService;
        this.tryOnResultService = tryOnResultService;
        this.recommendationService = recommendationService;
    }
    async createHairstyle(dto) {
        return this.hairstyleService.create(dto);
    }
    async getHairstyles(query) {
        return this.hairstyleService.findAll(query);
    }
    async getPopularHairstyles() {
        return this.hairstyleService.getPopular(10);
    }
    async getHairstyle(id) {
        return this.hairstyleService.findById(id);
    }
    async updateHairstyle(id, dto) {
        return this.hairstyleService.update(id, dto);
    }
    async deleteHairstyle(id) {
        await this.hairstyleService.delete(id);
        return { message: 'Hairstyle deleted successfully' };
    }
    async createBeard(dto) {
        return this.beardService.create(dto);
    }
    async getBeards(query) {
        return this.beardService.findAll(query);
    }
    async getPopularBeards() {
        return this.beardService.getPopular(10);
    }
    async getBeard(id) {
        return this.beardService.findById(id);
    }
    async updateBeard(id, dto) {
        return this.beardService.update(id, dto);
    }
    async deleteBeard(id) {
        await this.beardService.delete(id);
        return { message: 'Beard deleted successfully' };
    }
    async createNail(dto) {
        return this.nailService.create(dto);
    }
    async getNails(query) {
        return this.nailService.findAll(query);
    }
    async getPopularNails() {
        return this.nailService.getPopular(10);
    }
    async getNail(id) {
        return this.nailService.findById(id);
    }
    async updateNail(id, dto) {
        return this.nailService.update(id, dto);
    }
    async deleteNail(id) {
        await this.nailService.delete(id);
        return { message: 'Nail deleted successfully' };
    }
    async getRecommendations(query, req) {
        const userId = req.user?.id || 'anonymous';
        return this.recommendationService.getRecommendations(userId, query);
    }
    async analyzeFace(faceAnalysis, req) {
        const userId = req.user?.id;
        if (!userId) {
            return { error: 'User not authenticated' };
        }
        return this.recommendationService.saveUserAnalysis(userId, faceAnalysis);
    }
    async addToPreferred(type, styleId, req) {
        const userId = req.user?.id;
        if (!userId) {
            return { error: 'User not authenticated' };
        }
        return this.recommendationService.addToPreferred(userId, type, styleId);
    }
    async removeFromPreferred(type, styleId, req) {
        const userId = req.user?.id;
        if (!userId) {
            return { error: 'User not authenticated' };
        }
        return this.recommendationService.removeFromPreferred(userId, type, styleId);
    }
    async saveResult(dto, req) {
        const userId = req.user?.id;
        if (!userId) {
            return { error: 'User not authenticated' };
        }
        return this.tryOnResultService.save(userId, dto);
    }
    async getUserResults(query, req) {
        const userId = req.user?.id;
        if (!userId) {
            return { error: 'User not authenticated' };
        }
        return this.tryOnResultService.findByUserId(userId, query);
    }
    async getResult(id) {
        return this.tryOnResultService.findById(id);
    }
    async shareResult(id, dto) {
        return this.tryOnResultService.share(id, dto);
    }
    async getSharedResult(shareToken) {
        return this.tryOnResultService.findByShareToken(shareToken);
    }
    async deleteResult(id) {
        await this.tryOnResultService.delete(id);
        return { message: 'Result deleted successfully' };
    }
    async getUserStats(req) {
        const userId = req.user?.id;
        if (!userId) {
            return { error: 'User not authenticated' };
        }
        return this.tryOnResultService.getStats(userId);
    }
};
exports.ArTryonController = ArTryonController;
__decorate([
    (0, common_1.Post)('hairstyles'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_f = typeof dto_1.CreateHairstyleDto !== "undefined" && dto_1.CreateHairstyleDto) === "function" ? _f : Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "createHairstyle", null);
__decorate([
    (0, common_1.Get)('hairstyles'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_g = typeof dto_1.GetHairstylesDto !== "undefined" && dto_1.GetHairstylesDto) === "function" ? _g : Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getHairstyles", null);
__decorate([
    (0, common_1.Get)('hairstyles/popular'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getPopularHairstyles", null);
__decorate([
    (0, common_1.Get)('hairstyles/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getHairstyle", null);
__decorate([
    (0, common_1.Put)('hairstyles/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, typeof (_h = typeof dto_1.UpdateHairstyleDto !== "undefined" && dto_1.UpdateHairstyleDto) === "function" ? _h : Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "updateHairstyle", null);
__decorate([
    (0, common_1.Delete)('hairstyles/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "deleteHairstyle", null);
__decorate([
    (0, common_1.Post)('beards'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_j = typeof dto_1.CreateBeardDto !== "undefined" && dto_1.CreateBeardDto) === "function" ? _j : Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "createBeard", null);
__decorate([
    (0, common_1.Get)('beards'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_k = typeof dto_1.GetBeardsDto !== "undefined" && dto_1.GetBeardsDto) === "function" ? _k : Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getBeards", null);
__decorate([
    (0, common_1.Get)('beards/popular'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getPopularBeards", null);
__decorate([
    (0, common_1.Get)('beards/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getBeard", null);
__decorate([
    (0, common_1.Put)('beards/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, typeof (_l = typeof dto_1.UpdateBeardDto !== "undefined" && dto_1.UpdateBeardDto) === "function" ? _l : Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "updateBeard", null);
__decorate([
    (0, common_1.Delete)('beards/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "deleteBeard", null);
__decorate([
    (0, common_1.Post)('nails'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_m = typeof dto_1.CreateNailDto !== "undefined" && dto_1.CreateNailDto) === "function" ? _m : Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "createNail", null);
__decorate([
    (0, common_1.Get)('nails'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_o = typeof dto_1.GetNailsDto !== "undefined" && dto_1.GetNailsDto) === "function" ? _o : Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getNails", null);
__decorate([
    (0, common_1.Get)('nails/popular'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getPopularNails", null);
__decorate([
    (0, common_1.Get)('nails/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getNail", null);
__decorate([
    (0, common_1.Put)('nails/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, typeof (_p = typeof dto_1.UpdateNailDto !== "undefined" && dto_1.UpdateNailDto) === "function" ? _p : Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "updateNail", null);
__decorate([
    (0, common_1.Delete)('nails/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "deleteNail", null);
__decorate([
    (0, common_1.Get)('recommendations'),
    __param(0, (0, common_1.Query)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_q = typeof dto_1.GetRecommendationsDto !== "undefined" && dto_1.GetRecommendationsDto) === "function" ? _q : Object, Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getRecommendations", null);
__decorate([
    (0, common_1.Post)('recommendations/analyze-face'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "analyzeFace", null);
__decorate([
    (0, common_1.Post)('recommendations/prefer/:type/:styleId'),
    __param(0, (0, common_1.Param)('type')),
    __param(1, (0, common_1.Param)('styleId')),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "addToPreferred", null);
__decorate([
    (0, common_1.Delete)('recommendations/prefer/:type/:styleId'),
    __param(0, (0, common_1.Param)('type')),
    __param(1, (0, common_1.Param)('styleId')),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "removeFromPreferred", null);
__decorate([
    (0, common_1.Post)('results'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_r = typeof dto_1.SaveTryOnResultDto !== "undefined" && dto_1.SaveTryOnResultDto) === "function" ? _r : Object, Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "saveResult", null);
__decorate([
    (0, common_1.Get)('results'),
    __param(0, (0, common_1.Query)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_s = typeof dto_1.GetTryOnResultsDto !== "undefined" && dto_1.GetTryOnResultsDto) === "function" ? _s : Object, Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getUserResults", null);
__decorate([
    (0, common_1.Get)('results/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getResult", null);
__decorate([
    (0, common_1.Post)('results/:id/share'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, typeof (_t = typeof dto_1.ShareTryOnResultDto !== "undefined" && dto_1.ShareTryOnResultDto) === "function" ? _t : Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "shareResult", null);
__decorate([
    (0, common_1.Get)('results/shared/:shareToken'),
    __param(0, (0, common_1.Param)('shareToken')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getSharedResult", null);
__decorate([
    (0, common_1.Delete)('results/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "deleteResult", null);
__decorate([
    (0, common_1.Get)('results/stats/user'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ArTryonController.prototype, "getUserStats", null);
exports.ArTryonController = ArTryonController = __decorate([
    (0, common_1.Controller)('api/ar-tryon'),
    __metadata("design:paramtypes", [typeof (_a = typeof services_1.HairstyleService !== "undefined" && services_1.HairstyleService) === "function" ? _a : Object, typeof (_b = typeof services_1.BeardService !== "undefined" && services_1.BeardService) === "function" ? _b : Object, typeof (_c = typeof services_1.NailService !== "undefined" && services_1.NailService) === "function" ? _c : Object, typeof (_d = typeof services_1.TryOnResultService !== "undefined" && services_1.TryOnResultService) === "function" ? _d : Object, typeof (_e = typeof services_1.RecommendationService !== "undefined" && services_1.RecommendationService) === "function" ? _e : Object])
], ArTryonController);
//# sourceMappingURL=ar-tryon.controller.js.map