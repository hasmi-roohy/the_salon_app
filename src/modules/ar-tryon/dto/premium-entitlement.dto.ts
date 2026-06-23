import {
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsIn,
  IsOptional,
  IsString,
} from 'class-validator';

export class VerifyPremiumPurchaseDto {
  @IsString()
  userId: string;

  @IsArray()
  @ArrayNotEmpty()
  @IsIn(['premiumStudio', 'aiHair', 'aiBeard', 'aiNails'], { each: true })
  featureIds: Array<'premiumStudio' | 'aiHair' | 'aiBeard' | 'aiNails'>;

  @IsIn(['google_play', 'apple', 'upi', 'card', 'wallet'])
  provider: 'google_play' | 'apple' | 'upi' | 'card' | 'wallet';

  @IsString()
  productId: string;

  @IsString()
  purchaseToken: string;

  @IsOptional()
  @IsBoolean()
  developmentMock?: boolean;
}
