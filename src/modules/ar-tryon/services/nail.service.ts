import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Nail } from '../entities/nail.entity';
import { CreateNailDto, UpdateNailDto, GetNailsDto } from '../dto';

@Injectable()
export class NailService {
  constructor(
    @InjectRepository(Nail)
    private nailRepository: Repository<Nail>,
  ) {}

  async create(createNailDto: CreateNailDto): Promise<Nail> {
    const nail = this.nailRepository.create(createNailDto);
    return this.nailRepository.save(nail);
  }

  async findAll(query: GetNailsDto): Promise<Nail[]> {
    const queryBuilder = this.nailRepository.createQueryBuilder('nail');

    if (query.design) {
      queryBuilder.andWhere('nail.design = :design', { design: query.design });
    }

    if (query.nailShape) {
      queryBuilder.andWhere("nail.metadata->>'nailShape' = :nailShape", {
        nailShape: query.nailShape,
      });
    }

    queryBuilder.andWhere('nail.isActive = :isActive', { isActive: true });
    queryBuilder.orderBy('nail.trialCount', 'DESC');

    const limit = parseInt(query.limit || '10', 10);
    queryBuilder.limit(limit);

    return queryBuilder.getMany();
  }

  async findById(id: string): Promise<Nail> {
    const nail = await this.nailRepository.findOne({ where: { id } });
    if (!nail) {
      throw new NotFoundException(`Nail with ID ${id} not found`);
    }
    return nail;
  }

  async update(id: string, updateNailDto: UpdateNailDto): Promise<Nail> {
    const nail = await this.findById(id);
    Object.assign(nail, updateNailDto);
    return this.nailRepository.save(nail);
  }

  async delete(id: string): Promise<void> {
    const result = await this.nailRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException(`Nail with ID ${id} not found`);
    }
  }

  async incrementTrialCount(id: string): Promise<void> {
    await this.nailRepository.increment({ id }, 'trialCount', 1);
  }

  async findByDesign(design: string): Promise<Nail[]> {
    return this.nailRepository.find({
      where: { design, isActive: true },
      order: { trialCount: 'DESC' },
    });
  }

  async findByNailShape(nailShape: string): Promise<Nail[]> {
    return this.nailRepository
      .createQueryBuilder('nail')
      .where("nail.metadata->>'nailShape' = :nailShape", { nailShape })
      .andWhere('nail.isActive = :isActive', { isActive: true })
      .orderBy('nail.trialCount', 'DESC')
      .getMany();
  }

  async getPopular(limit: number = 5): Promise<Nail[]> {
    return this.nailRepository.find({
      where: { isActive: true },
      order: { trialCount: 'DESC' },
      take: limit,
    });
  }
}
