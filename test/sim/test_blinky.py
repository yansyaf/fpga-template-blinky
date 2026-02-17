"""
PyUVM Testbench for Blinky Module
Targets 100% code coverage including:
- Reset functionality
- Counter increment
- LED output toggle
- Counter overflow
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from pyuvm import *
import random

# PyUVM constants
try:
    from pyuvm import UVM_ACTIVE
except ImportError:
    # For newer PyUVM versions, define the constant
    UVM_ACTIVE = True


# Configuration object
class BlinkyConfig(uvm_object):
    def __init__(self, name="BlinkyConfig"):
        super().__init__(name)
        self.clk_period_ns = 8  # 125 MHz clock


# Sequence item for blinky transactions
class BlinkyItem(uvm_sequence_item):
    def __init__(self, name="BlinkyItem"):
        super().__init__(name)
        self.rst = 0
        self.led = 0
        self.counter_value = 0  # For monitoring
        
    def randomize(self):
        self.rst = random.choice([0, 1])
        return True
        
    def __str__(self):
        return f"BlinkyItem(rst={self.rst}, led={self.led}, counter={self.counter_value})"


# Driver: drives reset signal and monitors DUT
class BlinkyDriver(uvm_driver):
    def build_phase(self):
        self.dut = cocotb.top
        
    async def run_phase(self):
        while True:
            item = await self.seq_item_port.get_next_item()
            await self.drive_item(item)
            self.seq_item_port.item_done()
            
    async def drive_item(self, item):
        """Drive the reset signal"""
        self.dut.rst.value = item.rst
        await RisingEdge(self.dut.clk)


# Monitor: observes DUT outputs and counter state
class BlinkyMonitor(uvm_component):
    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)
        self.dut = cocotb.top
        
    async def run_phase(self):
        while True:
            await RisingEdge(self.dut.clk)
            
            # Create item with current state
            item = BlinkyItem("monitored_item")
            item.rst = int(self.dut.rst.value)
            item.led = int(self.dut.led.value)
            item.counter_value = int(self.dut.counter.value)
            
            # Send to analysis port
            self.ap.write(item)


# Scoreboard: checks functional correctness and coverage
class BlinkyScoreboard(uvm_subscriber):
    def build_phase(self):
        super().build_phase()
        self.expected_led = 0
        self.checks_passed = 0
        self.checks_failed = 0
        self.prev_counter = None
        
        # Coverage tracking
        self.reset_seen = False
        self.counter_overflow_seen = False
        self.led_toggle_seen = False
        self.led_states = set()
        
    def write(self, item):
        """Check the monitored transaction"""
        
        # Track coverage
        if item.rst == 1:
            self.reset_seen = True
            self.prev_counter = None
        elif self.prev_counter == 0x7FFFFFF and item.counter_value == 0:
            self.counter_overflow_seen = True
            
        # Expected LED value
        self.expected_led = (item.counter_value >> 26) & 1
        self.led_states.add(item.led)
        
        # Check LED toggle
        if len(self.led_states) > 1:
            self.led_toggle_seen = True
        
        # Verify LED output
        if item.led == self.expected_led:
            self.checks_passed += 1
        else:
            self.checks_failed += 1
            self.logger.error(
                f"LED mismatch! Expected: {self.expected_led}, Got: {item.led}, "
                f"Counter: {item.counter_value}"
            )

        self.prev_counter = item.counter_value
    
    def report_phase(self):
        """Report coverage and results"""
        self.logger.info("=" * 60)
        self.logger.info("SCOREBOARD REPORT")
        self.logger.info("=" * 60)
        self.logger.info(f"Checks Passed: {self.checks_passed}")
        self.logger.info(f"Checks Failed: {self.checks_failed}")
        self.logger.info("")
        self.logger.info("COVERAGE REPORT:")
        self.logger.info(f"  Reset tested: {'✓' if self.reset_seen else '✗'}")
        self.logger.info(f"  LED toggle observed: {'✓' if self.led_toggle_seen else '✗'}")
        self.logger.info(f"  Counter overflow: {'✓' if self.counter_overflow_seen else '✗'}")
        self.logger.info(f"  LED states seen: {self.led_states}")
        
        # Calculate coverage percentage
        coverage_items = [
            self.reset_seen,
            self.led_toggle_seen,
            self.counter_overflow_seen,
            len(self.led_states) == 2  # Both 0 and 1
        ]
        coverage = (sum(coverage_items) / len(coverage_items)) * 100
        self.logger.info(f"\nFunctional Coverage: {coverage:.1f}%")
        self.logger.info("=" * 60)
        
        if self.checks_failed > 0:
            self.logger.error(f"TEST FAILED: {self.checks_failed} checks failed")
        else:
            self.logger.info("TEST PASSED: All checks passed!")


# Agent: combines driver, monitor, and sequencer
class BlinkyAgent(uvm_agent):
    def build_phase(self):
        self.monitor = BlinkyMonitor("monitor", self)
        if self.get_is_active():
            self.seqr = uvm_sequencer("seqr", self)
            self.driver = BlinkyDriver("driver", self)
            
    def connect_phase(self):
        if self.get_is_active():
            self.driver.seq_item_port.connect(self.seqr.seq_item_export)


# Environment: top-level verification environment
class BlinkyEnv(uvm_env):
    def build_phase(self):
        self.agent = BlinkyAgent("agent", self)
        self.scoreboard = BlinkyScoreboard("scoreboard", self)
        # Set agent to active mode (has driver and sequencer)
        self.agent.is_active = UVM_ACTIVE
        
    def connect_phase(self):
        # Connect monitor analysis port to subscriber analysis export
        self.agent.monitor.ap.connect(self.scoreboard.analysis_export)


# Sequences
class ResetSequence(uvm_sequence):
    """Sequence to test reset functionality"""
    async def body(self):
        # Assert reset
        item = BlinkyItem("reset_item")
        item.rst = 1
        await self.start_item(item)
        await self.finish_item(item)
        
        # Hold reset for a few cycles
        for _ in range(5):
            await self.start_item(item)
            await self.finish_item(item)
        
        # Deassert reset
        item.rst = 0
        await self.start_item(item)
        await self.finish_item(item)


class RunSequence(uvm_sequence):
    """Sequence to let counter run and observe LED toggle"""
    async def body(self):
        item = BlinkyItem("run_item")
        item.rst = 0
        
        # Send one item to keep reset low
        await self.start_item(item)
        await self.finish_item(item)
        
        # Force internal counter near key boundaries so coverage completes quickly
        # without running millions of cycles on Icarus.
        dut = cocotb.top
        
        # Let design run naturally for a few cycles
        for _ in range(32):
            await RisingEdge(dut.clk)

        # Move near LED toggle boundary: counter[26] from 0 -> 1
        dut.counter.value = (1 << 26) - 2
        for _ in range(4):
            await RisingEdge(dut.clk)
        
        # Move near overflow boundary: 0x7FFFFFF -> 0
        dut.counter.value = (1 << 27) - 2
        for _ in range(4):
            await RisingEdge(dut.clk)


class BlinkyTest(uvm_test):
    """Main test that runs all sequences"""
    def build_phase(self):
        self.env = BlinkyEnv("env", self)
        
    def start_of_simulation_phase(self):
        self.logger.info("Starting Blinky UVM Test")
        
    async def run_phase(self):
        self.raise_objection()
        
        seqr = self.env.agent.seqr
        
        # Test 1: Reset
        self.logger.info("Running Reset Sequence...")
        reset_seq = ResetSequence("reset_seq")
        await reset_seq.start(seqr)
        
        # Test 2: Run and observe
        self.logger.info("Running Counter Sequence...")
        run_seq = RunSequence("run_seq")
        await run_seq.start(seqr)
        
        # Additional cycles to ensure all checks complete
        await Timer(100, unit='ns')
        
        self.drop_objection()


@cocotb.test()
async def run_blinky_test(dut):
    """Cocotb test entry point"""
    
    # Start clock
    clock = Clock(dut.clk, 8, unit="ns")  # 125 MHz
    cocotb.start_soon(clock.start())
    
    # Initial reset
    dut.rst.value = 1
    await Timer(100, unit='ns')
    dut.rst.value = 0
    await Timer(20, unit='ns')
    
    # Run UVM test
    await uvm_root().run_test("BlinkyTest")


# For running with pytest-pyuvm
if __name__ == "__main__":
    pass
