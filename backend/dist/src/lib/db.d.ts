import 'dotenv/config';
import { PrismaClient } from '../../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
export declare const prisma: PrismaClient<{
    adapter: PrismaPg;
    log: ("info" | "query" | "warn" | "error")[];
}, "info" | "query" | "warn" | "error", import("../../generated/prisma/runtime/client.js").DefaultArgs>;
//# sourceMappingURL=db.d.ts.map