# UART: RTL - Physical-Design
Complete ASIC Design of UART Interface with user selectable Baud Rate :- RTL to GDS2

Universal Asynchronous Receiver Transmitter is used for asynchronous communication between two or more modules which are running at different clock frequencies. UART uses a fixed baud rate for synchronization of a synchronous data transfer. The baud rate on the receiver and transmitter must be same for data synchronization.

![Block Diagram](https://github.com/mongrelgem/USART-RTL-Physical-Design/blob/master/Diagrams/Block%20Diagram.JPG?raw=true)

### Cotents

* The report file gives an overview of the USART protocol and covers the complete design flow.
* The uart_tx.v and uart_rx.v are the verilog descriptions for USART transmitter and receiver.
* CharLib.pl is the perl script which automates the library characterization by taking some inputs from the user.
* Convert.pl is the perl script which handles the cross platform conversion of the .LEF file (virtuoso to encounter).
* ViaAddition.pl and Cover.tcl are the scripts to fix the potential DRC errors after PNR.

In this project two modules, a transmitter and a receiver are designed. Both modules have a baud rate selection option. User can select between 8 different baud rates which are 9600, 14400, 19200, 38400, 57600, 115200, 128000, and 256000. The transmitter module receives 8-bit data parallelly from the system using 8-bit data bus and receives 2 control signals (start and reset) and a clock. Tx module starts sending out the data serially, at selected baud rate, when it detects high on start signal. Sync flip flop is used to mitigate the metastability issues. The receiver receives the data serially on serial data bus and it is tuned to the same baud rate as the transmitter. 

The UART transmits and receives the LSB first. The UART’s transmitter and receiver are functionally independent but use the same data format and baud rate. The Baud Rate Generator produces a clock, either x16 or x64 of the bit shift rate depending on the BRGH and BRG16 bits (TXSTA and BAUDCON). Parity is not supported by the hardware but can be implemented in software and stored as the 9th data bit. 
* The start bit signals the receiver that a new character is coming. 
* The next five to eight bits, depending on the code set employed, represent the character. 
*  The next one or two bits are always logic high, i.e., '1' condition and called the stop bit(s). They signal the receiver that the character is completed. 
* Since the start bit is logic low (0) and the stop bit is logic high (1) there are always at least two guaranteed signal changes between characters. 

![frame format](https://github.com/mongrelgem/USART-RTL-Physical-Design/blob/master/Diagrams/Frame.JPG?raw=true)

#### Transmitter 
1.	The transmitter module receives the 8-bit parallel data and waits for start signal to go high. 
2.	The user can select baud rate from 8 different options available. 

| **Operation** | **Code**   | 
| ------------- |:----------:| 
| 9600          |    000     | 
| 14400         |    001     |
| 19200         |    010     |
| 38400         |    011     | 
| 57600         |    100     |
| 115200        |    101     |
| 12800         |    110     | 
| 25600         |    111     |

 
3.	The 3-bit baud rate select works as select lines for a 8:1 multiplexer and baud rate to be used is selected. 
4.	Once the inputs are latched and baud rate is selected, start signal is ready to go high. 
5.	Once the start signal goes high a start bit is sent on the serial bus followed by 8-bit user data and a stop bit. 
Receiver 

![Transmitter](https://github.com/mongrelgem/USART-RTL-Physical-Design/blob/master/Diagrams/Layout%20Transmitter.JPG?raw=true)


#### Receiver
1.	The receiver receives this serial data which was sent at a fixed baud rate on its input port. The receiver MUST be configured to the same baud rate at which transmitter is sending the data to properly receive data. 
2.	Once the receiver detects the start bit at the input for half baud cycle, it starts latching the incoming data. 
3.	As soon as receiver receives all 8-bits it checks for stop bits and then goes to IDLE state to receive next incoming data. 
4.	Simultaneously the current data is made available on the output port which can be used parallelly. 
After deciding flow of design as specified above we designed this system in behavioral VerilogHDL. 

![Receiver](https://github.com/mongrelgem/USART-RTL-Physical-Design/blob/master/Diagrams/Receiver.JPG?raw=true)


### Simulation Output

![Waveforms](https://github.com/mongrelgem/USART-RTL-Physical-Design/blob/master/Diagrams/Waveforms.JPG?raw=true)


### Physical design of the standard cells:  
* To synthesize the behavioral code a library needs to be designed. To design this library first step was to layout the cells. Following are the cells which we included in the library. Aoi22, Oai21, Oai211, Inverter, Nand2, Nor2, Xor2, 2:1 multiplexer, and a falling edge triggered active high reset D flip-flop. Every layout in the library is optimized for area on chip.
* After laying out all the 9 cells in the physical library, schematics for these cells was created and their functionality verified using HSPICE once DRC/LVS was cleared. 
* Next step was to generate the library in the liberty (.lib) format and also ASCII format description of physical cells in LEF format. 

### Generating library in liberty format and .db format:
* The tools used to generate this library were SiliconsmartACE and Library compiler. Siliconsmart takes all spice netlist files for each cell as an input and generates the .lib library file. This process was automated using a Perl script where canges were made to the instance file. The instance files get automatically generated when spice netlists are imported. By default, all input and output pins were getting defined with inout direction. So, a script was written to change this direction of pins according to their behavior. This step generated the .lib format library. 
* The synthesis tool (Design Vision) cannot read this liberty formatted file. Therefore, using library compiler this .lib file was converted to .db file so that design vision can read this library file and the behavioral design can be synthesized. 

 



`STA & Primetime report attached to Report.pdf`



