/*
 * Copyright (c) 2024 HPMicro
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 */

#include <stdio.h>

#include "board.h"

int main(void) {
    board_init();

    while (1) {
        printf("Hello world!\n");
        // board_delay_ms(1000);
    }
    return 0;
}
