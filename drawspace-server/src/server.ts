import 'reflect-metadata';
import { createConnection } from 'typeorm';
import logger from 'morgan';
import express from 'express';
import compression from 'compression';
import helmet from 'helmet';
import hpp from 'hpp';
import chalk from 'chalk';

import routes from './api';
import connectionOptions from '../ormconfig';

createConnection(connectionOptions)
    .then(() => {
        const app = express();

        // Use helmet to secure Express with various HTTP headers
        app.use(helmet());
        // Prevent HTTP parameter pollution
        app.use(hpp());
        // Compress all requests
        app.use(compression());

        // Use for http request debug (show errors only)
        app.use(logger('dev', { skip: (_, res) => res.statusCode < 400 }));

        // TODO: Set up CORS properly.
        app.use('*', (_, res, next) => {
            res.setHeader('Access-Control-Allow-Origin', '*');
            res.setHeader('Access-Control-Allow-Methods', '*');
            res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
            next();
        });

        // Mount routes.
        app.use(routes);

        const { NODE_HOST, PORT } = process.env;
        app.listen(Number(PORT), NODE_HOST, (err) => {
            if (err) {
                console.error(chalk.red(`==> 😭  OMG!!! ${err}`));
            }

            const url = `http://${NODE_HOST}:${PORT}`;
            console.info(chalk.green(`==> 🌎  Listening at ${url}`));
        });
    })
    .catch((error: Error) => console.log(error));
