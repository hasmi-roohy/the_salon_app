import { Repository } from 'typeorm';
import { Hairstyle } from '../entities/hairstyle.entity';
import { CreateHairstyleDto, UpdateHairstyleDto, GetHairstylesDto } from '../dto';
export declare class HairstyleService {
    private hairstyleRepository;
    constructor(hairstyleRepository: Repository<Hairstyle>);
    create(createHairstyleDto: CreateHairstyleDto): Promise<Hairstyle>;
    findAll(query: GetHairstylesDto): Promise<Hairstyle[]>;
    findById(id: string): Promise<Hairstyle>;
    update(id: string, updateHairstyleDto: UpdateHairstyleDto): Promise<Hairstyle>;
    delete(id: string): Promise<void>;
    incrementTrialCount(id: string): Promise<void>;
    findByFaceShape(faceShape: string): Promise<Hairstyle[]>;
    getPopular(limit?: number): Promise<Hairstyle[]>;
}
