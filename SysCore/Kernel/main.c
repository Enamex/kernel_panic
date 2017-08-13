void main (){
    int i;
    for(i = 0; i < 2000;i += 1){
        char *hello = (char *) 0x000b8000;
        *(hello + 1 + i) = 2;
    }
    
    while(1);
}
