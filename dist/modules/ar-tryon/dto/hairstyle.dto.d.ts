export declare class CreateHairstyleDto {
    name: string;
    description?: string;
    imageUrl?: string;
    modelPath: string;
    category: string;
    metadata?: {
        faceShapeCompatibility?: string[];
        hairLength?: string;
        hairTexture?: string;
    };
}
export declare class UpdateHairstyleDto {
    name?: string;
    description?: string;
    imageUrl?: string;
    category?: string;
    metadata?: {
        faceShapeCompatibility?: string[];
        hairLength?: string;
        hairTexture?: string;
    };
}
export declare class GetHairstylesDto {
    category?: string;
    faceShape?: string;
    limit?: string;
}
