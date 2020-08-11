import { ConnectionOptions } from 'typeorm';

const __CLI__ = process.env.NODE_ENV === 'cli';
const __DEV__ = __CLI__ || process.env.NODE_ENV === 'development';

const connectionOptions: ConnectionOptions = {
    type: 'mysql',
    host: __CLI__ ? 'localhost' : process.env.DB_HOST,
    port: __CLI__ ? 5555 : Number(process.env.DB_PORT),
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    synchronize: false,
    logging: __DEV__,
    entities: ['src/entity/**/*.ts'],
    migrations: ['src/migration/**/*.ts'],
    subscribers: ['src/subscriber/**/*.ts'],
    cli: {
        entitiesDir: 'src/entity',
        migrationsDir: 'src/migration',
        subscribersDir: 'src/subscriber',
    },
};

module.exports = connectionOptions;
export default connectionOptions;
