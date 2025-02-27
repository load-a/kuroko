# Instruction Set

## Overview

### Operand Types

The system uses several general types of operands:

- **Literals**: Immediate values such as numbers or strings.
    - Examples: `5`, `"Hello, world!"`, `0b1101`
- **Addresses**: Memory locations.
    - **Direct Addresses**: `$50`, `$total`, `H` (registers use direct addressing by default)
    - **Indirect Addresses**: `@10`, `@pointer`, `@L`
- **Destination**: An _address_ where the result of an operation is stored.
- **Source**: A value used in an operation but not modified. Can be an address, literal, register, or variable.
    - Examples: `$12`, `0xff`, `@L`, `$subtotal`
- **Label**: A named location in memory or code, assigned using `NAME`, `VAR`, or `LABEL:`.
    - Naming rules: Letters, numbers, and underscores; must start with a letter or underscore; at least two characters long.
    - Examples: `user_name`, `START`, `x2`
- **Variable**: A label referring to a named RAM address. No symbol in declaration, but required in usage.
    - Examples: `$price`, `@id_number`
- **Location**: A label for instruction collections, not intended for calls or jumps. Should begin with an underscore.
    - Examples: `_MAIN_LOGIC`, `_INITIALIZE`
- **Subroutine**: A label for ROM addresses or instruction blocks, formatted differently for declaration and calls.
    - Declaration: `COUNT_CHARS:`, `LOOP:`
    - Call: `:COUNT_CHARS`, `:LOOP`

### Explanation Key

- Full instruction names appear in quotes where applicable.
- Syntax is specified at the top of each section:
    - `{source}` indicates an optional operand.
    - `<none>` denotes no operands.
    - `INST` represents the actual instruction name.
    - `INSTRUCTION operand operand` describes operand relationships.

---

## Instructions

### Arithmetic

#### Standard Operations

These operate on two values, with the second operand optional (default: Accumulator). The second operand stores the result.

`INST source {destination}`

- `ADD`
- `SUB`
- `MUL` or `MULT`
- `DIV`
- `MOD` or `REM` ("Modulus" or "Remainder")

Example: If `A = 5`, `DIV 20 A` results in `20 / 5`, storing `4` in `A`.

#### Special Operations

`INC` and `DEC` increment or decrement the _destination_ by an optional _step_ (default: `1`).

`INST destination {source}`

- `INC`
- `DEC`

`RAND {destination}`

- `RAND`: Generates a random integer (0–255) and stores it.

---

### Logic and Bitwise

These use the same syntax as arithmetic instructions.

#### Logical Operations

`INST source {destination}`

- `AND`
- `NOT`
- `OR`
- `XOR`

#### Bitwise Operations

`INST destination {source}`

- `LEFT`: Bitwise shift left
- `RGHT`: Bitwise shift right

---

### Control Flow

#### Branching Operations

Used after `COMP` to jump execution based on comparison results. Jumps are relative to instruction position.

`COMP source source`

- `COMP`

`BRANCH source`

- `POS`: Branch if positive
- `NEG`: Branch if negative
- `ZERO`: Branch if zero (equal values)

#### Jumps

Jump instructions take a _Subroutine_ as the first operand. All except `JUMP` take a second operand, which is compared to the Accumulator.

`JUMP subroutine`

- `JUMP`: Unconditional jump

`JMP subroutine source`

- `JGT`: Jump if greater than
- `JGE`: Jump if greater than or equal to
- `JEQ`: Jump if equal to
- `JLE`: Jump if less than or equal to
- `JLT`: Jump if less than

---

### Subroutine Instructions

`CALL subroutine`

- `CALL`: Calls a subroutine and pushes a return address to the stack.

`RTRN <none>`

- `RTRN`: Returns from a subroutine by popping the stack.
    - **Note:** Avoid excessive stack operations inside subroutines.

---

### Stack

`PUSH source`

- `PUSH`

`POP destination`

- `POP`

`INST <none>`

- `DUMP`: Pushes all general-purpose registers onto the stack.
- `RSTR`: Restores registers by popping them off the stack in reverse order.

---

### Memory

`MOVE source destination`

- `MOVE` or `COPY`: Copies the source value to the destination.

`LOAD register source`

- `LOAD`: Loads a register with a value.

`SAVE register destination`

- `SAVE`: Saves a register’s value.

`SWAP destination destination`

- `SWAP`: Swaps the values of two addresses.

---

### I/O

#### Input

`INST destination {source}`

- `IN`: Reads a string and stores it at the destination.
- `NIN`: Reads input, converts it to an integer, and stores it.

#### Output

`INST source {source}`

- `OUT`: Prints prompt + text at address + newline.
- `NOUT`: Prints prompt + numeric value + newline.
- `PRNT`: Prints text without a newline.
- `TLLY`: ("Tally") Prints a numeric value without a newline.

`INST <none>`

- `POST`: Prints prompt without newline.
- `NWLN`: Starts a new line.

>Note: the variety and effectiveness of the output instructions have been provided for convenience and to ease the learning process. However, they tend to trivialize the process. It is recommended, once students become more comfortable with Kuroko, that they implement their own output subroutines.

---

### Other

#### Declaratives

Used in the `#DATA` section. `TEXT` can be used outside `#DATA`.

`TEXT destination string_literal`

- `TEXT`: Stores a string in RAM.

`NAME destination variable`

- `NAME` or `VAR`: Assigns a label to a RAM address.

`LIST destination '[' literal | label = literal ... ']'`

- `LIST`: Defines multiple consecutive values in RAM, with optional labels.

#### Executables

Used in the `#LOGIC` section.

`HALT <none>`

- `HALT`: Stops execution.

`PIC natural_numeric_literal`

- `PIC`: Outputs a snapshot of the CPU state.

