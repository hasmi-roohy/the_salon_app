import { Hairstyle } from './hairstyle.entity';
import { Beard } from './beard.entity';
import { Nail } from './nail.entity';
export declare class TryOnResult {
    id: string;
    userId: string;
    hairstyleId: string;
    hairstyle: Hairstyle;
    beardId: string;
    beard: Beard;
    nailId: string;
    nail: Nail;
    originalImageUrl: string;
    resultImageUrl: string;
    metadata: {
        deviceType?: string;
        processingTime?: number;
        modelVersions?: {
            hairstyleVersion?: string;
            beardVersion?: string;
            nailVersion?: string;
        };
    };
    isShared: boolean;
    shareToken: string;
    createdAt: Date;
}
