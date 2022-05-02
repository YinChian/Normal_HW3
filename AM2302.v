
`timescale 1ns/10ps

module AM2302 (SDA);
  
   inout                SDA;                            // serial data I/O   

   


// *******************************************************************************************************
// **   DECLARATIONS                                                                                    **
// *******************************************************************************************************

 

   reg  [39:00]         SensorData;          // data array
   wire                 SDA_IN;
   integer              ii;
   reg                  SDA_OE;
   reg                  SDA_DO;
   reg                  read_cnt;
   reg                  master_req;

// *******************************************************************************************************
// **   INITIALIZATION                                                                                  **
// *******************************************************************************************************
 

   initial begin
      SDA_DO = 0;
      SDA_OE = 0;
      read_cnt = 0;
      master_req = 0;
      
      SensorData = 40'h1234567814;      
   end
 
   
   assign SDA = (SDA_OE)? SDA_DO : 1'bz ;
   assign SDA_IN = SDA;
   
   assign wire_a = master_req; 

// *******************************************************************************************************
// **   CORE LOGIC                                                                                      **
// *******************************************************************************************************
//always@(posedge CLK)
always
 begin       
     
     wait(SDA_IN == 0);       // wait write pulse  
     master_req = 1;          // min 800us 
     wait(SDA_IN == 1);
     master_req = 0;

     ///   $width (posedge SDA_IN, 20_000); // min 20us     
      #30_000;  
      SDA_DO = 0; SDA_OE = 1;
      #(80_000);
      
      SDA_DO = 1; SDA_OE = 1;
      #(80_000);      
      
      $display("time=%3d,sensor send 0x%X",$time,SensorData); 
      // send Data Byte
      if(read_cnt == 0)
        SensorData = 40'h1234567814;
      else
        SensorData = 40'h9ABCDEF024; 
      read_cnt = read_cnt + 1; 
       
      for (ii=39; ii >= 0; ii=ii-1)
        begin
          SDA_DO = 0; SDA_OE = 1;
          #(50_000);
          
          SDA_DO = 1; SDA_OE = 1;
          if(SensorData[ii] == 1'b1)
            #(70_000);
          else
            #(26_000);
          
        end            
        
    SDA_DO = 0; SDA_OE = 1;   // end
    #(50_000);
    
    SDA_OE = 0;  // RELEASE SDA    
    $display("sensor send end");
    #(1_000_000);
    //  $display("uart rx data = %X ", RX_Serial);     
 end


specify 
   $width(posedge wire_a, 800_000); /* 4 is ok */ 
endspecify

endmodule
