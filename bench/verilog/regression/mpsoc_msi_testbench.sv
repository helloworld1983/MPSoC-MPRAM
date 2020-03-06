////////////////////////////////////////////////////////////////////////////////
//                                            __ _      _     _               //
//                                           / _(_)    | |   | |              //
//                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
//               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
//              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
//               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
//                  | |                                                       //
//                  |_|                                                       //
//                                                                            //
//                                                                            //
//              MPSoC-RISCV CPU                                               //
//              Master Slave Interface Tesbench                               //
//              AMBA3 AHB-Lite Bus Interface                                  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/* Copyright (c) 2018-2019 by the author(s)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * =============================================================================
 * Author(s):
 *   Francisco Javier Reina Campo <frareicam@gmail.com>
 */

module mpsoc_msi_testbench;

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  localparam XLEN = 64;
  localparam PLEN = 64;

  localparam MASTERS = 5;
  localparam SLAVES  = 5;

  localparam SYNC_DEPTH = 3;
  localparam TECHNOLOGY = "GENERIC";


  //Wishbone parameters
  parameter DW = 32;

  //Memory parameters
  parameter DEPTH   = 256;
  parameter AW      = $clog2(DEPTH);
  parameter MEMFILE = "";

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Common signals
  wire                                     HRESETn;
  wire                                     HCLK;

  //AHB3 signals
  wire  [MASTERS-1:0]                      mst_mpram_HSEL;
  wire  [MASTERS-1:0][PLEN           -1:0] mst_mpram_HADDR;
  wire  [MASTERS-1:0][XLEN           -1:0] mst_mpram_HWDATA;
  wire  [MASTERS-1:0][XLEN           -1:0] mst_mpram_HRDATA;
  wire  [MASTERS-1:0]                      mst_mpram_HWRITE;
  wire  [MASTERS-1:0][                2:0] mst_mpram_HSIZE;
  wire  [MASTERS-1:0][                2:0] mst_mpram_HBURST;
  wire  [MASTERS-1:0][                3:0] mst_mpram_HPROT;
  wire  [MASTERS-1:0][                1:0] mst_mpram_HTRANS;
  wire  [MASTERS-1:0]                      mst_mpram_HMASTLOCK;
  wire  [MASTERS-1:0]                      mst_mpram_HREADY;
  wire  [MASTERS-1:0]                      mst_mpram_HREADYOUT;
  wire  [MASTERS-1:0]                      mst_mpram_HRESP;

  //WB signals
  wire  [MASTERS-1:0][AW             -1:0] mst_mpram_adr_i;
  wire  [MASTERS-1:0][DW             -1:0] mst_mpram_dat_i;
  wire  [MASTERS-1:0][                3:0] mst_mpram_sel_i;
  wire  [MASTERS-1:0]                      mst_mpram_we_i;
  wire  [MASTERS-1:0][                1:0] mst_mpram_bte_i;
  wire  [MASTERS-1:0][                2:0] mst_mpram_cti_i;
  wire  [MASTERS-1:0]                      mst_mpram_cyc_i;
  wire  [MASTERS-1:0]                      mst_mpram_stb_i;
  reg   [MASTERS-1:0]                      mst_mpram_ack_o;
  wire  [MASTERS-1:0]                      mst_mpram_err_o;
  wire  [MASTERS-1:0][DW             -1:0] mst_mpram_dat_o;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //DUT

  //Instantiate RISC-V RAM
  mpsoc_ahb3_mpram #(
    .MEM_SIZE          ( 0 ),
    .MEM_DEPTH         ( 256 ),
    .HADDR_SIZE        ( PLEN ),
    .HDATA_SIZE        ( XLEN ),
    .CORES_PER_TILE    ( MASTERS ),
    .TECHNOLOGY        ( TECHNOLOGY ),
    .REGISTERED_OUTPUT ( "NO" )
  )
  ahb3_mpram (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( mst_mpram_HSEL      ),
    .HADDR     ( mst_mpram_HADDR     ),
    .HWDATA    ( mst_mpram_HWDATA    ),
    .HRDATA    ( mst_mpram_HRDATA    ),
    .HWRITE    ( mst_mpram_HWRITE    ),
    .HSIZE     ( mst_mpram_HSIZE     ),
    .HBURST    ( mst_mpram_HBURST    ),
    .HPROT     ( mst_mpram_HPROT     ),
    .HTRANS    ( mst_mpram_HTRANS    ),
    .HMASTLOCK ( mst_mpram_HMASTLOCK ),
    .HREADYOUT ( mst_mpram_HREADYOUT ),
    .HREADY    ( mst_mpram_HREADY    ),
    .HRESP     ( mst_mpram_HRESP     )
  );

  //DUT WB
  mpsoc_wb_mpram #(
    .DW      ( DW      ),
    .DEPTH   ( DEPTH   ),
    .AW      ( AW      ),
    .MEMFILE ( MEMFILE ),

    .CORES_PER_TILE ( MASTERS )
  )
  wb_mpram (
    //Wishbone Master interface
    .wb_clk_i ( HRESETn ),
    .wb_rst_i ( HCLK    ),

    .wb_adr_i ( mst_mpram_adr_i ),
    .wb_dat_i ( mst_mpram_dat_i ),
    .wb_sel_i ( mst_mpram_sel_i ),
    .wb_we_i  ( mst_mpram_we_i  ),
    .wb_bte_i ( mst_mpram_bte_i ),
    .wb_cti_i ( mst_mpram_cti_i ),
    .wb_cyc_i ( mst_mpram_cyc_i ),
    .wb_stb_i ( mst_mpram_stb_i ),
    .wb_ack_o ( mst_mpram_ack_o ),
    .wb_err_o ( mst_mpram_err_o ),
    .wb_dat_o ( mst_mpram_dat_o )
  );
endmodule
