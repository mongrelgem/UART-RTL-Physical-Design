/* (c) Krishna Subramanian <https://github.com/mongrelgem>
 * UART Project <https://github.com/mongrelgem/USART-RTL-Physical-Design>
 * Report Bugs and Issues <https://github.com/mongrelgem/USART-RTL-Physical-Design/issues>
*/

module uart_tx (clk,baud_rate_select,start,Byte_To_Send,Tx_Active,Tx_Serial,Tx_Done,rst);
  //#(parameter baud_rate)
   input       clk;
	input 		rst;
	input [2:0]	baud_rate_select;
   input       start;
   input [7:0] Byte_To_Send; 
   output      Tx_Active;
   output reg  Tx_Serial;
   output      Tx_Done;
 
  parameter IDLE         = 3'b000;
  parameter TX_START_BIT = 3'b001;
  parameter TX_DATA_BITS = 3'b010;
  parameter TX_STOP_BIT  = 3'b011;
  parameter RESET      = 3'b100;
  
  reg [10:0]   baud_rate;
  reg [2:0]    State;
  reg [10:0]   clk_count;
  reg [2:0]    bit_index;
  reg [7:0]    Data_Byte;
  reg          Tx_Done;
  reg          Tx_Enable;
     
  always @(*)
    begin
		case (baud_rate_select)
		  3'b000:
			begin
				baud_rate = 11'b10000010010; //9600(1042)
			end
		  3'b001:
			begin
				baud_rate = 11'b01010110111; //14400(695)		
			end
		  3'b010:
			begin
				baud_rate = 11'b01000001001; //19200(521)
			end
		  3'b011:
			begin
				baud_rate = 11'b00100000101; //38400(261)
			end
		  3'b100:
			begin
				baud_rate = 11'b00010101110; //57600(174)
			end
		  3'b101:
			begin
				baud_rate = 11'b00001010111; //115200(87)
				$display("Baud rate = %d\n",baud_rate);
			end
		  3'b110:
			begin
				baud_rate = 11'b00001001111; //128000(79)
			end
		  3'b111:
			begin
				baud_rate = 11'b00000100111; //256000(39)
			end
		  default:
				baud_rate = 11'b10000010010; //9600
		endcase
    end		 
  
  always @(posedge clk or posedge rst)
    begin		
		if (rst)
			begin
				State     <= IDLE;
				clk_count <= 11'b00000000000;
				bit_index <= 3'b000;
				Data_Byte <= 8'b00000000;
				Tx_Done   <= 1'b0;
				Tx_Enable <= 1'b0;
			end
		else begin
      case (State)
        IDLE :
         begin
            Tx_Serial   <= 1'b1;         // Drive Line High for Idle
            Tx_Done     <= 1'b0;
            clk_count   <= 11'b00000000000;
            bit_index   <= 3'b000;
             
            if (start == 1'b1)
              begin
                Tx_Enable <= 1'b1;
                Data_Byte   <= Byte_To_Send;
                State   <= TX_START_BIT;
              end
            else
              State <= IDLE;
			end // case: IDLE
         
         
        // Send out Start Bit. Start bit = 0
        TX_START_BIT :
          begin
            Tx_Serial <= 1'b0;
             
            // Wait baud_rate-1 clock cycles for start bit to finish
            if (clk_count < (baud_rate - 1'b1))
              begin
                clk_count <= clk_count + 1'b1;
                State     <= TX_START_BIT;
              end
            else
              begin
                clk_count <= 11'b00000000000;
					 $display("start bit sent\n");
                State     <= TX_DATA_BITS;
              end
          end // case: TX_START_BIT
         
         
        // Wait baud_rate-1 clock cycles for data bits to finish         
        TX_DATA_BITS :
          begin
            Tx_Serial <= Data_Byte[bit_index];
             
            if (clk_count < (baud_rate-1'b1))
              begin
                clk_count <= clk_count + 1'b1;
                State     <= TX_DATA_BITS;
              end
            else
              begin
                clk_count <= 11'b00000000000;
                 $display("bit %b sent\n",bit_index);
                // Check if we have sent out all bits
                if (bit_index == 3'b111)
                  begin
                    bit_index <= 3'b000;
						  $display("all bits sent\n");
                    State   <= TX_STOP_BIT;
                  end
                else
                  begin             
						  bit_index <= bit_index + 1'b1;
                    State   <= TX_DATA_BITS;
                  end
              end
          end // case: TX_DATA_BITS
         
         
        // Send out Stop bit.  Stop bit = 1
        TX_STOP_BIT :
          begin
            Tx_Serial <= 1'b1;
            // Wait baud_rate-1 clock cycles for Stop bit to finish
            if (clk_count < (baud_rate-1'b1))
              begin
                clk_count <= clk_count + 1'b1;
                State     <= TX_STOP_BIT;
              end
            else
              begin
					 $display("stop bit sent\n");
                Tx_Done     <= 1'b1;
                clk_count <= 11'b00000000000;
                State     <= RESET;
                Tx_Enable   <= 1'b0;
              end
          end // case: TX_STOP_BIT
         
         
        // Stay here 1 clock
        RESET :
          begin
            Tx_Done <= 1'b1;
            State <= IDLE;
          end
        
        default :
          State <= IDLE;
         
      endcase
	 end
  end
 
  assign Tx_Active = Tx_Enable;
   
endmodule
