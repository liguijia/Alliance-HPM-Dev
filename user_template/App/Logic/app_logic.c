/*
 * Application Logic - LED Blink Example
 *
 * Copyright (c) 2024 HPMicro
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * NOTE: This file must NOT include any hpm_* headers!
 *       Only use Interface headers (intf_*.h) and standard C.
 */

#include <stdint.h>
#include <stdbool.h>

/* Use interfaces, not hardware directly */
#include "intf_pwm.h"
#include "intf_uart.h"

/* ============================================================================
 * Application Configuration
 * ============================================================================ */

#define LED_PWM_CHANNEL    0
#define LED_BLINK_PERIOD   500  /* ms */

/* ============================================================================
 * Application State
 * ============================================================================ */

static struct {
    uint8_t  duty;
    bool     increasing;
    uint32_t last_tick;
} app_state = {
    .duty = 0,
    .increasing = true,
    .last_tick = 0,
};

/* ============================================================================
 * Application Logic
 * ============================================================================ */

/**
 * @brief Initialize application
 *
 * This function uses only interface APIs, no hardware knowledge.
 */
void app_init(void)
{
    /* Configure PWM for LED */
    intf_pwm_cfg_t pwm_cfg = {
        .frequency_hz = 1000,
        .duty_percent = 0,
        .polarity     = true,
    };

    intf_pwm_init(LED_PWM_CHANNEL, &pwm_cfg);
    intf_pwm_start(LED_PWM_CHANNEL);

    /* Send startup message */
    const char *msg = "Application started\r\n";
    intf_uart_transmit(0, (const uint8_t *)msg, 21, 1000);
}

/**
 * @brief Application main loop
 *
 * This function contains pure business logic.
 * No hardware-specific code allowed here.
 */
void app_run(void)
{
    /* Simple breathing LED effect */
    if (app_state.increasing) {
        app_state.duty += 5;
        if (app_state.duty >= 100) {
            app_state.increasing = false;
        }
    } else {
        app_state.duty -= 5;
        if (app_state.duty <= 0) {
            app_state.increasing = true;
        }
    }

    intf_pwm_set_duty(LED_PWM_CHANNEL, app_state.duty);
}
