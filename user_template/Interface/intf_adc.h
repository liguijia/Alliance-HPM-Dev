/*
 * ADC Interface - C11 Abstract Interface
 *
 * Copyright (c) 2024 HPMicro
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef _INTF_ADC_H
#define _INTF_ADC_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ============================================================================
 * Types
 * ============================================================================ */

typedef uint8_t intf_adc_ch_t;

typedef struct {
    uint32_t sample_rate_hz;
    uint8_t  resolution_bits;
    bool     continuous;
} intf_adc_cfg_t;

typedef struct {
    int  (*init)(intf_adc_ch_t ch, const intf_adc_cfg_t *cfg);
    int  (*read)(intf_adc_ch_t ch, uint16_t *value);
    int  (*read_voltage)(intf_adc_ch_t ch, float *voltage_mv);
    int  (*start)(intf_adc_ch_t ch);
    int  (*stop)(intf_adc_ch_t ch);
    void (*deinit)(intf_adc_ch_t ch);
} intf_adc_ops_t;

/* ============================================================================
 * API
 * ============================================================================ */

int intf_adc_register(const intf_adc_ops_t *ops);
int intf_adc_init(intf_adc_ch_t ch, const intf_adc_cfg_t *cfg);
int intf_adc_read(intf_adc_ch_t ch, uint16_t *value);
int intf_adc_read_voltage(intf_adc_ch_t ch, float *voltage_mv);
int intf_adc_start(intf_adc_ch_t ch);
int intf_adc_stop(intf_adc_ch_t ch);

#ifdef __cplusplus
}
#endif

#endif /* _INTF_ADC_H */
