po4a = find_program('po4a', required : false)

if not po4a.found()
  subdir_done()
endif

custom_target('translate',
  build_by_default : true,
  command : ['translate.sh',
    '--srcdir', meson.current_source_dir(),
    '--destdir', meson.current_build_dir() / 'translations',
    '--asciidoctor-load-path', meson.project_source_root() / 'tools',
    '--docdir', docdir,
    '--po4acfg', meson.current_source_dir() / 'po4a.cfg',
    '--util-linux-version', meson.project_version(),
  ],
  depend_files : ['po4a.cfg'] + man_common_adocs,
  # + manadocs
  output : ['translations'])

manpages = []
foreach adoc : manadocs
  manpages += fs.stem(adoc)
endforeach

meson.add_install_script('install-translations.sh',
  '--mandir', get_option('mandir'),
  '--mansrcdir', meson.current_build_dir() / 'translations/man',
  manpages)
