      ORG   0   
  // delay     
      MOV   R0,#250
      DJNZ  R0,$  
  // start read AM2302  
      MOV  R0,#3
SEND_START:     
      MOV  0E1H,#01H
  
WAIT_LOOP: 
      MOV  A,0E1H    
      ANL  A,#10H	  
      JZ   WAIT_LOOP
  
  //  clear start_send / complete bit
      MOV  0E1H,#00  
  // read AM2302 data
    
      MOV  A,0E2H 
      MOV  A,0E3H
      MOV  A,0E4H
      MOV  A,0E5H
      MOV  A,0E6H
  
  // delay
      MOV   R2,#20
DELAY_LOOP:	  
      MOV   R1,#250
      DJNZ  R1,$      
      DJNZ  R2,DELAY_LOOP
      
      DJNZ R0,SEND_START
  //sim end
      JMP  0B16H
  
      END