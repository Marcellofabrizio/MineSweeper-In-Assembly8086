

.model small

.stack 100H

.data

    ;=========== TITULOS ===========;

    game_title db 'CAMPO MINADO'
    GAME_TITLE_STR_LEN EQU 12

    by_str db 'POR'
    BY_STR_LEN EQU 3

    name_arthur db 'ARTHUR CORSO'
    NAME_ARTHUR_STR_LEN EQU 12

    name_marcello db 'MARCELLO FABRIZIO'
    NAME_MARCELLO_STR_LEN EQU 17

    title_1 db '   ___    _    __  __  ___   ___  '
    title_2 db '  / __|  /_\  |  \/  || _ \ / _ \ '
    title_3 db ' | (__  / _ \ | |\/| ||  _/| (_) |'
    title_4 db '  \___|/_/ \_\|_|  |_||_|   \___/ '

    title_6 db ' __  __  __  _  _    _    ___    ___  '
    title_7 db '|  \/  ||__|| \| |  /_\  |   \  / _ \ '
    title_8 db '| |\/| | || | .` | / _ \ | |) || (_) |'
    title_9 db '|_|  |_||__||_|\_|/_/ \_\|___/  \___/ '

    TITLE_1_STR_LEN EQU 35
    TITLE_2_STR_LEN EQU 38

    ; =========== VARIVEIS CONFIGURACOES =========== ;

    configurations db 'CONFIGURACOES'
    CONFIGURATIONS_STR_LEN EQU 13 

    mines_config db 'NUMERO DE MINAS (>=5):'
    MINES_CONFIG_STR_LEN EQU 22

    field_width_config db 'LARGURA DO CAMPO [5;40]:'
    FIELD_WIDTH_CONFIG_STR_LEN EQU 24 

    field_height_config db 'ALTURA DO CAMPO [5;20]:'
    FIELD_HEIGHT_CONFIG_STR_LEN EQU 24

    user_config_input dw 3 dup (?)

    ; =========== VARI?VEIS GERAIS =========== ;
    
    BCK equ 8
    LF equ 10
    CR equ 13
    SPACE equ 32

    INPUT_LIMIT equ 3
    
    VIDEO_MODE EQU 01H             ;modo de video para tela 40x25 e texto 8x8
    VIDEO_MEM_START EQU 0B800H     ;endereco do buffer de video para modo grafico 01H
    
    MAX_COLS EQU 80                ;maximo de colunas 40 por 2 bytes
    MAX_ROWS EQU 40                ;maximo de linhas 20 por 2 bytes

    RED EQU 4H
    GREEN EQU 2H
    L_GREEN EQU 0AH
    BLUE EQU 1H
    CYAN EQU 3H
    MAGENTA EQU 5H
    BROWN EQU 6H
    WHITE EQU 0FH
    L_GRAY EQU 7H
    D_GRAY EQU 8H

.code 

    ;L? um char e armazena em AX
    READ_CHAR proc
        mov AH, 7
        int 21H
        ret       
      endp

    ;Escreve um char armazenado em DX
    PRINT_CHAR proc
        push AX   
        mov AH, 2
        int 21H
        pop AX     
        ret  
    endp   

    DELETE_CHAR proc
        push AX
        push DX

        mov DL, BCK
        call PRINT_CHAR

        mov DL, SPACE
        call PRINT_CHAR

        mov DL, BCK
        call PRINT_CHAR

        pop DX
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
    ; CONDICAO DE ENTRADA:
    ;   AX = Deslocamento da String na mem?ria
    ;   BL 4 bits menos significativos = Cor da string
    ;   BL 4 bits mais significativos = Cor de fundo
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
        mov ES:[DI], BX     ; especifica cor do char
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

        call PRINT_ASCII_TITLE
        call PRINT_AUTHORS
        call PRINT_CONFIGURATIONS

        call GET_GAME_CONFIGS                

        pop DX
        pop CX
        pop BX
        pop AX
        ret
    endp 
    
    PRINT_ASCII_TITLE proc

        mov DL, 1   
        mov DH, 2
        mov BX, GREEN

        mov AX, offset title_1
        mov CX, TITLE_1_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 2    
        mov DH, 2
        mov BX, GREEN

        mov AX, offset title_2
        mov CX, TITLE_1_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 3    
        mov DH, 2
        mov BX, GREEN

        mov AX, offset title_3
        mov CX, TITLE_1_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 4    
        mov DH, 2
        mov BX, GREEN

        mov AX, offset title_4
        mov CX, TITLE_1_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 5   
        mov DH, 1
        mov BX, GREEN

        mov AX, offset title_6
        mov CX, TITLE_2_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 6    
        mov DH, 1
        mov BX, GREEN

        mov AX, offset title_7
        mov CX, TITLE_2_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 7    
        mov DH, 1
        mov BX, GREEN

        mov AX, offset title_8
        mov CX, TITLE_2_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 8    
        mov DH, 1
        mov BX, GREEN

        mov AX, offset title_9
        mov CX, TITLE_2_STR_LEN

        call WRITE_IN_VIDEO_MEM
        ret    
    endp

    PRINT_AUTHORS proc

        mov DL, 10    
        mov DH, 16
        mov BX, GREEN

        mov AX, offset by_str
        mov CX, BY_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 11    
        mov DH, 12
        mov BL, GREEN

        mov AX, offset name_arthur
        mov CX, NAME_ARTHUR_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 12
        mov DH, 9
        mov BL, GREEN

        mov AX, offset name_marcello
        mov CX, NAME_MARCELLO_STR_LEN

        call WRITE_IN_VIDEO_MEM
        ret 
        
    endp

    PRINT_CONFIGURATIONS proc

        mov DL, 14    
        mov DH, 11
        mov BX, RED
        shl BX, 4
        add BL, WHITE

        mov AX, offset configurations
        mov CX, CONFIGURATIONS_STR_LEN

        call WRITE_IN_VIDEO_MEM
        
        mov DL, 16    
        mov DH, 7
        mov BX, GREEN

        mov AX, offset mines_config
        mov CX, MINES_CONFIG_STR_LEN

        call WRITE_IN_VIDEO_MEM

        mov DL, 18    
        mov DH, 7
        mov BX, GREEN

        mov AX, offset field_width_config
        mov CX, FIELD_WIDTH_CONFIG_STR_LEN

        call WRITE_IN_VIDEO_MEM
    
        mov DL, 20    
        mov DH, 7
        mov BX, GREEN

        mov AX, offset field_height_config
        mov CX, FIELD_HEIGHT_CONFIG_STR_LEN

        call WRITE_IN_VIDEO_MEM
        ret
    endp

    GET_GAME_CONFIGS proc

        push AX
        push BX
        push DX

        mov AX, user_config_input
        mov DL, 32 ; tamanho da maior linha mais um padding

        mov BX, 0
        mov CX, 3   ; para o loop de tres campos
        mov BL, 16  ; primeira linha

        INPUT:

        mov DH, BL

        call SET_CURSOR
        call GET_USER_INPUT

        add BL, 2

        loop INPUT

        pop DX
        pop BX
        pop AX

        ret
    endp


    GET_USER_INPUT proc

        call READ_USER_INPUT    

        ret
    endp

    READ_USER_INPUT proc

        push BX
        push CX
        push DX 

        mov BX, 10
        xor AX, AX
        xor CX, CX
        Xor DX, DX

        push DX 
        push CX
        push BX

        jmp READ_LOOP

        SAVE_CHAR:

        push AX     ; salva AX na pilha para poder acessar os caracteres

        READ_LOOP:
        
        call READ_CHAR

        cmp AL, CR
        jz SAVE_CHAR

        cmp AL, BCK     ; deletou
        jz DELETE
        
        cmp CX, INPUT_LIMIT     ; limite de caracteres
        jz READ_LOOP

        cmp AL, '0'
        jb READ_LOOP

        cmp AL,'9'        
        ja READ_LOOP
        
        mov DL, AL            
        call PRINT_CHAR

        mov CL, AL      ; salvar em CL o caractere
        sub CL, '0'     ; transforma o caractere em valor ('3' -> 3)
    
        pop AX          ; restaurando o acumulador 
    
        mul BX          ; deslocamento esquerda do numero para a soma
        add AX,CX

        inc CX
        jmp READ_LOOP

        DELETE:
        
        pop AX
        cmp CX, 0
        jz SAVE_CHAR

        dec CX
        div BL
        xOr AH, AH

        push AX
        div BL
        mov DL,AH    
        pop AX   
    
        call DELETE_CHAR    
        jmp SAVE_CHAR

        FINISH_READ:
        pop AX

        pop DX
        pop CX
        pop BX
        
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
        xor AX, AX
        mov AH, 2       ;usado para setar posi??o
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
    
