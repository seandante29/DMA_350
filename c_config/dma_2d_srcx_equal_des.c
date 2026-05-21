//---------------------------------------2d xsize equal-----------------------
#include "xil_io.h"
#include "xparameters.h"

#define BRAM0_BASE 0xC0000000 //periph0
#define BRAM1_BASE 0xC2000000 //periph1
#define BRAM2_BASE 0xC4000000 //cmd descriptor
#define BRAM3_BASE 0xC6000000 //apb master
#define BRAM4_BASE 0xC8000000 //periph2
#define BRAM5_BASE 0xCA000000 //periph3
#define BRAM6_BASE 0xCC000000  //periph4
#define BRAM7_BASE 0xCE000000 //periph5

//#define BRAM0_BASE 0x8000
//#define BRAM1_BASE 0x9000

#define WORD_COUNT 64

int main()
{
    //volatile u32 src;
    //volatile u32 dst;
    int i,j,k,l,m,n;
  //  int error = 0;

    // Initialize BRAM0
    for(i = 0; i < WORD_COUNT; i++)
    {
        Xil_Out32(BRAM0_BASE + i*4, 0xAAA00000 + i);
    }

    // INITALIZE BRAM1
    for(j = 0; j < WORD_COUNT; j++)
       {
           Xil_Out32(BRAM1_BASE + j*4, 0xBBB00000 + j);
       }
    // Initialize BRAM4
    for(k = 0; k < WORD_COUNT; k++)
    {
        Xil_Out32(BRAM4_BASE + k*4, 0xCCC00000 + k);
    }
    // Initialize BRAM5
    for(l = 0; l < WORD_COUNT; l++)
     {
         Xil_Out32(BRAM5_BASE + l*4, 0xDDD00000 + l);
     }
    // Initialize BRAM6
    for(m = 0; m < WORD_COUNT; m++)
       {
           Xil_Out32(BRAM6_BASE + m*4, 0xEEE00000 + m);
       }
    // Initialize BRAM7
    for(n = 0; n < WORD_COUNT; n++)
       {
           Xil_Out32(BRAM7_BASE + n*4, 0xFFF00000 + n);
       }
		// ================= CHANNEL 0 =================
		// srcxsize = desxsize
Xil_Out32(BRAM3_BASE + 120, 0XC4000000);      // LINKADDR(C4000000)
Xil_Out32(BRAM3_BASE + 116, 0);               // AUTO
Xil_Out32(BRAM3_BASE + 84 , 0X00000201);      // TRIGOUT(201)
Xil_Out32(BRAM3_BASE + 80 , 0X00000201);      // DESTRIGINCFG(201)
Xil_Out32(BRAM3_BASE + 76 , 0X00000200);      // SRCTRIGINCFG(200)
Xil_Out32(BRAM3_BASE + 72 , 0);               // ch_destmplt
Xil_Out32(BRAM3_BASE + 68 , 0);               // ch_srctmplt
Xil_Out32(BRAM3_BASE + 64 , 0);               // tmpltcfg
Xil_Out32(BRAM3_BASE + 60 , 0X00040004);               // ysize
Xil_Out32(BRAM3_BASE + 56 , 0X1234000);       // FILLVAL
Xil_Out32(BRAM3_BASE + 52 , 0X00aa00aa);               // yaddrstride
Xil_Out32(BRAM3_BASE + 48 , 0X00010001);      // XADDRINC(10001)
Xil_Out32(BRAM3_BASE + 44 , 0X00030000);      // DESTRANSCFG(h00030000)
Xil_Out32(BRAM3_BASE + 40 , 0X00030000);      // SRCTRANSCFG(h00030000)
Xil_Out32(BRAM3_BASE + 32 , 0X00080008);      // XSIZE(00080008)
Xil_Out32(BRAM3_BASE + 24 , 0XC2000000);      // desaddr(C2000000)
Xil_Out32(BRAM3_BASE + 16 , 0XC0000000);      // srcaddr(C0000000)
Xil_Out32(BRAM3_BASE + 12 , 0X0E2012A2);      // CH_CTRL
Xil_Out32(BRAM3_BASE + 8  , 0X0000070F);      // ch_intern(70f)
Xil_Out32(BRAM3_BASE + 0  , 0X00000001);      // ch_cmd

//desysize > srcysize
(wrap)

// ================= CHANNEL 1 =================
// base + 256 
Xil_Out32(BRAM3_BASE + 256 + 120, 0XC4000000); // LINKADDR(C4000000)
Xil_Out32(BRAM3_BASE + 256 + 116, 0);          // AUTO
Xil_Out32(BRAM3_BASE + 256 + 84 , 0X00000203); // TRIGOUT(203)
Xil_Out32(BRAM3_BASE + 256 + 80 , 0X00000203); // DESTRIGINCFG(203)
Xil_Out32(BRAM3_BASE + 256 + 76 , 0X00000202); // SRCTRIGINCFG(202)
Xil_Out32(BRAM3_BASE + 256 + 72 , 0);          // ch_destmplt
Xil_Out32(BRAM3_BASE + 256 + 68 , 0);          // ch_srctmplt
Xil_Out32(BRAM3_BASE + 256 + 64 , 0);          // tmpltcfg
Xil_Out32(BRAM3_BASE + 256 + 60 , 0X00060004);       // ysize
Xil_Out32(BRAM3_BASE + 256 + 56 , 0X1234000);  // FILLVAL
Xil_Out32(BRAM3_BASE + 256 + 52 , 0X00aa00aa);          // yaddrstride
Xil_Out32(BRAM3_BASE + 256 + 48 , 0X00010001); // XADDRINC(10001)
Xil_Out32(BRAM3_BASE + 256 + 44 , 0X00030000); // DESTRANSCFG(h00030000)
Xil_Out32(BRAM3_BASE + 256 + 40 , 0X00030000); // SRCTRANSCFG(h00030000)
Xil_Out32(BRAM3_BASE + 256 + 32 , 0X00080008); // XSIZE(00080008)
Xil_Out32(BRAM3_BASE + 256 + 24 , 0xCA000000); // desaddr(C2000000)
Xil_Out32(BRAM3_BASE + 256 + 16 , 0xC8000000); // srcaddr(C0000000)
Xil_Out32(BRAM3_BASE + 256 + 12 , 0X0E202252); // CH_CTRL
Xil_Out32(BRAM3_BASE + 256 + 8  , 0X0000070F); // ch_intern(70f)
Xil_Out32(BRAM3_BASE + 256 + 0  , 0X00000001); // ch_cmd

// fill
// ================= CHANNEL 2 =================
// base + 512
Xil_Out32(BRAM3_BASE + 512 + 120, 0XC4000000); // LINKADDR(C4000000)
Xil_Out32(BRAM3_BASE + 512 + 116, 0);          // AUTO
Xil_Out32(BRAM3_BASE + 512 + 84 , 0X00000205); // TRIGOUT(205)
Xil_Out32(BRAM3_BASE + 512 + 80 , 0X00000205); // DESTRIGINCFG(205)
Xil_Out32(BRAM3_BASE + 512 + 76 , 0X00000204); // SRCTRIGINCFG(204)
Xil_Out32(BRAM3_BASE + 512 + 72 , 0);          // ch_destmplt
Xil_Out32(BRAM3_BASE + 512 + 68 , 0);          // ch_srctmplt
Xil_Out32(BRAM3_BASE + 512 + 64 , 0);          // tmpltcfg
Xil_Out32(BRAM3_BASE + 512 + 60 , 0X00060004);          // ysize
Xil_Out32(BRAM3_BASE + 512 + 56 , 0X1234000);  // FILLVAL
Xil_Out32(BRAM3_BASE + 512 + 52 , 0X00aa00aa);          // yaddrstride
Xil_Out32(BRAM3_BASE + 512 + 48 , 0X00010001); // XADDRINC(10001)
Xil_Out32(BRAM3_BASE + 512 + 44 , 0X00030000); // DESTRANSCFG(h00030000)
Xil_Out32(BRAM3_BASE + 512 + 40 , 0X00030000); // SRCTRANSCFG(h00030000)
Xil_Out32(BRAM3_BASE + 512 + 32 , 0X00080008); // XSIZE(00080008)
Xil_Out32(BRAM3_BASE + 512 + 24 , 0xCE000000); // desaddr
Xil_Out32(BRAM3_BASE + 512 + 16 , 0xCC000000); // srcaddr
Xil_Out32(BRAM3_BASE + 512 + 12 , 0X0E203212); // CH_CTRL
Xil_Out32(BRAM3_BASE + 512 + 8  , 0X0000070F); // ch_intern(70f)
Xil_Out32(BRAM3_BASE + 512 + 0  , 0X00000001); // ch_cmd
}
 
 

