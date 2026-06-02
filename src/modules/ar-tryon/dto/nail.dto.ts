import { IsString, IsNotEmpty, IsOptional, IsUrl } from 'class-validator';

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

export class GetNailsDto {
  @IsString()
  @IsOptional()
  design?: string;

  @IsString()
  @IsOptional()
  nailShape?: string;

  @IsString()
  @IsOptional()
  limit?: string;
}
