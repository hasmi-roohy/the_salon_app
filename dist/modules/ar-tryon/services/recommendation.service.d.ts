import { Repository } from 'typeorm';
import { Hairstyle } from '../entities/hairstyle.entity';
import { Beard } from '../entities/beard.entity';
import { Nail } from '../entities/nail.entity';
import { UserArPreference } from '../entities/user-ar-preference.entity';
import { GetRecommendationsDto } from '../dto';
export declare class RecommendationService {
    private hairstyleRepository;
    private beardRepository;
    private nailRepository;
    private userPreferenceRepository;
    constructor(hairstyleRepository: Repository<Hairstyle>, beardRepository: Repository<Beard>, nailRepository: Repository<Nail>, userPreferenceRepository: Repository<UserArPreference>);
    getRecommendations(userId: string, query: GetRecommendationsDto): Promise<{
        hairstyles: Hairstyle[];
        beards: Beard[];
        nails: Nail[];
        basedOnFaceShape: string;
        personalized: boolean;
    }>;
    private getHairstyleRecommendations;
    private getBeardRecommendations;
    private getNailRecommendations;
    saveUserAnalysis(userId: string, faceAnalysis: {
        faceShape?: string;
        skinTone?: string;
        faceWidth?: number;
        faceLength?: number;
        jawlineWidth?: number;
    }): Promise<UserArPreference>;
    addToPreferred(userId: string, type: 'hairstyle' | 'beard' | 'nail', styleId: string): Promise<UserArPreference>;
    removeFromPreferred(userId: string, type: 'hairstyle' | 'beard' | 'nail', styleId: string): Promise<UserArPreference>;
}
