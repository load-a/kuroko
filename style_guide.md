# **Style Guide and Conventions**

## **Language Restrictions**

- **Kuroko is case-insensitive.**
- **Whitespace is ignored** except as a lexical unit delimiter.
- **Comments begin with a semicolon (`;`)** and extend to the end of the line.
- **Commas are ignored** and may be used for readability.
- **Labels serve different functions**, though the interpreter treats them the same. To improve clarity, we categorize them as:
    - **Locations** (structural markers, never called or jumped to).
    - **Subroutines** (used in `CALL` and `JUMP` instructions).
    - **Variables** (aliases for RAM locations, requiring an addressing symbol).

### **Label Examples**

```
# Data
; Variables - Aliases for RAM locations (preceded by an addressing symbol in code)
NAME  $10 total 
NAME  $11 quantity

# Logic
; Locations - Structural markers (not callable or jumpable)
_MAIN:
  ADD   100 $total
  MULT  $quantity $total
  CALL  :GIVE_TOTAL
  HALT

# Subroutines
; Subroutines - Entry points for calls and jumps
GIVE_TOTAL:
  OUT   "Your total is: "
  TLLY  $total
  RTRN
```

---

## **Style Conventions**

### **Case**

- **Instructions** → `UPPERCASE`
- **Labels**
    - **Locations & Subroutines** → `UPPERCASE`
    - **Variables** → `lowercase`
- **Headers** → `Capitalized`
- **Registers** → `UPPERCASE`

### **Indentation & Spacing**

- Use **two spaces** for indentation.
- **Do not use tabs.**
- **Labels and headers** should not be indented.
- **Instructions should align operands at column 6.**
- **Standalone instructions** (not within a label) should not be indented.
- **Comments should start one space after the semicolon.**
- **Comments under the same label should be flush with each other.**
- **Headers may optionally have a space after the hash (`# Data` vs. `#Data`).**

#### **Operand Spacing Example:**

```
; Incorrect
MOVE B C
ADD H L
OR I J

; Correct
MOVE B C
ADD  H L
OR   I J
```

### **Block Formatting**

- **Multi-line list elements** should be indented.
- **Mini-blocks** (like `POST`/`PRNT` pairs or code skipped by branches) should be indented relative to the first instruction.
- **Keep lines within 80 characters**, including comments.

---

## **Structure**

### **Headers**

- **`# Data`** is optional but must be the first line if present.
- **`# Logic`** is optional but required if `# Data` is used.
- **`# Subroutines` and `# Routines`** are purely organizational.

### **Data Section**

- **Separate multi-line lists with a blank line.**
- **Group similar data instructions (`LIST`, `TEXT`, `NAME`).**
- **Avoid single-item lists unless labeled and initialized.**

### **Logic Section**

- **Use an underscore (`_`) for Locations** (to indicate they are not callable).
- **Limit indentation depth to two levels.**
- **Separate each Location/Subroutine with a blank line.**
- **Prefer `# Logic` for main code and `# Subroutines` for functions.**
- **Explicit termination is recommended**:
    
    ```
    JUMP  :END  
    END:  
      HALT
    ```
    
- **Registers do not require explicit `$` addressing** and should not use it.

---

## **Example Program**

The following is a **guessing game program** that adheres to these conventions.

```
# Data
LIST  $10 [
  prompt     = "Guess a number between 1 and 100. ",
  too_high   = "Too high.",
  too_low    = "Too low.",
  win_text   = "You win!",
  lose_text  = "You lose. The number was "
]

LIST  $104 [
  number  = 0,
  chances = 0,
  guess   = 0
]

# Logic
_INITIALIZE:
  MOVE  5 $chances   ; Set player’s number of chances
  RAND  $number      ; Generate a random number (0-255)
  LOAD  A 100        
  MOD   $number A    ; Convert to 0-99
  INC   A            ; Convert to 1-100
  SAVE  A $number    ; Store the result

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
  PIC   0b10101111
  HALT
```
