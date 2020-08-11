import {MigrationInterface, QueryRunner} from "typeorm";

export class DateIntoString1597171942931 implements MigrationInterface {
    name = 'DateIntoString1597171942931'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query("ALTER TABLE `drawings` DROP COLUMN `createdAt`");
        await queryRunner.query("ALTER TABLE `drawings` ADD `createdAt` varchar(255) NOT NULL");
        await queryRunner.query("ALTER TABLE `drawings` CHANGE `drawingDurationSeconds` `drawingDurationSeconds` double NOT NULL");
        await queryRunner.query("ALTER TABLE `drawings` CHANGE `width` `width` double NOT NULL");
        await queryRunner.query("ALTER TABLE `drawings` CHANGE `height` `height` double NOT NULL");
        await queryRunner.query("ALTER TABLE `drawings` CHANGE `imageId` `imageId` varchar(255) NULL DEFAULT NULL");
        await queryRunner.query("ALTER TABLE `drawings` CHANGE `imageUrl` `imageUrl` varchar(255) NULL DEFAULT NULL");
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query("ALTER TABLE `drawings` CHANGE `imageUrl` `imageUrl` varchar(255) NULL");
        await queryRunner.query("ALTER TABLE `drawings` CHANGE `imageId` `imageId` varchar(255) NULL");
        await queryRunner.query("ALTER TABLE `drawings` CHANGE `height` `height` double(22) NOT NULL");
        await queryRunner.query("ALTER TABLE `drawings` CHANGE `width` `width` double(22) NOT NULL");
        await queryRunner.query("ALTER TABLE `drawings` CHANGE `drawingDurationSeconds` `drawingDurationSeconds` double(22) NOT NULL");
        await queryRunner.query("ALTER TABLE `drawings` DROP COLUMN `createdAt`");
        await queryRunner.query("ALTER TABLE `drawings` ADD `createdAt` date NOT NULL");
    }

}
