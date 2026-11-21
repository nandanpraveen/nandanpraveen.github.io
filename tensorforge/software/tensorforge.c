#include "tensorforge.h"
#include <string.h>

enum {
    CONTROL = 0, STATUS = 4, M = 8, N = 12, K = 16, CYCLES = 20, MODE = 24,
    BIAS = 0x100, A_BASE = 0x1000, B_BASE = 0x2000, C_BASE = 0x3000,
    BUSY = 1, DONE = 2, ERROR = 4, START_AND_CLEAR = 3, RELU = 32
};

static uint16_t offset(unsigned base, unsigned stride, unsigned row, unsigned col) {
    return (uint16_t)(base + 4 * (stride * row + col));
}

tf_status tf_gemm(const tf_bus *bus, unsigned m, unsigned n, unsigned k,
                  const int8_t *a, const int8_t *b, const int32_t *bias,
                  unsigned shift, int32_t *c, unsigned poll_limit, uint32_t *cycles) {
    if (!bus || !bus->read || !bus->write || !a || !b || !c || !poll_limit ||
        !m || !n || !k || bus->stride > 32 || m > bus->stride ||
        n > bus->stride || k > bus->stride || shift > 31)
        return TF_INVALID;

    void *context = bus->context;
    if (bus->read(context, STATUS) & BUSY)
        return TF_BUSY;

    bus->write(context, M, m);
    bus->write(context, N, n);
    bus->write(context, K, k);
    bus->write(context, MODE, bias ? RELU | shift : 0);
    if (bias)
        for (unsigned col = 0; col < n; ++col)
            bus->write(context, (uint16_t)(BIAS + col * 4), (uint32_t)bias[col]);

    for (unsigned row = 0; row < m; ++row)
        for (unsigned col = 0; col < k; ++col)
            bus->write(context, offset(A_BASE, bus->stride, row, col), (uint8_t)a[row*k + col]);
    for (unsigned row = 0; row < k; ++row)
        for (unsigned col = 0; col < n; ++col)
            bus->write(context, offset(B_BASE, bus->stride, row, col), (uint8_t)b[row*n + col]);

    bus->write(context, CONTROL, START_AND_CLEAR);
    for (unsigned poll = 0; poll < poll_limit; ++poll) {
        uint32_t status = bus->read(context, STATUS);
        if (status & ERROR)
            return TF_DEVICE_ERROR;
        if ((status & (BUSY | DONE)) == DONE) {
            for (unsigned row = 0; row < m; ++row)
                for (unsigned col = 0; col < n; ++col) {
                    uint32_t value = bus->read(context, offset(C_BASE, bus->stride, row, col));
                    memcpy(&c[row*n + col], &value, sizeof value);
                }
            if (cycles)
                *cycles = bus->read(context, CYCLES);
            return TF_OK;
        }
    }
    return TF_TIMEOUT;
}
