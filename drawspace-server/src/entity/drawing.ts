import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('drawings')
export default class Drawing {
    @PrimaryGeneratedColumn()
    id: number;

    @Column('date')
    createdAt: string;

    @Column('double')
    drawingDurationSeconds: number;

    @Column('double')
    width: number;

    @Column('double')
    height: number;

    @Column()
    imageId: string;

    @Column()
    imageUrl: string;

    @Column('json')
    steps: string;
}
