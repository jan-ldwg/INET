## Installation on macOS using Docker

1. Make sure make and docker are installed

```sh
make --version
docker --version
```

2. Create a folder and place the Dockerfile, Makefile as well as the full source code for ns-3

3. Build the container

```sh
make build_ns3 NS3_PATH=$(pwd)/ns-3.45
```

4. Test that ns-3 is running correctly

```sh
make run NS3_PATH=$(pwd)/ns-3.45 SCRIPT=hello-simulator
```

This should print `Hello Simulator` to the console.

5. Put the script you want to run into the scratch folder of ns3

6. Run the script with

```sh
make run NS3_PATH=$(pwd)/ns-3.45 SCRIPT=npa-04 ARGS="--queueDiscType=FifoQueueDisc"
make run NS3_PATH=$(pwd)/ns-3.45 SCRIPT=npa-04 ARGS="--queueDiscType=CoDelQueueDisc"
make run NS3_PATH=$(pwd)/ns-3.45 SCRIPT=npa-04 ARGS="--queueDiscType=RedQueueDisc"
```
