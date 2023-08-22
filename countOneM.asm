%ifndef SYS_EQUAL
%define SYS_EQUAL
    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
   
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
     

    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
   
     
    sys_exit     equ     60
   
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3

 
 
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
   
    ;access mode
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000

   
; create permission mode
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission

    NL            equ   0xA
    Space         equ   0x20

%endif
;---------------------------------------------------------
GetStrlen:
   push    rbx
   push    rcx
   push    rax  

   xor     rcx, rcx
   not     rcx
   xor     rax, rax
   cld
         repne   scasb
   not     rcx
   lea     rdx, [rcx -1]  ; length in rdx

   pop     rax
   pop     rcx
   pop     rbx
   ret
;-----------------------
writeNum:
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax  

wAgain:
   cmp    rax, 9
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret
;-----------------------
putc:

   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

   push   ax
   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout
   syscall
   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
printString:
    push    rax
    push    rcx
    push    rsi
    push    rdx
    push    rdi

    mov     rdi, rsi
    call    GetStrlen
    mov     rax, sys_write  
    mov     rdi, stdout
    syscall
   
    pop     rdi
    pop     rdx
    pop     rsi
    pop     rcx
    pop     rax
    ret
;-------------------------------------------
getString:
    push rax
    push rsp
    push rdi
    push rsi
    push rdx
   
    mov rax, 0      
    mov rdi, 0      
    mov rsi, input  
    mov rdx, 101    ; maximum number of bytes to read
    syscall      
   
   
    pop rdx
    pop rsi
    pop rdi
    pop rsp
    pop rax
    ret
;-------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
readNum:
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
   
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx
   cmp    bl, 0
   je     sEnd
   neg    rax
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret
;-------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

 
   sub    rsp, 1
   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall
   mov    al, byte [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------

section .data
    prompt db 'asfsa', 0

section .bss
    input resb 100000000
    temp resb 100

section .text
    global _start

_start:
    ; get first number
    call readNum
    mov r10, rax
    ; get second number
    call readNum
    ; get string
    call getString
    mov r11, rax
    inc r11
    ; cut the input string input[num1(-->r12), num2(-->r13)]
    mov r12, input ; r12 : first of string
    add r12, r10
    sub r11, r10 ; num2 - num1
    mov r13, r12
    add r13, r11 ;now the end of the portion of srting we need is stored in r13
    mov byte [r13], 0 ; we mark the end of the string as 0

    xor rax, rax     ; rax --> counter
    mov rbx, r12  ; use rbx as a pointer to the input string
    count_loop:
        cmp byte [rbx], 0 ; check for end of the portion of string we need
        je ex
        mov r15b, byte [rbx] ; load the current character into r15b
        add rbx, 1
        xor edx, edx      ; clear edx to use as a counter for the number of ones in the current byte
    byte_loop:
        test r15b, 1      ; check if the lowest bit is set
        jnz one_found
        shr r15b, 1       ; shift the bits to the right
        cmp r15b, 0       ; check if all bits have been shifted out
        jne byte_loop
        jmp count_loop
    one_found:
        add rax, 1        ; increment the counter
        shr r15b, 1       ; shift the bits to the right
        cmp r15b, 0       ; check if all the bits have been shifted out
        jne byte_loop
        jmp count_loop
    ex:
    call writeNum
    call newLine
   
Exit:
    mov rax, 1
    xor rbx, rbx
    int 0x80