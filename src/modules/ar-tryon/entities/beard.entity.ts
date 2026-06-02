import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { TryOnResult } from './try-on-result.entity';

@Entity('beards')
export class Beard {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'varchar', length: 100 })
  style: string; // Full, Goatee, Van Dyke, Stubble, Mustache, etc.

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'varchar', length: 500, nullable: true })
  imageUrl: string;

  @Column({ type: 'varchar', length: 500 })
  modelPath: string;

  @Column({ type: 'json', nullable: true })
  metadata: {
    faceShapeCompatibility?: string[];
    density?: string; // light, medium, heavy
    length?: string;
  };

  @Column({ type: 'boolean', default: true })
  isActive: boolean;

  @Column({ type: 'integer', default: 0 })
  trialCount: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => TryOnResult, (result) => result.beard)
  tryOnResults: TryOnResult[];
}
