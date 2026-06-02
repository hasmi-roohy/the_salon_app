import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('user_ar_preferences')
export class UserArPreference {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', unique: true })
  userId: string;

  @Column({ type: 'json', nullable: true })
  faceAnalysis: {
    faceShape?: string; // oval, round, square, heart, oblong
    skinTone?: string;
    faceWidth?: number;
    faceLength?: number;
    jawlineWidth?: number;
  };

  @Column('uuid', { array: true, default: [] })
  preferredHairstyles: string[]; // IDs of favorite hairstyles

  @Column('uuid', { array: true, default: [] })
  preferredBeards: string[];

  @Column('uuid', { array: true, default: [] })
  preferredNails: string[];

  @Column({ type: 'json', nullable: true })
  stylePreferences: {
    traditional?: boolean;
    modern?: boolean;
    bold?: boolean;
    natural?: boolean;
  };

  @Column({ type: 'integer', default: 0 })
  totalTrials: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
