#include "stdio.h"

#define FB_COLUMN_CHAR_LEN 25
#define FB_BLACK 0
#define FB_GREEN 2
#define FB_DARK_GREY 8
#define LIGHT_GREEN 10
/* The I/O ports */
#define FB_COMMAND_PORT         0x3D4
#define FB_DATA_PORT            0x3D5
/* The I/O port commands */
#define FB_HIGH_BYTE_COMMAND    14
#define FB_LOW_BYTE_COMMAND     15

#define SERIAL_COM1_BASE                0x3F8
#define SERIAL_DATA_PORT(base)          (base)
#define SERIAL_FIFO_PORT(base)          (base + 2)
#define SERIAL_LINE_COMMAND_PORT(base)  (base + 3)
#define SERIAL_MODEM_COMMAND_PORT(base) (base + 4)
#define SERIAL_LINE_STATUS_PORT(base)   (base + 5)
#define SERIAL_LINE_ENABLE_DLAB         0x80

#define FRAME_BUFFER_START              0x000b8000
#define FRAME_BUFFER_END                0x000b87D0

static int xpos = 0, ypos = 0;

typedef struct{
    char c;
    char color;
} __attribute__((packed)) fb_mem_cell; // frame buffer memory location content


void fb_scroll_down()
{
    short *first =  ((short *)FRAME_BUFFER_START);
    short *second = ((short *)(FRAME_BUFFER_START + FB_COLUMN_CHAR_LEN));

    while(second < ((short *)FRAME_BUFFER_END)){
        *first = *second;
        first += 1;
        second += 1;
    }
    ypos = 0;
    xpos -= 1;
}

void puts(char *buff)
{
    fb_mem_cell *ptr = (fb_mem_cell*) FRAME_BUFFER_START;
    while(*buff){
        ptr->c = *buff;
        ptr->color = ((FB_BLACK & 0x0F) << 4) | (FB_GREEN & 0x0F);
        ++buff;
        ++ptr;
    }
}
