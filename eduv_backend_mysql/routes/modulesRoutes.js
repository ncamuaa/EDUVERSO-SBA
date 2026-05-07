const express = require('express');
const { getModules, getModuleById } = require('../controllers/modulesController');

const router = express.Router();

// TEMP: no auth yet (for testing)
router.get('/', getModules);
router.get('/:id', getModuleById);

module.exports = router;