import { TryOnResult } from './try-on-result.entity';
export declare class Nail {
    id: string;
    name: string;
    design: string;
    description: string;
    imageUrl: string;
    overlayPath: string;
    colorPalette: {
        primary?: string;
        secondary?: string;
        accent?: string;
    };
    metadata: {
        nailShape?: string;
        length?: string;
    };
    isActive: boolean;
    trialCount: number;
    createdAt: Date;
    updatedAt: Date;
    tryOnResults: TryOnResult[];
}
