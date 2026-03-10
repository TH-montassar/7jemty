import { deleteUserAdmin, getAllUsersAdmin, updateUserAdmin } from './auth.service.js';
const parseId = (rawId) => {
    const id = Number.parseInt(rawId, 10);
    if (Number.isNaN(id)) {
        throw new Error('ID utilisateur invalide');
    }
    return id;
};
export const getAllUsersAdminHandler = async (req, res) => {
    try {
        const users = await getAllUsersAdmin();
        res.status(200).json({ success: true, data: users });
    }
    catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
export const updateUserAdminHandler = async (req, res) => {
    try {
        const id = parseId(req.params.id);
        const { fullName, phoneNumber, role, isVerified, isBlacklistedBySystem, profile } = req.body;
        const updatedUser = await updateUserAdmin(id, { fullName, phoneNumber, role, isVerified, isBlacklistedBySystem, profile });
        res.status(200).json({ success: true, data: updatedUser });
    }
    catch (error) {
        const status = error.message?.includes('invalide') ? 400 : 500;
        res.status(status).json({ success: false, message: error.message });
    }
};
export const deleteUserAdminHandler = async (req, res) => {
    try {
        const id = parseId(req.params.id);
        await deleteUserAdmin(id);
        res.status(200).json({ success: true, message: 'User deleted' });
    }
    catch (error) {
        const status = error.message?.includes('invalide') ? 400 : 500;
        res.status(status).json({ success: false, message: error.message });
    }
};
//# sourceMappingURL=auth.admin.controller.js.map