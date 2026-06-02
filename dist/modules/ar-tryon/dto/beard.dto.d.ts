export declare class CreateBeardDto {
    name: string;
    style: string;
    description?: string;
    imageUrl?: string;
    modelPath: string;
    metadata?: {
        faceShapeCompatibility?: string[];
        density?: string;
        length?: string;
    };
}
export declare class UpdateBeardDto {
    name?: string;
    style?: string;
    description?: string;
    imageUrl?: string;
    metadata?: {
        faceShapeCompatibility?: string[];
        density?: string;
        length?: string;
    };
}
export declare class GetBeardsDto {
    style?: string;
    faceShape?: string;
    limit?: string;
}
