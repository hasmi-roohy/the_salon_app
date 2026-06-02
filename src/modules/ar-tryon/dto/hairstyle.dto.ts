import { IsString, IsNotEmpty, IsOptional, IsUrl } from 'class-validator';

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

export class GetHairstylesDto {
  @IsString()
  @IsOptional()
  category?: string;

  @IsString()
  @IsOptional()
  faceShape?: string;

  @IsString()
  @IsOptional()
  limit?: string;
}
