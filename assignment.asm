; COMP2721 Assembly Assignment
; 
; This program is meant to:
; * take an integer input from the user
; * delay the program by the specified number of seconds
; * repeat
;
; This program is to be run on the online compiler at "https://www.mycompiler.io/new/asm-x86_64"
; Compile with: nasm -f elf helloworld-inc.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 helloworld-inc.o -o helloworld-inc
; Run with: ./helloworld-inc

; for reference, opcodes for EAX are:
; 1 = sys_exit (EBX = 0)
; 2 = sys_fork (won't be used)
; 3 = sys_read
; 4 = sys_write
;   for both sys_read and sys_write:
;   EBX = 0 for stdin (keyboard/console), 1 for stdout
;   ECX = the address of the data
;   EDX = length of the input (string)
; 5 = sys_open
; 6 = sys_close

section .data           ; section for initialized variables
    userPrompt      db      'Enter an integer: ', 0h    ; 0h is null-terminator
    promptLen       equ     $-userPrompt
    delayMsg        db      0Ah, 'Delaying', 0h         ; 0Ah is linefeed
    delayMsgLen     equ     $-delayMsg

section .bss            ; section for uninitialized variables
    userInput       resb    5   ; remember to add 1 for the null-terminator

section .text
global _start

_start:
    mov     edx, promptLen      ; move the userPrompt message and display integer
    mov     ecx, userPrompt
    mov     ebx, 1
    mov     eax, 4
    int     80h                 ; call the system kernel with an interrupt

; call a subroutine here to go to read the input
    jmp     readInput
; call another subroutine here to delay
; after return, jump back to start to repeat

    mov     ebx, 0              ; return status 0 on exit
    mov     eax, 1              ; invoke exit
    int     80h


; ---------------------------------------------------------------------------------
; read input subroutine
; * no need to push, since we don't interact with any data before calling this subroutine
; return: string of integers from user -> 
; ---------------------------------------------------------------------------------
readInput:
    mov     edx, 255            ; number of bytes to read into buffer
    mov     ecx, userInput      ; address that will store input
    mov     ebx, 0              ; input from stdin
    mov     eax, 3              ; sys_read
    int     80h


; --------------------------------------------------------------------------------------------------
; delay subroutine
; * no push or pop, don't need to manually call because the end of readInput will continue into here
; * reference: https://www.mycompiler.io/view/I72osPmHt3a (someone's code for checking time)
; --------------------------------------------------------------------------------------------------
delaySeconds:


; ------------------------------------------
; sprint subroutine (taken from asmtutor.com, lesson 5)
; String printing function
; parameter: the string message -> eax
; ------------------------------------------
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

;------------------------------------------
; slen subroutine (taken from asmtutor.com, lesson 5)
; String length calculation function
; parameter: the string message -> eax
; return: integer equal to length of string -> eax
;------------------------------------------
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