;Size-optimized LZSA1 Intel 8080 decoder version by Ivan Gorodetsky
;Based on LZSA1 decompressor by spke
;input: 	hl=compressed data start
;			de=uncompressed destination start
;v 1.0 - 2019-09-15
;v 1.1 - 2019-10-02 (-1 byte)
;v 1.2 - 2019-10-27 (-2 bytes and self-modifying code removed)
;v 1.4 - 2021-02-26 (+5 bytes and faster)
;
;compress forward with <-f1 -r> options
;87 bytes - forward version
;
;compress backward with <-f1 -r -b> options
;92 bytes - backward version
;
;Compile with The Telemark Assembler (TASM) 3.2
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


;#DEFINE BACKWARD_DECOMPRESS

#IFNDEF BACKWARD_DECOMPRESS

.DEFINE NEXT_HL inx h
.DEFINE ADD_OFFSET xchg\ dad d
.DEFINE NEXT_DE inx d

#ELSE

.DEFINE NEXT_HL dcx h
.DEFINE ADD_OFFSET xchg\ mov a,e\ sub l\ mov l,a\ mov a,d\ sbb h\ mov h,a
.DEFINE NEXT_DE dcx d

#ENDIF 


unlzsa1:
			mvi b,0
ReadToken:
			mov a,m
			push psw
			NEXT_HL
			ani 70h
			jz NoLiterals 
			rrc\ rrc\ rrc\ rrc
			cpi 7
			cz ReadLongBA
			mov c,a
			call BLOCKCOPY
NoLiterals:
			pop psw
			push d
			mov e,m
			NEXT_HL
			mvi d,0FFh
			ora a
			jp ShortOffset
LongOffset:
			mov d,m
			NEXT_HL
ShortOffset:
			ani 0Fh
			adi 3
			cpi 15+3
			cz ReadLongBA
			mov c,a
			xthl
			ADD_OFFSET
			call BLOCKCOPY
			pop h
			jmp ReadToken
ReadLongBA:
			add m
			NEXT_HL
			rnc
			mov b,a\ mov a,m\ NEXT_HL\ rnz
			mov c,a\ mov b,m\ NEXT_HL
			ora b
			mov a,c
			rnz
			pop d
			pop d
			ret
BLOCKCOPY:
			dcx b
			inr c
			inr b
BLOCKCOPY_:
			mov a,m
			stax d
			NEXT_HL
			NEXT_DE
			dcr c
			jnz BLOCKCOPY_
			dcr b
			rz
			jmp BLOCKCOPY_

			.end
