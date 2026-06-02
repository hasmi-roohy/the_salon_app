import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Hairstyle } from './hairstyle.entity';
import { Beard } from './beard.entity';
import { Nail } from './nail.entity';

@Entity('try_on_results')
export class TryOnResult {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string; // Reference to User entity (if exists)

  @Column({ type: 'uuid', nullable: true })
  hairstyleId: string;

  @ManyToOne(() => Hairstyle, (hairstyle) => hairstyle.tryOnResults, {
    nullable: true,
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'hairstyleId' })
  hairstyle: Hairstyle;

  @Column({ type: 'uuid', nullable: true })
  beardId: string;

  @ManyToOne(() => Beard, (beard) => beard.tryOnResults, {
    nullable: true,
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'beardId' })
  beard: Beard;

  @Column({ type: 'uuid', nullable: true })
  nailId: string;

  @ManyToOne(() => Nail, (nail) => nail.tryOnResults, {
    nullable: true,
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'nailId' })
  nail: Nail;

  @Column({ type: 'varchar', length: 500, nullable: true })
  originalImageUrl: string; // Original photo before AR

  @Column({ type: 'varchar', length: 500, nullable: true })
  resultImageUrl: string; // AR rendered image

  @Column({ type: 'json', nullable: true })
  metadata: {
    deviceType?: string; // iOS, Android, Web
    processingTime?: number; // ms
    modelVersions?: {
      hairstyleVersion?: string;
      beardVersion?: string;
      nailVersion?: string;
    };
  };

  @Column({ type: 'boolean', default: false })
  isShared: boolean;

  @Column({ type: 'text', nullable: true })
  shareToken: string; // For public sharing

  @CreateDateColumn()
  createdAt: Date;
}
