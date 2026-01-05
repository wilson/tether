# tether
![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)

**Ballistic transport for high-latency, lossy, or hostile networks.**

`tether` is a research networking stack designed for environments where latency is strictly constrained by physics and link quality is probabilistic (e.g., satellite constellations, quantum computer microwave-steering, or heavily-oversubscribed data center fabrics).

It abandons the "Stop-and-Wait" determinism of TCP in favor of **Schrödinger Bridge** dynamics, treating data transmission as a probability distribution of mass rather than a serialized stream of messages. Entropic Optimal Transport (EOT) is a direct source of inspiration for Tether.

## The Problem: The Acknowledgement Tax

Standard protocols (TCP/QUIC) assume that the cost of coordination (ACKs, Handshakes) is negligible compared to bandwidth. In high-friction regimes (where lag is non-trivial or packet loss is a feature of the medium) this assumption fails.

1.  **ACK Storms:** Waiting for confirmation on a 500ms RTT link halts throughput.
2.  **Jitter Amplification:** Retransmission logic often exacerbates congestion (bufferbloat).
3.  **Context Blindness:** A firewall sees "Port 443" but cannot see "This packet is an Authentication Command sent to a Monitoring Node."

## The Solution: Ballistic Networking

`tether` implements a **Single-Context Hyperplane**. It does not distinguish between Transport and Application layers.

### 1. Solitons (Probabilistic Transmissions)
Data is not segmented; it is emitted as **Solitons**: erasure-coded bursts of immutable state (`Atoms`).
* **Ballistic Erasure:** The sender calculates the channel entropy (noise floor) and emits the necessary `N` shards to guarantee reconstruction with the desired (default `99.999%`) confidence.
* **Zero-ACK:** The receiver reconstructs the state. It does not reply. The sender stops transmitting when the "Entropy Budget" is exhausted. Application-layer responses can optionally be used to tune such a budget as the "link stabilizes".

### 2. Sinkhorn Routing
Flow control is modeled as a thermodynamic problem using **Sinkhorn Distances**.
* **Congestion** is treated as **Heat**, which effectively produces "resistance".
* As the link "heats up" and the cost increases, the sender naturally throttles emission to maintain the optimal transport plan.

### 3. Physics-Aware Filtering (OWASP AppSensor-inspired)
Routing decisions are made based on the **Capabilities** of the destination, not its address.
* The protocol header contains a `Context Hash`: a cryptographic binding to the receiver's hardware constraints (e.g., "Must support f64 math").
* **Result:** A packet destined for a node that cannot physically execute the payload is dropped at the NIC level, long before "userspace".

## Reference Implementation

This repository contains the reference implementation in **Zig**.

### Target Architecture
* **Language:** Zig 0.16+ [(nightly)](https://ziglang.org/download/)
* **Hardware:** Intel E800 Series NICs
    * Specifically, [E810-CQDA2](https://www.intel.com/content/www/us/en/products/sku/192558/intel-ethernet-network-adapter-e810cqda2/specifications.html) and [E830-CQDA2](https://www.intel.com/content/www/us/en/products/sku/239775/intel-ethernet-network-adapter-e830cqda2/specifications.html)
* **Driver Model:** `AF_XDP` (Zero-Copy) with [DDP](https://cdrdv2.intel.com/v1/dl/getContent/617015) (Dynamic Device Personalization).

### Why Intel E800?
Tether's prototype utilizes the **DDP** capabilities of the Intel architecture to program the Tether Protocol Header directly into the NIC's parse graph. This allows:
1.  **Hardware Steering:** `Context Hash` validation happens in silicon. Invalid packets never pollute the PCIe bus.
2.  **ADQ Isolation:** Tether traffic is isolated into dedicated hardware queues, bypassing the host OS kernel scheduler.

## Initial Performance Goals
* **Throughput:** 80Gbps+ on 100GbE links (Single Core).
* **Latency:** < 3µs (Wire-to-App).

## Status
**Pre-Alpha / Research**
This is an experimental clean-room implementation. It is not compatible with standard IP networks, though I may implement an IPv6 bridge separately.

* [ ] **Atom Layout:** 128-byte alignment definition.
* [ ] **DDP Profile:** Intel DDP binary generation for Tether headers.
* [ ] **Sinkhorn Solver:** Zig SIMD implementation of the transport plan.

---
*© 02026 Wilson Bilkovich*
