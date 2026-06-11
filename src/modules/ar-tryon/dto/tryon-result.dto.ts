import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsUUID,
  IsInt,
  Min,
  Max,

} from 'class-validator';

import { Type } from 'class-transformer';
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

// ✅ FIX #9: Add pagination support
// ✅ FIXED: Changed offset and limit from string to number with validation
export class GetTryOnResultsDto {
  // ✅ NEW: Pagination page
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  // ✅ FIXED: Changed from string to number with validation
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: string;

  // ✅ FIXED: Changed from string to number (deprecated in favor of page)
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
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

  // ✅ NEW: Pagination page
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  // ✅ NEW: Pagination limit
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}