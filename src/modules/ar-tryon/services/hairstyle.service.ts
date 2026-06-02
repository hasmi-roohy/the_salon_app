import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Hairstyle } from '../entities/hairstyle.entity';
import { CreateHairstyleDto, UpdateHairstyleDto, GetHairstylesDto } from '../dto';

@Injectable()
export class HairstyleService {
  constructor(
    @InjectRepository(Hairstyle)
    private hairstyleRepository: Repository<Hairstyle>,
  ) {}

  async create(createHairstyleDto: CreateHairstyleDto): Promise<Hairstyle> {
    const hairstyle = this.hairstyleRepository.create(createHairstyleDto);
    return this.hairstyleRepository.save(hairstyle);
  }

  async findAll(query: GetHairstylesDto): Promise<Hairstyle[]> {
    const queryBuilder = this.hairstyleRepository.createQueryBuilder('hairstyle');

    if (query.category) {
      queryBuilder.andWhere('hairstyle.category = :category', {
        category: query.category,
      });
    }

    if (query.faceShape) {
      queryBuilder.andWhere(
        "hairstyle.metadata->>'faceShapeCompatibility' ILIKE :faceShape",
        {
          faceShape: `%${query.faceShape}%`,
        },
      );
    }

    queryBuilder.andWhere('hairstyle.isActive = :isActive', { isActive: true });
    queryBuilder.orderBy('hairstyle.trialCount', 'DESC');

    const limit = parseInt(query.limit || '10', 10);
    queryBuilder.limit(limit);

    return queryBuilder.getMany();
  }

  async findById(id: string): Promise<Hairstyle> {
    const hairstyle = await this.hairstyleRepository.findOne({ where: { id } });
    if (!hairstyle) {
      throw new NotFoundException(`Hairstyle with ID ${id} not found`);
    }
    return hairstyle;
  }

  async update(
    id: string,
    updateHairstyleDto: UpdateHairstyleDto,
  ): Promise<Hairstyle> {
    const hairstyle = await this.findById(id);
    Object.assign(hairstyle, updateHairstyleDto);
    return this.hairstyleRepository.save(hairstyle);
  }

  async delete(id: string): Promise<void> {
    const result = await this.hairstyleRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException(`Hairstyle with ID ${id} not found`);
    }
  }

  async incrementTrialCount(id: string): Promise<void> {
    await this.hairstyleRepository.increment({ id }, 'trialCount', 1);
  }

  async findByFaceShape(faceShape: string): Promise<Hairstyle[]> {
    return this.hairstyleRepository
      .createQueryBuilder('hairstyle')
      .where("hairstyle.metadata->>'faceShapeCompatibility' ILIKE :faceShape", {
        faceShape: `%${faceShape}%`,
      })
      .andWhere('hairstyle.isActive = :isActive', { isActive: true })
      .orderBy('hairstyle.trialCount', 'DESC')
      .limit(10)
      .getMany();
  }

  async getPopular(limit: number = 5): Promise<Hairstyle[]> {
    return this.hairstyleRepository.find({
      where: { isActive: true },
      order: { trialCount: 'DESC' },
      take: limit,
    });
  }
}
