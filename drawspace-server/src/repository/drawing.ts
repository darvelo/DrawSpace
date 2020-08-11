import { EntityRepository, Repository } from 'typeorm';
import Drawing from '../entity/drawing';

@EntityRepository(Drawing)
export default class DrawingRepository extends Repository<Drawing> {
    deleteAll(): Promise<any> {
        return this.query('DELETE FROM drawings');
    }
}
