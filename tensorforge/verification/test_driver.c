#include "tensorforge.h"
#include <assert.h>
#include <stdio.h>

struct fake_bus {
    uint32_t words[4096];
    unsigned polls;
};

static uint32_t read_reg(void *context, uint16_t address) {
    struct fake_bus *device = context;
    if (address == 4 && device->polls && !--device->polls)
        device->words[1] = 2;
    return device->words[address / 4];
}

static void write_reg(void *context, uint16_t address, uint32_t value) {
    struct fake_bus *device = context;
    device->words[address / 4] = value;
    if (address == 0) {
        device->words[1] = 1;
        device->polls = 3;
    }
}

int main(void) {
    struct fake_bus device = {0};
    const tf_bus bus = {&device, read_reg, write_reg, 32};
    const int8_t a[] = {3, -2, 5, -128, 127, 0};
    const int8_t b[] = {2, -6, 4};
    const int32_t bias[] = {-9};
    int32_t output[] = {0, 0};
    uint32_t cycles;
    device.words[0x3000/4] = (uint32_t)-42;
    device.words[0x3000/4 + 32] = 12;
    device.words[20/4] = 17;
    assert(tf_gemm(&bus, 2, 1, 3, a, b, bias, 4, output, 8, &cycles) == TF_OK);
    assert(output[0] == -42 && output[1] == 12 && cycles == 17);
    assert(device.words[8/4] == 2 && device.words[12/4] == 1 && device.words[16/4] == 3);
    assert(device.words[0x1000/4 + 1] == 254 && device.words[0x1000/4 + 32] == 128);
    assert(device.words[0x2000/4 + 32] == 250 && device.words[0x2000/4 + 64] == 4);
    assert(device.words[0x100/4] == (uint32_t)-9 && device.words[24/4] == 36);
    assert(tf_gemm(&bus, 33, 1, 1, a, b, NULL, 0, output, 8, NULL) == TF_INVALID);
    assert(tf_gemm(&bus, 2, 1, 3, a, b, NULL, 0, output, 1, NULL) == TF_TIMEOUT);
    assert(tf_gemm(&bus, 2, 1, 3, a, b, NULL, 0, output, 8, NULL) == TF_BUSY);
    puts("PASS C register driver");
}
