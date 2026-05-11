/*
 * I2C Interface - C11 Abstract Interface
 *
 * Copyright (c) 2024 HPMicro
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef _INTF_I2C_H
#define _INTF_I2C_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uint8_t intf_i2c_port_t;

typedef struct {
    uint32_t clock_hz;
    uint16_t dev_addr;
} intf_i2c_cfg_t;

typedef struct {
    int  (*init)(intf_i2c_port_t port, const intf_i2c_cfg_t *cfg);
    int  (*master_transmit)(intf_i2c_port_t port, uint16_t addr, const uint8_t *data, size_t len, uint32_t timeout_ms);
    int  (*master_receive)(intf_i2c_port_t port, uint16_t addr, uint8_t *data, size_t len, uint32_t timeout_ms);
    int  (*write_reg)(intf_i2c_port_t port, uint16_t addr, uint16_t reg, uint8_t reg_size, const uint8_t *data, size_t len);
    int  (*read_reg)(intf_i2c_port_t port, uint16_t addr, uint16_t reg, uint8_t reg_size, uint8_t *data, size_t len);
    void (*deinit)(intf_i2c_port_t port);
} intf_i2c_ops_t;

int intf_i2c_register(const intf_i2c_ops_t *ops);
int intf_i2c_init(intf_i2c_port_t port, const intf_i2c_cfg_t *cfg);
int intf_i2c_master_transmit(intf_i2c_port_t port, uint16_t addr, const uint8_t *data, size_t len, uint32_t timeout_ms);
int intf_i2c_master_receive(intf_i2c_port_t port, uint16_t addr, uint8_t *data, size_t len, uint32_t timeout_ms);

#ifdef __cplusplus
}
#endif

#endif /* _INTF_I2C_H */
