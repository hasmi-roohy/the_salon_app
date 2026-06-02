import { TryOnResult } from './try-on-result.entity';
export declare class Hairstyle {
    id: string;
    name: string;
    description: string;
    imageUrl: string;
    modelPath: string;
    category: string;
    metadata: {
        faceShapeCompatibility?: string[];
        hairLength?: string;
        hairTexture?: string;
    };
    isActive: boolean;
    trialCount: number;
    createdAt: Date;
    updatedAt: Date;
    tryOnResults: TryOnResult[];
}
