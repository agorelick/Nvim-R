function JobStdin(ch, cmd)
    call ch_sendraw(a:ch, a:cmd)
endfunction

function StartJob(cmd, opt)
    let jobid = job_start(a:cmd, a:opt)
    return job_getchannel(jobid)
endfunction

function GetJobTitle(job_id)
    for key in keys(g:rplugin_jobs)
        if g:rplugin_jobs[key] == a:job_id
            return key
        endif
    endfor
    return "Job"
endfunction

function ROnJobStdout(job_id, msg)
    let cmd = substitute(a:msg, '\n', '', 'g')
    let cmd = substitute(cmd, '\r', '', 'g')
    if cmd =~ "^call " || cmd  =~ "^let " || cmd =~ "^unlet "
        exe cmd
    else
        call RWarningMsg("[" . GetJobTitle(a:job_id) . "] Unknown command: " . cmd)
    endif
endfunction

function ROnJobStderr(job_id, msg)
    let msg = substitute(a:msg, '\n', '', 'g')
    if msg != "DETACH"
        call RWarningMsg("[" . GetJobTitle(a:job_id) . "] " . msg)
    endif
endfunction

function ROnJobExit(job_id)
    let key = GetJobTitle(a:job_id)
    if key != "Job"
        let g:rplugin_jobs[key] = "no"
    endif
endfunction

function IsJobRunning(key)
    try
        let chstt =  ch_status(g:rplugin_jobs[a:key])
    catch
        let chstt = "no"
    endtry
    if chstt == "open"
        return 1
    else
        return 0
    endif
endfunction

let g:rplugin_jobs = {"ClientServer": "no", "R": "no", "Terminal emulator": "no"}
let g:rplugin_job_handlers = {
            \ 'out_cb':   function('ROnJobStdout'),
            \ 'err_cb':   function('ROnJobStderr'),
            \ 'close_cb': function('ROnJobExit')}


" Check if Vim-R-plugin is installed
let s:ff = globpath(&rtp, "r-plugin/functions.vim")
let s:ft = globpath(&rtp, "ftplugin/r*_rplugin.vim")
if s:ff != "" || s:ft != ""
    let s:ff = substitute(s:ff, "functions.vim", "", "g")
    call RWarningMsgInp("Nvim-R conflicts with Vim-R-plugin. Please, uninstall Vim-R-plugin.\n" .
                \ "At least the following directories and files are from a Vim-R-plugin installation:\n" . s:ff . "\n" . s:ft . "\n")
endif
unlet s:ff
unlet s:ft
