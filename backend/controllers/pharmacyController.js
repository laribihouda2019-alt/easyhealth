const pharmacyService = require('../services/pharmacyService');

async function getInventory(req, res, next) {
    try {
        const { pharmacyId } = req.params;
        const inventory = await pharmacyService.getInventory(pharmacyId);
        res.json(inventory);
    } catch(err) {
        next(err);
    }
}

async function addInventoryItem(req, res, next) {
    try {
        const { medName, price } = req.body;
        
        if (req.user.role !== 'pharmacy') {
            return res.status(403).json({ error: 'Accès réservé aux pharmacies' });
        }
        
        const item = await pharmacyService.addInventoryItem({ 
            pharmacyId: req.user.id, 
            medName, 
            price 
        });
        
        res.status(201).json(item);
    } catch(err) {
        next(err);
    }
}

async function updateInventoryItem(req, res, next) {
    try {
        const { itemId } = req.params;
        const { isAvailable } = req.body;
        
        if (req.user.role !== 'pharmacy') {
            return res.status(403).json({ error: 'Accès réservé aux pharmacies' });
        }
        
        const updatedItem = await pharmacyService.updateInventoryItemStatus(itemId, isAvailable);
        res.json(updatedItem);
    } catch(err) {
         next(err);
    }
}

module.exports = {
    getInventory,
    addInventoryItem,
    updateInventoryItem
};
