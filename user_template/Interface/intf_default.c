/*
 * Interface Layer - Default Implementation (Stub)
 *
 * Copyright (c) 2024 HPMicro
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * This file provides default stub implementations for interface APIs.
 * When a driver registers, it replaces these stubs.
 */

#include "intf_pwm.h"
#include "intf_adc.h"
#include "intf_uart.h"
#include "intf_spi.h"
#include "intf_i2c.h"

#include <stddef.h>

/* ============================================================================
 * PWM Interface
 * ============================================================================ */

static const intf_pwm_ops_t *pwm_ops = NULL;

int intf_pwm_register(const intf_pwm_ops_t *ops)
{
    pwm_ops = ops;
    return 0;
}

int intf_pwm_init(intf_pwm_ch_t ch, const intf_pwm_cfg_t *cfg)
{
    if (pwm_ops && pwm_ops->init) return pwm_ops->init(ch, cfg);
    return -1;
}

int intf_pwm_set_duty(intf_pwm_ch_t ch, uint8_t duty_percent)
{
    if (pwm_ops && pwm_ops->set_duty) return pwm_ops->set_duty(ch, duty_percent);
    return -1;
}

int intf_pwm_start(intf_pwm_ch_t ch)
{
    if (pwm_ops && pwm_ops->start) return pwm_ops->start(ch);
    return -1;
}

int intf_pwm_stop(intf_pwm_ch_t ch)
{
    if (pwm_ops && pwm_ops->stop) return pwm_ops->stop(ch);
    return -1;
}

/* ============================================================================
 * UART Interface
 * ============================================================================ */

static const intf_uart_ops_t *uart_ops = NULL;

int intf_uart_register(const intf_uart_ops_t *ops)
{
    uart_ops = ops;
    return 0;
}

int intf_uart_init(intf_uart_port_t port, const intf_uart_cfg_t *cfg)
{
    if (uart_ops && uart_ops->init) return uart_ops->init(port, cfg);
    return -1;
}

int intf_uart_transmit(intf_uart_port_t port, const uint8_t *data, size_t len, uint32_t timeout_ms)
{
    if (uart_ops && uart_ops->transmit) return uart_ops->transmit(port, data, len, timeout_ms);
    return -1;
}

int intf_uart_receive(intf_uart_port_t port, uint8_t *data, size_t len, uint32_t timeout_ms)
{
    if (uart_ops && uart_ops->receive) return uart_ops->receive(port, data, len, timeout_ms);
    return -1;
}

int intf_uart_register_rx_callback(intf_uart_port_t port, intf_uart_rx_cb_t cb)
{
    if (uart_ops && uart_ops->register_rx_callback) return uart_ops->register_rx_callback(port, cb);
    return -1;
}
