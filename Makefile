## Copyright 2010 Benoît Chesneau
## 
## Licensed under the Apache License, Version 2.0 (the "License"); you may not
## use this file except in compliance with the License. You may obtain a copy of
## the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
## WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
## License for the specific language governing permissions and limitations under
## the License.

DESTDIR?=
DISTDIR=       rel/archive

all: deps compile

compile:
	@./rebar compile

gitorious-all: gitorious-deps compile

gitorious-deps:
	./rebar -C gitorious.rebar.config get-deps

deps:
	./rebar get-deps

clean:
	@./rebar clean

%.beam: %.erl
	@erlc -o deps/couch/test/etap/ $<
 
check: deps/couch/test/etap/etap.beam deps/couch/test/etap/test_util.beam deps/couch/test/etap/test_web.beam
	@ERL_FLAGS="-pa `pwd`/deps/couch/ebin `pwd`/deps/couch/test/etap" \
		prove -v deps/couch/test/etap/*.t

dist: compile
	@rm -rf rel/rcouch
	@./rebar generate

distclean: clean
	@rm -rf rel/rcouch
	@rm -rf rel/dev*
	@rm -f rel/couchdb.config
	@rm -rf deps
	@rm -rf rel/tmpdata
	@rm -rf install.mk


include install.mk
install: dist
	@echo "==> install to $(DESTDIR)$(PREFIX)"
	@mkdir -p $(DESTDIR)$(PREFIX)
	@for D in bin erts-* lib	releases share var; do\
		cp -R rel/rcouch/$$F $(DESTDIR)$(PREFIX) ; \
	done
	@mkdir -p $(DESTDIR)$(SYSCONF_DIR)/rcouch
	@cp -R rel/rcouch/etc/*  $(DESTDIR)$(SYSCONF_DIR)/rcouch/
	@mkdir -p $(DESTDIR)$(DATADIR)
	@chown $(RCOUCH_USER) $(DESTDIR)$(DATADIR)
	@mkdir -p $(DESTDIR)$(VIEWDIR)
	@chown $(RCOUCH_USER) $(DESTDIR)$(VIEWDIR)
	@touch $(DESTDIR)$(PREFIX)/var/log/rcouch.log
	@chown $(RCOUCH_USER) $(DESTDIR)$(PREFIX)/var/log/rcouch.log

deps-snapshot: clean
	@rm -rf rcouch-deps-$(OS)-$(ARCH).tar.gz
	(cd deps && \
		tar cvzf ../rcouch-deps-$(VERSION)-$(OS)-$(ARCH).tar.gz .)

archive: dist
	@rm -rf $(DISTDIR)
	@rm -f rcouch-$(VERSION)-$(OS)-$(ARCH).tar.gz
	@mkdir -p $(DISTDIR)/$(PREFIX)
	@cp -R rel/rcouch/* $(DISTDIR)/$(PREFIX)
	@mkdir -p $(DISTDIR)/$(DATADIR)
	@mkdir -p $(DISTDIR)/$(VIEWDIR)
	@touch $(DISTDIR)/$(PREFIX)/var/log/rcouch.log
	@for F in LICENSE NOTICE README ; do \
		cp -f $$F $(DISTDIR)/$(PREFIX) ; \
	done
	(cd $(DISTDIR) && \
		tar -cvzf ../rcouch-$(VERSION)-$(OS)-$(ARCH).tar.gz .)

dev: all
	@rm -rf rel/tmpdata
	@rm -rf rel/dev
	@echo "==> Building development node (ports 15984/15986)"
	@./rebar generate target_dir=dev overlay_vars=dev.config
	@echo "\n\
Development node is built, and can be started using ./rel/dev/bin/rcouch.\n" 
