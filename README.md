# tether
![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)

**A sovereign transport protocol for finite networks.**

This is the reference implementation of [Tether](https://github.com/wilson/rfc/blob/ultra2krad4u/chronos/0001.md).

It is a connection-oriented, datagram-agnostic networking stack designed to operate deterministically across all reference frames—from 100GbE datacenter fabrics to high-latency deep-space links. It rejects the "Best Effort" and "Open World" assumptions of the IP stack in favor of **Explicit Capacity** and **Cryptographic Identity**.

## Architecture

Tether treats bandwidth as a currency and latency as a physical constant.

### Explicit Capacity
Transmission is transactional. A node **MUST NOT** transmit data unless it has been explicitly granted the capacity to do so by the receiver.
* **Congestion Control:** Congestion is impossible because data is never sent unless buffer space is pre-reserved.
* **Flow Dynamics:** Eliminates ACK storms by requiring prepaid receipts.

### Speculative Discovery
To bridge the void between disconnected nodes, Tether defines a mechanism for **Speculative Transmission**.
* The Initiator expends its own resources to fund the Receiver's ability to reply.
* This enables "Cold Start" discovery without violating the "Finite Universe" constraint.

### Branchless 64-Byte Header
The protocol uses a fixed-width, branchless 64-byte header for every frame.
* **No Opcodes:** Every field (Grant, NACK, Timestamp) is evaluated in every packet.
* **Determinism:** Processing time is constant (`O(1)`) regardless of payload or network state.

## Hardware Acceleration

Tether is designed for mechanical sympathy.

This repository initially focuses on the **Intel E800 Series (Columbiaville)** architecture.

Because the header is fixed-width and branchless, it maps perfectly to the **Intel DDP (Dynamic Device Personalization)** parse graph:
*  **Silicon Steering:** The NIC matches the 48-bit `TargetID` and standardizes the flow in hardware.
*  **Zero-Copy:** Traffic is steered directly into `AF_XDP` umem rings, bypassing the kernel scheduler entirely.
*  **App-to-Wire Latency:** The fixed header layout allows for pre-calculated template transmission, pushing latency toward the theoretical PCIe bus minimum (~3µs).

## Implementation Status

### Pre-Alpha

* **Protocol Spec:** [RFC 0001](https://github.com/wilson/rfc/blob/ultra2krad4u/chronos/0001.md)
* **Language:** Zig 0.16+ [(nightly)](https://ziglang.org/download/)
* **Hardware:** Initially, Intel E800 Series NICs:
    * [E810-CQDA2](https://www.intel.com/content/www/us/en/products/sku/192558/intel-ethernet-network-adapter-e810cqda2/specifications.html)
    * [E830-CQDA2](https://www.intel.com/content/www/us/en/products/sku/239775/intel-ethernet-network-adapter-e830cqda2/specifications.html)
* **Driver Model:** `AF_XDP` with [Intel DDP](https://cdrdv2.intel.com/v1/dl/getContent/617015).

### Roadmap
* [ ] **Struct Layout:** Validating `extern struct` alignment for the 64-byte header.
* [ ] **DDP Profile:** Generating the `.pkg` file to teach the E810 parser about EtherType `0x88B5`.
* [ ] **Credit Accounting:** Performant implementation of the atomic grant-subtraction logic.

---
*© 02026 Wilson Bilkovich*
