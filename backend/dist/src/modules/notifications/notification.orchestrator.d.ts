export type AppointmentNotificationEvent = 'APPT_CREATED' | 'APPT_CONFIRMED' | 'APPT_CLIENT_ARRIVED' | 'APPT_CANCELLED' | 'APPT_DECLINED' | 'APPT_COMPLETED' | 'APPT_SHIFTED' | 'APPT_REMINDER_1H10_CLIENT' | 'APPT_REMINDER_1H10_BARBER' | 'APPT_CLIENT_LOCK_LT_1H' | 'APPT_REMINDER_LT_1H_BARBER' | 'APPT_REMINDER_30M' | 'APPT_BARBER_REMINDER_30M' | 'APPT_PATRON_EMPLOYEE_REMINDER_30M' | 'APPT_REMINDER_15M' | 'APPT_REMINDER_1M' | 'APPT_BARBER_ARRIVAL_CHECK' | 'APPT_CLIENT_START_NOW' | 'APPT_BARBER_COMPLETION_CHECK';
export type AppointmentEventContext = {
    appointmentId: number;
    appointmentDate?: Date | undefined;
    status?: string | undefined;
    clientId?: number | undefined;
    barberId?: number | null | undefined;
    patronId?: number | undefined;
    clientName?: string | undefined;
    actorUserId?: number | undefined;
    actorRole?: 'CLIENT' | 'EMPLOYEE' | 'PATRON' | 'ADMIN' | undefined;
    deeplink?: string | undefined;
    targetUserIds?: number[] | undefined;
    extraData?: Record<string, string | number | boolean | undefined> | undefined;
    dedupeWindowMs?: number | undefined;
};
type RefreshPayload = {
    appointmentId: number;
    status?: string | undefined;
    userIds: number[];
    deeplink?: string | undefined;
    pushTitle?: string | undefined;
    pushBody?: string | undefined;
    pushUserIds?: number[] | undefined;
};
export declare const emitAppointmentEvent: (event: AppointmentNotificationEvent, ctx: AppointmentEventContext) => Promise<void>;
export declare const broadcastAppointmentRefresh: (payload: RefreshPayload) => Promise<void>;
export {};
//# sourceMappingURL=notification.orchestrator.d.ts.map