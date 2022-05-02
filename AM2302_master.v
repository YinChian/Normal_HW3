module AM2302_master(
	
	//System
	input clk,
	input rst_n,
	
	//SFR
	input [7:0] sfr_addr,
	input [7:0] sfr_data_out,
	output reg [7:0] sfr_data_in,
	input sfr_rd,
	input sfr_wr,
	
	//IIC
	inout sda

);

	wire OE;
	reg [7:0] data [5:0]; //E1 ~ E6
	
	wire sda_o = 0;
	assign sda = OE ? sda_o : 1'bz;
	
	wire sda_pos, sda_neg;
	edge_detect edge_sda(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(sda),
		.pos_edge(sda_pos),
		.neg_edge(sda_neg)
	);

	initial 
		$readmemh("init.dat",data);

	parameter idle = 3'd0, init = 3'd1, hi_z = 3'd2, square = 3'd3, receive = 3'd4, finish = 3'd5,real_fin = 3'd6; 
	reg [2:0] iic_state;

	//adj. counter declaration
	reg [15:0] init_counter;
	reg [10:0] hi_z_counter;
	reg [1:0] square_count;
	reg [11:0] duration_counter;
	reg [5:0] byte_state;
	reg [2:0] bit_state;
	reg [11:0] cool_counter;

	//-----------main-fsm-----------//
	parameter ready = 1'b0, fetch = 1'b1;
	reg state;
	always@(posedge clk, negedge rst_n)begin
		if(!rst_n) state <= ready;
		else begin
			case (state)
				ready: state <= data[0][0] == 1'b1 ? fetch : ready;
				fetch: state <= data[0][4] == 1'b1 ? ready : fetch;
			endcase
		end
	end

	//-----------memory-ctrl-----------//
	//Write Memory
	wire data_input = duration_counter == 12'd2_500;
	always@(posedge clk)begin
		if(sfr_wr && sfr_addr == 8'he1)
			data[0] <= sfr_data_out;
		else if(iic_state == receive && sda)
			data[byte_state + 4'h1][4'h7 -bit_state] <= data_input;
		else if(iic_state == finish)
			data[0] <= 8'h10;
		else
			data[byte_state][bit_state] <= data[byte_state][bit_state];
	end

	//Read Memory
	
	always @(*) begin
		if(!rst_n) 
			sfr_data_in <= 8'h0;
		else if(sfr_rd && sfr_addr >= 8'he1 && sfr_addr <= 8'he6) 
			sfr_data_in <= data[sfr_addr - 8'hE1];
		else 
			sfr_data_in <= 8'hzz;
	end


	//-----------iic-fsm-----------//
	//Transistion
	
	
	always@(posedge clk,negedge rst_n)begin
		if(!rst_n) iic_state <= idle;
		else begin
			case (iic_state)
				idle     : iic_state <= (state == fetch) ? init : idle;
				init     : iic_state <= (init_counter == 16'd50_000) ? hi_z : init;
				hi_z     : iic_state <= (hi_z_counter == 11'd1_500) ? square : hi_z;
				square   : iic_state <= (square_count == 2'd2) ? receive : square;
				receive  : iic_state <= (byte_state == 3'd4 && bit_state == 3'd7 && sda_neg) ? finish : receive;
				finish   : iic_state <= (cool_counter == 12'd5_000) ? real_fin : finish;
				real_fin : iic_state <= idle;
				default  : iic_state <= idle;
			endcase
		end
	end

	assign OE = (iic_state == init) ? 1'b1 : 1'b0;


	//-----------adj.counters-----------//


	//--init counter--
	
	always@(posedge clk, negedge rst_n)begin
		if(!rst_n) init_counter <= 16'd0;
		else if(iic_state == init) begin
			if(init_counter == 16'd50_000) init_counter <= 16'd0;
			else init_counter <= init_counter + 16'd1;
		end
		else init_counter <= 16'd0;
	end


	//--hi_z counter--
	
	always@(posedge clk, negedge rst_n)begin
		if(!rst_n) hi_z_counter <= 11'd0;
		else if(iic_state == hi_z) begin
			if(hi_z_counter == 11'd1500) hi_z_counter <= 11'd0;
			else hi_z_counter <= hi_z_counter + 11'd1; 
		end
		else hi_z_counter <= 11'd0;
	end


	//--square count--
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) square_count <= 2'b0;
		else if(iic_state == square)begin
			if(square_count == 2'd2) square_count <= 2'd0;
			else if(sda_pos || sda_neg) square_count <= square_count + 2'd1;
			else square_count <= square_count;
		end
		else square_count <= 2'b0;
	end


	//--Receive--
	//Byte
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) byte_state <= 3'd1;
		else if(iic_state == receive)begin
			if(byte_state == 3'd4 && bit_state == 3'd7 && sda_neg) byte_state <= 3'd0;
			else if(bit_state == 3'd7 && sda_neg) byte_state <= byte_state + 3'd1;
			else byte_state <= byte_state;
		end
		else byte_state <= 6'd0;
	end

	//bit
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) bit_state <= 3'd0;
		else if(iic_state == receive)begin
			if(bit_state == 3'd7 && sda_neg) bit_state <= 3'd0;
			else if(sda_neg) bit_state <= bit_state + 3'd1;
			else bit_state <= bit_state;
		end
		else bit_state <= 3'd0;
	end
	
	
	//duration counter
	//count when sda == 1
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) duration_counter <= 12'd0;
		else if(iic_state == receive && (sda == 1'b1 || sda_neg))begin //NOT SURE
			if(duration_counter == 12'd2_500) duration_counter <= duration_counter;
			else duration_counter <= duration_counter + 12'd1;
		end
		else duration_counter <= 12'd0;
	end

	//Wait_end counter
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) cool_counter <= 12'd0;
		else if(iic_state == finish) begin
			if(cool_counter == 12'd5_000) cool_counter <= 12'd0;
			else cool_counter <= cool_counter + 12'd1;
		end
		else cool_counter <= 12'd0;
	end

	

endmodule 