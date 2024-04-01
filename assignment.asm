; COMP2721 Assembly Assignment
; 
; This program is meant to:
; * take an integer input from the user
; * delay the program by the specified number of seconds
; * repeat
;
; THIS VERSION IS OBSOLETE, KEPT FOR REFERENCE OR BACKUP LATER
;
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
    delayMsgApp     db      ' .', 0h
    delayMsgAppLen  equ     % - delayMsgApp
    delayCycles     equ     1000

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
; the print is for testing
    call    readInput
    mov     eax, userInput
    call    sprint

;;;;;; THE CODE WORKS UP TO HERE ////////////////////////////////////

; convert the input from a string to an integer
    mov     ecx, userInput
    call    atoi


; call another subroutine here to delay
    call    delaySeconds

; after return, jump back to start to repeat

    mov     ebx, 0              ; return status 0 on exit
    mov     eax, 1              ; invoke exit
    int     80h


; -----------------------------------------------------
; read input subroutine
; return: string of integers from user -> userInput
; -----------------------------------------------------
readInput:
    push    edx                 ; technically don't need to push or pop since
    push    ecx                 ; we weren't doing anything important before
    push    ebx                 ; calling this subroutine
    push    eax

    mov     edx, 255            ; number of bytes to read into buffer
    mov     ecx, userInput      ; address that will store input
    mov     ebx, 0              ; input from stdin
    mov     eax, 3              ; sys_read
    int     80h

    pop     eax                 ; pop in reverse order (LIFO)
    pop     ebx
    pop     ecx
    pop     edx
    ret


; -----------------------------------------------------
; delay subroutine
; * reference: https://www.mycompiler.io/view/I72osPmHt3a (someone's code for checking time)
; parameter: number of seconds to delay by -> eax
; -----------------------------------------------------
delaySeconds:
    ; convert delay time to number of iterations
    imul    eax, 1000000      ; converts seconds to microseconds

delayLoop:
    ; Decrement a counter and check if it has reached zero
    ; This loop consumes CPU time and acts as a delay
    nop
    dec     eax                    ; Decrement the counter
    jnz     delayLoop              ; Jump back to delayLoop if counter is not zero

    ret                            ; Return from the subroutine

    

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

; ------------------------------------------
; atoi subroutine
; Convert string to integer
; Parameter: Address of the input string (in ECX)
; Returns: Integer value (in EAX)
; ------------------------------------------
atoi:
    xor     eax, eax            ; Clear EAX (initialize result to 0)
    mov     edi, ecx            ; Copy the address of the string to EDI (destination index)
    mov     ecx, 10             ; ECX = 10 (base 10 conversion)

atoi_loop:
    movzx   ebx, byte [edi]    ; Move the character from the string to EBX, zero extending it to 32 bits
    test    ebx, ebx            ; Check if we've reached the end of the string (null terminator)
    jz      atoi_done           ; If the character is null, we're done

    sub     ebx, '0'            ; Convert ASCII character to integer by subtracting ASCII '0'
    imul    eax, eax, ecx       ; Multiply result by 10 (shift left by 1 digit in base 10)
    add     eax, ebx            ; Add current digit to result

    inc     edi                 ; Move to the next character in the string
    jmp     atoi_loop           ; Repeat the loop

atoi_done:
    ret