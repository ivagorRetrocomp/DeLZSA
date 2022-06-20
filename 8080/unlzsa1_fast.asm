;Speed-optimized LZSA1 Intel 8080 decoder version by Ivan Gorodetsky
;Based on LZSA1 decompressor by spke
;input: 	hl=compressed data start
;			de=uncompressed destination start
;v 1.0 - 2019-09-15
;v 1.1 - 2019-10-27 (-4 bytes and self-modifying code removed)
;v 1.2 - 2021-02-23 (-25 bytes and slightly faster)
;v 1.3 - 2021-02-25 (-6 bytes, tnanks to Improver)
;v 1.4 - 2021-02-25 (+12 bytes, bug fix)
;v 1.5 - 2022-06-14 (faster, +7 bytes forward/+12 bytes backward)
;
;compress forward with <-f1 -r> options
;178 bytes - forward version
;
;compress backward with <-f1 -r -b> options
;188 bytes - backward version
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
			mvi b,0\ jmp ReadToken
NoLiterals:
			xra m
			push d\ NEXT_HL\ mov e,m\ jm LongOffset
ShortOffset:
			mvi d,0FFh\ adi 3\ cpi 15+3\ jnc LongerMatch
CopyMatch:
			mov c,a
			NEXT_HL\ xthl
			ADD_OFFSET
			mov a,m\ NEXT_HL\ stax d\ NEXT_DE\ dcr c
			mov a,m\ NEXT_HL\ stax d\ NEXT_DE\ dcr c
BLOCKCOPY1:
			mov a,m
			stax d
			NEXT_HL
			NEXT_DE
			dcr c
			jnz BLOCKCOPY1
AfterBLOCKCOPY1:
			pop h
ReadToken:
			mov a,m\ ani 70h\ jz NoLiterals 
			cpi 70h\ jz MoreLiterals
			rrc\ rrc\ rrc\ rrc
			mov c,a
			mov b,m
			NEXT_HL
			mov a,m
			stax d
			NEXT_HL
			NEXT_DE
			dcr c
			jnz $-5
			push d\ mov e,m
			mvi a,8Fh\ ana b\ mov b,c\ jp ShortOffset
LongOffset:
			NEXT_HL\ mov d,m
			adi -128+3\ cpi 15+3\ jc CopyMatch
LongerMatch:
			NEXT_HL\ add m\ jnc CopyMatch
			mov b,a\ NEXT_HL\ mov c,m\ jnz CopyMatch_UseBC
			NEXT_HL\ mov b,m
			mov a,b\ ora c\ jnz CopyMatch_UseBC
			pop d\ ret
CopyMatch_UseBC:
			NEXT_HL\ xthl
			ADD_OFFSET
			call BLOCKCOPYbc
			jmp AfterBLOCKCOPY1
MoreLiterals:		
			xra m
			push psw
			mvi a,7\ NEXT_HL\ add m\ jc ManyLiterals
			mov c,a
			NEXT_HL
BLOCKCOPY2c:
			mov a,m
			stax d
			NEXT_HL
			NEXT_DE
			dcr c
			jnz BLOCKCOPY2c
AfterBLOCKCOPY2:
			pop psw
			push d\ mov e,m
			jp ShortOffset
			jmp LongOffset

ManyLiterals:
			mov b,a\ NEXT_HL\ mov c,m\ jnz CopyLiterals
			NEXT_HL\ mov b,m
CopyLiterals:
			NEXT_HL
			call BLOCKCOPYbc
			jmp AfterBLOCKCOPY2

BLOCKCOPYbc:
			dcx b
			inr c
			inr b
BLOCKCOPYbc1:
			mov a,m
			stax d
			NEXT_HL
			NEXT_DE
			dcr c
			jnz BLOCKCOPYbc1
			dcr b
			jnz BLOCKCOPYbc1
			ret

			.end
