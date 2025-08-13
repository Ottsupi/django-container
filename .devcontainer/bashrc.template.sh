# https://gist.github.com/KaMeHb-UA/7b12035f29dad630f13a63a3dd72d183
# credits to https://github.com/KaMeHb-UA

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# persistent bash history
HISTFILE=~/.bash_history
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# Using color promt
if [[ ${EUID} == 0 ]] ; then
    PS1='\[\033[48;2;221;75;57;38;2;255;255;255m\] \$ \[\033[48;2;0;135;175;38;2;221;75;57m\]\[\033[48;2;0;135;175;38;2;255;255;255m\] \h \[\033[48;2;83;85;85;38;2;0;135;175m\]\[\033[48;2;83;85;85;38;2;255;255;255m\] \w \[\033[49;38;2;83;85;85m\]\[\033[00m\] '
else
    PS1='\[\033[48;2;105;121;16;38;2;255;255;255m\] \$ \[\033[48;2;0;135;175;38;2;105;121;16m\]\[\033[48;2;0;135;175;38;2;255;255;255m\] \u@\h \[\033[48;2;83;85;85;38;2;0;135;175m\]\[\033[48;2;83;85;85;38;2;255;255;255m\] \w \[\033[49;38;2;83;85;85m\]\[\033[00m\] '
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'


# Define a list of items
my_messages=(
    "Happy coding!"
    "You got this!"
    "One line at a time."
    "Enjoy the challenge."
    "Embrace the struggle."
    "Progress, not perfection."
    "Remember why you started."
    "Make something amazing today."
    "Every bug is a chance to learn something new."
    "Every problem has a solution. It's no problem otherwise."
    "You're not just writing code; you're building the future."
    "Breathe. The bug will still be there after you take a break."
    "The journey of a thousand lines begins with a single commit."
    "The code you write today will simplify tomorrow. Keep building."
    "The biggest breakthroughs often follow the toughest bugs. Keep going."
    "Celebrate your small victories. Every single commit brings you closer to your goal."
)
random_index=$(( RANDOM % ${#my_messages[@]} ))     # Select a random index
random_message=${my_messages[$random_index]}        # Get the random item
echo "π $random_message"


# start ssh-agent
# run ssh-agent if it's not running and do nothing otherwise
# https://stackoverflow.com/a/48509425
if [ $(ps ax | grep [s]sh-agent | wc -l) -gt 0 ] ; then
    echo "✓ ssh"
else
    eval $(ssh-agent -s)
    # add your key here
    # if [ "$(ssh-add -l)" == "The agent has no identities." ] ; then
        # ssh-add ~/.ssh/id_rsa
        # echo "Identity added"
    # fi

    # Don't leave extra agents around: kill it on exit. You may not want this part.
    # trap "ssh-agent -k" exit
fi

echo ""