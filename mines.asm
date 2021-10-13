

.model small

.stack 100H

.data
    hello_str db 'HELLO DOS!'
    HELLO_STR_LEN EQU 10

    name db 'MARCELLO'
    NAME_STR_LEN EQU 8

    mine_title1 db ' ######\   ######\  ##\      ##\ #######\   ######\  ' 
    mine_title2 db '##  __##\ ##  __##\ ###\    ### |##  __##\ ##  __##\ '
    mine_title3 db '## /  \__|## /  ## |####\  #### |## |  ## |## /  ## |'
    mine_title4 db '## |      ######## |##\##\## ## |#######  |## |  ## |'
    mine_title5 db '## |      ##  __## |## \###  ## |##  ____/ ## |  ## |'
    mine_title6 db '## |  ##\ ## |  ## |## |\#  /## |## |      ## |  ## |'
    mine_title7 db '\######  |## |  ## |## | \_/ ## |## |       ######  |'
    mine_title8 db ' \______/ \__|  \__|\__|     \__|\__|       \______/ '
    
    TITLE_LEN EQU 54
    
    CR equ 13
    LF equ 10
    
    VIDEO_MODE EQU 01H             ;modo de v?deo para tela 40x25 e texto 8x8
    VIDEO_MEM_START EQU 0b800h     ;endere?o do buffer de v?deo para modo gr?fico 01H
    
    MAX_COLS EQU 80     ;máximo de colunas 40 por 2 bytes
    MAX_ROWS EQU 40     ;máximo de linhas 20 por 2 bytes
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

    ; Esceve string na tela através do endereçamento
    ; em memória
    ; CONDIÇÃO DE ENTRADA:
    ;   AX = Deslocamento da String na memória
    ;   BX = Cor da String
    ;   CX = Tamanha da String
    ;   DH = Coluna escrita
    ;   DL = LInha escrita
    WRITE_IN_VIDEO_MEM proc 

        push AX ;acho que não precisa, ver depois
        push DI
        push ES
        push SI

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

    ; Calcula e retorna o deslocamento da memória 
    ; da posição (linha, coluna) espeficada
    ; CONDIÇÃO DE ENTRADA:
    ;   DH = Coluna
    ;   DL = Linha
    ;
    ; CONDIÇÃO DE SAÍDA:
    ;   AX = Deslocamento em memória da posição
    GET_VIDEO_OFFSET proc

        push BX

        mov AX, 0

        mov AL, MAX_COLS
        mul DL
        
        mov BX, AX  ; salva AX para o próximo cálculo

        xor AX
        mov AH, 2   ; 2 bytes por char na tela
        mul DH

        add AX, BX
        
        pop BX

    endp

    MAIN_SCREEN proc
        
        push AX
        push BX
        push CX
        push DX    

        call PRINT_GAME_TITLE

        pop DX
        pop CX
        pop BX
        pop AX
        ret
    endp 

    PRINT_GAME_TITLE proc

        mov CX, HELLO_STR_LEN
        mov AX, offset hello_str



        ret
    endp

    START_VIDEO_MODE proc

        push AX
        
        mov AH
        mov AL, 01H     ;define formato cursor

        mov DH, 0FFH
        mov DL, 0FFH

        call SET_CURSOR

        pop AX
        ret
    endp

    ;Posiciona cursor na linha e coluna especificadas
    ;em DH e DL, respectivamente
    SET_CURSOR proc

        push AX
        push BX
        mov AX, 2       ;usado para setar posição
        mov BX, 0       ;página do vídeo
        int 10H

        pop BX
        pop AX
        ret
    endp

    main:
        mov AX, @DATA
        mov DS, AX
        
        mov AH, 01H
        mov AL, 13H     ;modo de escrita de string da interrup??o 10H
        int 10H
        
        mov AX, 1301h
        mov BH, 0 
        mov BL, 02h 

        mov CX, str_end - offset str1      ;comprimento da string
        mov DL, 15       ;coordenada X na tela
        mov DH, 5        ;coordenada Y na tela
        
        push DS
        pop ES
        
        mov BP, offset str1
        int 10H
        
        mov CX, str_end2 - offset strl2      ;comprimento da string
        mov DL, 15       ;coordenada X na tela
        mov DH, 5        ;coordenada Y na tela
        
        push DS
        pop ES
        
        mov BP, offset strl2
        int 10H
        
        mov al, 0h
        mov ah, 4ch
        int 21h
        
    end main
    
