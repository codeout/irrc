# irrc

[![Build Status](https://travis-ci.org/codeout/irrc.svg)](https://travis-ci.org/codeout/irrc)
[![Code Climate](https://codeclimate.com/github/codeout/irrc.png)](https://codeclimate.com/github/codeout/irrc)

irrc is a lightweight and flexible client of IRR / Whois Database to expand arbitrary as-set and route-set objects into a list of origin ASs and prefixes belonging to those ASs. It will concurrently queries multiple IRR / Whois Databases for performance.

## Features

* Fast. irrc runs multi-threaded micro clients to process simultaneous IRR / Whois queries for performance. It also uses object caches.
* Handy. irrc's CLI client provides an easy way to resolve prefixes from as-set and route-set objects. It works even when multiple objects given as arguments.
* Dual stack. irrc returns both IPv4 and IPv6 prefixes by default. There is no need to kick a command twice for dual stacked result.
* Flexible. irrc provides an extensible ruby library which allows to modify IRR / Whois queries more flexibly.
* Pretty print. irrc shows prefixes in YAML format like [this](#example).
* Pure ruby. irrc doesn't depend on any other ruby gem.
* Lightweight. irrc is designed to gather prefixes from arbitrary as-set and route-set. It's implemented as simple as possible to achieve that. In other words, domain name related features are not supported.


## Installation

For bundler:

    gem 'irrc'

And then:

    $ bundle

Otherwise:

    $ gem install irrc


## Usage

### CLI

irrc privides a peval-like CLI interface.

* Query JPIRR about AS-JPNIC and AS-OCN

    ```shell
    $ irrc -h jpirr AS-JPNIC AS-OCN
    ```

* Query JPIRR about AS-JPNIC with authoritative IRR (SOURCE:) based filter

    ```shell
    $ irrc -h jpirr -s radb -s apnic AS-JPNIC
    ```

* Query JPIRR about AS-JPNIC for IPv4 only

    ```shell
    $ irrc -h jpirr -4 AS-JPNIC
    ```

### As a Library

You can load irrc as a library and use it easily in your own code.

```ruby
require 'irrc'

client = Irrc::Client.new
client.query(:jpirr, 'AS-JPNIC', source: :jpirr)    # queries JPIRR about AS-JPNIC with a SOURCE: filter
client.query(:ripe, 'AS-RIPENCC', protocol: :ipv4)  # queries RIPE Whoisd about AS-RIPENCC for IPv4 only
client.perform                                      # returns the results in a Hash
```


## Example

```shell
$ irrc -h jpirr AS-JPNIC
```

will result in a YAML:

```yaml
---
AS-JPNIC:               # queried object
  :ipv4:
    AS2515:             # AS-JPNIC has AS2515 as a origin AS
    - 202.12.30.0/24    # 4 IPv4 prefixes belonging to AS2515
    - 192.41.192.0/24   #
    - 211.120.240.0/21  #
    - 211.120.248.0/24  #
  :ipv6:
    AS2515:
    - 2001:0fa0::/32
    - 2001:dc2::/32
    - 2001:DC2::/32
```


## Supported Ruby Versions

* Ruby >= 2.0.0

Successfully tested with 2.0.0, 2.1.0, 2.1.1, 2.1.2.


## Threading

irrc will send queries to multiple IRR / Whois servers simultaneously in multi-threads. Single-thread processing for each server by default.

To configure the number of threads per server:

### CLI

```shell
$ irrc -h jpirr -t 2 AS-JPNIC AS-OCN  # 2 threads to query JPIRR
```

### AS a Library

```ruby
client = Irrc::Client.new(2)  # 2 threads per IRR / Whois server
```


## Debugging

irrc uses ```STDERR``` printer for a logger by default, which reports more severe messages than INFO.

### CLI

To display debug information including raw messages of IRR / Whois protocol:

```shell
$ irrc -h jpirr -d AS-JPNIC
```

### As a Library

To use modified Logger:

```ruby
client = Irrc::Client.new {|c| c.logger = Rails.logger }
```


## Quick Benchmark

Here is a quick performance comparison with peval and irrpt.

* Ordinary as-set

| CLI command                     |      user |     system |     cpu |      total |
| :------------------------------ | --------: | ---------: | ------: | ---------: |
| peval -h jpirr.nic.ad.jp AS-OCN |     0.14s |      0.04s |      1% |      9.397 |
| irrpt_eval AS-OCN               |     0.35s |      0.06s |      5% |      8.021 |
| **irrc -h jpirr AS-OCN**        | **0.42s** |  **0.09s** |  **4%** | **10.639** |

* Huge as-set

Object caching may contribute to the query performance.

| CLI command                               |        user |     system |     cpu |       total |
| :---------------------------------------- | ----------: | ---------: | ------: | ----------: |
| peval -h jpirr.nic.ad.jp AS-HURRICANE     |      67.29s |      1.21s |     22% |     4:58.16 |
| irrpt_eval AS-HURRICANE                   |     163.10s |      1.38s |     43% |     6:18.17 |
| **irrc -h jpirr AS-HURRICANE**            |  **20.26s** |  **1.84s** |  **7%** | **4:54.37** |

* Multiple as-set

Multi-threading and object caching may contribute to the query performance.

| CLI command                                                    |        user |     system |     cpu |       total |
| :------------------------------------------------------------- | ----------: | ---------: | ------: | ----------: |
| for i in AS-HURRICANE AS-GBLX; peval -h jpirr.nic.ad.jp $i     |      76.47s |      1.08s |     20% |     6:15.80 |
| irrpt_fetch                                                    |     174.21s |      1.29s |     44% |     6:38.50 |
| irrc -h jpirr AS-HURRICANE AS-GBLX                             |      22.28s |      1.75s |      8% |     4:34.31 |
| **irrc -h jpirr -t 2 AS-HURRICANE AS-GBLX**                    |  **23.04s** |  **1.81s** |  **9%** | **4:09.27** |


## Contributing

Please fork it, fix and then send a pull request. :tada:

To run tests just type:

```shell
$ rake
```

Please report issues or enhancement requests to [GitHub issues](https://github.com/codeout/irrc/issues).
For questions or feedbacks write to my twitter @codeout.


## Copyright and License

Copyright (c) 2014 Shintaro Kojima. Code released under the [MIT license](LICENSE).
