import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { TryOnResult } from './try-on-result.entity';

@Entity('hairstyles')
export class Hairstyle {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'varchar', length: 500, nullable: true })
  imageUrl: string;

  @Column({ type: 'varchar', length: 500 })
  modelPath: string;

  @Column({ type: 'varchar', length: 100 })
  category: string;

  @Column({ type: 'json', nullable: true })
  metadata: {
    faceShapeCompatibility?: string[];
    hairLength?: string;
    hairTexture?: string;
  };

  @Column({ type: 'boolean', default: true })
  isActive: boolean;

  @Column({ type: 'integer', default: 0 })
  trialCount: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => TryOnResult, (result) => result.hairstyle)
  tryOnResults: TryOnResult[];
}
