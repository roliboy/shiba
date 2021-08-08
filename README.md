<p align="center">
  <a href="https://github.com/roliboy/shiba">
    <img src="images/logo.png" alt="logo" width="128" height="128">
  </a>
  <h1 align="center">SHIBA</h1>
  <p align="center">
    The good boie webdev companion
  </p>
</p>

<br />


## About The Project [WIP]

Shiba is your all-in-one webapp prototyping companion. A versatile and easy-to-use tool that can act as a static HTTP server, CORS proxy, REST API and more.

<!-- TL;DR of how it compares to other frameworks? -->
<!-- shiba is intended to be used exclusively in the prototyping phase -->
<!-- fail fast and fail safe mentality? -->
<!-- developing a rest api backend in <insert language> for days vs spinning up some shiba resources in seconds; even if the project is doomed to fail you didn't spend time on implementing something that can be closely aproximated -->


## Features & Usage [WIP]

<!-- TODO: more relevant example / full app -->
Currently, shiba has four request handlers:

- ### static
  ```plaintext
  shiba static /      index.html
  shiba static /media images/
  ```
  Used for statically serving local files and directories.
  See [static.md](examples/static.md) for more examples.
  
- ### proxy
  ```plaintext
  shiba proxy /api localhost:8080/api/v2
  ```
  Used for forwarding requests to a different server or endpoint and attaching CORS headers to responses.
  See [proxy.md](examples/proxy.md) for more examples.

- ### command
  ```plaintext
  shiba command /wordcount    'wc -w'
  shiba command /drop/{table} ./dropit
  ```
  Used for executing commands and scripts.
  See [command.md](examples/command.md) for more examples.

- ### resource
  ```plaintext
  shiba resource /documents documents.sqlite3 [ title:string pages:int ]
  ```
  Used for creating a REST resource that supports CRUD operations.
  See [resource.md](examples/resource.md) for more examples.

### example
Using the following parameters, shiba will statically host an index page and create an endpoint that counts the number of words in post data:
```plaintext
shiba \
  static  /          index.html \
  command /wordcount 'wc -w'
```
let's make some requests as well:
```bash
curl -X GET  localhost:1337/
curl -X GET  localhost:1337/404
curl -X POST localhost:1337/wordcount -d 'hello shiba'
```

<!-- - `σ` (sigma): static file
- `Σ` (uppercase sigma): static directory
- `ψ` (psi): proxy
- `λ` (lambda): command
- `δ` (delta): resource -->


<div align="center" href="https://asciinema.org/a/">
  <img src="images/run.gif" alt="shiba demo" width="1337">
</div>

## Installation & Prerequisites [WIP]

Shiba was written entirely in bash, so you will only need a copy of the source file to get up and running

```bash
# curl | bash like real chads
curl -Ls roliboy.ml/shiba | bash -s static / index.html

# or

# assemble from source
git clone git@github.com:roliboy/shiba.git
cd shiba
make
./shiba static index.html
```

Depending on your system, there might be some missing command line utilities required by shiba, please check that the following are installed before running:
- [socat](http://www.dest-unreach.org/socat) - listening for incoming connections and communicating with clients
- [jq](https://stedolan.github.io/jq) - for parsing and validating JSON
- [sqlite3](https://github.com/sqlite/sqlite) - for data storage

## Todos [WIP]

- Disallow null keys when using custom key field
- Make logging thread safe (kind of)
- Token authentication
- Update --help
- Entity relations (maybe)
- TLS support
  - `https://airman604.medium.com/simple-tls-listener-4e1cca7856b8`
  - `socat TCP4-LISTEN:8080,fork EXEC:/usr/local/bin/shiba`


## ~~Bugs~~ More Features [WIP]

- `http GET :1337/dir/` matches `/dir/` and tries to retrieve a file with empty name


## License [WIP]

Distributed under the MIT License, see `LICENSE` for more information


## Contact [WIP]

Nagy Roland - [roliboy.ml](https://roliboy.ml) - roliboy@protonmail.com

Project Link: [https://github.com/roliboy/shiba](https://github.com/roliboy/shiba)


## Acknowledgements
* [avleen's bashttpd](https://github.com/avleen/bashttpd) - for the idea
* [rust's rocket framework](https://rocket.rs) - for the cli logging
* [regex101](https://regex101.com/) - for preserving my sanity while writing regular expressions
