module DragonCapture(
	input InternalClock,
	input HDMI_A_ClockP, HDMI_A_ClockN,
	output HDMI_B_ClockP, HDMI_B_ClockN,
	output [1:0] LED
);

wire HDMI_Clock;
reg [31:0] InternalClockCounter = 0, ExternalClockCounter = 0;
reg InternalState = 0, ExternalState = 0;

OBUFDS OBUFDS_B_Clock(.I(InternalClock), .O(HDMI_B_ClockP), .OB(HDMI_B_ClockN));
IBUFGDS IBUFDS_A_Clock(.I(HDMI_A_ClockP), .IB(HDMI_A_ClockN), .O(HDMI_Clock));

always @(posedge HDMI_Clock)
begin
	ExternalClockCounter <= ExternalClockCounter + 32'h111;
	ExternalState <= ExternalClockCounter > 32'h7FFFFFFF;
end

always @(posedge InternalClock)
begin
	InternalClockCounter <= InternalClockCounter + 32'h111;
	InternalState <= InternalClockCounter > 32'h7FFFFFFF;
end

assign LED[0] = ExternalState;
assign LED[1] = InternalState;

endmodule
