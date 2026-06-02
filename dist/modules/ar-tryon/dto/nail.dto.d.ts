export declare class CreateNailDto {
    name: string;
    design: string;
    description?: string;
    imageUrl?: string;
    overlayPath: string;
    colorPalette?: {
        primary?: string;
        secondary?: string;
        accent?: string;
    };
    metadata?: {
        nailShape?: string;
        length?: string;
    };
}
export declare class UpdateNailDto {
    name?: string;
    design?: string;
    description?: string;
    imageUrl?: string;
    colorPalette?: {
        primary?: string;
        secondary?: string;
        accent?: string;
    };
    metadata?: {
        nailShape?: string;
        length?: string;
    };
}
export declare class GetNailsDto {
    design?: string;
    nailShape?: string;
    limit?: string;
}
