import {MigrationInterface, QueryRunner} from "typeorm";

export class Initial1597167789283 implements MigrationInterface {
    name = 'Initial1597167789283'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query("CREATE TABLE `drawings` (`id` int NOT NULL AUTO_INCREMENT, `createdAt` date NOT NULL, `drawingDurationSeconds` double NOT NULL, `width` double NOT NULL, `height` double NOT NULL, `imageId` varchar(255) NOT NULL, `imageUrl` varchar(255) NOT NULL, `steps` json NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB");
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query("DROP TABLE `drawings`");
    }

}
