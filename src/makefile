SHELL=/bin/bash
CFLAGS=--std=c99

prefix=/usr
bindir=$(prefix)/bin
sharedir=$(prefix)/share
localedir=$(sharedir)/locale
launcherdir=$(sharedir)/applications
mandir=$(sharedir)/man
man1dir=$(mandir)/man1

app_name=aptik-gtk
app_fullname='Aptik GTK'

# vte -----------------------------

vte_symbol = -D VTE_291
vte_version=$(shell { (pkg-config --modversion vte-2.91 | cut -d. -f 2); } )
vala_version=$(shell { (valac --version | cut -d. -f 2); } )
dist_id=$(shell { (lsb_release -i -s); } )
dist_codename=$(shell { (lsb_release -c -s); } )

ifeq ($(shell { test ${vte_version} -lt 52 ; echo $$? ; } ), 0)
vte_symbol=$(shell echo '-D VTE_291_OLD')
#else ifeq "${dist_codename}" "bionic"
#vte_symbol=$(shell echo '-D VTE_291_OLD')
#else ifeq "${dist_codename}" "xenial"
#vte_symbol=$(shell echo '-D VTE_291_OLD')
else
vte_symbol=$(shell echo '-D VTE_291_OLD')
endif

# symbols --------------------------

symbols=$(shell echo "${vte_symbol}")

all:
	# aptik-gtk
	valac -X -D'GETTEXT_PACKAGE="${app_name}"' --Xcc="-lm" ${symbols} --Xcc="-O3" \
		*.vala Gtk/*.vala Utility/Console/*.vala Utility/Gtk/*.vala Utility/*.vala \
		-o ${app_name} \
		--pkg glib-2.0 \
		--pkg gio-unix-2.0 \
		--pkg posix \
		--pkg gee-0.8 \
		--pkg json-glib-1.0 \
		--pkg vte-2.91 \
		--pkg gtk+-3.0

clean:
	rm -rfv ../release/{source,i386,amd64,armel,armhf}
	rm -rfv ../release/*.{run,deb}
	rm -rfv *.c *.o *.mo
	rm -fv ${app_name}

install:
	
	#dirs
	mkdir -p "$(DESTDIR)$(bindir)"
	mkdir -p "$(DESTDIR)$(sharedir)"
	mkdir -p "$(DESTDIR)$(mandir)"
	mkdir -p "$(DESTDIR)$(man1dir)"
	mkdir -p "$(DESTDIR)$(launcherdir)"
	mkdir -p "$(DESTDIR)$(sharedir)/${app_name}"
	mkdir -p "$(DESTDIR)$(sharedir)/pixmaps"
	
	#binary
	install -m 0755 ${app_name} "$(DESTDIR)$(bindir)"
	
	#shared files
	cp -dpr --no-preserve=ownership -t "$(DESTDIR)$(sharedir)/${app_name}" ./share/${app_name}/*
	chmod --recursive 0755 $(DESTDIR)$(sharedir)/${app_name}/*

	#launcher
	install -m 0755 ${app_name}.desktop "$(DESTDIR)$(launcherdir)"
	
	#app icon
	install -m 0755 ./share/pixmaps/${app_name}.svg "$(DESTDIR)$(sharedir)/pixmaps/"

uninstall:

	#binary
	rm -f "$(DESTDIR)$(bindir)/${app_name}"
	rm -f "$(DESTDIR)$(bindir)/${app_name}-gtk"
	rm -f "$(DESTDIR)$(bindir)/${app_name}-uninstall"
	rm -f "$(DESTDIR)$(bindir)/${app_name}-launcher"

	#shared files
	rm -rf "$(DESTDIR)$(sharedir)/${app_name}"

	#launcher
	rm -f "$(DESTDIR)$(launcherdir)/${app_name}.desktop"

	#app icon
	rm -f "$(DESTDIR)$(sharedir)/pixmaps/${app_name}.svg"

	#translations
	rm -f $(DESTDIR)$(localedir)/*/LC_MESSAGES/${app_name}.mo
