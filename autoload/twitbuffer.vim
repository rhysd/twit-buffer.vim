" tweet asynchronously
function! s:update_status() "{{{
    if ! has('ruby')
        echoerr 'Ruby interface is disabled.'
        return
    endif
    if ! filereadable(expand('~/.credential.yml'))
        echoerr "There are no keys to authenticate: ~/.credential.yml"
        return
    endif

    ruby << EOF
    buffer = VIM::Buffer::current

    Process.fork do
        require 'rubygems' if RUBY_VERSION < '1.9'
        require 'twitter'
        require 'yaml'
        has_terminal_notifier = true
        begin
            require 'terminal-notifier'
        rescue LoadError
            has_terminal_notifier = false
        end

        lines = []
        (1..buffer.length).each do |lnum|
            lines << buffer[lnum]
        end
        text = lines.join("\n")
        # hooter = VIM::evaluate "exists('g:tweet_hooter') ? g:tweet_hooter : ''"
        # text += hooter unless hooter.empty?

        begin
            yaml = YAML.load(File.open(File.expand_path('~/.credential.yml')).read)
            Twitter::configure do |config|
                config.consumer_key = yaml['consumer_key']
                config.consumer_secret = yaml['consumer_secret']
                config.oauth_token = yaml['oauth_token']
                config.oauth_token_secret = yaml['oauth_token_secret']
            end
            Twitter::update text
            if has_terminal_notifier
                TerminalNotifier::notify(text, :title => 'from vim')
            else
                puts "success in tweet"
            end
        rescue => e
            if has_terminal_notifier
                TerminalNotifier::notify(e.to_s, :title => 'fail to tweet')
            else
                VIM::command <<-CMD.gsub(/^\s+/,'').gsub("\n", " | ")
                    echohl Error
                    echomsg 'fail to tweet!'
                    echomsg '#{e.to_s}'
                    echohl None
                CMD
            end
        end
    end
EOF

    if bufwinnr('tweet') == winnr()
        bd!
    endif
endfunction
"}}}

function! twitbuffer#tweet() "{{{
    let bufnr = bufwinnr('__tweet')
    if bufnr > 0
        execute bufnr.'wincmd w'
    else
        botright split __tweet
        resize 6
        setlocal bufhidden=wipe nobuflisted noswapfile modifiable
        setlocal statusline=Tweet\ Buffer
        execute 0
        nnoremap <silent><buffer><CR>  :<C-u>call <SID>update_status()<CR>
        inoremap <silent><buffer><C-q> <Esc>:<C-u>call <SID>update_status()<CR>
        nnoremap <silent><buffer>q     :<C-u>bd!<CR>
        inoremap <silent><buffer><C-g> <Esc>:<C-u>bd!<CR>
        if !exists('b:tweet_already_bufwrite_cmd')
            autocmd BufWriteCmd <buffer> echohl Error | echo 'type <CR> to tweet' | echohl None
            let b:tweet_already_bufwrite_cmd = 1
        endif
        set ft=tweet
    endif
    startinsert!
endfunction
"}}}
