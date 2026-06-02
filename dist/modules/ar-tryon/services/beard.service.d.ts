import { Repository } from 'typeorm';
import { Beard } from '../entities/beard.entity';
import { CreateBeardDto, UpdateBeardDto, GetBeardsDto } from '../dto';
export declare class BeardService {
    private beardRepository;
    constructor(beardRepository: Repository<Beard>);
    create(createBeardDto: CreateBeardDto): Promise<Beard>;
    findAll(query: GetBeardsDto): Promise<Beard[]>;
    findById(id: string): Promise<Beard>;
    update(id: string, updateBeardDto: UpdateBeardDto): Promise<Beard>;
    delete(id: string): Promise<void>;
    incrementTrialCount(id: string): Promise<void>;
    findByFaceShape(faceShape: string): Promise<Beard[]>;
    getByStyle(style: string): Promise<Beard[]>;
    getPopular(limit?: number): Promise<Beard[]>;
}
