import { Repository } from 'typeorm';
import { TryOnResult } from '../entities/try-on-result.entity';
import { SaveTryOnResultDto, GetTryOnResultsDto, ShareTryOnResultDto } from '../dto';
export declare class TryOnResultService {
    private tryOnResultRepository;
    constructor(tryOnResultRepository: Repository<TryOnResult>);
    save(userId: string, saveDto: SaveTryOnResultDto): Promise<TryOnResult>;
    findByUserId(userId: string, query: GetTryOnResultsDto): Promise<TryOnResult[]>;
    findById(id: string): Promise<TryOnResult>;
    delete(id: string): Promise<void>;
    share(id: string, shareDto: ShareTryOnResultDto): Promise<{
        shareToken: string;
        shareUrl: string;
    }>;
    findByShareToken(shareToken: string): Promise<TryOnResult>;
    getStats(userId: string): Promise<{
        totalTrials: number;
        mostUsedHairstyle?: string;
        mostUsedBeard?: string;
        mostUsedNail?: string;
    }>;
}
