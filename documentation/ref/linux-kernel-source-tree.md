## Linux - Kernel Source Tree
### Introduction
The source-tree is a directory which contains all of the kernel source. You could build a new kernel, install that, and reboot your machine to use the rebuilt kernel. Other than for learning, people rebuild the kernel to select less-used options, or to add device drivers which are normally not bundled with Linux.

Traditionally **the kernel source** locates at `/usr/src/linux` with a set of subdirectories (`arch`,`block`,`crypto`,...). This path is also often just a symbolic link to a directory. e.g. 
```
$ ls -l /usr/src/linux
lrwxrwxrwx 1 root root 18 Dec  7 17:03 /usr/src/linux -> linux-3.1.4-gentoo
```

**Installed kernel binaries** are usually installed in the `/boot` directory, along with bootloader binaries and configuration files. (This is sometimes an independent filesystem, not mounted by default.) The exact name of the files depends on the kernel and distribution. (So does the bootloader.)

**Installed kernel modules** reside in sub-directories of:
```/lib/modules/`uname -r`/```

### Downloading Source Packages
You may not find the source packages in Ubuntu, but would have to download the source tar-file, e.g., from kernel.org. Ubuntu uses Debian packages for many things, and the latter's website makes it easier to find the packages.

    http://packages.ubuntu.com/
    https://www.debian.org/distrib/packages

Those consist (in either case) of a "pristine" tar-file (from "upstream") and a "debian" add-on (scripts and packages). You can download both of those from Debian. If you are looking for the source for the kernel package which you have installed, you would download both parts.

You can also install the "linux-source" package: Debian and Ubuntu provide a few source-packages, this is one of the few (a quick check finds only a couple of dozen packages with "-source" in their names, compared to tens of thousands of other packages). The source-package is preferred, since there are many fixes (and customizations) needed, and the source-package has those patches incorporated into the tree.

### Header Packages\
Linux kernel source tree is rather large, and completely unnecessary if you don't intend to compile the kernel yourself. The header packages are built and shipped by distributions to provide just the right things necessary to build modules(e.g. a special driver), but no more. (They certainly do not contain the compiled kernel.) The whole point of having this type of package is to save space (and bandwidth).

Distribution `kernel-header` packages contain, as their name implies, only kernel header files (plus the necessary plumbing) that are required to build software like kernel modules. `Header packages` only contain the header part of the above (and not all of that - only the "exported" headers), and some of the build infrastructure. Header packages do not contain C source code. (except for some stubs and build infrastructure code)

Header packages don't relocate anywhere. They are built for specific versions of the kernel, packaged in a specific directory, and that's that. It's just a set of files. Note that the header packages don't necessarily have the same version as the current stable kernel binary packages - the header packages are generic, and can lag behind the actual kernel you're running. They should not, however, be from a kernel version that is more recent than the current installed (or target) kernel.

### Reference: 
- [What is a kernel-source-tree?](https://unix.stackexchange.com/questions/267835/what-is-a-kernel-source-tree)
- [What does a kernel source tree contain? Is this related to Linux kernel headers?](https://unix.stackexchange.com/questions/27042/what-does-a-kernel-source-tree-contain-is-this-related-to-linux-kernel-headers)
- [Ubuntu Wiki:  Kernel/Compile](https://help.ubuntu.com/community/Kernel/Compile)
- [Debian Wiki: SourcePackage](https://wiki.debian.org/Packaging/SourcePackage)
- [Kernel.org git repositories : kernel/git/stable/linux.git](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/)
- [Packaging SourcePackage](https://wiki.debian.org/Packaging/SourcePackage)