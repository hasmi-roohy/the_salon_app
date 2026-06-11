import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsUrl,
  IsInt,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
export class CreateBeardDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  style: string;

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

  @IsOptional()
  metadata?: {
    faceShapeCompatibility?: string[];
    density?: string;
    length?: string;
  };
}

export class UpdateBeardDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  style?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  @IsUrl()
  imageUrl?: string;

  @IsOptional()
  metadata?: {
    faceShapeCompatibility?: string[];
    density?: string;
    length?: string;
  };
}

// ✅ FIX #9: Add pagination support
// ✅ FIX #1: Change limit from string to number with validation
export class GetBeardsDto {
  @IsString()
  @IsOptional()
  style?: string;

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
  limit?: string;
}
