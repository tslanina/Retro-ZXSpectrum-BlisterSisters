; BLISTER SISTERS by dox
; 256 bytes speccy intro
; tomasz@slanina.pl

				org 0xe000
start:
				call $d6b	; clear
				xor a			; does $d6b clear a? not sure
			
				ld b,a
				ld c,a
				
				;the slowest possible way to generate  n/sqrt(x*x+y*y) table :)
gen_loop:
				push bc
				ld a,c
				call 0x2d28	; STACK-A  
				pop bc
				push bc
				ld a,b
				call 0x2d28	; STACK-A	
				rst 0x28 ; FP-CALC
		
				db 0x31 ; dup
				db 0x04 ; mul
				db 0x01 ; exchange
				db 0x31 ; dup
 				db 0x04 ; mul
				db 0x0f ; add
				db 0x28 ; sqrt
				db 0x38 ; endc
				
				call 0x2dd5		; FP-TO-A  -> dirty way to avoid /0
				or a
				jr z,skip_s
				call 0x2d28	; STACK-A
				ld a,40
				call 0x2d28	; STACK-A
				
				rst 0x28 ; FP-CALC
				
				db 0x01 ; exchange
				db 0x05 ; div
				db 0x38 ; endc
		
				call 0x2dd5 ; FP-TO-A
				jr omit
				
skip_s:
				ld a,$3d
omit:
				pop bc
				
				;store data at address %100xxxxx 000yyyyy for easier access
				
				set 7,b
				ld [bc],a
				res 7,b
				
				;draw progress bar
				
				ld h,$59
				ld l,b
				ld [hl],a
				
				inc c
				ld a,31
				cp c
				jr nc,gen_loop
				inc hl
				ld c,0
				inc b
				cp b
				jr nc,gen_loop
				
				;change character base + print
				
				ld hl,chars-$41*8
				ld [23606],hl
				
				ld a,'A'
				rst $10
				ld a,'B'
				rst $10

main_loop:
				ld hl,$5800
				exx
				
				;generate sound
				ld de,$e001
				ld a,[de]
				ld b,a
				ld a,e		; blue border + reset sound var
				ld [de],a
i_loop:
				out [$fe],a
				xor %10000
				djnz i_loop		
		
				ld hl,meta_pos
	
				;calculate new coords
				ld b,6
				ld c,29
c_loop:		
				ld a,[hl]
				inc l
				add a,[hl]
				cp 1
				jr nc,ok_1
				ld a,[hl]
				ld[de],a			;sound at $e001
				neg
				ld[hl],a
				ld a,$1
ok_1:
				cp c
				jr c,ok_2
				ld a,[hl]
				neg
				ld[de],a
				ld[hl],a
				ld a,c
ok_2:		
				dec l
				ld [hl],a
				inc l
				inc l
				dec c	; a bit more random movement
				djnz c_loop
		
				ld c,b
				
screen_loop:
				
				ld hl,meta_pos

				;calculate tension
				
				call calc
				push af
				call calc
				pop de
				add a,d
				push af
				call calc
				pop de
				add a,d
				add a,a
			
				;play with colors
				
				cp %0111000	
				jr c,skip_clr
				ld a,%1011000
skip_clr:			
				and %1111000
				jr z,set_blue

				cp %011000
				jr nz,skip_set
set_blue:		
				ld a,%1000
skip_set:		
				cp %10000
				jr nz,no_red
				or %1000000
no_red:		
				or %111
				
				exx
				ld [hl],a
				inc hl
				exx
				
				inc c
				ld a,31
				cp c
				jr nc,screen_loop
				ld c,0
		
				inc b
				ld a,23
				cp b
				jr nc,screen_loop

				jp main_loop
		
				;calc tension at given point, use table
calc:
				ld a,b
				sub [hl]
				jr nc,calc_1
				neg 
calc_1:
				or 128
				ld d,a
				inc l
				inc l
				ld a,c
				sub [hl]
				jr nc,calc_2
				neg 
calc_2:
				ld e,a
				ld a,[de]
				inc l
				inc l
				ret	

meta_pos:
				; x,dx,y,dy
				db 2,1,2,1
				db 26,-1,2,1  
				db 16,-1,22,-1

chars:	
				db %01111111
				db %10000000
				db %10110001
				db %10101010
				db %10101010
				db %10110001
				db %10000000
				db %01111111
			
				db %11111110
				db %11111111
				db %11010111
				db %01101111
				db %01101111
				db %11010111
				db %11111111
				db %11111110
			
end start