; TO BE USED AT https://www.tutorialspoint.com/compile_assembly_online.php
;
section .data
    userPrompt      db      0Ah, 'Enter an integer greater than 0: ', 0h
    promptLen       equ     $ - userPrompt
    delayDot        db      '.', 0h
    delayDotLen     equ     $ - delayDot
    exitMsg         db      0Ah, 'Exiting', 0h
    exitMsgLen      equ     $ - exitMsg
    
    timeval:
        tv_sec          dd      0
        tv_usec         dd      0


section .bss            ; section for uninitialized variables
    userInput       resw    1

section	.text
	global _start       ;must be declared for using gcc
	
_start:                     ;tell linker entry point
    mov     edx, promptLen      ; move the userPrompt message and display integer
    mov     ecx, userPrompt
    mov     ebx, 1
    mov     eax, 4
    int     0x80
    
; call a subroutine here to go to read the input
    call    readInput
;    mov     eax, userInput
;    call    sprint

    
; convert the input from a string to an integer
    mov     ecx, userInput
    call    atoi
    
    call    delaySeconds

end:
    mov     edx, exitMsgLen      ; move the userPrompt message and display integer
    mov     ecx, exitMsg
    mov     ebx, 1
    mov     eax, 4
    int     0x80


	mov	eax, 1	    ;system call number (sys_exit)
	mov ebx, 0
	int	0x80        ;call kernel

; -----------------------------------------------------
; read input subroutine
; return: string of integers from user -> userInput
; -----------------------------------------------------
readInput:
    push    edx                 ; technically don't need to push or pop since
    push    ecx                 ; we weren't doing anything important before
    push    ebx                 ; calling this subroutine
    push    eax

    mov     edx, 8            ; number of bytes to read into buffer
    mov     ecx, userInput      ; address that will store input
    mov     ebx, 0              ; input from stdin
    mov     eax, 3              ; sys_read
    int     80h

    pop     eax                 ; pop in reverse order (LIFO)
    pop     ebx
    pop     ecx
    pop     edx
    ret
    
; ------------------------------------------
; atoi subroutine
; Convert string to integer
; Parameter: Address of the input string (in ECX)
; Returns: Integer value (in EAX)
; ------------------------------------------
atoi:
    xor     eax, eax            ; Clear EAX (initialize result to 0)
    mov     esi, ecx            ; Copy the address of the string to EDI (destination index)
    mov     ecx, 10             ; ECX = 10 (base 10 conversion)
    xor     edx, edx
    
atoi_loop:
    xor     ebx, ebx
    movzx   bx, byte [esi + edx]    ; Move the character from the string to EBX, zero extending it to 32 bits
    cmp     bl, 48
    jl      atoi_done
    cmp     bl, 57
    jg      atoi_done

    sub     bl, 48            ; Convert ASCII character to integer by subtracting ASCII '0'
    add     eax, ebx            ; Add current digit to result
    mov     ebx, 10
    mul     ebx         ; Multiply result by 10 (shift left by 1 digit in base 10)
    inc     edx                 ; Move to the next character in the string
    jmp     atoi_loop           ; Repeat the loop

atoi_done:
    cmp     edx, 0
    je      atoi_ret
    xor     edx, edx
    mov     ebx, 10
    div     ebx

atoi_ret:
    ret
    
    
; -----------------------------------------------------
; sprint subroutine (taken from asmtutor.com, lesson 5)
; String printing function
; parameter: the string message -> eax
; -----------------------------------------------------
sprint:
    push    edx
    push    ecx
    push    ebx
    push    eax
    call    slen
 
    mov     edx, eax
    pop     eax             ; eax from stack is put back
 
    mov     ecx, eax
    mov     ebx, 1
    mov     eax, 4
    int     80h
 
    pop     ebx
    pop     ecx
    pop     edx
    ret

;----------------------------------------------------
; slen subroutine (taken from asmtutor.com, lesson 5)
; String length calculation function
; parameter: the string message -> eax
; return: integer equal to length of string -> eax
;----------------------------------------------------
slen:
    push    ebx
    mov     ebx, eax
 
nextchar:
    cmp     byte [eax], 0   ; compare the byte pointed to by EAX at this address against zero (Zero is an end of string delimiter)
    jz      finished        ; jump (if the zero flagged has been set) to the point in the code labeled 'finished'
    inc     eax             ; increment the address in EAX by one byte (if the zero flagged has NOT been set)
    jmp     nextchar        ; jump to the point in the code labeled 'nextchar'
 
finished:
    sub     eax, ebx        ; subtract the address in EBX from the address in EAX
                            ; remember both registers started pointing to the same address (see line 15)
                            ; but EAX has been incremented one byte for each character in the message string
                            ; when you subtract one memory address from another of the same type
                            ; the result is number of segments between them - in this case the number of bytes
    pop     ebx
    ret
    
    
; -----------------------------------------------------
; delay subroutine
; reference: https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md
; syscall 162 = nanosleep, coming from the arm(32bit)/x86(32bit) tables
; parameter: number of seconds to delay by -> eax
; -----------------------------------------------------
delaySeconds:
    cmp     eax, 0
    je      delayEnd

    mov     dword [tv_sec], eax
    mov     dword [tv_usec], 0
    mov     eax, 162
    mov     ebx, timeval
    mov     ecx, 0
    int     0x80

delayEnd:
    ret                            ; Return from the subroutine
