import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TryOnResult } from '../entities/try-on-result.entity';
import { SaveTryOnResultDto, GetTryOnResultsDto, ShareTryOnResultDto } from '../dto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class TryOnResultService {
  constructor(
    @InjectRepository(TryOnResult)
    private tryOnResultRepository: Repository<TryOnResult>,
  ) {}

  async save(userId: string, saveDto: SaveTryOnResultDto): Promise<TryOnResult> {
    const result = this.tryOnResultRepository.create({
      userId,
      ...saveDto,
    });
    return this.tryOnResultRepository.save(result);
  }

  async findByUserId(
    userId: string,
    query: GetTryOnResultsDto,
  ): Promise<TryOnResult[]> {
    const limit = parseInt(query.limit || '20', 10);
    const offset = parseInt(query.offset || '0', 10);

    return this.tryOnResultRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: limit,
      skip: offset,
      relations: ['hairstyle', 'beard', 'nail'],
    });
  }

  async findById(id: string): Promise<TryOnResult> {
    const result = await this.tryOnResultRepository.findOne({
      where: { id },
      relations: ['hairstyle', 'beard', 'nail'],
    });

    if (!result) {
      throw new NotFoundException(`Try-on result with ID ${id} not found`);
    }

    return result;
  }

  async delete(id: string): Promise<void> {
    const result = await this.tryOnResultRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException(`Try-on result with ID ${id} not found`);
    }
  }

  async share(
    id: string,
    shareDto: ShareTryOnResultDto,
  ): Promise<{ shareToken: string; shareUrl: string }> {
    const result = await this.findById(id);

    const shareToken = uuidv4();
    result.isShared = true;
    result.shareToken = shareToken;

    await this.tryOnResultRepository.save(result);

    return {
      shareToken,
      shareUrl: `${process.env.APP_URL}/ar/shared/${shareToken}`,
    };
  }

  async findByShareToken(shareToken: string): Promise<TryOnResult> {
    const result = await this.tryOnResultRepository.findOne({
      where: { shareToken, isShared: true },
      relations: ['hairstyle', 'beard', 'nail'],
    });

    if (!result) {
      throw new NotFoundException('Shared result not found');
    }

    return result;
  }

  async getStats(userId: string): Promise<{
    totalTrials: number;
    mostUsedHairstyle?: string;
    mostUsedBeard?: string;
    mostUsedNail?: string;
  }> {
    const results = await this.tryOnResultRepository.find({
      where: { userId },
      relations: ['hairstyle', 'beard', 'nail'],
    });

    const hairstyleCount = {};
    const beardCount = {};
    const nailCount = {};

    results.forEach((r) => {
      if (r.hairstyle) {
        hairstyleCount[r.hairstyle.name] =
          (hairstyleCount[r.hairstyle.name] || 0) + 1;
      }
      if (r.beard) {
        beardCount[r.beard.name] = (beardCount[r.beard.name] || 0) + 1;
      }
      if (r.nail) {
        nailCount[r.nail.name] = (nailCount[r.nail.name] || 0) + 1;
      }
    });

    const getMostUsed = (obj: Record<string, number>) => {
      return Object.keys(obj).reduce((a, b) =>
        obj[a] > obj[b] ? a : b,
      );
    };

    return {
      totalTrials: results.length,
      mostUsedHairstyle:
        Object.keys(hairstyleCount).length > 0
          ? getMostUsed(hairstyleCount)
          : undefined,
      mostUsedBeard:
        Object.keys(beardCount).length > 0
          ? getMostUsed(beardCount)
          : undefined,
      mostUsedNail:
        Object.keys(nailCount).length > 0
          ? getMostUsed(nailCount)
          : undefined,
    };
  }
}
