# Papilio Tang Bootloader

A hardware bootloader for the Papilio Retrocade Board that enables safe FPGA bitstream programming via ESP32-S3 SPI Flash interface. This bootloader runs on the Tang Primer 20K FPGA module and provides a time-based reconfiguration mechanism with visual LED feedback.

## Overview

The Papilio Tang Bootloader is a Verilog-based hardware module designed to work in conjunction with [pesptool](https://github.com/Papilio-Labs/pesptool) for programming FPGA bitstreams on the Papilio Retrocade Board. It provides:

- **Safe Programming Window**: 5-second bootloader mode for FPGA reconfiguration
- **SPI Flash Passthrough**: Direct connection between ESP32-S3 and FPGA SPI Flash
- **Visual Feedback**: LED blink pattern indicates bootloader active status
- **Auto-Reset Protection**: Prevents premature reconfiguration during programming

## Key Features

### Time-Based Reconfiguration
- **5-Second Window**: Bootloader remains active for 5 seconds after power-up or reset
- **Activity Detection**: Any SPI communication (CS_N going low) resets the timer
- **Automatic Boot**: After timeout, FPGA automatically loads the user bitstream from flash

### SPI Flash Interface
- **Transparent Passthrough**: ESP32-S3 SPI signals routed directly to FPGA SPI Flash
- **Pin Mapping**:
  - `esp_clk` → `spiflash_clk` (Clock)
  - `esp_mosi` → `spiflash_mosi` (Master Out, Slave In)
  - `esp_miso` ← `spiflash_miso` (Master In, Slave Out)
  - `esp_cs_n` → `spiflash_cs_n` (Chip Select, active low)

### LED Status Indicator
- RGB LED provides visual feedback during programming:
  - **Purple**: Bootloader active, waiting for programming
  - **Cyan**: Programming in progress
- **Blink Rate**: 1 Hz (toggles every 0.5 seconds)
- **Clock Frequency**: Designed for 27 MHz system clock
- **Purpose**: Visual confirmation that bootloader is active

## Hardware Requirements

### Papilio Retrocade Board Components
- **FPGA**: Tang Primer 20K (Gowin GW2A-LV18PG256C8/I7)
- **Microcontroller**: ESP32-S3 SuperMini
- **SPI Flash**: Connected to FPGA for bitstream storage
- **System Clock**: 27 MHz oscillator

### Pin Connections
See [Papilio Retrocade Hardware Repository](https://github.com/Papilio-Labs/papilio_retrocade_hardware) for complete schematics.

**ESP32-S3 to FPGA SPI Interface** (configured in pesptool):
- CLK: GPIO 12
- Q (MISO): GPIO 9
- D (MOSI): GPIO 11
- HD: GPIO 26
- CS: GPIO 10

## How It Works

### Boot Sequence

1. **Power-On/Reset**: FPGA loads bootloader bitstream
2. **LED Starts Blinking**: Visual indication of bootloader mode (1 Hz)
3. **Timer Starts**: 5-second countdown begins
4. **Programming Window**: 
   - ESP32-S3 can write new bitstream via SPI
   - Any SPI activity (CS_N low) resets the 5-second timer
   - Programming can continue indefinitely as long as SPI is active
5. **Timeout**: 
   - After 5 seconds of SPI inactivity
   - Bootloader asserts `reconfig` signal (goes low)
   - FPGA reconfigures from flash address 0x100000
   - User bitstream starts running

### Reconfiguration Mechanism

The bootloader controls the FPGA's `reconfig` signal:
- **High (1)**: Bootloader active, programming allowed
- **Low (0)**: Triggers FPGA reconfiguration from SPI flash

```verilog
// Simplified logic
if (counter < 135_000_000) begin  // 5 seconds at 27 MHz
    if (esp_cs_n == 0) begin
        counter <= 0;  // Reset timer on SPI activity
    end else begin
        counter <= counter + 1;  // Increment if idle
    end
end else begin
    reconfig_r <= 0;  // Trigger reconfiguration
end
```

## Usage with pesptool

The bootloader is designed to work seamlessly with [pesptool](https://github.com/Papilio-Labs/pesptool), a modified version of Espressif's esptool for FPGA programming.

### Programming a Bitstream

```bash
# Quick programming (default address 0x100000)
pesptool your_bitstream.bin

# Explicit flash address
pesptool write-flash 0x100000 your_bitstream.bin

# Specify serial port
pesptool --port COM3 your_bitstream.bin
```

### Bootloader Installation

The bootloader itself must be programmed as the FPGA's boot bitstream:

1. **Build the Bootloader**: Synthesize `papilio_tang_bootloader.v` with Gowin EDA
2. **Program as Boot Image**: Flash to the FPGA's boot configuration area
3. **Protected Region**: User bitstreams go to address `0x100000` (1MB offset)

## Technical Specifications

### Timing Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| System Clock | 27 MHz | FPGA system clock frequency |
| Bootloader Timeout | 5 seconds | Time before auto-reconfiguration |
| Delay Count | 135,000,000 cycles | Counter value for 5-second timeout |
| LED Period | 1 Hz | Status LED blink rate |
| LED Toggle Count | 13,500,000 cycles | Counter value for 0.5 second intervals |

### Module Interface

```verilog
module top(
    input       clk,           // 27 MHz system clock
    output      reconfig,      // FPGA reconfiguration trigger (active low)
    output      led,           // Status LED output
    
    // ESP32-S3 SPI Interface
    input wire  esp_clk,       // SPI clock from ESP32
    input wire  esp_cs_n,      // Chip select from ESP32 (active low)
    output wire esp_miso,      // Data out to ESP32
    input wire  esp_mosi,      // Data in from ESP32
    
    // FPGA SPI Flash Interface
    output wire spiflash_clk,  // SPI clock to flash
    output wire spiflash_cs_n, // Chip select to flash (active low)
    input wire  spiflash_miso, // Data in from flash
    output wire spiflash_mosi  // Data out to flash
);
```

### Resource Utilization

The bootloader is designed to be minimal and efficient:
- **Logic Cells**: ~100-150 LUTs (exact count varies by synthesis)
- **Registers**: ~60 flip-flops
- **Timing**: Meets timing at 27 MHz with default constraints

## Building from Source

### Prerequisites

- [Gowin EDA](https://www.gowinsemi.com/en/support/download_eda/) - FPGA development tools
- Tang Primer 20K device support package
- Papilio Retrocade Board hardware

### Build Steps

1. **Open Project**:
   ```
   File → Open Project → papilio_tang_bootloader.gprj
   ```

2. **Verify Device Settings**:
   - Device: GW2A-LV18PG256C8/I7
   - Package: PBGA256
   - Speed: -8

3. **Synthesize and Implement**:
   - Run synthesis
   - Place and route
   - Generate bitstream

4. **Program FPGA**:
   - Use Gowin Programmer or pesptool
   - Program as boot configuration

### Project Files

- `src/papilio_tang_bootloader.v` - Main bootloader module
- `src/papilio_tang_bootloader.cst` - Pin constraints
- `src/papilio_tang_bootloader.sdc` - Timing constraints
- `papilio_tang_bootloader.gprj` - Gowin project file

## Troubleshooting

### LED Not Blinking
- **Check Clock**: Verify 27 MHz clock is present on `clk` input
- **Check LED Connection**: Ensure LED pin is correctly mapped in constraints

### Programming Fails
- **Timeout Too Short**: If programming large bitstreams, ensure continuous SPI activity
- **Flash Address**: Verify programming to address 0x100000, not bootloader area
- **SPI Connections**: Check ESP32-S3 to FPGA SPI wiring

### FPGA Doesn't Boot User Design
- **Flash Content**: Verify bitstream was successfully written to 0x100000
- **Reconfiguration**: Check that `reconfig` signal goes low after timeout
- **Bitstream Valid**: Ensure user bitstream is compatible with Tang Primer 20K

### Early Reconfiguration
- **SPI Activity**: Any spurious signals on ESP SPI pins will reset timer
- **Debounce**: Consider adding debounce logic if noise is present

## Memory Map

The Papilio system uses a specific memory layout in the FPGA's SPI Flash:

| Address | Size | Description |
|---------|------|-------------|
| 0x000000 | 1 MB | Bootloader area (protected) |
| 0x100000 | Variable | User FPGA bitstream |
| Higher | Variable | Additional storage (optional) |

**Important**: Always program user bitstreams to address `0x100000` or higher to avoid overwriting the bootloader.

## Development

### Modifying Timeout Duration

To change the bootloader timeout, adjust the `DELAY_COUNT` parameter:

```verilog
// For T seconds at 27 MHz
localparam DELAY_COUNT = T * 27_000_000;

// Examples:
// 3 seconds:  localparam DELAY_COUNT = 81_000_000;
// 10 seconds: localparam DELAY_COUNT = 270_000_000;
```

### Changing LED Blink Rate

Adjust the LED counter comparison value:

```verilog
// Current: 1 Hz (0.5 second half-period)
if( count_1s < 27000000/2 )

// Examples:
// 2 Hz:   if( count_1s < 27000000/4 )
// 0.5 Hz: if( count_1s < 27000000 )
```

### Adapting for Different FPGAs

To use this bootloader on other FPGA families:
1. Adjust clock frequency in timing calculations
2. Verify reconfiguration mechanism for target device
3. Update pin constraints for your board
4. Check SPI flash interface compatibility

## Resources

- **Hardware Documentation**: [Papilio Retrocade Hardware Repository](https://github.com/Papilio-Labs/papilio_retrocade_hardware)
- **Programming Tool**: [pesptool Repository](https://github.com/Papilio-Labs/pesptool)
- **FPGA Documentation**: [Tang Primer 20K Wiki](https://wiki.sipeed.com/hardware/en/tang/tang-primer-20k/primer-20k.html)
- **Development Tools**: [Gowin EDA](https://www.gowinsemi.com/en/support/download_eda/)

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on actual hardware
5. Submit a pull request

## License

This project is released under the **CC0 1.0 Universal (Public Domain)** license. See the [LICENSE](LICENSE) file for details.

You can copy, modify, distribute, and perform the work, even for commercial purposes, all without asking permission.

## About

The Papilio Tang Bootloader is part of the **Papilio Retrocade** ecosystem, designed to provide a robust and user-friendly FPGA development platform for retro gaming and digital design projects.

**Papilio Labs** - Building open hardware for FPGA enthusiasts

---

*For questions, issues, or contributions, please visit the project repository or contact the Papilio community.*
