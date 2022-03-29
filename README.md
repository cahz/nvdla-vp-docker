# NVDLA VP docker

A more updated version of the VP docker image, configured to the `nv_small` definition. Please pull from dockerhub:

```
docker pull esatu/nvdla-vp
```

## Running LeNet example

```
# start docker container
docker run -it esatu/nvdla-vp

# inside the container, execute the following:

# 1) prepare the inference
cd /usr/local/nvdla-compiler/
wget https://www.esp.cs.columbia.edu/docs/thirdparty_acc/lenet_mnist.prototxt
wget https://www.esp.cs.columbia.edu/docs/thirdparty_acc/lenet_mnist.caffemodel
wget https://www.esp.cs.columbia.edu/docs/thirdparty_acc/lenet_mnist.json
wget https://github.com/nvdla/sw/raw/master/regression/images/digits/seven.pgm
./nvdla_compiler --prototxt lenet_mnist.prototxt --caffemodel lenet_mnist.caffemodel --profile fast-math --cprecision int8 --configtarget nv_small --calibtable lenet_mnist.json --quantizationMode per-filter --informat nchw
mv fast-math.nvdla seven.pgm /usr/local/vp/sw

# 2) launch emulator
export SC_SIGNAL_WRITE_CHECK=DISABLE
cd /usr/local/vp/
./bin/aarch64_toplevel -c sw/aarch64_nvdla.lua

# now the qemu emulation starts, you can exit with CTRL-A X
buildroot login: root
Password: nvdla

mount -t 9p -o trans=virtio r /mnt && cd /mnt/sw
insmod drm.ko && insmod opendla_2.ko

./nvdla_runtime --loadable fast-math.nvdla --image seven.pgm --rawdump
# should finish after around 30 seconds
# for exit, press CTRL+A X
```
