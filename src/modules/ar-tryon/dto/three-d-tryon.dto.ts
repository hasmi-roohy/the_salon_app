import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class GenerateThreeDTryOnDto {
  @IsIn(['hair', 'beard', 'nails'])
  category: 'hair' | 'beard' | 'nails';

  @IsString()
  @MaxLength(120)
  styleId: string;

  @IsString()
  @MaxLength(500)
  prompt: string;

  @IsOptional()
  @IsString()
  imageBase64?: string;
}

