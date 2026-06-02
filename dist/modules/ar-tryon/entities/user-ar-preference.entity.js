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
exports.UserArPreference = void 0;
const typeorm_1 = require("typeorm");
let UserArPreference = class UserArPreference {
};
exports.UserArPreference = UserArPreference;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], UserArPreference.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'uuid', unique: true }),
    __metadata("design:type", String)
], UserArPreference.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'json', nullable: true }),
    __metadata("design:type", Object)
], UserArPreference.prototype, "faceAnalysis", void 0);
__decorate([
    (0, typeorm_1.Column)('uuid', { array: true, default: [] }),
    __metadata("design:type", Array)
], UserArPreference.prototype, "preferredHairstyles", void 0);
__decorate([
    (0, typeorm_1.Column)('uuid', { array: true, default: [] }),
    __metadata("design:type", Array)
], UserArPreference.prototype, "preferredBeards", void 0);
__decorate([
    (0, typeorm_1.Column)('uuid', { array: true, default: [] }),
    __metadata("design:type", Array)
], UserArPreference.prototype, "preferredNails", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'json', nullable: true }),
    __metadata("design:type", Object)
], UserArPreference.prototype, "stylePreferences", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'integer', default: 0 }),
    __metadata("design:type", Number)
], UserArPreference.prototype, "totalTrials", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], UserArPreference.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], UserArPreference.prototype, "updatedAt", void 0);
exports.UserArPreference = UserArPreference = __decorate([
    (0, typeorm_1.Entity)('user_ar_preferences')
], UserArPreference);
//# sourceMappingURL=user-ar-preference.entity.js.map