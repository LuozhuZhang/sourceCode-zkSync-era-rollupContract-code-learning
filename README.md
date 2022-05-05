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

# 结构

### High-level overview

zksync的这个repo由多个application组成，不能简单理解成一个大而杂的proj，所以阅读的时候也要学会模块化阅读，zkSync由以下几个部分组成
* 1）contract on L1：就是接收batch，验证l2的proof和correctness的合约
* 2）Prover application：<br/>
为batch/block生成proof的application（貌似是多线程的，很多works和jobs），proof生成后会report给server application，然后server会把这个proof publish到L1 contract上<br/>
core team说prover application设计成on-demand worker（应该还是多线程的），所以当并发量很大的时候（或者根本没有tx的时候）都可以应对，只要server load is high就行，而且生成proof非常耗费时间，需要现代CPU或者许多ARM才可以执行
* 3）Server application：<br/>
一个zksync network的node节点（应该是类似于geth一样的后端？），其本身应该也是一个blockchain，存储/处理batch里面具体的transaction，还有request proof和publish data on L1-contract
* 4）Explorer等工具：<br/>
zkSync的区块链浏览器，从server API中直接接收数据（大概率获取l2链上数据可以直接跑一个server然后调用API，不需要再写RPC调用工具）

更详细的拆解server（实现rollup就需要写一个network）
* 1）core/bin/server中有一个完整的binary单片应用，可以实现所有的功能（Monolithic application，有指binary的意思？所有这些功能都由binary就可以压缩完成）
* 2）server还实现了一个模块化的（Microservices applications，非binary）<br/>
  * core/bin/zksync_core（作为CORE server）中包含了transaction的memory pool，还有new blocks的commit<br/>
  * core/bin/zksync_api（API server）实现了REST API、JSON RPC、HTTP/WS的front-end（前端）通信接口<br/>
  * core/bin/zksync_eth_sender（Ethereum Sender server）把batch打包完的blocks传回layer1 contract（这个很重要，因为和l1的rollup contract通信，对应的还有一个eth watcher）<br/>
  * core/bin/zksync_witness_generator（Witness Generator service），貌似是定期处理witness生成proof的模块（原文是“creates input data required for provers to prove blocks, and implements a private API server for provers to interact with.” ）<br/>

zkSync启动的方式
* 1）compiled and deployed zkSync contract on L1
* 2）launch zksync server
* 3）至少启动一个prover，而且需要连接到server application

![image](https://user-images.githubusercontent.com/70309026/166221909-3288c3cd-7905-4814-b256-4f5733352931.png)

### Low-level Overview

我们选择master branch来阅读（最新的v1代码，不会再有大幅度的更新），mater branch的更迭速度较快（每天都有更新），团队目前的重心主要是v2，也就是zkEVM

- `/bin`: 一些bash代码（cli，command-line interface）
- `/contracts`: 所有zkSync的smart contract
  - `/contracts`: 详细的合约代码
  - `/contracts`: 一些ts scripts，也是contract的管理工具
- `/core`: 实现zksync network的代码
  - `/bin`: 运行zksync network必须要运行的几个模块，包含了server和prover
  - `/lib`: 偏向于工具的一些东西
  - `/test`: 测试工具（测试用rust写的rollup network）
- `/docker`: zkSync的环境文件，docker的那一套
- `/etc`: 配置文件（包括env环境和token list）
- `/infrastructure`: 基础设施（比如一些wallet和explorer可能就会归为此类）
- `/keys`: circuit模块的verification key
- `/sdk`: 为zksync network实现的sdk（有多种语言，比如js、rust等，还有一个WASM工具）

- `/changelog`: SDK和contract各模块更新的record
- `/docs`: 详细的说明文档，比如architecture和contract

<br/>

最重要的两个模块是contract和core，contract里面有L1-rollup contract和contract manage的代码，Core模块里有server和prover的代码，基本上L2的主要逻辑都在里面

- `/core`: 
  - `/bin`: 
    - `/server`: server的单片程序
    - `/prover`: prover的大部分程序（可以看到有个dummy和plonk setup的文件）
    - `/data_restore`: Utility｜可以从contract中恢复zksync state的工具（崩溃时提现用的工具，保证数据可用性 DA）
    - `/key_generator`: Utility｜为network生成verification key的工具
    - `/parse_pub_data`: Utility｜parse zkSync operation pubdata的工具（用来更新state的）
    - `/zksync_core`: server Core
    - `/zksync_api`: server API
    - `/zksync_eth_sender`: server Ethereum sender
    - `/zksync_witness_generator`: server Witness Generator & Prover Server
  - `/lib`: 
    - `/basic_types`: 定义了一些基本的数据结构，还有essential zkSync primitives的声明
    - `/circuit`: 生成proof所需的一些circuit代码，官方解释是为了保证tx执行结果的正确而必不可少的cryptographic environment
    - `/config`: Utilities｜为zksync加载各种config option的工具
    - `/contracts`: Loaders｜加载zksync contract接口和ABI的工具
    - `/crypto`: Cryptographical primitives using among zkSync crates
    - `/eth_client`: Interact｜有一个跟以太坊节点交互的接口，为了上面的eth_sender和eth_watcher与layer1交互
    - `/zksync_prometheus_exporter`: Prometheus数据导出工具
    - `/prover_utils`: Utilities｜一系列proof generate的工具
    - `/state`: 一个 fast pre-circuit executor，用于快速打包zksync的交易，生成能够返回到layer1的block
    - `/storage`: Database｜这是一个封装的db接口，是不是像以太坊levelDB、stateDB的那种东西？
    - `/types`: 定义了transactions、priority operations（L1操作）和 operations的数据类型
    - `/utils`: 各种杂项的工具（Miscellaneous helpers）
    - `/vlog`: Utility｜记录日志的工具
  - `/test`: 
    - `/loadtest`: 测试server的highload testing工具
    - `/test_account`: 一个可以生成虚拟account，然后测试zksync network的工具
    - `/testkit`: zksync的一个relatively low-level的测试library
    - `/ts-test`: 一个集成测试集（用ts实现），需要运行server和prover

### zkSync v1基本上已经稳定了，团队重心在v2和zkEVM上

core team目前主要在做v2的升级和开发（而且还没开源），v1只会进行一些 stability & security updates（而且他们还同时在做许多件事，比如 wallets, exchanges and offramp/onramp solutions等）<br/>

他们的重心在v2（zkEVM），而且他们还在围绕zkEVM做许多件事（比如 prepare the new server that is web3 compatible, compiler and plugins for it, etc），所以再次，zkEVM是我们肯定需要研究的一块内容（applied zkp就很不错）

# 智能合约

### 合约调用关系
我们手动把这个合约的调用关系给可视化了一下

![WechatIMG17369](https://user-images.githubusercontent.com/70309026/165947173-52b35cf6-017a-4318-97b2-1d964e5c9f3e.jpeg)

而且也可以把这个流程可视化出来，目测最主要的入口文件是zkSync contract，我们从这个文件开始看zkSync contract的主要功能：governance、deposit、withdraw、Block Commitment、Block Verification、Reverting expired blocks、Priority queue

![zksync](https://raw.githubusercontent.com/LuozhuZhang/sourceCode-zkSync-rollupContract/6b55f79361f260c5d31ca6eff305e1652af8b649/imgs/zksync.svg)

每个工作的模块可能都对应着一个文件/contract program

![image](https://user-images.githubusercontent.com/70309026/166223753-0905ba2e-d6c5-4874-a41f-f5d1caf0cb4b.png)

* zkSync调用了middleware合约：storage、additionalZkSync、utils、operation、events
调用了atom合约：Bytes、Configs、ReentrancyGuard、SafeCast、SafeMath、SafeMathUInt128、UpgradeableMaster
zkSync Contract继承了UpgradeableMaster、Storage、Config、Events、ReentrancyGuard

* 非常核心的是 event contract 和防止 reentrant calls 的合约

* UpgradeableMaster模块主要是控制contract的升级与关闭，除了zksync.sol，upgradeGatekeeper文件也调用很频繁，ownable合约：定义了合约的拥有者，封装了其他几个方法

* 最值得看的是deposit、withdraw（full/part exit）模块，然后看看怎么被block commit的

* 涉及到L1的操作都是Priority（但是不知道withdraw有没有比deposit的优先级更高一些），depositETH调用registerDeposit，后者操作asset deposit，其中tokenID=0代表Ether，zkSync自己定义了ERC20的接口，zksync中有owner和rollup key的概念，owner就是asset的实际拥有者，转账就是更换owner。rollup key就是owner的private key，L2的addr由L1相同的private key生成，该机制非常值得深入研究

* Deposit ERC20与depositETH类似，但是要传入不同的token address
