import 'dotenv/config';
import { PrismaClient } from '../../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
export declare const prisma: PrismaClient<{
    adapter: PrismaPg;
    log: "error"[];
}, "error", import("../../generated/prisma/runtime/client.js").DefaultArgs>;
//# sourceMappingURL=db.d.ts.map