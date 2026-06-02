import { HairstyleService, BeardService, NailService, TryOnResultService, RecommendationService } from '../services';
import { CreateHairstyleDto, UpdateHairstyleDto, GetHairstylesDto, CreateBeardDto, UpdateBeardDto, GetBeardsDto, CreateNailDto, UpdateNailDto, GetNailsDto, SaveTryOnResultDto, GetTryOnResultsDto, ShareTryOnResultDto, GetRecommendationsDto } from '../dto';
export declare class ArTryonController {
    private hairstyleService;
    private beardService;
    private nailService;
    private tryOnResultService;
    private recommendationService;
    constructor(hairstyleService: HairstyleService, beardService: BeardService, nailService: NailService, tryOnResultService: TryOnResultService, recommendationService: RecommendationService);
    createHairstyle(dto: CreateHairstyleDto): Promise<any>;
    getHairstyles(query: GetHairstylesDto): Promise<any>;
    getPopularHairstyles(): Promise<any>;
    getHairstyle(id: string): Promise<any>;
    updateHairstyle(id: string, dto: UpdateHairstyleDto): Promise<any>;
    deleteHairstyle(id: string): Promise<{
        message: string;
    }>;
    createBeard(dto: CreateBeardDto): Promise<any>;
    getBeards(query: GetBeardsDto): Promise<any>;
    getPopularBeards(): Promise<any>;
    getBeard(id: string): Promise<any>;
    updateBeard(id: string, dto: UpdateBeardDto): Promise<any>;
    deleteBeard(id: string): Promise<{
        message: string;
    }>;
    createNail(dto: CreateNailDto): Promise<any>;
    getNails(query: GetNailsDto): Promise<any>;
    getPopularNails(): Promise<any>;
    getNail(id: string): Promise<any>;
    updateNail(id: string, dto: UpdateNailDto): Promise<any>;
    deleteNail(id: string): Promise<{
        message: string;
    }>;
    getRecommendations(query: GetRecommendationsDto, req: any): Promise<any>;
    analyzeFace(faceAnalysis: {
        faceShape?: string;
        skinTone?: string;
        faceWidth?: number;
        faceLength?: number;
        jawlineWidth?: number;
    }, req: any): Promise<any>;
    addToPreferred(type: 'hairstyle' | 'beard' | 'nail', styleId: string, req: any): Promise<any>;
    removeFromPreferred(type: 'hairstyle' | 'beard' | 'nail', styleId: string, req: any): Promise<any>;
    saveResult(dto: SaveTryOnResultDto, req: any): Promise<any>;
    getUserResults(query: GetTryOnResultsDto, req: any): Promise<any>;
    getResult(id: string): Promise<any>;
    shareResult(id: string, dto: ShareTryOnResultDto): Promise<any>;
    getSharedResult(shareToken: string): Promise<any>;
    deleteResult(id: string): Promise<{
        message: string;
    }>;
    getUserStats(req: any): Promise<any>;
}
