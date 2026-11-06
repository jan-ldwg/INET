ifndef NS3_PATH
$(error Need NS3_PATH. Please specify the path to your NS3 root directory. E.g., make <target> NS3_PATH=<your path to ns3 root>)
endif
DIMG_NAME=npa-ns3
DCMD=docker run --rm -v "$(NS3_PATH):/ns3" $(DIMG_NAME):latest
# One of the following: optimized, debug. Debug will print more outputs.
BUILD_PROFILE=debug 

build_docker_image: Dockerfile
	docker build . -t $(DIMG_NAME)


build_ns3: build_docker_image
	$(DCMD) bash -c "\
		cd /ns3 && \
		./ns3 configure --enable-examples --build-profile=$(BUILD_PROFILE) --disable-tests && \
		./ns3 build \
		"

run: 
ifndef SCRIPT
	$(error No script provided. Usage: make run SCRIPT=your-script.)
endif
	$(DCMD) bash -c " \
		cd /ns3 && \
		./ns3 run $(SCRIPT) \
		"
