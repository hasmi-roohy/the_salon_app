"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ArTryonModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const ar_tryon_controller_1 = require("./ar-tryon.controller");
const services_1 = require("./services");
const entities_1 = require("./entities");
let ArTryonModule = class ArTryonModule {
};
exports.ArTryonModule = ArTryonModule;
exports.ArTryonModule = ArTryonModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([
                entities_1.Hairstyle,
                entities_1.Beard,
                entities_1.Nail,
                entities_1.TryOnResult,
                entities_1.UserArPreference,
            ]),
        ],
        controllers: [ar_tryon_controller_1.ArTryonController],
        providers: [
            services_1.HairstyleService,
            services_1.BeardService,
            services_1.NailService,
            services_1.TryOnResultService,
            services_1.RecommendationService,
        ],
        exports: [
            services_1.HairstyleService,
            services_1.BeardService,
            services_1.NailService,
            services_1.TryOnResultService,
            services_1.RecommendationService,
        ],
    })
], ArTryonModule);
//# sourceMappingURL=ar-tryon.module.js.map