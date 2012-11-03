## Twit Buffer

This is a Vim plugin to tweet, not to view a timeline.
If you do so, using TweetVim is recommended.
I create this plugin to learn how to use Vim's Ruby interface.
If you use `Tweet` command, a mini-buffer pops up and you can write something to it.
And Enter key updates the buffer's content as a tweet.

### Requirements

- Vim must be compiled with --with-rubyinterp option. (You can check using `:echo has('ruby')`.)
- This plugin uses twitter gem. Use `gem install twitter`.
