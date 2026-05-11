/*
 * SPI Interface - C11 Abstract Interface
 *
 * Copyright (c) 2024 HPMicro
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef _INTF_SPI_H
#define _INTF_SPI_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uint8_t intf_spi_port_t;

typedef enum {
    INTF_SPI_MODE_0 = 0,
    INTF_SPI_MODE_1,
    INTF_SPI_MODE_2,
    INTF_SPI_MODE_3,
} intf_spi_mode_t;

typedef struct {
    intf_spi_mode_t mode;
    uint32_t        clock_hz;
    uint8_t         data_bits;
    bool            msb_first;
} intf_spi_cfg_t;

typedef struct {
    int  (*init)(intf_spi_port_t port, const intf_spi_cfg_t *cfg);
    int  (*transfer)(intf_spi_port_t port, const uint8_t *tx, uint8_t *rx, size_t len, uint32_t timeout_ms);
    int  (*transmit)(intf_spi_port_t port, const uint8_t *data, size_t len, uint32_t timeout_ms);
    int  (*receive)(intf_spi_port_t port, uint8_t *data, size_t len, uint32_t timeout_ms);
    void (*deinit)(intf_spi_port_t port);
} intf_spi_ops_t;

int intf_spi_register(const intf_spi_ops_t *ops);
int intf_spi_init(intf_spi_port_t port, const intf_spi_cfg_t *cfg);
int intf_spi_transfer(intf_spi_port_t port, const uint8_t *tx, uint8_t *rx, size_t len, uint32_t timeout_ms);

#ifdef __cplusplus
}
#endif

#endif /* _INTF_SPI_H */
