# RV32I 5-Stage Pipelined Processor

## Overview
This repository contains the RTL implementation of a 32-bit RISC-V processor based on a subset of the RV32I base integer instruction set. The core is built around a classic 5-stage pipeline and features a Harvard memory architecture, robust hazard mitigation, and a comprehensive AXI-interconnected cache hierarchy.

## Key Architecture Features

### Core Pipeline
The datapath implements a standard 5-stage pipeline: **Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory (MEM), and Write-Back (WB)**.
* **Early Branch Resolution:** The branching calculation and comparison unit is located in the **Instruction Decode (ID) stage** rather than the EX stage. This architectural optimization reduces the branch penalty (flush cycles) to just 1 cycle on a miss/taken branch, drastically improving overall CPI.
* **Forwarding Unit:** Implements full EX-to-EX and MEM-to-EX data forwarding paths to seamlessly resolve Read-After-Write (RAW) data hazards without stalling the pipeline.
* **Hazard Detection Unit:** Monitors for Load-Use hazards and automatically inserts pipeline stalls (bubbles) when forwarding alone cannot resolve the dependency.

### Memory Hierarchy & AXI Interconnect
The system follows a strict **Harvard Architecture** at the L1 cache level to allow simultaneous instruction and data memory access, preventing structural hazards.
* **Instruction Cache (I-Cache):** Direct-mapped structure optimized for fast instruction fetching.
* **Data Cache (D-Cache):** 2-way set-associative structure. It implements a **Least Recently Used (LRU)** replacement policy to manage evictions and a **Write-Back** policy to minimize write traffic to main memory.
* **AXI Interconnect:** Since both caches must ultimately communicate with a single, unified main memory (SRAM) block, the system uses an AMBA AXI interconnect. This interconnect arbitrates memory access requests, handles cache misses, and processes burst read/write transactions between the caches and the unified SRAM.
