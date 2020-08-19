---
layout: post
type: posts
title: Data Science and AI with Raspberry Pi 4’s ARM v8 64-bit (AArch64)
date: '2019-11-30T02:04:00.000+01:00'
author: Raul Pingarron
tags:
- IA
---
In this post I’ll show how to use a Raspberry Pi 4 as a lightweight Data Science station.   
The new board, which was released in June 2019, is based on a Broadcom BCM2711 SoC and its architecture represents a considerable upgrade on that used by the SoCs in earlier Pi models.   

---
To read a Spanish Google-translated version of this post click <a href="https://translate.google.com/translate?sl=auto&tl=es&u=https%3A%2F%2Fraul-pingarron.github.io%2F2019%2F11%2F30%2Fdata-science-and-AI-with-raspberry-pi4.html" target="_blank">here</a>.

---   


The new Pi 4 has a quad-core Cortex A72 64-bit CPU (ARM v8 64-bit) and the ARM cores can run up to 1.5Ghz. It also has a greatly improved GPU feaure set with much faster input/output, due to the addition of a PCIe link that connects the USB 2 and USB 3 ports, and a natively attached Gigabit Ethernet controller. There is also a new Memory Management Unit that allows the Pi 4 to access more memory than its antecesors; in fact, the Pi 4 unit I have has 4GB of main memory (LPDDR4-3200 SDRAM).   
<p align="center">
  <img width="480" height="300" src="/images/posts/rPi4_2.jpg">
</p>
## STEP 1: Getting a 64-bit OS for the Raspberry Pi 4
Current Raspbian is based on 32-bit armhfp kernel with specific optimizations to enable the use of the Pi’s processor’s floating-point hardware. There is no official support for ARMv8 64 bit in Raspbian yet, despite some Community-based distributions like Fedora and Archlinux already had an AArch64 version for the Raspberry 3-series (3B, 3B+, etc.) but not for the Pi 4. It is expected to have full support for Raspberry Pi 4 in Fedora with the Linux kernel 5.4.   
#### Why AArch64 for the Pi 4?
In older Raspberry PI models (like the 3B+), running a 32-bit kernel shouldn’t make a difference since the board has only 1GB of RAM but in a Pi 4, with 4GB of RAM and a more powerful ARMv8 CPU, we should see a difference according to this <a href="https://armkeil.blob.core.windows.net/developer/Files/pdf/graphics-and-multimedia/ARM_CPU_Architecture.pdf" target="_blank">presentation</a>. The 64-bit mode of the AArch64 architecture provides wider data register, better SIMD, better floating point, etc.   

 To get a running AArch64 kernel on the Pi 4 as easiest as possible we have several options:
- Use BalenaOS; see this <a href="https://www.balena.io/blog/balena-releases-first-fully-functional-64-bit-os-for-the-raspberry-pi-4/" target="_blank">link</a>.
- Go to the <a href="http://sarpi64.fatdog.eu/index.php?p=rpi4downloads" target="_blank">SARPi64 Project</a> (Slackware AArch64 on the Raspberry Pi).
- Use the beta version of the official 64-bit kernel released by the Raspberry Pi Foundation, upgrading the existing kernel using the rpi-update script located <a href="https://github.com/Hexxeh/rpi-update/blob/master/rpi-update" target="_blank">here</a>.
- Use the Debian Pi AArch64 by <a href="https://github.com/openfans-community-offical/Debian-Pi-Aarch64" target="_blank">OPENFANS</a>, which is the option I have chosen for this Blog post.   
<p align="center">
  <img width="640" height="363" src="/images/posts/raspbian64-bit.jpg">
</p>

## STEP 2: Installing Anaconda on AArch64
Unfortunatelly, Anaconda hasn’t delivered yet a Linux AArch64 build to install on ARMv8 systems but a few people at <a href="https://conda-forge.org/#about" target="_blank">conda-forge</a> already worked on this and delivered the <a href="https://anaconda.org/archiarm/" target="_blank">archiarm channel</a> and the <a href="https://github.com/Archiconda/build-tools" target="_blank">Archiconda3 repository</a>, which holds the equivalent Anaconda distribution for AArch64.   
**Archiconda3** does not include all the packages Anacoda does, but at least includes conda (the package manager) and its dependencies, plus some packages (it could be seen as something similar to Miniconda). Any missing prebuilt package for AArch64 can be installed from the different Anaconda Cloud channels, simply go to <a href="https://anaconda.org/" target="_blank">https://anaconda.org/</a> and search for the package you need.
For example, as you can see in the screenshot below, the scipy library package for aarch64 is available at several channels, being the conda-forge channel the one with most hosts and with the latest release:
<p align="center">
  <img width="640" height="363" src="/images/posts/Anaconda2.jpg">
</p>

If you click on the channel link you’ll get the package details and the command to install it using conda, which typically is
```pascal
conda install -c conda-forge scipy
```
The advantage of using Conda to install the packages is that those packages are binaries so there is no need to compile them (and have the required compiler and libraries for it).
Another advantage of Conda is the ability to create isolated environments that can contain different versions of Python and/or the packages installed in them. This can be extremely useful when working with data science tools as different tools may contain conflicting requirements which could prevent them all being installed into a single environment. 
Nevertheless, as mentioned before, it may happen that the Python package we are looking for is not available as a conda package for aarch64 and it is only available on PyPI. It also can happen that there is an available conda package, but its version is older than the one provided by PyPI, and we want to test the latest one. For such cases we can combine both Conda with PIP methods and install the package with pip, which will download the source and then build the corresponding wheel.
It is also possible to revert from a pip-installed package with `pip uninstall <package>` and then install the conda package.

To download the latest Archiconda distribution do:
```pascal
# wget https://github.com/Archiconda/build-tools/releases/download/0.2.3/Archiconda3-0.2.3-Linux-aarch64.sh 
```
To install the Archiconda distribution so all the users in the system can use it follow this:
```pascal
# bash ./Archiconda3-0.2.3-Linux-aarch64.sh
```
![Archiconda install output](/images/posts/Archiconda_install.jpg)   

Since we will be installing some packages with `PIP` later, we will have to install the development tools (compiler and libraries) to build the wheels first. To do so just run:
```pascal
# apt-get update
# apt-get install build-essential
# apt-get install libffi-dev python-dev libopencv-dev python3-opencv
# apt-get install libatlas-base-dev
```
## STEP 3: Installing data science libraries 
Let’s install the basic stuff first using Conda:
```pascal
# conda install pandas matplotlib nltk scipy
# conda install scikit-learn ipython protobuf jupyterlab
```
Let’s install the Pandas and NumPy libraries using PiP:
```pascal
# pip install --upgrade pip setuptools
# pip install scikit-image
# pip install seaborn
```
NOTE: building the scikit-image wheel will take long....

## STEP 4: Installing TensorFlow and Keras
As of today, there is no official linux aarch64 python wheel for TensorFlow (check out <a href="https://www.tensorflow.org/install/pip?lang=python3#package-location" target="_blank">here</a>). So you have two options: build it on your own or install a prebuilt one. For the lazy onces you can follow the steps from here: <a href="https://github.com/PINTO0309/Tensorflow-bin" target="_blank">https://github.com/PINTO0309/Tensorflow-bin</a> which basically means:
```pascal
# apt-get install -y libhdf5-dev libc-ares-dev libeigen3-dev
# pip install keras_applications==1.0.8 --no-deps
# pip install keras_preprocessing==1.1.0 --no-deps
# pip install h5py==2.9.0
# apt-get install -y openmpi-bin libopenmpi-dev
# apt-get install -y libatlas-base-dev
# pip install -U --user six wheel mock
# pip uninstall tensorflow
# wget https://github.com/PINTO0309/Tensorflow-bin/raw/master/tensorflow-1.15.0-cp37-cp37m-linux_aarch64.whl
# pip install tensorflow-1.15.0-cp37-cp37m-linux_aarch64.whl
```
Finally, we install Keras an some other libraries to visualize Keras models graphically:
```pascal
# pip install keras pydot
# conda install python-graphviz
```
Let’s check our framework’s versions:
```pascal
raul@rpi4-nodo01:~$ python
 Python 3.7.1 | packaged by conda-forge | (default, Feb 18 2019, 01:34:39)
 [GCC 7.3.0] :: Anaconda, Inc. on linux
 Type "help", "copyright", "credits" or "license" for more information.
 >>> import numpy; numpy.__version__
 '1.17.3'
 >>> import tensorflow; tensorflow.__version__
 '1.15.0'
 >>> import keras; keras.__version__
 Using TensorFlow backend.
 '2.3.1'
 >>> keras.backend.floatx()
 'float32'
```

## STEP 5: The final test
Before starting the Jupyter Notebook server to run some stuff I’ll set it up to listen to the IP of the active network interface in the Raspberry Pi4. I first need to generate a standard configuration file with:
```pascal
$ jupyter notebook --generate-config --allow-root
```
and then edit the `.jupyter/jupyter_notebook_config.py` file to add the following line:
```programming
c.NotebookApp.ip = '192.168.137.10'
```

Now I can start the Notebook server with
```pascal
$ jupyter notebook &
```
![Archiconda install output](/images/posts/jupyter_start.jpg)  
You can download <a href="https://github.com/raul-pingarron/IA/blob/master/Keras-TensorFlow_example.ipynb" target="_blank">here</a> a sample Notebook I have created that shows how to build a Classifier for the IRIS dataset using a Neural Network with Keras and TensorFlow as the back-end.   

![Archiconda install output](/images/posts/Jupyter_NB.jpg) 

