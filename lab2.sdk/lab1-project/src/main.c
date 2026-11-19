#include "xparameters.h"
#include "xil_io.h"
#include "xil_types.h"

#define N              10
#define C_BITS         20

#define GPIO_BASE      XPAR_AXI_GPIO_0_BASEADDR
#define GPIO_OUT_REG   (GPIO_BASE + 0x0)
#define GPIO_IN_REG    (GPIO_BASE + 0x8)

#define IN_DATA        0x01u
#define IN_STRB        0x02u
#define IN_ACK         0x04u

#define OUT_DATA       0x01u
#define OUT_STRB       0x02u
#define OUT_ACK        0x04u

static u8  A[N][N];
static u8  B[N][N];
static u32 C[N][N];

static u32 out_reg;

static void out_write(u32 value)
{
    out_reg = value;
    Xil_Out32(GPIO_OUT_REG, out_reg);
}

static u32 recv_bit(void)
{
    u32 in;

    do {
        in = Xil_In32(GPIO_IN_REG);
    } while ((in & IN_STRB) == 0);

    out_write(out_reg | OUT_ACK);

    while (Xil_In32(GPIO_IN_REG) & IN_STRB) {
    }

    out_write(out_reg & ~OUT_ACK);

    return in & IN_DATA;
}

static u8 recv_byte(void)
{
    u32 mask, value = 0;

    for (mask = 1; mask < 0x100u; mask <<= 1)
        if (recv_bit())
            value |= mask;

    return (u8)value;
}

static void send_bit(u32 bit)
{
    out_write((out_reg & ~OUT_DATA) | (bit ? OUT_DATA : 0) | OUT_STRB);

    while ((Xil_In32(GPIO_IN_REG) & IN_ACK) == 0) {
    }

    out_write(out_reg & ~OUT_STRB);

    while (Xil_In32(GPIO_IN_REG) & IN_ACK) {
    }
}

static void send_word(u32 value)
{
    u32 mask;

    for (mask = 1; mask < (1u << C_BITS); mask <<= 1)
        send_bit(value & mask);
}

int main(void)
{
    int i, j, k;
    u32 sum;

    out_write(0);

    while (1) {
        for (i = 0; i < N; i++)
            for (j = 0; j < N; j++)
                A[i][j] = recv_byte();

        for (i = 0; i < N; i++)
            for (j = 0; j < N; j++)
                B[i][j] = recv_byte();

        for (i = 0; i < N; i++) {
            for (j = 0; j < N; j++) {
                sum = B[i][j];
                for (k = 0; k < N; k++)
                    sum += (u32)A[i][k] * (u32)A[k][j];
                C[i][j] = sum;
            }
        }

        for (i = 0; i < N; i++)
            for (j = 0; j < N; j++)
                send_word(C[i][j]);
    }

    return 0;
}
