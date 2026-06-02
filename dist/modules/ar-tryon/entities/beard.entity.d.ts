import { TryOnResult } from './try-on-result.entity';
export declare class Beard {
    id: string;
    name: string;
    style: string;
    description: string;
    imageUrl: string;
    modelPath: string;
    metadata: {
        faceShapeCompatibility?: string[];
        density?: string;
        length?: string;
    };
    isActive: boolean;
    trialCount: number;
    createdAt: Date;
    updatedAt: Date;
    tryOnResults: TryOnResult[];
}
