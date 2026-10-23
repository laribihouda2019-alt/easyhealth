const db = require('../config/db');

async function getInventory(pharmacyId) {
    const { rows } = await db.query(
        'SELECT * FROM public.pharmacy_items WHERE pharmacy_id = $1 ORDER BY med_name ASC', 
        [pharmacyId]
    );
    return rows;
}

async function addInventoryItem({ pharmacyId, medName, price }) {
    const { rows } = await db.query(
        'INSERT INTO public.pharmacy_items (pharmacy_id, med_name, price) VALUES ($1, $2, $3) RETURNING *',
        [pharmacyId, medName, price]
    );
    return rows[0];
}

async function updateInventoryItemStatus(itemId, isAvailable) {
     const { rows } = await db.query(
         'UPDATE public.pharmacy_items SET is_available = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
         [isAvailable, itemId]
     );
     return rows[0];
}

module.exports = {
   getInventory,
   addInventoryItem,
   updateInventoryItemStatus
};

