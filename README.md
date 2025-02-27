# Kuroko - 8-bit Assembly-Like Language

## Overview

Kuroko is a simple, structured, case-insensitive assembly-like language designed for an 8-bit interpreted environment. It emphasizes clarity, strict formatting, and readability while maintaining low-level control over memory and execution flow.

## Features

- **Case-insensitive syntax**
- **Whitespace and commas ignored** (except as delimiters)
- **Labels for structure, subroutines, and variables**
- **Strong formatting rules for clarity**
- **Registers, RAM addressing, and stack operations**
- **Arithmetic, logical, and bitwise operations**
- **Branching, jumps, and subroutine handling**
- **Input/output handling for interactive programs**

## Code Structure

A Kuroko program consists of labeled sections with structured indentation and spacing rules. Common sections include:

### Data Section

Used to declare named memory locations and structured data:

```assembly
# Data
LIST  $10 [
  prompt     = "Enter a number: ",
  too_high   = "Too high!",
  too_low    = "Too low!",
  win_text   = "You got it!"
]
NAME  $11 user_input
```

### Logic Section

Contains the main execution flow and structured labels for better organization:

```assembly
# Logic
MAIN:
  OUT   $prompt
  CALL  :GET_INPUT
  CALL  :CHECK_NUMBER
  JUMP  :MAIN
```

### Subroutines

Encapsulated code blocks for reuse and organization:

```assembly
# Subroutines
GET_INPUT:
  NIN   $user_input
  RTRN

CHECK_NUMBER:
  COMP  $user_input 42
  ZERO  :CORRECT
  POS   :TOO_HIGH
  OUT   $too_low
  RTRN

TOO_HIGH:
  OUT   $too_high
  RTRN

CORRECT:
  OUT   $win_text
  HALT
```

## Style Guide

### Formatting Rules

- **Labels**: Use `UPPERCASE` for locations and subroutines, `lowercase` for variables.
- **Indentation**: Use **two spaces**, no tabs.
- **Operand alignment**: Ensure operands start at column 6.
- **Comments**: Use `;` for inline explanations.

Example:

```assembly
; Correct alignment
MOVE  B C
ADD   H L
OR    I J
```

## Instruction Set

### Arithmetic Operations

```
ADD  source {destination}  ; Addition
SUB  source {destination}  ; Subtraction
MUL  source {destination}  ; Multiplication
DIV  source {destination}  ; Division
MOD  source {destination}  ; Modulus (Remainder)
```

### Logic & Bitwise Operations

```
AND  source {destination}  ; Bitwise AND
OR   source {destination}  ; Bitwise OR
XOR  source {destination}  ; Bitwise XOR
NOT  source                ; Bitwise NOT
LEFT destination {source}  ; Left shift
RGHT destination {source}  ; Right shift
```

### Control Flow

```
COMP  source source        ; Compare two values
ZERO  label                ; Jump if result is zero
POS   label                ; Jump if positive
NEG   label                ; Jump if negative
JUMP  label                ; Unconditional jump
CALL  subroutine           ; Call a subroutine
RTRN                        ; Return from subroutine
```

### Stack Operations

```
PUSH  source               ; Push value to stack
POP   destination          ; Pop value from stack
DUMP                        ; Push all registers to stack
RSTR                        ; Restore registers from stack
```

### Memory Operations

```
MOVE  source destination   ; Copy value
LOAD  register source      ; Load value into register
SAVE  register destination ; Store register value
SWAP  destination destination ; Swap two values
```

### Input/Output

```
OUT   source               ; Output text or number
NIN   destination          ; Get user input (numeric)
TLLY  destination          ; Output number in text format
POST                        ; Begin formatted output block
PRNT  source               ; Print within a formatted block
NWLN                        ; Print newline
```

## Example Program

A simple guessing game following Kuroko's conventions:

```assembly
# Data
LIST  $10 [
  prompt = "Guess a number between 1 and 100. ",
  too_high = "Too high.",
  too_low = "Too low.",
  win_text = "You win!",
  lose_text = "You lose. The number was "
]

LIST  $104 [
  number = 0,
  chances = 0,
  guess = 0
]

# Logic
_INITIALIZE:
  MOVE  5 $chances
  RAND  $number
  LOAD  A 100
  MOD   $number A
  INC   A
  SAVE  A $number

_START_GAME:
  OUT   $prompt

GAME_LOOP: 
  CALL  :GET_GUESS
  CALL  :CHECK_GUESS
  JUMP  :GAME_LOOP

# Subroutines
GET_GUESS:
  NIN   $guess
  RTRN

CHECK_GUESS:
  COMP  $guess $number
  ZERO  6
    CALL  :GIVE_HINT
    DEC   $chances
    LOAD  A 0
    JLE   :LOST $chances
    RTRN
  CALL  :WON
  RTRN

GIVE_HINT: 
  POS   3 
    OUT   $too_low 
    RTRN
  OUT   $too_high
  RTRN

LOST:
  POST
    PRNT  $lose_text
    TLLY  $number
    NWLN
  JUMP  :END

WON: 
  OUT   $win_text
  JUMP  :END

END:
  HALT
```

## Summary

Kuroko is designed for clarity, structure, and control, making it a powerful educational tool for understanding low-level programming concepts. By enforcing strict formatting and readable conventions, it provides an accessible yet disciplined environment for writing structured assembly-like code.

