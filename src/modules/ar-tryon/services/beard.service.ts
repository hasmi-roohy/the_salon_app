import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Beard } from '../entities/beard.entity';
import { CreateBeardDto, UpdateBeardDto, GetBeardsDto } from '../dto';

@Injectable()
export class BeardService {
  constructor(
    @InjectRepository(Beard)
    private beardRepository: Repository<Beard>,
  ) {}

  async create(createBeardDto: CreateBeardDto): Promise<Beard> {
    const beard = this.beardRepository.create(createBeardDto);
    return this.beardRepository.save(beard);
  }

  async findAll(query: GetBeardsDto): Promise<Beard[]> {
    const queryBuilder = this.beardRepository.createQueryBuilder('beard');

    if (query.style) {
      queryBuilder.andWhere('beard.style = :style', { style: query.style });
    }

    if (query.faceShape) {
      queryBuilder.andWhere(
        "beard.metadata->>'faceShapeCompatibility' ILIKE :faceShape",
        {
          faceShape: `%${query.faceShape}%`,
        },
      );
    }

    queryBuilder.andWhere('beard.isActive = :isActive', { isActive: true });
    queryBuilder.orderBy('beard.trialCount', 'DESC');

   const limit = parseInt(String(query.limit ?? '10'), 10);
    queryBuilder.limit(limit);

    return queryBuilder.getMany();
  }

  async findById(id: string): Promise<Beard> {
    const beard = await this.beardRepository.findOne({ where: { id } });
    if (!beard) {
      throw new NotFoundException(`Beard with ID ${id} not found`);
    }
    return beard;
  }

  async update(id: string, updateBeardDto: UpdateBeardDto): Promise<Beard> {
    const beard = await this.findById(id);
    Object.assign(beard, updateBeardDto);
    return this.beardRepository.save(beard);
  }

  async delete(id: string): Promise<void> {
    const result = await this.beardRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException(`Beard with ID ${id} not found`);
    }
  }

  async incrementTrialCount(id: string): Promise<void> {
    await this.beardRepository.increment({ id }, 'trialCount', 1);
  }

  async findByFaceShape(faceShape: string): Promise<Beard[]> {
    return this.beardRepository
      .createQueryBuilder('beard')
      .where("beard.metadata->>'faceShapeCompatibility' ILIKE :faceShape", {
        faceShape: `%${faceShape}%`,
      })
      .andWhere('beard.isActive = :isActive', { isActive: true })
      .orderBy('beard.trialCount', 'DESC')
      .limit(10)
      .getMany();
  }

  async getByStyle(style: string): Promise<Beard[]> {
    return this.beardRepository.find({
      where: { style, isActive: true },
      order: { trialCount: 'DESC' },
    });
  }

  async getPopular(limit: number = 5): Promise<Beard[]> {
    return this.beardRepository.find({
      where: { isActive: true },
      order: { trialCount: 'DESC' },
      take: limit,
    });
  }
}
