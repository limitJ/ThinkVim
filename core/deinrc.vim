" dein configurations.
let g:dein#install_max_processes = 16
let g:dein#install_progress_type = 'echo'
let g:dein#enable_notification = 1
let g:dein#install_progress_type = 'title'
let g:dein#install_log_filename = '~/.tmp/dein.log'
let g:dein#auto_recache = 1


let $CACHE = expand('~/.cache')
let s:path = expand('$CACHE/dein')
let s:plugins_path = expand('$VIMPATH/core/dein/plugins.yaml')
let s:user_plugins_path = expand('$VIMPATH/core/local/local_plugins.yaml')

function! s:dein_check_ruby() abort
	call system("ruby -e 'require \"json\"; require \"yaml\"'")
	return (v:shell_error == 0) ? 1 : 0
endfunction

function! s:dein_check_yaml2json()
	try
		let result = system('yaml2json', "---\ntest: 1")
		if v:shell_error != 0
			return 0
		endif
		let result = json_decode(result)
		return result.test
	catch
	endtry
	return 0
endfunction

function! s:dein_load_yaml(filename) abort
	if executable('yaml2json') && exists('*json_decode') &&
				\ s:dein_check_yaml2json()
		" Decode YAML using the CLI tool yaml2json
		" See: https://github.com/koraa/large-yaml2json-json2yaml
		let g:denite_plugins = json_decode(
					\ system('yaml2json', readfile(a:filename)))
	elseif executable('ruby') && exists('*json_decode') && s:dein_check_ruby()
		let g:denite_plugins = json_decode(
					\ system("ruby -e 'require \"json\"; require \"yaml\"; ".
									\ "print JSON.generate YAML.load \$stdin.read'",
									\ readfile(a:filename)))
	else
		" Fallback to use python3 and PyYAML
	python3 << endpython
import vim, yaml
with open(vim.eval('a:filename'), 'r') as f:
	vim.vars['denite_plugins'] = yaml.safe_load(f.read())
endpython
	endif

	for plugin in g:denite_plugins
		call dein#add(plugin['repo'], extend(plugin, {}, 'keep'))
	endfor
	unlet g:denite_plugins
endfunction


function! s:check_file_notnull(filename)abort
       let  content = readfile(a:filename)
       if empty(content)
           return 0
       endif
       return 1
endfunction


if dein#load_state(s:path)
     call dein#begin(s:path, [expand('<sfile>'), s:plugins_path])
       try
            call s:dein_load_yaml(s:plugins_path)
                if filereadable(s:user_plugins_path)
		            if s:check_file_notnull(s:user_plugins_path)
	                  call s:dein_load_yaml(s:user_plugins_path)
	                endif
	            endif
        catch /.*/
            echoerr v:exception
            echomsg 'Error loading config/plugins.yaml...'
            echomsg 'Caught: ' v:exception
            echoerr 'Please run: pip3 install --user PyYAML'
        endtry
    call dein#end()
    call dein#save_state()
    if dein#check_install()
         " Installation check.
       call dein#install()
    endif
endif

let s:plugin_setting_dirname = expand('$VIMPATH/core/plugins/')

function! s:edit_plugin_setting(plugin_name)
  if !isdirectory(s:plugin_setting_dirname)
    call mkdir(s:plugin_setting_dirname)
  endif
  execute 'edit' s:plugin_setting_dirname . '/' . a:plugin_name . '.vim'
endfunction

command! -nargs=1
  \ EditPluginSetting
  \ call s:edit_plugin_setting(<q-args>)

