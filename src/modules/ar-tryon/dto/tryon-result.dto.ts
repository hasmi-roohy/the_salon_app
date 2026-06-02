import { IsString, IsNotEmpty, IsOptional, IsUUID } from 'class-validator';

export class SaveTryOnResultDto {
  @IsUUID()
  @IsOptional()
  hairstyleId?: string;

  @IsUUID()
  @IsOptional()
  beardId?: string;

  @IsUUID()
  @IsOptional()
  nailId?: string;

  @IsString()
  @IsNotEmpty()
  originalImageUrl: string;

  @IsString()
  @IsNotEmpty()
  resultImageUrl: string;

  @IsOptional()
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

export class GetTryOnResultsDto {
  @IsString()
  @IsOptional()
  limit?: string;

  @IsString()
  @IsOptional()
  offset?: string;
}

export class ShareTryOnResultDto {
  @IsString()
  @IsOptional()
  expiresIn?: string; // Duration: "7d", "30d", etc.
}

export class GetRecommendationsDto {
  @IsString()
  @IsNotEmpty()
  faceShape: string; // oval, round, square, heart, oblong

  @IsString()
  @IsOptional()
  skinTone?: string;

  @IsString()
  @IsOptional()
  type?: string; // hairstyle, beard, nail
}
