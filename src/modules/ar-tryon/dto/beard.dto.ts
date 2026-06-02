import { IsString, IsNotEmpty, IsOptional, IsUrl } from 'class-validator';

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

export class GetBeardsDto {
  @IsString()
  @IsOptional()
  style?: string;

  @IsString()
  @IsOptional()
  faceShape?: string;

  @IsString()
  @IsOptional()
  limit?: string;
}
