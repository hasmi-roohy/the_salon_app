export declare class UserArPreference {
    id: string;
    userId: string;
    faceAnalysis: {
        faceShape?: string;
        skinTone?: string;
        faceWidth?: number;
        faceLength?: number;
        jawlineWidth?: number;
    };
    preferredHairstyles: string[];
    preferredBeards: string[];
    preferredNails: string[];
    stylePreferences: {
        traditional?: boolean;
        modern?: boolean;
        bold?: boolean;
        natural?: boolean;
    };
    totalTrials: number;
    createdAt: Date;
    updatedAt: Date;
}
