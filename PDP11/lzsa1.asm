;LZSA1 PDP-11 decoder version by Ivan Gorodetsky
;
;usage:
; mov #src_adr,r1
; mov #dst_adr,r2
; jsr pc,unlzsa1
;
;v 1.0 - 2019-10-20
;v 1.1 - 2019-10-22 (-4 bytes)
;v 1.2 - 2019-10-24 (-2 bytes)
;v 1.3 - 2020-04-24 (+4 bytes; Counter bug fixed, thanks to Nikita Zeemin for bugreport)
;v 1.4 - 2020-04-27 (-8 bytes and slightly faster)
;v 1.5 - 2020-04-27 (-4 bytes and slightly faster)
;v 1.6 - 2020-04-29 (-18 bytes, significantly faster and self-modifying code completly removed)
;v 1.61 - 2020-04-29 (-2 bytes, excess command removed)
;
;compress with <-f1 -r> options
;124 bytes
;
;  LZSA compression algorithms are (c) 2019 Emmanuel Marty,
;  see https://github.com/emmanuel-marty/lzsa for more information
;
;  This software is provided 'as-is', without any express or implied
;  warranty.  In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.
		
unlzsa1:
		mov #177400,r4
		clr r3
ReadToken:
		movb (r1)+,r0
		mov r0,r5
		bic #177617,r0
		beq NoLiterals
		asr r0
		asr r0
		asr r0
		asr r0
		cmp #7,r0
		bne m1
		jsr pc,ReadLong
m1:
		bisb r0,r3
bc1:
		movb (r1)+,(r2)+
		sob r3,bc1
NoLiterals:
		movb r5,r0
		mov r4,r5
		bisb (r1)+,r5
		tst r0
		bpl ShortOffset
;LongOffset:
		bic r4,r5
		swab r5
		bisb (r1)+,r5
		swab r5
ShortOffset:
		bic #177760,r0
		add #3,r0
		cmp #18.,r0
		bne m2
		jsr pc,ReadLong
m2:
		bisb r0,r3
		add r2,r5
bc2:
		movb (r5)+,(r2)+
		sob r3,bc2
		br ReadToken
ReadLong:
		movb (r1)+,r3
		bis r4,r3
		add r3,r0
		bcc m3
		mov r0,r3
		clr r0
		bisb (r1)+,r0
		swab r3
		bic #377,r3
		bne m4
		movb (r1)+,r3
		bic r4,r3
		swab r3
		bisb r0,r3
		bne m4
		mov (sp)+,r4
m3:
		clr r3
m4:		
		rts pc
