const express = require('express');
const { getModules, getModuleById, updateModule } = require('../controllers/modulesController');

const router = express.Router();

router.get('/',    getModules);
router.get('/:id', getModuleById);
router.put('/:id', updateModule);

module.exports = router;
