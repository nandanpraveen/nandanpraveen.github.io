#ifndef TENSORFORGE_H
#define TENSORFORGE_H

#include <stddef.h>
#include <stdint.h>

/* Callbacks transact one aligned 32-bit register at the given byte offset. */
typedef struct {
    void *context;
    uint32_t (*read)(void *context, uint16_t offset);
    void (*write)(void *context, uint16_t offset, uint32_t value);
    unsigned stride; /* Synthesized DIM (32 by default). */
} tf_bus;

typedef enum {
    TF_OK = 0, TF_INVALID = -1, TF_BUSY = -2, TF_DEVICE_ERROR = -3, TF_TIMEOUT = -4
} tf_status;

/* A, B and C are compact row-major M×K, K×N and M×N arrays, respectively.
 * A non-null bias selects bias + ReLU + rounded INT8 requantization. */
tf_status tf_gemm(const tf_bus *bus, unsigned m, unsigned n, unsigned k,
                  const int8_t *a, const int8_t *b, const int32_t *bias,
                  unsigned shift, int32_t *c, unsigned poll_limit, uint32_t *cycles);
#endif
