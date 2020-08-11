import express from 'express';
import { getCustomRepository } from 'typeorm';
import * as bodyParser from 'body-parser';

import type { Request, Response } from 'express';

import DrawingRepository from './repository/drawing';

const api = express.Router();
api.use(bodyParser.json());

// Get drawings.
api.get('/drawings', async (_: Request, res: Response) => {
    const drawingRepository = getCustomRepository(DrawingRepository);
    const drawing = await drawingRepository.find();
    res.json(drawing);
});

// Get drawing.
api.get('/drawings/:id', async (req: Request, res: Response) => {
    const { id } = req.params;
    const drawingRepository = getCustomRepository(DrawingRepository);
    const drawing = await drawingRepository.findOne(id);
    res.json(drawing);
});

// Create drawing.
api.post('/drawings', async (req: Request, res: Response) => {
    const drawingRepository = getCustomRepository(DrawingRepository);
    const {
        createdAt,
        drawingDurationSeconds,
        width,
        height,
        imageId,
        imageUrl,
        steps,
    } = req.body;

    console.log('Attempting to create drawing with:', req.body);

    const drawing = drawingRepository.create({
        createdAt,
        drawingDurationSeconds,
        width,
        height,
        imageId,
        imageUrl,
        steps,
    });

    console.log('Drawing created: ', drawing);

    try {
        await drawingRepository.save(drawing);
        console.log('Drawing saved', drawing);
        res.json(drawing);
    } catch (error) {
        console.error('Drawing save failed.');
        res.sendStatus(500);
    }
});

// Update drawing.
api.put('/drawings/:id', async (req: Request, res: Response) => {
    const drawingRepository = getCustomRepository(DrawingRepository);
    const { id } = req.params;
    const {
        createdAt,
        drawingDurationSeconds,
        width,
        height,
        imageId,
        imageUrl,
        steps,
    } = req.body;

    await drawingRepository.update(id, {
        createdAt,
        drawingDurationSeconds,
        width,
        height,
        imageId,
        imageUrl,
        steps,
    });

    const drawing = await drawingRepository.findOne(id);
    res.json(drawing);
});

export default api;
