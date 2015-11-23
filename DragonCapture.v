module DragonCapture(
	input InternalClock,
	output [1:0] LED
);

DragonCore Core(.Clock(InternalClock), .LED(LED));

/*
reg [35:0] dstack [0:63];
reg [9:0] rstack [0:15];
reg [35:0] ram [0:1023];
reg [9:0] pc = 0;
reg [5:0] dtop = 0;
reg [3:0] rtop = 0;
reg InternalState = 0;
reg Fault = 0;
wire [35:0] insn = ram[pc];
wire satisfied = dstack[dtop] != 0;

initial
begin : init_blk
	reg [31:0] k;

	$readmemh("ram.bin", ram, 0, 1023);
	for (k = 0; k < 64; k = k + 1) begin
		dstack[k] = 0;
	end
	for (k = 0; k < 16; k = k + 1) begin
		rstack[k] = 0;
	end
end

always @(posedge InternalClock)
begin
	case(insn[35:32])
		// OUT
		4'h1: begin
			InternalState = dstack[dtop] != 0;
			pc = pc + 1'b1;
		end
		// CALL
		4'h2: begin
			rtop = rtop + 1'b1;
			rstack[rtop] = pc;
			pc = insn[9:0];
		end
		// RET
		4'h3: begin
			pc = rstack[rtop][9:0];
			rtop = rtop - 1'b1;
		end
		// IMM32
		4'h4: begin
			dtop = dtop + 1'b1;
			dstack[dtop] = insn[31:0];
			pc = pc + 1'b1;
		end
		// STORE
		4'h5: begin
			ram[dstack[dtop]] = dstack[dtop - 1'b1];
			pc = pc + 1'b1;
		end
		// LOAD
		4'h6: begin
			dstack[dtop] = ram[dstack[dtop]];
			pc = pc + 1'b1;
		end
		// IF
		4'h7: begin			
			dtop = dtop - 1'b1;
			
			if (satisfied)
				pc = insn[10] ? pc + insn[9:0] : pc - insn[9:0];
			else
				pc = pc + 1'b1;
		end
		// EQ
		4'h8: begin
			dstack[dtop - 1'b1] = dstack[dtop] == dstack[dtop - 1'b1];
			dtop = dtop - 1'b1;
			pc = pc + 1'b1;
		end
		// ADD
		4'h9: begin
			dstack[dtop - 1'b1] = dstack[dtop - 1'b1] + dstack[dtop];
			pc = pc + 1'b1;
		end
		// DUP
		4'hA: begin
			dstack[dtop + 1'b1] = dstack[dtop];
			dtop = dtop + 1'b1;
			pc = pc + 1'b1;
		end
		default: begin
			Fault = 1;
		end
	endcase

end

assign LED[0] = Fault;
assign LED[1] = InternalState;
*/
endmodule

module DragonCore(
	input Clock,
	output [1:0] LED
);

`define CORE_STAGE_WAIT_0 4'h0
`define CORE_STAGE_FETCH 4'h1
`define CORE_STAGE_DECODE 4'h2
`define CORE_STAGE_EXECUTE 4'h3
`define CORE_STAGE_STORE 4'h4

`define CORE_INSN_OUT 4'h1
`define CORE_INSN_CALL 4'h2
`define CORE_INSN_RET 4'h3
`define CORE_INSN_IMM32 4'h4
`define CORE_INSN_STORE 4'h5
`define CORE_INSN_LOAD 4'h6
`define CORE_INSN_IF 4'h7
`define CORE_INSN_EQ 4'h8
`define CORE_INSN_ADD 4'h9
`define CORE_INSN_DUP 4'hA

reg [3:0] stage = `CORE_STAGE_WAIT_0;

reg [9:0] pc = 0;    // Program Counter
reg [35:0] pcd = 0;   // Program Counter Data (*PC)
wire [35:0] pcdr;  // Program Counter Data Read
reg [9:0] newpc = 0; // New Program Counter

reg [9:0] dp = 0;    // Data Pointer
reg [35:0] dpd = 0;  // Data Pointer Data (*DP)
wire [35:0] dpdr; // Data Pointer Data Read
reg endp = 0;        // Data Pointer Write Enable

reg [8:0] dst = 0;            // Data Stack Top
wire [8:0] dsp = dst - 1'b1;  // Data Stack Previous
reg [35:0] dstd = 0;          // Data Stack Top Data
wire [35:0] dstdr;            // Data Stack Top Data Read
reg [35:0] dspd = 0;          // Data Stack Previous Data
wire [35:0] dspdr;            // Data Stack Previous Data Read
reg endst = 0;                // Data Stack Top Write Enable
reg endsp = 0;                // Data Stack Previous Write Enable

reg [8:0] rst = 0;    // Return Stack Top
reg [35:0] rstd = 0;  // Return Stack Top Data
wire [35:0] rstdr; // Return Stack Top Data Read
reg enrst = 0;        // Return Stack Top Write Enable

reg pshds = 0;   // Push Data Stack
reg popds = 0;   // Pop Data Stack
reg pshrs = 0;   // Push Return Stack
reg poprs = 0;   // Pop Return Stack
reg setpc = 0;   // Set Program Counter
reg setdpd = 0;  // Set Data
reg setdst = 0;  // Set Data Stack Top

reg blinky = 0;
reg error = 0;

assign LED[0] = blinky;
assign LED[1] = error;

DragonRAM #(.WordCount(1024), .SourceFile("ram.bin"), .Name("RAM")) RAM(
	.Clock(Clock),
	.WriteEnable0(endp),
	.WriteEnable1(1'b0),
	.Address0(dp),
	.Address1(pc),
	.Data0Write(dpd),
	.Data1Write(36'b0),
	.Data0Read(dpdr),
	.Data1Read(pcdr));

DragonRAM #(.WordCount(512), .AddressWidth(9), .Name("Data")) DataStack(
	.Clock(Clock),
	.WriteEnable0(endst),
	.WriteEnable1(endsp),
	.Address0(dst),
	.Address1(dsp),
	.Data0Write(dstd),
	.Data1Write(dspd),
	.Data0Read(dstdr),
	.Data1Read(dspdr));

DragonRAM #(.WordCount(512), .AddressWidth(9), .Name("Return")) ReturnStack(
	.Clock(Clock),
	.WriteEnable0(enrst),
	.WriteEnable1(1'b0),
	.Address0(rst),
	.Address1(9'b0),
	.Data0Write(rstd),
	.Data1Write(36'b0),
	.Data0Read(rstdr),
	.Data1Read());

always @(posedge Clock) case (stage)
    `CORE_STAGE_WAIT_0: begin
        stage <= `CORE_STAGE_FETCH;
		endp <= 0;
		endst <= 0;
		endsp <= 0;
		enrst <= 0;
		pshds <= 0;
		popds <= 0;
		pshrs <= 0;
		poprs <= 0;
		setpc <= 0;
		setdpd <= 0;
        setdst <= 0;
    end
	`CORE_STAGE_FETCH: begin
		pcd <= pcdr;
		pc <= pc + 1'b1;
		stage <= `CORE_STAGE_DECODE;
	end
	`CORE_STAGE_DECODE: begin
		stage <= `CORE_STAGE_EXECUTE;
		dpd <= dpdr;
		dstd <= dstdr;
		dspd <= dspdr;
		rstd <= rstdr;
	end
	`CORE_STAGE_EXECUTE: begin
		case (pcd[35:32])
			`CORE_INSN_OUT: begin
				blinky <= dstd != 0;
                popds <= 1;
            end
			`CORE_INSN_CALL: begin
				rstd <= pc;
				newpc <= pcd[9:0];
				setpc <= 1;
				pshrs <= 1;
			end
			`CORE_INSN_RET: begin
				poprs <= 1;
				newpc <= rstd[9:0];
				setpc <= 1;
			end
			`CORE_INSN_IMM32: begin
				dstd <= pcd[31:0];
				pshds <= 1;
			end
			`CORE_INSN_STORE: begin
				dp <= dstd[9:0];
				dpd <= dspd;
				setdpd <= 1;
			end
			`CORE_INSN_LOAD: begin
				dstd <= dpd;
				pshds <= 1;
			end
			`CORE_INSN_IF: begin
				popds <= 1;
				setpc <= dstd != 0;
				newpc <= (pcd[10] ? pc + pcd[9:0] : pc - pcd[9:0]);
			end
			`CORE_INSN_EQ: begin
                popds <= 1;
                setdst <= 1;
                dst <= dstd == dspd;
            end
			`CORE_INSN_ADD: begin
                error <= 1;
            end
			`CORE_INSN_DUP: begin
                error <= 1;
            end
			default: begin
				error <= 1;
            end
		endcase

		stage <= `CORE_STAGE_STORE;
	end
	`CORE_STAGE_STORE: begin
		if (pshrs) begin
			rst <= rst + 1'b1;
			enrst <= 1;
		end

		if (pshds) begin
			dst <= dst + 1'b1;
			endst <= 1;
		end

		if (popds) begin
			dst <= dst - 1'b1;
		end

        if (setdst) begin
            endst <= 1;
        end

		if (setpc) begin
			pc <= newpc;
		end

		stage <= `CORE_STAGE_WAIT_0;
	end
endcase

endmodule

module DragonRAM(
	input Clock, WriteEnable0, WriteEnable1,
	input [AddressWidth - 1:0] Address0, Address1,
	input [35:0] Data0Write, Data1Write,
	output reg [35:0] Data0Read, output reg [35:0] Data1Read
);

parameter AddressWidth = 10;
parameter WordCount = 1024;
parameter SourceFile = "";
parameter Name = "";

reg [35:0] ram [0:WordCount - 1];
initial
begin : init_blk
	integer i;

	if (SourceFile != "")
		$readmemh(SourceFile, ram, 0, WordCount - 1);
	else
		for (i = 0; i < WordCount; i = i + 1)
			ram[i] = 0;
end

always @(posedge Clock) begin
	if (WriteEnable0) begin
		ram[Address0] <= Data0Write;
	end else begin
		Data0Read <= ram[Address0];
    end

	if (WriteEnable1) begin
		ram[Address1] <= Data1Write;
	end else begin
		Data1Read <= ram[Address1];
    end
end

endmodule
