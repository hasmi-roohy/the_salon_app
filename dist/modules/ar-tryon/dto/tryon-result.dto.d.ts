export declare class SaveTryOnResultDto {
    hairstyleId?: string;
    beardId?: string;
    nailId?: string;
    originalImageUrl: string;
    resultImageUrl: string;
    metadata?: {
        deviceType?: string;
        processingTime?: number;
        modelVersions?: {
            hairstyleVersion?: string;
            beardVersion?: string;
            nailVersion?: string;
        };
    };
}
export declare class GetTryOnResultsDto {
    limit?: string;
    offset?: string;
}
export declare class ShareTryOnResultDto {
    expiresIn?: string;
}
export declare class GetRecommendationsDto {
    faceShape: string;
    skinTone?: string;
    type?: string;
}
