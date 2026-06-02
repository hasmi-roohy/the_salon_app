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
Object.defineProperty(exports, "__esModule", { value: true });
exports.TryOnResult = void 0;
const typeorm_1 = require("typeorm");
const hairstyle_entity_1 = require("./hairstyle.entity");
const beard_entity_1 = require("./beard.entity");
const nail_entity_1 = require("./nail.entity");
let TryOnResult = class TryOnResult {
};
exports.TryOnResult = TryOnResult;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], TryOnResult.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'uuid' }),
    __metadata("design:type", String)
], TryOnResult.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'uuid', nullable: true }),
    __metadata("design:type", String)
], TryOnResult.prototype, "hairstyleId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => hairstyle_entity_1.Hairstyle, (hairstyle) => hairstyle.tryOnResults, {
        nullable: true,
        onDelete: 'SET NULL',
    }),
    (0, typeorm_1.JoinColumn)({ name: 'hairstyleId' }),
    __metadata("design:type", hairstyle_entity_1.Hairstyle)
], TryOnResult.prototype, "hairstyle", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'uuid', nullable: true }),
    __metadata("design:type", String)
], TryOnResult.prototype, "beardId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => beard_entity_1.Beard, (beard) => beard.tryOnResults, {
        nullable: true,
        onDelete: 'SET NULL',
    }),
    (0, typeorm_1.JoinColumn)({ name: 'beardId' }),
    __metadata("design:type", beard_entity_1.Beard)
], TryOnResult.prototype, "beard", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'uuid', nullable: true }),
    __metadata("design:type", String)
], TryOnResult.prototype, "nailId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => nail_entity_1.Nail, (nail) => nail.tryOnResults, {
        nullable: true,
        onDelete: 'SET NULL',
    }),
    (0, typeorm_1.JoinColumn)({ name: 'nailId' }),
    __metadata("design:type", nail_entity_1.Nail)
], TryOnResult.prototype, "nail", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 500, nullable: true }),
    __metadata("design:type", String)
], TryOnResult.prototype, "originalImageUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'varchar', length: 500, nullable: true }),
    __metadata("design:type", String)
], TryOnResult.prototype, "resultImageUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'json', nullable: true }),
    __metadata("design:type", Object)
], TryOnResult.prototype, "metadata", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'boolean', default: false }),
    __metadata("design:type", Boolean)
], TryOnResult.prototype, "isShared", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], TryOnResult.prototype, "shareToken", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], TryOnResult.prototype, "createdAt", void 0);
exports.TryOnResult = TryOnResult = __decorate([
    (0, typeorm_1.Entity)('try_on_results')
], TryOnResult);
//# sourceMappingURL=try-on-result.entity.js.map