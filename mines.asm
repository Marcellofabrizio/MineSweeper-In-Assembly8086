

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

    board_width_config db 'LARGURA DO CAMPO [5;40]:'
    BOARD_WIDTH_CONFIG_STR_LEN EQU 24 

    board_height_config db 'ALTURA DO CAMPO [5;20]:'
    BOARD_HEIGHT_CONFIG_STR_LEN EQU 24

    config_options_lines db 16,18,20
    config_options dw 3 dup (?)

    MAX_NUM_MINES EQU 5

    MIN_BOARD_WIDTH EQU 5
    MAX_BOARD_WIDTH EQU 40

    MIN_BOARD_HEIGHT EQU 5
    MAX_BOARD_HEIGHT EQU 20

    MAX_BOARD_SIZE EQU 800

    ; ============= VARIAVEIS JOGO ============= ;

    INITIAL_LINE_LABEL EQU 'A'
    INITIAL_COL_LABEL EQU 1

    possible_x_moves db -1, 0, 1, -1, 1, -1, 0, 1
    possible_y_moves db -1, -1, -1, 0, 0, 1, 1, 1

    ; vetor onde ser?o feitas as operacoes logicas do jogo
    logical_board db MAX_BOARD_SIZE dup(0)
    BOMB EQU 0Ah

    uncovered_blocks dw ?
    board_size dw ?

    game_result dw 0    ; 0 - perdeu, 1 - ganhou, so sera valido se game_over = 1
    game_over dw 0      ; 0 - jogo em andamento, 1 - jogo terminou
    marked_bombs DW 0   ; numero de bombas marcadas

    ; esta variavel e a semente que vai ser utilizada para a geracao de numeros aleatorios 
    ; com o gerador congruente linear
    prev_seed_lcg dw 1664
    LCG_MULTIPLIER EQU 21   ; multiplicador para o LCG
    LCG_INCREMENT EQU 13    

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

    START_SCREEN proc
        
        push AX
        push BX
        push CX
        push DX    

        ;call PRINT_ASCII_TITLE
        ;call PRINT_AUTHORS
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

        mov AX, offset board_width_config
        mov CX, BOARD_WIDTH_CONFIG_STR_LEN

        call WRITE_IN_VIDEO_MEM
    
        mov DL, 20    
        mov DH, 7
        mov BX, GREEN

        mov AX, offset board_height_config
        mov CX, BOARD_HEIGHT_CONFIG_STR_LEN

        call WRITE_IN_VIDEO_MEM
        ret
    endp

    GET_GAME_CONFIGS proc

        push AX
        push DX

        push offset config_options   ;empilha para as tres entradas

        mov DI, 0
        mov CX, 3   ; para o loop de tres campos
        
        INPUT:
        
        mov DL, 32  ; tamanho da maior linha mais um padding
        mov BX, offset config_options_lines  ; primeira linha


        mov AL, [BX+DI]
        mov DH, AL
        
        inc BX

        call SET_CURSOR
        
        call READ_USER_INPUT

        call SAVE_USER_INPUT

        inc DI        
        loop INPUT

        pop BX
        pop DX
        pop AX

        ret
    endp

    ;Posiciona cursor na linha e coluna especificadas
    ;em DH e DL, respectivamente
    SET_CURSOR proc

        push AX
        push BX
        xor AX, AX
        mov AH, 2       ;usado para setar posicao
        mov BX, 0       ;pagina do video
        int 10H

        pop BX
        pop AX
        ret
    endp

    READ_USER_INPUT proc  ; le o valor do teclado em AX
        push BX
        push CX
        push DX 

        xor AX, AX 
        xor CX, CX
        xor DX, DX ; contador de caracteres
        mov BX, 10
                    
        SAVE_LOOP:
        push AX    ; salvando o acumulador
        READ_LOOP:       
        call READ_CHAR           ; ler o caractere
         
        cmp AL, CR              ; verifica se eh ENTER
        jz END_READ ; je

        cmp AL, BCK  ;Verifica se pressionou backspace
        jz DELETE

        cmp DX, 3
        jz READ_LOOP

        cmp AL, '0'            
        jb READ_LOOP 
      
        cmp AL, '9'
        ja READ_LOOP 

        push DX                 
        mov DL, AL
        call PRINT_CHAR
        pop DX

        mov CL, AL
        sub CL, '0'
       
        pop AX
        push DX
        mul BX
        add AX,CX
        pop DX
        
        inc DX
        jmp SAVE_LOOP

        DELETE:        
                
        pop AX
        cmp DX,0
        jz SAVE_LOOP

        dec DX 
        div BL 
        xor AH,AH

        push AX
        div BL
        mov CL,AH    
        pop AX   
    
        call DELETE_CHAR    
        jmp SAVE_LOOP

        END_READ: 
        pop AX                  ; restaurando o acumulador              
        pop DX
        pop CX
        pop BX    
        ret
    endp

    ; Salva entrada do usu?rio no deslocamento de 
    ; mem ria em BX 
    ; CONDICA DE ENTRADA:
    ;   DI = Campo atual que se deseja salvar a entrada
    SAVE_USER_INPUT proc

        mov BX, offset config_options

        push DI
        push AX
        push DX
        push BX
        
        mov AX, DI
        mov BX,2

        mul BX

        pop BX
        pop DX

        mov DI, AX
        pop AX

        mov [BX+DI],AX
        pop DI

        ret
    endp

    VALIDATE_USER_INPUT proc

        push BX
        push CX

        call VALIDATE_MINES_INPUT
        cmp AX, 0
        jz INVALID_INPUT    

        call VALIDATE_BOARD_WIDTH_INPUT
        cmp AX, 0
        jz INVALID_INPUT    

        call VALIDATE_BOARD_HEIGHT_INPUT
        cmp AX, 0
        jz INVALID_INPUT    
        
        mov AX, 1
        jmp END_VALIDATE_INPUT

        INVALID_INPUT:
        
        mov AX, 0

        END_VALIDATE_INPUT:
        pop CX
        POP BX

        ret
    endp

    VALIDATE_MINES_INPUT proc

        call GET_NUM_MINES
        cmp AX, MAX_NUM_MINES
        jb INVALID_MINES_VALUE 

        mov AX, 1
        jmp END_VALIDATE_MINES

        INVALID_MINES_VALUE:
        mov AX, 0
        
        END_VALIDATE_MINES:
        ret
    endp

    VALIDATE_BOARD_WIDTH_INPUT proc

        call GET_BOARD_WIDTH
        cmp AX, MIN_BOARD_WIDTH
        jb INVALID_BOARD_WIDTH 

        cmp AX, MAX_BOARD_WIDTH
        ja INVALID_BOARD_WIDTH

        mov AX, 1
        jmp END_VALIDATE_BOARD_WIDTH

        INVALID_BOARD_WIDTH:
        mov AX, 0
        
        END_VALIDATE_BOARD_WIDTH:
        ret
    endp

    VALIDATE_BOARD_HEIGHT_INPUT proc

        call GET_BOARD_HEIGHT
        cmp AX, MIN_BOARD_HEIGHT
        jb INVALID_BOARD_HEIGHT

        cmp AX, MAX_BOARD_HEIGHT
        ja INVALID_BOARD_HEIGHT

        mov AX, 1
        jmp END_VALIDATE_BOARD_HEIGHT

        INVALID_BOARD_HEIGHT:
        mov AX, 0
        
        END_VALIDATE_BOARD_HEIGHT:
        ret
    endp

    GET_NUM_MINES proc    
        MOV AX, 0
        call GET_CONFIG_OPTION
        ret
    endp

    GET_BOARD_WIDTH proc
        MOV AX, 1
        call GET_CONFIG_OPTION
        ret
    endp

    GET_BOARD_HEIGHT proc  
        MOV AX, 2
        call GET_CONFIG_OPTION
        ret
    endp

    ; Retorna opCAo de configuracao solicitada
    ; CONDICAO DE ENTRADA:
    ;   AX = Posicao da opcao que se deseja buscar
    ;
    ; CONDICAO DE SAIDA:
    ;   AX = Opcao desejada
    GET_CONFIG_OPTION proc

        push BX
        push DI    
        push DX

        mov DX, 0
        mov BL, 2
        mul BL

        mov BX, offset config_options
        mov DI, AX
        mov AX, [BX+DI]

        pop DX
        pop DI    
        pop BX

        ret
    endp

    START_GAME proc

        call SET_INITIAL_GAME_STATE
        call SET_LOGIC_BOARD

        ret
    endp

    SET_INITIAL_GAME_STATE proc

        push AX
        push BX

        call GET_BOARD_WIDTH
        mov BX, AX

        call GET_BOARD_HEIGHT
        mul BX                      ; calcula o tamanho do tabuleiro

        mov BX, offset board_size
        mov [BX], AX                ;GUarda o tamanho definido do tabuleiro

        MOV AX, 0 

        mov BX, offset uncovered_blocks
        mov [BX], AX                ; guarda n?mero de blocos j? descobertos, comeca vazio

        mov BX, offset marked_bombs
        mov [BX], AX

        mov BX, offset game_result
        mov [BX], AX 

        mov BX, offset game_over
        mov [BX], AX

        pop BX
        pop AX

        ret
    endp

    SET_LOGIC_BOARD proc

        PUSH AX
        push BX
        push CX
        push DX

        call GET_NUM_MINES
        mov CX, AX

        SET_BOMB_LOOP:
        call SET_BOMB
        loop SET_BOMB_LOOP

        call GET_BOARD_HEIGHT
        mov CX, AX

        HEIGHT_LOOP:        ; Iteracao sobre as linhas do tabuleiro

        push CX        

        dec CX
        Mov DL, CL          ; seta coordenada Y em DL

        call GET_BOARD_WIDTH
        mov CX, AX

        WIDTH_LOOP:         ; Iteracao sobre as colunas

        push CX

        dec CX
        mov DH, CL          ; Seta coordenada X em DH

        ;Com X e Y em DX, agora se percore a area ao redor da posicao para setar
        ;o numero de minas ao redor de Tab[x, y] 
        call SET_BOMBS_GRID

        pop DX
        POP CX
        pop BX
        pop AX

        ret
    endp

    ; Seta uma bomba em uma posicao aleatoria do vetor do campo logico
    SET_BOMB proc 

        push AX
        push BX
        push DX
        push DI

        mov BX, offset board_size
        mov AX, [BX]
        mov BX, AX

        SET_LOOP:
        call LCG
        mov DX, AX
        HAS_BOMBS_TO_PLANT_LOOP:
        push BX

        mov DI, DX              ; Seta DI como indice aleatorio no  tabuleir
        mov BX, offset logical_board
        mov AX, [BX+DI]

        cmp AX, BOMB            ; Verifica se posicao possui uma bomba
        jnz PUT_BOMB            ; se nao tiver bomba, planta

        pop BX
        inc DX
        mov DI, DX

        cmp BX, DX              ; Verifica se não passou do limite do campo
        jna HAS_BOMBS_TO_PLANT_LOOP

        mov DX, 0
        jmp SET_BOMB_LOOP

        PUT_BOMB:
        pop BX
        
        mov BX, offset logical_board
        mov AX, BOMB
        mov [BX+DI], AX
        mov BX, offset prev_seed_lcg
        mov [BX], DX

        pop DI
        pop DX
        pop BX
        pop AX

        ret
    endp

    ; Seta o numero de bombas ao redor da posicao tab[x, y]
    ; CONDICAO INICIAL:
    ;   DH = Coordenada X no tabuleiro
    ;   DL = Coordenada Y no tabuleiro
    SET_BOMBS_GRID proc



        ret
    endp

    HAS_BOMB_IN_POSITION proc



        ret
    endp

    ; Retorna o valor da posicao X, Y no tabuleiro logico
    ; CONDICAO INICIAL:
    ;   DH = Coordenada X
    ;   DL = Coordenada Y
    ; CONDICAO DE SAIDA:
    ;   AX = Valor de TabLogico[X, y]
    GET_POSITION_VALUE proc

        push BX
        push DX
        push DI



        pop DI
        pop DX
        pop BX

        ret
    endp

    ; Verifica se posicao em X, Y esta dentro nos limites do tabuleiro 
    ;   DH = Coordenada X
    ;   DL = Coordenada Y
    ; CONDICAO DE SAIDA:
    ;   AX = 0 se posicao estiver fora, 1 se posicao estiver dentro
    IS_POSITION_IN_RANGE proc

        

        ret
    endp

    ; Retorna o Deslocamento da coordenada X, Y no tabuleiro logico
    ; CONDICAO INICIAL:
    ;   DH = Coordenada X
    ;   DL = Coordenada Y
    ; CONDICAO DE SAIDA:
    ;   AX = Deslocamento da posicao no tabuleiro logico
    GET_LOGICAL_BOARD_OFFSET proc

        push BX
        xor BX, BX

        call GET_BOARD_WIDTH
        mul DL              ; Multiplica coordenada Y pelo numero de colunas
        mov BL, DH
        add AX, BX

        pop BX

        ret
    endp

    ; Gera um n?mero pseudo-aleat?rio utilizando o algoritmo
    ; Gerador congruente linear(https://pt.wikipedia.org/wiki/Geradores_congruentes_lineares)
    ;
    ;   Algoritmo: (a * Xi-1 + c) mod m, onde
    ;               a eh o multiplicador 0 < a < m
    ;               Xi-1 eh a semente anterior, ou seja, o ultimo num aleatorio gerado
    ;               c eh o incremento
    ;               m eh o espaco para geracao dos numeros
    ;
    ; CONDICAO INICIAL:
    ;   AX = Espaco para geracao dos numeros
    ; CONDICAO DE SAIDA:
    ;   AX = Numero aleatorio gerado
    LCG proc

        push BX
        push CX
        PUSH DX

        mov BX, AX                      
        mov AX, LCG_MULTIPLIER          ; AX eh o multiplicador
        xor CX, CX

        push BX
        mov BX, offset prev_seed_lcg    ; Valor da ultima semente gerada
        mov CX, [BX]                    ;
        add CX, LCG_INCREMENT           ; CX = Xi-1 + c
        pop BX
        mul CX                          ; AX = a * (Xi-1 + c)
        xor DX, DX
        
        div BX                          ; Divide valor gerado pelo tamanho do campo
                                        ; e salva valor gerado em DX
        mov AX, DX
        mov BX, offset prev_seed_lcg
        mov [BX], AX

        pop DX
        pop CX
        pop BX

        ret
    endp

    DRAW_BOARD proc

        push AX
        push BX
        push CX
        push DX

        ; limpando tela
        call START_VIDEO_MODE

        mov AX, INITIAL_LINE_LABEL
        mov BX, 0
        call DRAW_LABELS

        mov AX, INITIAL_COL_LABEL
        mov BX, 1
        call DRAW_LABELS

        pop DX
        pop CX
        pop BX
        pop AX

        ret
    endp

    ; Desenha os labels do tabuleiro
    ; CONDICAO INICIAL:
    ;   AX = Valor inicial dos labels
    ;   BX = Orientacao, 0 se for linhas e 1 se for colunas
    DRAW_LABELS proc

        push CX
        push DX

        xor DX, DX
        mov DH, 2
        call SET_CURSOR

        xor DX, DX

        cmp BX, 0
        jz Y_LABELS

        cmp BX, 1
        jz X_LABELS

        Y_LABELS:
        push AX
        call GET_BOARD_HEIGHT
        mov DH, 2
        mov CX, AX
        pop AX

        DRAW_Y:

        call SET_CURSOR

        push DX
        mov DX, AX
        call PRINT_CHAR
        pop DX

        inc DH
        inc AX

        loop DRAW_Y
        jmp END_DRAW

        X_LABELS:
        push AX
        call GET_BOARD_WIDTH
        mov DH, 1
        mov DL, 1
        mov CX, AX
        pop AX

        DRAW_X:
        call SET_CURSOR

        push DX
        push BX
        push AX
        push CX

        mov CX, AX

        mov BX, 10

        DIV_LOOP:
        xor DX, DX
        div BX

        add DL, '0' 
        call PRINT_CHAR

        cmp AX, 0
        jz NEXT_LABEL_X

        push CX
        push DX

        xor DX, DX
        mov DH, 0
        mov DL, CL
        call SET_CURSOR
        pop DX        
        pop CX

        jmp DIV_LOOP

        NEXT_LABEL_X:
        pop CX
        pop AX
        pop BX
        pop DX

        inc DL
        inc AX

        loop DRAW_X

        END_DRAW:

        pop DX
        pop CX

        ret
    endp

    START_VIDEO_MODE proc

        push AX
        
        xor AX, AX
        mov AL, 01H    ;define formato cursor
        int 10H

        pop AX
        ret
    endp

    main:
        mov AX, @DATA
        mov DS, AX
        
        START_SCREEN_LOOP:        
        call START_VIDEO_MODE
        call START_SCREEN
        call VALIDATE_USER_INPUT

        cmp AX, 0
        jz START_SCREEN_LOOP

        GAME_LOOP:
        call DRAW_BOARD
        ;call START_GAME

        mov al, 0h
        mov ah, 4ch
        int 21h
        
    end main
    

    