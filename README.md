<p align="center">
  <a href="https://github.com/roliboy/shiba">
    <img src="images/logo.png" alt="logo" width="128" height="128">
  </a>
  <h1 align="center">SHIBA</h1>
  <p align="center">
    The good boie HTTP server
  </p>
</p>

<br />


## About The Project [WIP]

Shiba is your all-in-one webapp prototyping companion. A versatile and easy-to-use tool that can act as a static HTTP server, CORS proxy, REST API and more

<!-- TL;DR of how it compares to other frameworks? -->
<!-- shiba is intended to be used exclusively in the prototyping phase -->
<!-- fail fast and fail safe mentality? -->
<!-- developing a rest api backend in <insert language> for days vs spinning up some shiba resources in seconds; even if the project is doomed to fail you didn't spend time on implementing something that can be closely aproximated -->


## Features & Usage [WIP]

<!-- TODO: more relevant example / full app -->

- ### static
  ```plaintext
  shiba static /      index.html
  shiba static /media images
  ```
  Used for statically serving local files and directories
  
- ### proxy
  ```plaintext
  shiba proxy /api localhost:8080/api/v2
  ```
  Used for forwarding requests to a different server or endpoint and attaching CORS headers to responses

- ### command
  ```plaintext
  shiba command /wordcount    'wc -w'
  shiba command /drop/{table} ./dropit
  ```
  Used for executing commands and scripts. Path variables will be used as arguments and the request body as standard input

- ### resource
  ```plaintext
  shiba resource /documents documents.json
  ```
  Used for creating a REST resource that supports CRUD operations

### putting everything together
invoking shiba with these arguments:
```plaintext
shiba \
  static   /             index.html            \
  static   /media        images/               \
  proxy    /service      localhost:8080/api/v2 \
  command  /wordcount    'wc -w'               \
  command  /drop/{table} ./dropit              \
  resource /documents    documents.json 
```
will produce the following output:
![startup](images/startup.png)

<!-- - `σ` (sigma): static file
- `Σ` (uppercase sigma): static directory
- `ψ` (psi): proxy
- `λ` (lambda): command
- `δ` (delta): resource -->

making a few requests to the generated endpoints

```bash
http GET    :1337/media/logo.png
http GET    :1337/media/shiba.png
http GET    :1337/service/say-hello
http GET    :1337/drop/users
http POST   :1337/documents title="new document" pages:=256
http DELETE :1337/documents/2
```

will generate these logs:

![logs](images/logs.png)

see `shiba --help` for more information


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
- [netcat](http://netcat.sourceforge.net) - listening for incoming connections
<!-- - [socat](http://www.dest-unreach.org/socat) -->
- [jq](https://stedolan.github.io/jq) - for processing JSON


## Todos [WIP]

- Token authentication
- Sqlite backend
- Entity relations (maybe)
- Allow spaces in resource field names
- Configuration console
  - serve file: file listing with `fzf`
  - serve directory: directory listing with `fzf`
  - executable: file listing with `fzf`
  - script: text editor
  - rest resource: ?
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
* [avleen's bashttp](https://github.com/avleen/bashttp)
* [rocket](https://rocket.rs)
