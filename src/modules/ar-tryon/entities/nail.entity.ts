import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { TryOnResult } from './try-on-result.entity';

@Entity('nails')
export class Nail {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'varchar', length: 100 })
  design: string; // French, Gel, Acrylic, Ombre, Glitter, etc.

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'varchar', length: 500, nullable: true })
  imageUrl: string;

  @Column({ type: 'varchar', length: 500 })
  overlayPath: string; // PNG with transparency

  @Column({ type: 'json', nullable: true })
  colorPalette: {
    primary?: string; // Hex color
    secondary?: string;
    accent?: string;
  };

  @Column({ type: 'json', nullable: true })
  metadata: {
    nailShape?: string; // square, round, almond, oval
    length?: string; // short, medium, long
  };

  @Column({ type: 'boolean', default: true })
  isActive: boolean;

  @Column({ type: 'integer', default: 0 })
  trialCount: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => TryOnResult, (result) => result.nail)
  tryOnResults: TryOnResult[];
}
