import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsUrl,
  IsInt,
  IsNumber,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
export class CreateHairstyleDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  @IsUrl()
  imageUrl?: string;

  @IsString()
  @IsNotEmpty()
  modelPath: string;

  @IsString()
  @IsNotEmpty()
  category: string;

  @IsOptional()
  metadata?: {
    faceShapeCompatibility?: string[];
    hairLength?: string;
    hairTexture?: string;
  };
}

export class UpdateHairstyleDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  @IsUrl()
  imageUrl?: string;

  @IsString()
  @IsOptional()
  category?: string;

  @IsOptional()
  metadata?: {
    faceShapeCompatibility?: string[];
    hairLength?: string;
    hairTexture?: string;
  };
}

// ✅ FIX #9: Add pagination support
// ✅ FIX #1: Change limit from string to number with validation
export class GetHairstylesDto {
  @IsString()
  @IsOptional()
  category?: string;

  @IsString()
  @IsOptional()
  faceShape?: string;

  // ✅ NEW: Pagination page
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  // ✅ FIXED: Changed from string to number
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}
