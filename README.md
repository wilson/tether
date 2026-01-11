# tether
![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)

> A sovereign transport protocol for finite networks.

This is the reference implementation of [Tether](https://github.com/wilson/rfc/blob/ultra2krad4u/chronos/0001.md).

It is a connection-oriented, datagram-agnostic networking stack designed to operate deterministically across all reference frames—from 100GbE datacenter fabrics to high-latency deep-space links. It rejects the "Best Effort" and "Open World" assumptions of the IP stack in favor of **Explicit Capacity** and **Cryptographic Identity**.

## Architecture

Tether treats bandwidth as a currency and latency as a physical constant.

### Explicit Capacity (Grants)

Transmission is transactional. A node **MUST NOT** transmit data unless it has been explicitly granted the capacity to do so by the receiver (via the `GrantAmount` field).

* **Congestion Control:** Congestion is impossible because data is never sent unless buffer space is pre-reserved.
* **Flow Dynamics:** Eliminates ACK storms and "Slow Start" heuristics by requiring prepaid receipts.

### Lamp Mode (Discovery)

To bridge the void between disconnected nodes, Tether defines a mechanism for **Speculative Transmission** called a **Lamp**.

* The Initiator sets the `LAMP` flag (`0x01`) and expends its own credits to fund the Receiver's ability to reply.
* This enables "Cold Start" discovery without violating the "Finite Universe" constraint.

### The 64-Byte Block

The protocol is physically structured as a sequence of **64-byte Blocks** (matching the standard cache line size).

* **Branchless Header:** The first Block (Header) has no opcodes. Every field (Grant, NackSlot, Timestamp) is evaluated in `O(1)` time for every packet.
* **Control Tags:** Complex logic (Manifests, Definitions) is segregated into specific "Control Blocks" on **Flow 0**.

## Hardware Acceleration

Tether is designed for mechanical sympathy.

This repository targets these initial architectures:

1. **Modern EAL NICs with AF_XDP**: The best we can do that works across Linux/FreeBSD/Windows.
2. **Intel E800 Series (Columbiaville)**: As above, but natively utilizing [DDP](https://cdrdv2.intel.com/v1/dl/getContent/617015) (Dynamic Device Personalization) and [DPDK](https://www.dpdk.org) (Data Plane Development Kit) instead of `AF_XDP`, for ideal performance:
    * [E810-CQDA2](https://www.intel.com/content/www/us/en/products/sku/192558/intel-ethernet-network-adapter-e810cqda2/specifications.html)
    * [E830-CQDA2](https://www.intel.com/content/www/us/en/products/sku/239775/intel-ethernet-network-adapter-e830cqda2/specifications.html)
3. **NVIDIA ConnectX-7 (BlueField)**: Utilizing `switchdev` and hardware flow steering for ARM64 environments.

## Implementation Status

### Pre-Alpha

* **Protocol Spec:** [RFC 0001](https://github.com/wilson/rfc/blob/ultra2krad4u/chronos/0001.md)
* **Language:** Zig 0.16+ [(nightly)](https://ziglang.org/download/)
* **Driver Model:** `AF_XDP` (Linux) with Hardware Flow Steering.

### Roadmap

* [ ] **Struct Layout:** Validating `extern struct` alignment for the 64-byte Header Block.
* [ ] **DDP Profile:** Generating the `.pkg` file to teach the E810 parser about EtherType `0x88B5`.
* [ ] **Credit Accounting:** Performant implementation of the atomic grant-subtraction logic.
* [ ] **Control Plane:** Implementation of the Flow 0 `Tag` parser (Hail, Define, Manifest).

---

*© 02026 Wilson Bilkovich*
