[Zshelf](https://github.com/quantiusbenignus/zshelf) is a Zsh-centric command-line interface for interacting with local Large Language Models (LLMs) using [llama.cpp](https://github.com/ggml-org/llama.cpp). It supports context persistence, model switching, and advanced prompt workflows, ingesting from the command line, files and mouse-selected text in any window. 

Unique to this setup is the ability to have an itermittent one-shot conversations outside the isolated bubble of the lamma.cpp conversation mode: 

```
❯❯ mist 'Given the csv file sample I showed you, write a python function to convert it to binary format using the python struct.pack().
    Pad all strings in the first column with zero bytes to a fixed length of 90 bytes.'
❯❯ ls -al *.bin
❯❯ remist 'Since the file is too big, we will rewrite the first column data as a byte with the string length, followed by the variable length string.'
❯❯ ls -al *.bin
❯❯ remist 'Good. Let us rewrite the function to first sort the data and then prepend an index with the offset and record length for each 1st character.'
❯❯ remist 'Change the code to write an integer (4 bytes) with the byte length of the index at the beginning of the file.'    
```

This is powerful because one can use the shell while interacting (and affect the interaction itself) with the local LLM. All the flexibility, power and programming logic of the zsh shell is thus available in this one-shot conversation mode. For example, one can loop through all locall LLM files with the same prompt and collect the results for comparison:

```
prompt="Explain the concept of quantum computing."
# Loop through each model defined in llmodels (qlm.cfg)
for model in "${(k)llmodels}"; do
    echo "Running model: $model"
    qlm "$model" "$prompt"
    echo "----------------------------------------"
done
```


## Table of Contents

- [Features](#features)
- [Installation & Setup](#installation--setup)
- [Usage](#usage)
  - [Core Command: `qlm`](#core-command-qlm)
  - [Dedicated Model Commands](#dedicated-model-commands)
  - [Context Building with `promf`](#context-building-with-promf)
  - [Conversation Continuation](#conversation-continuation)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Features

- **Zsh Completion**: Tab-complete model names when using `qlm`.
- **Context Persistence**: Conversations saved in `/dev/shm/re*` files for resuming later with the same model.
- **Flexible Input**: Prompts can come from command line, files, clipboard, or accumulated `promf` calls.
- **Model-Specific Prompts**: Each model has optimized system instructions (see preset values in qlm.cfg).

## Installation & Setup

### Requirements:
- Zsh (configured with `compinit` for the TAB competion of model names.)
- [llama.cpp](https://github.com/ggml-org/llama.cpp) (`llam`/`llama-cli` in PATH)
- `xsel` (or `wl-copy` on Wayland) for clipboard access (`sudo apt install xsel` on Linux)

### Steps:

1. **Place files in Zsh function path**:
    ```zsh
    git clone https://github.com/QuantiusBenignus/Zshelf.git
    [[ -z "$ZDOTDIR" ]] && export ZDOTDIR="$HOME"
    mkdir -p $ZDOTDIR/.zfunc   
    cd zshelf  
    cp * $ZDOTDIR/.zfunc/
    ```

2. **Configure `.zshrc`**:
    ```zsh
    #It would be best to set ZDOTDIR in your ~/.zshenv
    if [[ -z "$ZDOTDIR" ]]; then
        export ZDOTDIR="$HOME"
    fi

    fpath=($ZDOTDIR/.zfunc $fpath)
    # Enables model name completion
    
    # Autoload functions and completion
    autoload -Uz qlm _qlm reqlm qwec qwen gem gem2 deeq mist 

    #This comes after compinit:
    compdef _qlm qlm
    ```
Please, check the bottom of supplied `.zshrc` for configuration related to this tool set.
All the response aliases/functions are defined in the config file qlm.cfg.

## Usage

### Core Command: `qlm` (Model-Agnostic)

```bash
❯❯qlm <TAB>[ModelName] ["Prompt"]
❯❯qlm [-lammacli_opts --if_any -- ] <TAB>[ModelName] ["Prompt"]
```
The command uses a custom zsh completion function to TAB-complete the model name from all available in the qlm.cfg file.
The second, optional form is when the user wants to add or override `llama-cli` options.  Everything before '--' will be passed to `llama-cli` AS IS.

#### Scenarios:

| Input Type | Example | Behavior |
|---------------------|----------------------------------|--------------------------------------------------------------------------|
| **No arguments** | `qlm` | Uses default model (Qwen-14B) + clipboard/prompt file/context |
| **Only prompt** | `qlm "Explain relativity"` | Default model + given prompt |
| **Model + prompt** | `qlm Gemma2-9B "Write a poem"` | Specific model + given prompt |
| **Clipboard input** | `qlm` (with selected text) | Uses selected text as prompt |

### Dedicated Model Commands

Pre-configured for specific, frequently-used models (use without model names):

| Command | Model | Use Case |
|---------|--------------------------------|------------------------------|
| `qwec` | Qwen2.5-Coder-14B | Coding/technical tasks |
| `qwen` | Qwen2.5-14B-Instruct | General assistance |
| `gem` | Gemma2-9B | Multilingual queries |
| `gem2` | Gemma2-2B | Fast responses |
| `deeq` | DeepSeek-Qwen-14B | Advanced analysis |
| `mist` | Mistral-Small-24B | Large context handling |

Their response aliases (defined in `qlm.cfg` as anon. functions): `reqwec`, `reqwen`, `regem` etc.

**Example**:
```bash
❯❯qwec "Generate Python code for a Fibonacci sequence"
❯❯ls -al
❯❯reqwec 'Make it recursive'
```

### Context Building with `promf`

The `promf` helper populates the temporary prompt file (`$TPROMPTF`):

```bash
# Append content to the prompt file
❯❯promf file.txt
# From a file

❯❯promf "Custom instruction"
# Direct input

❯❯promf
# From mouse-selected text (via xsel)

❯❯promf 0 #or any other single character
#delete temporary prompt file
```

**Workflow Example**:
```bash
❯❯promf "Context1" # Start building prompt
❯❯promf data.txt # Add file content
❯❯promf # Append text selected with the mouse from a browser
❯❯qlm [ModelName] # Use accumulated context
❯❯promf 1 #Clear context (empty file)
```

### Conversation Continuation

Use `reqlm` or model-specific aliases to continue previous sessions:

```bash
# Continue last `qlm` session
❯❯reqlm "Follow-up question?"

# Continue Qwen session
❯❯reqwec "Next coding task?"
```

## Configuration (qlm.cfg)

Edit `.zfunc/qlm.cfg` to add models and parameters:

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
