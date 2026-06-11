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
export class CreateNailDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  design: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  @IsUrl()
  imageUrl?: string;

  @IsString()
  @IsNotEmpty()
  overlayPath: string;

  @IsOptional()
  colorPalette?: {
    primary?: string;
    secondary?: string;
    accent?: string;
  };

  @IsOptional()
  metadata?: {
    nailShape?: string;
    length?: string;
  };
}

export class UpdateNailDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  design?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  @IsUrl()
  imageUrl?: string;

  @IsOptional()
  colorPalette?: {
    primary?: string;
    secondary?: string;
    accent?: string;
  };

  @IsOptional()
  metadata?: {
    nailShape?: string;
    length?: string;
  };
}

// ✅ FIX #9: Add pagination support
// ✅ FIX #1: Change limit from string to number with validation
export class GetNailsDto {
  @IsString()
  @IsOptional()
  design?: string;

  @IsString()
  @IsOptional()
  nailShape?: string;

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
