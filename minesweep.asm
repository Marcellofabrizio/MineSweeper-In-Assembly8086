

.model small

.stack 100H

.data

    ;=========== STRINGS ===========;

    game_title db 'CAMPO MINADO'
    GAME_TITLE_STR_LEN EQU 12

    by_str db 'POR'
    BY_STR_LEN EQU 3

    name_arthur db 'ARTHUR CORSO'
    NAME_ARTHUR_STR_LEN EQU 12

    name_marcello db 'MARCELLO FABRIZIO'
    NAME_MARCELLO_STR_LEN EQU 17
    
    configurations db 'CONFIGURACOES'
    CONFIGURATIONS_STR_LEN EQU 13 

;    ____                 
;   | ___| ___  ___ ___  ___  ___
;   | |__ | _ ||  _  _ || , '| , |
;   |____||_ _||_| _| _|| __'|___|
;                       |_|                                

    title_1 db ' ____                         '
    title_2 db '| ___| ___  ___ ___  ___  ___ '
    title_3 db '| |__ | _ ||  _  _ || , )( , )'
    title_4 db '|____||_ _||_| _| _|| __)(___)'
    title_5 db '                    |_|       '


    TITLE_1_STR_LEN EQU 30
    TITLE_2_STR_LEN EQU 31
    ; =========== VARI?VEIS GERAIS =========== ;
    
    CR equ 13
    LF equ 10
    
    VIDEO_MODE EQU 01H             ;modo de v?deo para tela 40x25 e texto 8x8
    VIDEO_MEM_START EQU 0B800H     ;endere?o do buffer de v?deo para modo gr?fico 01H
    
    MAX_COLS EQU 80                ;m?ximo de colunas 40 por 2 bytes
    MAX_ROWS EQU 40                ;m?ximo de linhas 20 por 2 bytes

    GREEN EQU 2H
.code 

    PRINT_CHAR proc
        push AX   
        mov AH, 2
        int 21H
        pop AX     
        ret  
    endp   

    LINE_BREAK proc
        push DX
    
        mov DL, CR              
        call PRINT_CHAR
        mov DL, LF             
        call PRINT_CHAR
    
        pop DX
        
        ret
    endp

    ; Esceve string na tela atrav?s do endere?amento
    ; em mem?ria
    ; CONDI??O DE ENTRADA:
    ;   AX = Deslocamento da String na mem?ria
    ;   BL = Cor da String
    ;   BH = Cor de Fundo da String
    ;   CX = Tamanha da String
    ;   DL = LInha escrita
    ;   DH = Coluna escrita 
    WRITE_IN_VIDEO_MEM proc 

        push AX ;acho que n?o precisa, ver depois
        push DI
        push ES
        push SI

        mov SI, AX

        call GET_VIDEO_OFFSET

        mov DI, AX  

        mov AX, VIDEO_MEM_START
        mov ES, AX
        
        .L1:
        
        movsb
        mov ES:[DI], BL     ; especifica cor do char
        inc DI
        ;
        loop .L1        

        pop SI
        pop ES
        pop DI
        pop AX

    endp

    ; Calcula e retorna o deslocamento da mem?ria 
    ; da posi??o (linha, coluna) espeficada
    ; CONDI??O DE ENTRADA:
    ;   DL = Linha
    ;   DH = Coluna
    ;
    ; CONDI??O DE SA?DA:
    ;   AX = Deslocamento em mem?ria da posi??o
    GET_VIDEO_OFFSET proc

        push BX

        mov AX, 0

        mov AL, MAX_COLS
        mul DL
        
        mov BX, AX  ; salva AX para o pr?ximo c?lculo
 
        mov AL, 2   ; 2 bytes por char na tela
        mul DH

        add AX, BX
        
        pop BX
        ret

    endp

    MAIN_SCREEN proc
        
        push AX
        push BX
        push CX
        push DX    

        ;call PRINT_GAME_TITLE
        ;call PRINT_AUTHORS
        ;call PRINT_CONFIGURATIONS
        call PRINT_ASCII_TITLE

        pop DX
        pop CX
        pop BX
        pop AX
        ret
    endp 

    PRINT_GAME_TITLE proc

        mov DL, 2        ; linha 2
        mov DH, 12       ; coluna 12
        mov BX, GREEN

        mov AX, offset game_title
        mov CX, GAME_TITLE_STR_LEN

        call WRITE_IN_VIDEO_MEM
        ret
    endp
    
    PRINT_ASCII_TITLE proc

        mov DL, 4   
        mov DH, 1
        mov BX, GREEN

        mov AX, offset title_1
        mov CX, TITLE_1_STR_LEN

        call WRITE_IN_VIDEO_MEM
        mov DL, 5    
        mov DH, 1
        mov BX, GREEN

        mov AX, offset title_2
        mov CX, TITLE_1_STR_LEN

        call WRITE_IN_VIDEO_MEM
        mov DL, 6    
        mov DH, 1
        mov BX, GREEN

        mov AX, offset title_3
        mov CX, TITLE_1_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 7    
        mov DH, 1
        mov BX, GREEN

        mov AX, offset title_4
        mov CX, TITLE_1_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 8    
        mov DH, 1
        mov BX, GREEN

        mov AX, offset title_5
        mov CX, TITLE_1_STR_LEN

        call WRITE_IN_VIDEO_MEM

        ret    
    endp

    PRINT_AUTHORS proc

        mov DL, 4    
        mov DH, 16
        mov BX, GREEN

        mov AX, offset by_str
        mov CX, BY_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 6    
        mov DH, 12
        mov BX, GREEN

        mov AX, offset name_arthur
        mov CX, NAME_ARTHUR_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 8
        mov DH, 9
        mov BX, GREEN

        mov AX, offset name_marcello
        mov CX, NAME_MARCELLO_STR_LEN

        call WRITE_IN_VIDEO_MEM
        ret 
        
    endp

    PRINT_CONFIGURATIONS proc

        mov DL, 12    
        mov DH, 11
        mov BX, GREEN

        mov AX, offset configurations
        mov CX, CONFIGURATIONS_STR_LEN

        call WRITE_IN_VIDEO_MEM
            
        ret
    endp

    START_VIDEO_MODE proc

        push AX
        
        xor AX, AX
        mov AL, 01H    ;define formato cursor
        int 10H

        mov DX, 0FFFFH
        pop AX
        ret
    endp

    ;Posiciona cursor na linha e coluna especificadas
    ;em DH e DL, respectivamente
    SET_CURSOR proc

        push AX
        push BX
        mov AX, 2       ;usado para setar posi??o
        mov BX, 0       ;p?gina do v?deo
        int 10H

        pop BX
        pop AX
        ret
    endp

    main:
        mov AX, @DATA
        mov DS, AX
        
        call START_VIDEO_MODE
        call MAIN_SCREEN
        
        ;mov al, 0h
        ;mov ah, 4ch
        ;int 21h
        
    end main
    
