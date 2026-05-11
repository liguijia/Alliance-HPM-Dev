/*
 * Main Entry Point
 *
 * Copyright (c) 2024 HPMicro
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * This file bridges Board/Driver initialization with App logic.
 */

#include <stdio.h>

#include "board.h"

/* Driver registration */
extern void hpm_pwm_driver_register(void);
extern void hpm_uart_driver_register(void);

/* Application entry */
extern void app_init(void);
extern void app_run(void);

/* ============================================================================
 * Main
 * ============================================================================ */

int main(void)
{
    /* 1. Board-level initialization (clocks, pins) */
    board_init();

    /* 2. Register hardware drivers */
    hpm_pwm_driver_register();
    hpm_uart_driver_register();

    /* 3. Initialize application */
    app_init();

    /* 4. Main loop */
    while (1) {
        app_run();
    }

    return 0;
}
