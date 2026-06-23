import {
  Injectable,
  BadRequestException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { fal } from '@fal-ai/client';
import { GenerateThreeDTryOnDto } from '../dto';

export interface ThreeDTryOnResult {
  status: 'mock' | 'generated';
  provider: string;
  imageUrl?: string;
  previewImageUrl?: string;
  taskId?: string;
  message: string;
}

@Injectable()
export class ThreeDTryOnService {
  constructor(private config: ConfigService) {}

  async generate(dto: GenerateThreeDTryOnDto): Promise<ThreeDTryOnResult> {
    const provider = this.config.get<string>('AI_TRYON_PROVIDER') || 'mock';
    const mockEnabled =
      this.config.get<string>('AI_TRYON_MOCK_ENABLED') !== 'false';

    if (mockEnabled || provider === 'mock') {
      return {
        status: 'mock',
        provider,
        taskId: `mock-${Date.now()}`,
        message:
          'Mock AI try-on response returned. Connect fal.ai Nano Banana for realistic blended image output.',
      };
    }

    if (provider === 'fal' && !this.config.get<string>('FAL_KEY')) {
      throw new ServiceUnavailableException({
        provider,
        message:
          'fal.ai is selected but FAL_KEY is missing. Enable AI_TRYON_MOCK_ENABLED=true for free UI testing.',
      });
    }

    if (provider === 'fal') {
      return this.generateWithFal(dto);
    }

    throw new ServiceUnavailableException({
      provider,
      message:
        'Unsupported AI provider. Use AI_TRYON_PROVIDER=mock for free demo or AI_TRYON_PROVIDER=fal for Nano Banana.',
    });
  }

  private async generateWithFal(
    dto: GenerateThreeDTryOnDto,
  ): Promise<ThreeDTryOnResult> {
    if (!dto.imageBase64) {
      throw new BadRequestException({
        provider: 'fal',
        message: 'Upload or capture a photo before generating the AI try-on.',
      });
    }

    const apiKey = this.config.get<string>('FAL_KEY');
    if (!apiKey) {
      throw new ServiceUnavailableException({
        provider: 'fal',
        message:
          'fal.ai is selected but FAL_KEY is missing. Add it to .env or enable mock mode.',
      });
    }

    fal.config({ credentials: apiKey });

    const model = 'fal-ai/nano-banana-pro/edit';
    const imageBuffer = this.decodeBase64Image(dto.imageBase64);
    const imageFile = new Blob([new Uint8Array(imageBuffer)], {
      type: 'image/png',
    });
    const imageUrl = await fal.storage.upload(imageFile);
    const prompt = this.buildEditPrompt(dto);

    return this.runFalModel(model, prompt, imageUrl);
  }

  private decodeBase64Image(imageBase64: string): Buffer {
    const cleaned = imageBase64.includes(',')
      ? imageBase64.split(',').pop()
      : imageBase64;
    const buffer = Buffer.from(cleaned || '', 'base64');
    if (!buffer.length) {
      throw new BadRequestException({
        provider: 'fal',
        message: 'The uploaded image could not be decoded.',
      });
    }
    return buffer;
  }

  private buildEditPrompt(dto: GenerateThreeDTryOnDto): string {
    const requestedStyle = dto.prompt?.trim() || dto.styleId;
    const shared =
      'Keep the same person, identity, face shape, expression, skin tone, pose, clothing, lighting, and background. Do not beautify or replace the face. Make the edit realistic, clean, and salon-quality.';

    if (dto.category === 'hair') {
      return `${shared} Edit only the hairstyle and hair color. Preserve the original face and facial features exactly. Blend the hairline naturally with realistic strands. Requested hairstyle: ${requestedStyle}.`;
    }

    if (dto.category === 'beard') {
      return `${shared} Edit only facial hair. Add or modify beard and moustache naturally along the jaw, chin, and upper lip. Preserve all other face details. Requested beard style: ${requestedStyle}.`;
    }

    return `${shared} Edit only the fingernails. Keep the hand, fingers, skin texture, jewelry, and background unchanged. Apply realistic nail art with correct nail beds, perspective, shine, and finger alignment. Requested nail design: ${requestedStyle}.`;
  }

  private async runFalModel(
    model: string,
    prompt: string,
    imageUrl: string,
  ): Promise<ThreeDTryOnResult> {
    const result = await fal.subscribe(model, {
      input: {
        prompt,
        image_urls: [imageUrl],
        num_images: 1,
        output_format: 'png',
        resolution: '1K',
      },
    });

    const data = result.data as Record<string, any>;
    const generatedUrl =
      data?.images?.[0]?.url ||
      data?.image?.url ||
      data?.image_url ||
      data?.output?.[0]?.url;

    if (!generatedUrl) {
      throw new ServiceUnavailableException({
        provider: 'fal',
        message: 'fal.ai finished but did not return an edited image URL.',
      });
    }

    return {
      status: 'generated',
      provider: `fal:${model}`,
      imageUrl: generatedUrl,
      previewImageUrl: generatedUrl,
      taskId: result.requestId,
      message: 'Realistic premium AI try-on generated with fal.ai Nano Banana.',
    };
  }
}
