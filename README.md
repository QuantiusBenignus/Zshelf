[Zshelf](https://github.com/quantiusbenignus/zshelf) is a Zsh-centric command-line interface for interacting with local Large Language Models (LLMs) using [llama.cpp](https://github.com/ggml-org/llama.cpp). It supports context persistence, model switching, and advanced prompt workflows, ingesting from the command line, files and mouse-selected text in any window. 

Unique to this setup is the ability to have an itermittent one-shot conversations outside the isolated bubble of the lamma.cpp conversation mode. This is powerful because one can use the shell while interacting (and affect the interaction itself) with the local LLM. All the flexibility, power and programming logic of the zsh shell is thus available in this one-shot conversation mode. For example, one can loop through all locall LLM files with the same prompt and collect the results for comparison:

```
# Define the prompt to be used for each model
prompt="Explain the concept of quantum computing."

# Loop through each model defined in llmodels
for model in "${(k)llmodels}"; do
    echo "Running model: $model"
    qlm "$model" "$prompt"
    echo "----------------------------------------"
done
```


## Table of Contents

- [Installation & Setup](#installation--setup)
- [Usage](#usage)
  - [Core Command: `qlm`](#core-command-qlm)
  - [Dedicated Model Commands](#dedicated-model-commands)
  - [Context Building with `promf`](#context-building-with-promf)
  - [Conversation Continuation](#conversation-continuation)
- [Configuration](#configuration)
- [Features](#features)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Installation & Setup

### Requirements:
- Zsh (configured with `compinit`)
- [llama.cpp](https://github.com/ggml-org/llama.cpp) (`llam`/`llama-cli` in PATH)
- `xsel` (or `wl-copy` on Wayland) for clipboard access (`sudo apt install xsel` on Linux)

### Steps:

1. **Place files in Zsh function path**:
    ```bash
	  git clone https://github.com/QuantiusBenignus/Zshelf.git
    mkdir -p ~/.zfunc
	  cd zshelf  
    cp * ~/.zfunc/
    ```

2. **Configure `.zshrc`**:
    ```zsh
    # Autoload functions and completion
    #fpath=($ZDOTDIR/.zfunc $fpath)
    fpath=(~/.zfunc $fpath)
    autoload -Uz qlm _qlm reqlm qwec qwen gem gem2 deeq mist 

    # Enables model name completion
    # Create temp files (already set in code but can be adjusted)
    export TPROMPTF='/dev/shm/promf'
    export LLMDIR='/location/of/LLMfiles'

    #This comes after compinit:
    compdef _qlm qlm
    ```
    IMPORTANT: Please, reuse/check the supplied `.zshrc` for extra aliases, functions, and configuration related to this tool set.
All the response aliases/functions are defined in the sample .zshrc file:

```
LLM response aliases (anon. functions) to provide one-shot conversations with the corresponding models.
#LLM inference functions gem, gem2, qwen, qwec, mist and deeq are defined in .zfunc, for autoloading:
alias reqwen='() {[[ -f /dev/shm/reqwen ]] && qwen "$(cat /dev/shm/reqwen)\n$1" || print "No previous qwen calls found!" ; }'
alias reqwec='() {[[ -f /dev/shm/reqwec ]] && qwec "$(cat /dev/shm/reqwec)\n$1" || print "No previous qwec calls found!" ; }'
alias remist='() {[[ -f /dev/shm/remist ]] && mist "$(cat /dev/shm/remist)\n$1" || print "No previous mist calls found!" ; }'
alias redeeq='() {[[ -f /dev/shm/redeeq ]] && deeq "$(cat /dev/shm/redeeq)\n$1" || print "No previous deeq calls found!" ; }'
alias regem='() {[[ -f /dev/shm/regem ]] && gem "$(cat /dev/shm/regem)\n$1" || print "No previous gem calls found!" ; }'
alias regem2='() {[[ -f /dev/shm/regem2 ]] && gem2 "$(cat /dev/shm/regem2)\n$1" || print "No previous gem2 calls found!" ; }'
#Anon. function to populate LLM prompt file $TPROMPTF:
alias promf='() {(( $# )) && {[[ -f $1 ]] && cat "$1" >> $TPROMPTF || {(( $#1 - 1 )) && echo -e $1 >> $TPROMPTF || rm $TPROMPTF ; } ; } || echo -e "$(xsel -op)\n" >> $TPROMPTF ; }'

```

## Usage

### Core Command: `qlm` (Model-Agnostic)

```bash
qlm [ModelName] ["Prompt"]
qlm [-lammacli_opts --if_any -- ] [ModelName] ["Prompt"]
```

The second form is when the user wants to add or override `llama-cli` options.  Everything before '--' will be passed to `llama-cli` AS IS.

#### Scenarios:

| Input Type | Example | Behavior |
|---------------------|----------------------------------|--------------------------------------------------------------------------|
| **No arguments** | `qlm` | Uses default model (Qwen-14B) + clipboard/prompt file/context |
| **Only prompt** | `qlm "Explain relativity"` | Default model + given prompt |
| **Model + prompt** | `qlm Gemma2-9B "Write a poem"` | Specific model + given prompt |
| **Clipboard input** | `qlm` (with selected text) | Uses selected text as prompt |

### Dedicated Model Commands

Pre-configured for specific models (use without model names):

| Command | Model | Use Case |
|---------|--------------------------------|------------------------------|
| `qwec` | Qwen2.5-Coder-14B | Coding/technical tasks |
| `qwen` | Qwen2.5-14B-Instruct | General assistance |
| `gem` | Gemma2-9B | Multilingual queries |
| `gem2` | Gemma2-2B | Fast responses |
| `deeq` | DeepSeek-Qwen-14B | Advanced analysis |
| `mist` | Mistral-Small-24B | Large context handling |

Their response aliases (defined in `.zshrc` as anon. functions): `reqwec`, `reqwen`, `regem` etc.

**Example**:
```bash
>> qwec "Generate Python code for a Fibonacci sequence"
>> ls -al
>> reqwec 'Make it recursive'
```

### Context Building with `promf`

The `promf` helper populates the temporary prompt file (`$TPROMPTF`):

```bash
# Append content to the prompt file
promf file.txt

# From a file
promf "Custom instruction"

# Direct input
promf

# From selected text (via xsel)
```

**Workflow Example**:
```bash
promf "Context1" # Start building prompt
promf data.txt # Add file content
promf # Append text selected with the mouse from a browser
qlm [ModelName] # Use accumulated context
```

### Conversation Continuation

Use `reqlm` or model-specific aliases to continue previous sessions:

```bash
# Continue last `qlm` session
reqlm "Follow-up question?"

# Continue Qwen session
reqwec "Next coding task?"
```

## Configuration (qlm.cfg)

Edit `~/.zfunc/qlm.cfg` to add models and parameters:

```bash
# Example model entry
llmodels=( QwenCoder-14B "Qwen2.5-Coder-14B-Instruct-Q5_K_L.gguf" )

# Context size (adjust for VRAM)
ctxsize=(QwenCoder-14B 4096)

# GPU layer offloading
gpulayers=(QwenCoder-14B 99)

# Temperature (creativity)
temps=(QwenCoder-14B 0.2)
```

## Features

- **Zsh Completion**: Tab-complete model names when using `qlm`.
- **Context Persistence**: Conversations saved in `/dev/shm/req*` files for resuming later with the same model.
- **Flexible Input**: Prompts can come from command line, files, clipboard, or accumulated `promf` calls.
- **Model-Specific Prompts**: Each model has optimized system instructions (see `llmprompts` in qlm.cfg).

## Troubleshooting

- **Missing models**: Verify paths in `llmodels` and model filenames.
- **GPU issues**: Reduce `gpulayers` values if VRAM limited.
- **Context errors**: Lower `ctxsize` which competes for VRAM.
- **Dependencies**: Ensure `llama.cpp` binaries and `xsel` are installed. Concerning `xsel`, the equivalent on systems with Wayland is `wl-copy` and that should be installed.
## ToDo
Create an installantion script.

## Contributing

Add new models by editing `qlm.cfg` and following the parameter format. Pull requests welcome!

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [llama.cpp](https://github.com/ggml-org/llama.cpp) for the underlying LLM inference engine.
- The Zsh community for inspiration and tools.
