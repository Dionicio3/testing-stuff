#include <nds.h>

#include <stdio.h>

volatile int frame = 0;

void Vblank() {
	frame++;
}

int main(void) {

	irqSet(IRQ_VBLANK, Vblank);

	consoleDemoInit();

	iprintf("Testing :)\n");
 
	while(true) {
		swiWaitForVBlank();
		scanKeys();
		int keys = keysDown();
		if (keys & KEY_A) {
			iprintf("penis\n");
		}
		if (keys & KEY_B) {
			iprintf("balls\n");
		}
	}

	return 0;
}
