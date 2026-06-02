import { Repository } from 'typeorm';
import { Nail } from '../entities/nail.entity';
import { CreateNailDto, UpdateNailDto, GetNailsDto } from '../dto';
export declare class NailService {
    private nailRepository;
    constructor(nailRepository: Repository<Nail>);
    create(createNailDto: CreateNailDto): Promise<Nail>;
    findAll(query: GetNailsDto): Promise<Nail[]>;
    findById(id: string): Promise<Nail>;
    update(id: string, updateNailDto: UpdateNailDto): Promise<Nail>;
    delete(id: string): Promise<void>;
    incrementTrialCount(id: string): Promise<void>;
    findByDesign(design: string): Promise<Nail[]>;
    findByNailShape(nailShape: string): Promise<Nail[]>;
    getPopular(limit?: number): Promise<Nail[]>;
}
