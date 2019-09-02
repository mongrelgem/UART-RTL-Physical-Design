/* (c) Krishna Subramanian <https://github.com/mongrelgem>
 * UART Project <https://github.com/mongrelgem/USART-RTL-Physical-Design>
 * Report Bugs and Issues <https://github.com/mongrelgem/USART-RTL-Physical-Design/issues>
*/

module uart_rx (clk, baud_rate_select, Rx_Serial, Rx_Done, Rx_Out, rst);
  //#(parameter baud_rate)

   input        clk;
   input        rst;
   input [2:0]  baud_rate_select;
   input        Rx_Serial;
   output       Rx_Done;
   output [7:0] Rx_Out;
  //reg [7:0] 	 Rx_Out;
  reg [10:0]	 baud_rate;  
  reg           Data_Received_R ;
  reg           Data_Received   ;
  reg				 Rx_Done; 
  reg [10:0]    clk_count;
  reg [2:0]     bit_index; //8 bits total
  reg [7:0]     Data_Byte;
  reg [2:0]     State;
  
  parameter IDLE         = 3'b000;
  parameter RX_START_BIT = 3'b001;
  parameter RX_DATA_BITS = 3'b010;
  parameter RX_STOP_BIT  = 3'b011;
  parameter RESET        = 3'b100;
   
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
	   
	//rx main
  always @(posedge clk or posedge rst)
    begin
       if (rst)
	 begin
	    State <= IDLE;
	    clk_count       <= 11'b00000000000;
            bit_index       <=  3'b000;
	    Data_Received   <=  1'b0;
	    Data_Received_R <=  1'b0;
	    Rx_Done         <=  1'b0;
	    Data_Byte       <= 8'b00000000;
	 end

      else begin
      Data_Received_R <= Rx_Serial;
      Data_Received   <= Data_Received_R;	
      case (State)
        IDLE :
          begin
            Rx_Done       <= 1'b0;
            clk_count <= 11'b00000000000;
            bit_index   <= 3'b000;
             
            if (Data_Received == 1'b0)          // Start bit detected
              State <= RX_START_BIT;
            else
              State <= IDLE;
          end
         
        // Check middle of start bit to make sure it's still low
        RX_START_BIT :
          begin
            if (clk_count == ((baud_rate - 1'b1) >> 1))
              begin
                if (Data_Received == 1'b0)
                  begin
                    clk_count <= 11'b00000000000;  // reset counter, found the middle
                    State     <= RX_DATA_BITS;
                  end
                else
                  State <= IDLE;
              end
            else
              begin
                clk_count <= clk_count + 1'b1;
                State     <= RX_START_BIT;
              end
          end // case: RX_START_BIT
         
         
        // Wait baud_rate-1 clock cycles to sample serial data
        RX_DATA_BITS :
          begin
            if (clk_count < (baud_rate - 1'b1))
              begin
                clk_count <= clk_count + 1'b1;
                State     <= RX_DATA_BITS;
              end
            else
              begin
                clk_count <= 11'b00000000000;
                Data_Byte[bit_index] <= Data_Received;
		$display("bit %b received\n",bit_index);
                 
                // Check if we have received all bits
                if (bit_index == 3'b111)
                  begin
		    bit_index <= 3'b000;
		    $display("all bits received\n");
                    State   <= RX_STOP_BIT;
                   
                  end
                else
                  begin
                    bit_index <= bit_index + 1'b1;
                    State   <= RX_DATA_BITS;
                  end
              end
          end // case: RX_DATA_BITS
     
     
        // Receive Stop bit.  Stop bit = 1
        RX_STOP_BIT :
          begin
            // Wait baud_rate-1 clock cycles for Stop bit to finish
            if (clk_count < (baud_rate-1'b1))
              begin
                clk_count <= clk_count + 1'b1;
                State     <= RX_STOP_BIT;
              end
            else
              begin
                Rx_Done       <= 1'b1;
		$display("stop bit received\n");
                clk_count <= 11'b00000000000;
                State     <= RESET;
              end
          end // case: RX_STOP_BIT
     
         
        // Stay here 1 clock
        RESET :
          begin
            State <= IDLE;
            Rx_Done   <= 1'b0;
          end
         
         
        default :
          State <= IDLE;
         
      endcase
    end   
   end
  assign Rx_Out = Data_Byte;
   
endmodule // uart_rx
