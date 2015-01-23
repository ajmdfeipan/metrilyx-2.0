
SHELL = /bin/bash

USER = metrilyx
METRILYX_HOME = /opt/metrilyx
METRILYX_CONF = $(METRILYX_HOME)/etc/metrilyx/metrilyx.conf
DEFAULT_DB = $(METRILYX_HOME)/data/metrilyx.sqlite3

INSTALL_DIR = $(shell pwd)/build/metrilyx


build:
	python setup.py install --root $(INSTALL_DIR)

deps:
	which pip || easy_install pip
	[ -e "$(INSTALL_DIR)$(METRILYX_HOME)" ] || mkdir -p "$(INSTALL_DIR)$(METRILYX_HOME)"
	pip install --root $(INSTALL_DIR)$(METRILYX_HOME) -e .
	find $(INSTALL_DIR)$(METRILYX_HOME) -name 'zope' -type d -exec touch '{}'/__init__.py \;

install:
	cd build && tar -czvf metrilyx.tgz metrilyx ; cd -
	rsync -vaHP $(INSTALL_DIR)/ /

post_install:
	( id $(USER) > /dev/null 2>&1 ) || ( useradd $(USER) > /dev/null 2>&1 )
	chown -R $(USER) $(METRILYX_HOME)
	
	find $(METRILYX_HOME)/usr -type d -name 'site-packages' -exec echo export PYTHONPATH='{}':\$$PYTHONPATH >> ~$(USER)/.bashrc \;

.clean:
	rm -rf /tmp/pip_build_root
	rm -rf /tmp/pip-*
	rm -rf ./build ./dist 
	rm -rf ./numpy-1*
	rm -rf ./Twisted-14*
	rm -rf ./six-1*
	rm -rf ./node_modules
	rm -rf ./metrilyx.egg-info
	find . -name '*.py[c|o]' -exec rm -rvf '{}' \;
#
# Test dataserver and modelmanager after they have been started.
#
.test:
	python -m unittest tests.dataserver
	python -m unittest tests.modelmanager

# Copies sample configs if no configs exist
.config:
	[ -f $(METRILYX_CONF) ] || cp $(METRILYX_CONF).sample $(METRILYX_CONF)
	[ -f $(DEFAULT_DB) ] || cp $(DEFAULT_DB).default $(DEFAULT_DB)

.start:
	/etc/init.d/metrilyx start
	/etc/init.d/nginx restart
