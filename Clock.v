`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE 3829
// Engineer: Aung Khant Min & Myo Min Thein
// Create Date: 09/26/2018 06:37:06 PM
// Design Name: 
// Module Name: Clock
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Clock is the top module. It uses 10Mhz clock for SCLK and 100kHz clock enable for the Chip Select. 
// After adding these clocks to DAC, we send data using DIN output. Another variable named "Sending[15]", used for accepting
// the variable volt(which is the voltage we are sending) and control bits, is plugged back inside DIN to send out data using the
// shift register. There is also a state machine with three states: Load(s0), Shift(s1), and Idle(s2)
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

module Clock(
   output CS,
   output DIN,
   output wire SCK,
   //output NC,
   output [3:0] vgaRed,
   output [3:0] vgaBlue,
   output [3:0] vgaGreen,
   output [6:0] seg,
   output [3:0] an,
   input clk_fpga,
   input [4:0] button,
   output Hsync,
   output Vsync
   );   
    wire clk_10M, clk_25M, locked, reset; 
//   wire [7:0] display;
//   reg [13:0] counter_2_5kHz;
    
    VGA display (.clk_25M(clk_25M), .clk_10M(clk_10M), . button(button), .vgaRed(vgaRed), .vgaGreen(vgaGreen), .vgaBlue(vgaBlue), .seg(seg), .an(an), .Hsync(Hsync), .Vsync(Vsync));
    
    parameter [7:0] p1 = 127; 
    parameter [7:0]p2 = 176; 
    parameter [7:0]p3 = 217, p4 = 244, p5 = 254, p6 = 244, p7 = 216, p8 = 176, p9 = 127, p10 = 78, p11 = 37, p12 = 10, p13 = 0, p14 = 10, p15 = 37, p16 = 78; 
         
    reg [4:0] count = 0;
    reg [6:0] counter_100kHz;
    wire clk_100kHz;
    reg send;
    reg [7:0] volt;
    reg [15:0] sending;
    parameter [1:0] s0 = 0, s1 =2'b01, s2 = 2;
    reg [1:0] current_state, next_state; 
        clk_wiz_0 instance_name
     (
     // Clock out ports
     .clk_10M(clk_10M),     // output clk_10M
     .clk_25M(clk_25M),
     // Status and control signals
     .reset(reset), // input reset
     .locked(locked),       // output locked
    // Clock in ports
     .clk_in1(clk_fpga));  
       
    
    assign reset = button[0];
    assign CS = clk_100kHz;
    assign SCK = clk_10M;
    assign DIN = sending[15]; 
    always @(posedge clk_10M, posedge reset)  
         begin
         if(reset)
             counter_100kHz <= 0;
         else if(counter_100kHz == 99)
             counter_100kHz <= 0;
         else 
             counter_100kHz <= counter_100kHz + 1;
         end
         
    assign clk_100kHz = (counter_100kHz > 83)? 1'b0 :  1'b1; //99-16 = 83. Need 16 cycles to get the data
    always @ ( count) 
    case (count)
        0: volt = p1; 
        1: volt = p2; 
        2: volt = p3; 
        3: volt = p4; 
        4: volt = p5; 
        5: volt = p6; 
        6: volt = p7; 
        7: volt = p8; 
        8: volt = p9; 
        9: volt = p10; 
        10: volt = p11; 
        11: volt = p12; 
        12: volt = p13; 
        13: volt = p14; 
        14: volt = p15;
        15: volt = p16; 
    endcase
    always@(posedge clk_10M, posedge reset)
    if( reset) 
        sending <= 0; 
    else if( current_state == s0) begin
            sending = {8'b0000_0000, volt};
            if(count == 16) 
                count <=0;
            else// if(count <16)
                count <= count + 1;  
            end
     else if(current_state == s1 && clk_100kHz == 0)
            sending = sending << 1;
     else 
        sending = sending;     
     
    always @(posedge clk_10M, posedge reset)
        if (reset)
                current_state = s0;
        else //if (SCK)    
                current_state = next_state;
    always @(current_state) 
        case(current_state) 
        s0: begin
            if(counter_100kHz == 82) 
                next_state = s1; 
            else
                next_state = s0; 
            end
         s1: begin
            if(counter_100kHz == 0) 
                next_state = s2; 
            else
                next_state = s1; 
         end
         s2: begin
            if(counter_100kHz == 81) 
                next_state = s0; 
            else   
                next_state = s2; 
         end
    endcase
   
endmodule
