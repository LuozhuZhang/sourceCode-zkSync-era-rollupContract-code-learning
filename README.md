<div align="center">
  <a href="https://www.artstation.com/artwork/Gy8Rz">
    <img alt="eth logo" src="https://pbs.twimg.com/media/FPHiK-XWUAQKSLj?format=jpg&name=large" >
  </a>
  <p align="center">
    <a href="https://github.com/LuozhuZhang/sourceCode-zkSync-rollupContract/graphs/contributors">
      <img alt="GitHub contributors" src="https://img.shields.io/github/contributors/LuozhuZhang/sourceCode-zkSync-rollupContract">
    </a>
    <a href="https://GitHub.com/LuozhuZhang/sourceCode-zkSync-rollupContract/issues/">
      <img alt="GitHub issues" src="https://badgen.net/github/issues/LuozhuZhang/sourceCode-zkSync-rollupContract/">
    </a>
    <a href="http://makeapullrequest.com">
      <img alt="pull requests welcome badge" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat">
    </a>
    <a href="https://twitter.com/LuozhuZhang">
      <img alt="Twitter" src="https://img.shields.io/twitter/url/https/twitter.com/LuozhuZhang.svg?style=social&label=Follow%20%40LuozhuZhang">
    </a>
  </p>
</div>

This [tweet](https://twitter.com/LuozhuZhang/status/1521124870385405953?s=20&t=QPozv7Qx1QP9y4i1B_ABAQ) show more details, please feel free to DM me.

# Architecture

### High-level overview

This repo of zksync consists of multiple applications, which cannot be simply understood as one large and complex proj, so you must learn to read modularly when reading. zkSync consists of the following parts
* 1) contract on L1: the contract that receives the batch and verifies the proof and correctness of l2
* 2) Prover application: <br/>
The application that generates the proof for batch/block (it seems to be multi-threaded, many works and jobs), after the proof is generated, it will be reported to the server application, and then the server will publish the proof to the L1 contract<br/>
The core team said that the prover application is designed as an on-demand worker (it should be multi-threaded), so it can be dealt with when the amount of concurrency is large (or when there is no tx at all), as long as the server load is high, and the generation of proof is very Time consuming, requires modern CPUs or many ARMs to execute
* 3) Server application: <br/>
A node of a zksync network (should be a backend similar to geth?), which itself should also be a blockchain, storing/processing the specific transactions in the batch, as well as request proof and publish data on L1-contract
* 4) Tools such as Explorer: <br/>
zkSync's blockchain browser, which directly receives data from the server API (with a high probability of obtaining data on the l2 chain, you can directly run a server and then call the API, no need to write RPC calling tools)

More detailed disassembly of the server (to implement rollup, you need to write a network)
* 1) There is a complete binary monolithic application in core/bin/server, which can realize all functions (Monolithic application, which means binary? All these functions can be compressed by binary)
* 2) The server also implements a modular (Microservices applications, non-binary) <br/>
  * core/bin/zksync_core (as the CORE server) contains the memory pool of the transaction and the commit of the new blocks<br/>
  * core/bin/zksync_api (API server) implements the front-end (front-end) communication interface of REST API, JSON RPC, HTTP/WS<br/>
  * core/bin/zksync_eth_sender (Ethereum Sender server) sends the batched blocks back to the layer1 contract (this is very important, because it communicates with the rollup contract of l1, and there is a corresponding eth watcher)<br/>
  * core/bin/zksync_witness_generator (Witness Generator service), seems to be a module that regularly processes witness to generate proof (the original text is "creates input data required for provers to prove blocks, and implements a private API server for provers to interact with.")<br />

How zkSync is started
* 1) compiled and deployed zkSync contract on L1
* 2) launch zksync server
* 3) Start at least one prover and need to connect to the server application

![image](https://user-images.githubusercontent.com/70309026/166221909-3288c3cd-7905-4814-b256-4f5733352931.png)

### Low-level Overview

We choose the master branch to read (the latest v1 code, there will be no major updates), the change speed of the mater branch is fast (updated every day), the team's current focus is mainly v2, which is zkEVM

- `/bin`: Some bash code（cli，command-line interface）
- `/contracts`: All zkSync smart contract
  - `/contracts`: Detailed contract code
  - `/contracts`: Some ts scripts are also contract management tools
- `/core`: Code to implement zksync network
  - `/bin`: Several modules that must be run to run zksync network, including server and prover
  - `/lib`: Something biased towards tools
  - `/test`: Test tool (test rollup network written in rust)
- `/docker`: The environment file of zkSync, the set of docker
- `/etc`: Configuration file (including env environment and token list)
- `/infrastructure`: Infrastructure (such as some wallets and explorers may fall into this category)
- `/keys`: Verification key of the circuit module
- `/sdk`: The sdk implemented for the zksync network (in multiple languages, such as js, rust, etc., and a WASM tool)

- `/changelog`: The updated record of each module of SDK and contract
- `/docs`: Detailed documentation, such as architecture and contract

<br/>

The two most important modules are contract and core. The contract contains the code of L1-rollup contract and contract manage. The Core module contains the code of server and prover. Basically, the main logic of L2 is in it.

- `/core`: 
  - `/bin`: 
    - `/server`: Monolithic program for server
    - `/prover`: most programs of prover (you can see the files with dummy and plonk setup)
    - `/data_restore`: Utility｜A tool that can restore zksync state from a contract (a tool for withdrawing cash when it crashes, ensuring data availability DA)
    - `/key_generator`: Utility｜A tool for generating verification keys for the network
    - `/parse_pub_data`: Utility|tool for parse zkSync operation pubdata (used to update state)
    - `/zksync_core`: server Core
    - `/zksync_api`: server API
    - `/zksync_eth_sender`: server Ethereum sender
    - `/zksync_witness_generator`: server Witness Generator & Prover Server
  - `/lib`: 
    - `/basic_types`: defines some basic data structures, as well as the declaration of essential zkSync primitives
    - `/circuit`: some circuit code required to generate proof, the official explanation is the cryptographic environment necessary to ensure the correct execution result of tx
    - `/config`: Utilities｜Utilities to load various config options for zksync
    - `/contracts`: Loaders｜Tools for loading zksync contract interfaces and ABIs
    - `/crypto`: Cryptographical primitives using among zkSync crates
    - `/eth_client`: Interact｜There is an interface to interact with the Ethereum node, for the above eth_sender and eth_watcher to interact with layer1
    - `/zksync_prometheus_exporter`: Prometheus data exporter
    - `/prover_utils`: Utilities｜A series of tools for proof generate
    - `/state`: a fast pre-circuit executor for quickly packing zksync transactions and generating blocks that can be returned to layer1
    - `/storage`: Database｜This is an encapsulated db interface, is it something like the Ethereum levelDB and stateDB?
    - `/types`: defines the data types of transactions, priority operations (L1 operations) and operations
    - `/utils`: Miscellaneous helpers
    - `/vlog`: Utility｜A tool for logging
  - `/test`: 
    - `/loadtest`: highload testing tool for testing server
    - `/test_account`: a tool that can generate a virtual account and then test the zksync network
    - `/testkit`: a relatively low-level test library for zksync
    - `/ts-test`: an integration test suite (implemented with ts), which needs to run server and prover

### zkSync v1 is basically stable, the team focuses on v2 and zkEVM

The core team is currently mainly doing v2 upgrades and development (and not open source yet), v1 will only do some stability & security updates (and they are also doing many things at the same time, such as wallets, exchanges and offramp/onramp solutions, etc.)<br/>

Their focus is on v2 (zkEVM) and they are still doing a lot of things around zkEVM (like prepare the new server that is web3 compatible, compiler and plugins for it, etc), so again, zkEVM is a piece we definitely need to look into Content (applied zkp is good)

# Smart Contract

### contract call relationship
We manually visualized the calling relationship of this contract

![WechatIMG17369](https://user-images.githubusercontent.com/70309026/165947173-52b35cf6-017a-4318-97b2-1d964e5c9f3e.jpeg)

And this process can also be visualized. The most important entry file is the zkSync contract. We start from this file to see the main functions of the zkSync contract: governance, deposit, withdraw, Block Commitment, Block Verification, Reverting expired blocks, Priority queue

![zksync](https://raw.githubusercontent.com/LuozhuZhang/sourceCode-zkSync-rollupContract/6b55f79361f260c5d31ca6eff305e1652af8b649/imgs/zksync.svg)

Each working module may correspond to a file/contract program

![image](https://user-images.githubusercontent.com/70309026/166223753-0905ba2e-d6c5-4874-a41f-f5d1caf0cb4b.png)

* zkSync calls middleware contracts: storage, additionalZkSync, utils, operation, events
Called atom contracts: Bytes, Configs, ReentrancyGuard, SafeCast, SafeMath, SafeMathUInt128, UpgradeableMaster
zkSync Contract inherits UpgradeableMaster, Storage, Config, Events, ReentrancyGuard

* The very core is the event contract and the contract that prevents reentrant calls

* The UpgradeableMaster module mainly controls the upgrade and shutdown of the contract. In addition to zksync.sol, the upgradeGatekeeper file is also called frequently. The ownable contract: defines the owner of the contract and encapsulates several other methods

* The most worth watching is the deposit, withdraw (full/part exit) module, and then see how it is block committed

* Operations involving L1 are all Priority (but I don’t know if withdraw has a higher priority than deposit), depositETH calls registerDeposit, which operates asset deposit, where tokenID=0 represents Ether, and zkSync defines its own ERC20 interface , zksync has the concept of owner and rollup key, the owner is the actual owner of the asset, and the transfer is to change the owner. The rollup key is the private key of the owner, and the addr of L2 is generated by the same private key of L1. This mechanism is worthy of further study.

* Deposit ERC20 is similar to depositETH, but requires a different token address
