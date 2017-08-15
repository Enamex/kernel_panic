void main (){
    char *fb_start = (char*) 0x000b8000;
    char *fb_end = (char*) 0x000b87D0;

    while(fb_start < fb_end)
    {
        *(fb_start)  = (0xF)<<4 | (0xD);
        *(fb_start + 1) = '#';
        fb_start += 2;
    }
    

    // int i = 0;
    while(1);
}
