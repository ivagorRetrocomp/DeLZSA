;LZSA2 Intel 8080 decoder version by Ivan Gorodetsky
;Based on LZSA2 decompressor by spke
;input: 	hl=compressed data start
;			de=uncompressed destination start
;v 1.1 - 2019-09-22
;v 1.3 - 2021-02-26 (+13 bytes and much faster, merged with fast version)
;
;compress forward with <-f2 -r> options
;200 bytes - forward version
;
;compress backward with <-f2 -r -b> options
;205 bytes - backward version
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

unlzsa2:
			xra a
			sta A1
			mov b,a
			jmp ReadToken
CASE00x:
			call ReadNibble
			mov e,a
			mov a,c
			cpi 00100000b
			mov a,e\ adc a\ mov e,a
			mov a,c
			jmp SaveOffset
CASE0xx:
			mvi d,0FFh
			cpi 01000000b
			jc CASE00x
CASE01x:
			cpi 01100000b
			mov e,a
			mov a,d\ adc a\ mov d,a
			mov a,e
OffsetReadE:
			mov e,m
			NEXT_HL
SaveOffset:
			xchg\ shld IY\ xchg
MatchLen:
			ani 00000111b
			adi 2
			cpi 7+2
			cz ExtendedCode
CopyMatch:
			mov c,a
			xthl
			ADD_OFFSET
			dcx b
			inr c
			inr b
BLOCKCOPY1:
			mov a,m
			stax d
			NEXT_HL
			NEXT_DE
			dcr c
			jnz BLOCKCOPY1
			dcr b
			jnz BLOCKCOPY1
			pop h
ReadToken:
			mov a,m
			NEXT_HL
			push psw
			ani 00011000b
			jz NoLiterals
			rrc\ rrc\ rrc
			cpe ExtendedCode
			mov c,a
			dcx b
			inr c
			inr b
BLOCKCOPY2:
			mov a,m
			stax d
			NEXT_HL
			NEXT_DE
			dcr c
			jnz BLOCKCOPY2
			dcr b
			jnz BLOCKCOPY2
NoLiterals:
			pop psw
			push d
			ora a
			jp CASE0xx
CASE1xx:
			cpi 11000000b
			jnc CASE11x
CASE10x:
			call ReadNibble
			mov d,a
			mov a,c
			cpi 10100000b
			mov a,d\ dcr a\ adc a\ mov d,a
			mov a,c
			.db 0CAh		;jz ...
CASE110:
			mov d,m
			NEXT_HL
			jmp OffsetReadE
CASE11x:
			cpi 11100000b
			jc CASE110
CASE111:
			xchg\ lhld IY\ xchg
			jmp MatchLen
ExtendedCode:
			call ReadNibble
			inr a
			jz ExtraByte
			sui 0F0h+1
			add c
			ret
ExtraByte:
			mvi a,15
			add c
			add m
			NEXT_HL
			rnc
			mov a,m
			NEXT_HL
			mov b,m
			NEXT_HL
			rnz
			pop d
			pop d
ReadNibble:
			mov c,a
			lda A1
			ora a
			jp UpdateNibble
			rar
			sta A1
			ral
			ret
UpdateNibble:
			mov a,m
			ori 0F0h
			sta A1
			mov a,m
			NEXT_HL
			ori 0Fh
			rrc\ rrc\ rrc\ rrc
			ret

IY			.dw 0
A1			.db 0


			.end
