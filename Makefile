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
	# Adjust binaries paths
	find ./build/bin -type f -print|xargs file|grep ASCII|cut -d: -f1|xargs sed -i 's|export PYTHONPATH=.*|export PYTHONPATH=/usr/local/lib/python2.7/dist-packages:/usr/local/lib/python2.7/site-packages:${PYTHONPATH}|g'
	find ./build/bin -type f -print|xargs file|grep ASCII|cut -d: -f1|xargs sed -i 's|CLASSPATH=`.*|CLASSPATH=`PKG_CONFIG_PATH=PKG_CONFIG_PATH:/usr/local/lib/pkgconfig pkg-config --variable=classpath lcm-java`|g'
	find ./build/bin -type f -print|xargs file|grep ASCII|cut -d: -f1|xargs sed -i 's|for d in.*|for d in . .. "/usr/local"; do|g'
	# Adjust python paths
	sed -i 's|BUILD_PREFIX=.*|BUILD_PREFIX=\x27/usr/local/\x27|g' ./build/lib/python2.7/dist-packages/bot_procman/*.py
	sed -i 's|getBase.*|getBasePath(): return \x27/usr/local\x27|g' ./build/lib/python2.7/dist-packages/path_util/*.py
	sed -i 's|getData.*|getDataPath(): return \x27/usr/local/data\x27|g' ./build/lib/python2.7/dist-packages/path_util/*.py
	sed -i 's|getConfig.*|getConfigPath(): return \x27/usr/local/config\x27|g' ./build/lib/python2.7/dist-packages/path_util/*.py
	sed -i 's|getModels.*|getModelsPath(): return \x27/usr/local/models\x27|g' ./build/lib/python2.7/dist-packages/path_util/*.py
	cp -r ./build/* ./builddeb/usr/local
	cp -r ./DEBIAN ./builddeb/
	cp -r ./common_utils/eigen-utils/matlab/*.m ./builddeb/usr/local/matlab
	# Adjust matlab paths
	sed -i 's|path = \x27.*|path = \x27/usr/local/matlab\x27;|g' ./builddeb/usr/local/matlab/*.m
	dpkg-deb --build builddeb
	mv builddeb.deb legacy-pods_$(PACKAGE_VERSION).deb
	rm -rf ./builddeb

install: package
	sudo dpkg -i legacy-pods_$(PACKAGE_VERSION).deb

clean:
	@for subdir in $(SUBDIRS); do \
		echo "\n-------------------------------------------"; \
		echo "-- $$subdir"; \
		echo "-------------------------------------------"; \
		$(MAKE) -C $$subdir clean; \
	done
	rm -rf build *.deb
	@# Place additional commands here if you have any
