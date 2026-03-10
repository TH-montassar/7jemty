import { Router } from 'express';
import { deleteUserAdminHandler, getAllUsersAdminHandler, updateUserAdminHandler } from './auth.admin.controller.js';
const router = Router();
router.get('/users', getAllUsersAdminHandler);
router.patch('/users/:id', updateUserAdminHandler);
router.delete('/users/:id', deleteUserAdminHandler);
export default router;
//# sourceMappingURL=auth.admin.routes.js.map