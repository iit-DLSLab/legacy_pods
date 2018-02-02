default_target: all

# get a list of subdirs to build by reading tobuild.txt
SUBDIRS:=$(shell grep -v "^\#" tobuild.txt)

# Figure out where to build the software.
#   Use BUILD_PREFIX if it was passed in.
#   If not, search up to three parent directories for a 'build' directory.
#   Otherwise, use ./build.
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX=$(shell for pfx in ./ .. ../.. ../../..; do d=`pwd`/$$pfx/build; \
               if [ -d $$d ]; then echo $$d; exit 0; fi; done; echo `pwd`/build)
endif

# Define here the debian package version
PACKAGE_VERSION=1.0.0

# build quietly by default.  For a verbose build, run "make VERBOSE=1"
$(VERBOSE).SILENT:

all: 
	@[ -d $(BUILD_PREFIX) ] || mkdir -p $(BUILD_PREFIX) || exit 1
	@for subdir in $(SUBDIRS); do \
		echo "\n-------------------------------------------"; \
		echo "-- $$subdir"; \
		echo "-------------------------------------------"; \
		$(MAKE) -C $$subdir all || exit 2; \
	done
	@# Place additional commands here if you have any

package: all
	mkdir --parents ./builddeb/usr/local
	# Adjust package config paths
	sed -i '/\(.*[^_]\|^\)prefix=/s/.*/prefix=\/usr\/local/' ./build/lib/pkgconfig/*.pc
	cp -r ./build/* ./builddeb/usr/local
	cp -r ./DEBIAN ./builddeb/
	dpkg-deb --build builddeb
	mv builddeb.deb legacy-pods_$(PACKAGE_VERSION).deb
	rm -rf ./builddeb

clean:
	@for subdir in $(SUBDIRS); do \
		echo "\n-------------------------------------------"; \
		echo "-- $$subdir"; \
		echo "-------------------------------------------"; \
		$(MAKE) -C $$subdir clean; \
	done
	rm -rf build *.deb
	@# Place additional commands here if you have any
