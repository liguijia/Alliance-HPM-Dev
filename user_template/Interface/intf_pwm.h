/*
 * PWM Interface - C11 Abstract Interface
 *
 * Copyright (c) 2024 HPMicro
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * This interface defines a hardware-independent PWM API.
 * Implementations must NOT expose hpm_sdk types.
 */

#ifndef _INTF_PWM_H
#define _INTF_PWM_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ============================================================================
 * Types
 * ============================================================================ */

typedef uint8_t intf_pwm_ch_t;

typedef struct {
    uint32_t frequency_hz;
    uint8_t  duty_percent;
    bool     polarity;
} intf_pwm_cfg_t;

typedef struct {
    int  (*init)(intf_pwm_ch_t ch, const intf_pwm_cfg_t *cfg);
    int  (*set_duty)(intf_pwm_ch_t ch, uint8_t duty_percent);
    int  (*set_frequency)(intf_pwm_ch_t ch, uint32_t freq_hz);
    int  (*start)(intf_pwm_ch_t ch);
    int  (*stop)(intf_pwm_ch_t ch);
    void (*deinit)(intf_pwm_ch_t ch);
} intf_pwm_ops_t;

/* ============================================================================
 * API
 * ============================================================================ */

/**
 * @brief Register PWM implementation
 * @param ops Pointer to operations structure
 * @return 0 on success, negative on error
 */
int intf_pwm_register(const intf_pwm_ops_t *ops);
int intf_pwm_init(intf_pwm_ch_t ch, const intf_pwm_cfg_t *cfg);
int intf_pwm_set_duty(intf_pwm_ch_t ch, uint8_t duty_percent);
int intf_pwm_start(intf_pwm_ch_t ch);
int intf_pwm_stop(intf_pwm_ch_t ch);

#ifdef __cplusplus
}
#endif

#endif /* _INTF_PWM_H */
