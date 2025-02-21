### **Kuroko Language Specification:**

#### **General Rules:**
- Case Insensitive.
- Numbers are treated as literals by default.
- **"$"** indicates an address.
- **"@"** indicates a pointer (e.g., `@0xAE` means "the address held at location $0xAE").
- Subroutines are declared with `LABEL:` syntax. Subroutines can be called with `:LABEL` syntax.
- Numbers are unsigned by default (range 0–255). A leading `+` or `-` indicates a signed integer (range -128 to 127).
- Only whole integers are supported. 
- Hex, Decimal and Binary are supported.
- Registers: **A**, **B**, **C**, **H**, **L**, **I**, **J**.
- The grammar for any operation is based on a `VERB DIRECT-OBJECT INDIRECT-OBJECT` structure. Another way of looking at it is `DO THIS with/using/into THIS`.
- Math and Logical operations follow the structure `OPERAND operation OPERATOR`. So `ADD 1 2` is the same as `1 + 2`, `DIV 10 5` is the same as `10 /  5`, etc.
- The **A Register** is always the implied second operand. If **A** is the first operand, a second operand must be present (when applicable).
- Strings are delineated with the Null Character (0x00). This is not added by default; the user must ensure their strings are null separated.
- Optional operands will be enclosed in brakets. If a default value is assumed, it will be specified there.

---

### **Commands:**

#### **Arithmetic:**
"Source" must be a *Number, Variable, Register or Address*.
"Destination" and "Step" must be a *Variable, Register or Address*.

- **ADD source, [destination: Accumulator]**  
  *"Add"*: Adds `source` to `destination`; stores the sum in `destination`.
- **SUB source, [destination: Accumulator]**  
  *"Subtract"*: Subtracts `destination` from `source`; stores the difference in `destination`.
- **MUL source, [destination: Accumulator]**  
  *"Multiply"*: Multiplies `source` by `destination`; stores the product in `destination`.
  Alias: `MULT`
- **DIV source, [destination: Accumulator]**  
  *"Divide"*: Divides `source` by `destination`; stores the quotient in `destination`.
- **REM source, [destination: Accumulator]**  
  *"Remainder"*: Divides `source` by `destination`; stores the remainder in `destination`. 
  Alias: `MOD`
- **INC destination, [step: 1]**  
  *"Increase"*: Adds `step` to `destination`; step is 1 by default.
- **DEC destination, [step: 1]**  
  *"Decrease"*: Subtracts `step` from `destination`; step is 1 by default.

#### **Logic & Bitwise:**
"Source" must be a *Number, Variable, Register or Address*.
"Destination" and "Step" must be a *Variable, Register or Address*.

- **AND source, [destination: Accumulator]**  
  *"Logical AND"*: Performs logical AND between `source` and `destination`; stores the result in `destination`.
- **OR source, [destination: Accumulator]**  
  *"Logical OR"*: Performs logical OR between `source` and `destination`; stores the result in `destination`.
- **NOT destination**  
  *"Logical NOT"*: Inverts bits in `destination`.
- **XOR source, [destination: Accumulator]**  
  *"Logical XOR"*: Performs logical XOR between `source` and `destination`; stores the result in `destination`.
- **LEFT destination, [step: 1]**  
  *"Bit Shift Left"*: Shifts the bits in `destination` left by `step` number of times.
- **RGHT destination, [step: 1]**  
  *"Bit Shift Right"*: Shifts the bits in `destination` right by `step` number of times.

#### **Control Flow:**

- **Branching (comparison with Zero):**

"Offset" must be an Integer(signed or unsigned). Offset cannot be zero, as that would cause a command to jump to itself infinitely.

NOTE: Whitespace and other certain lexical items (`NAME` instruction, subroutine `LABEL:`, `; Comments`) are removed from ROM before execution. These should be avoided (or at least accounted for) if used within range of a Branch instruction. 
  - **COMP source, destination**  
    *"Compare"*: Subtracts `destination` from `source`, setting the Flag Register in the process.
  - **ZERO offset**  
    *"Branch if Zero"*: Jumps `offset` number of instructions if the Zero flag is set.
  - **POS offset**  
    *"Branch if Positive"*: Jumps `offset` number of instructions if no flags are set.
  - **NEG offset**  
    *"Branch if Negative"*: Jumps `offset` number of instructions if the Negative flag is set.

- **Jumps (comparison with Accumulator):**
"Destination" must be a *Subroutine*. "Source" is the *Number, Register, Address or Variable* being compared to the Accumulator to initiate the jump.
  - **JUMP destination**  
    *"Jump"*: Jumps to `destination`.
  - **JEQ destination, source**  
    *"Jump if Equal"*: Jumps to `destination` if `source == A`.
  - **JLT destination, source**  
    *"Jump if Less Than"*: Jumps to `destination` if `source < A`.
  - **JGT destination, source**  
    *"Jump if Greater Than"*: Jumps to `destination` if `source > A`.
  - **JGE destination, source**  
    *"Jump if Greater Than or Equal"*: Jumps to `destination` if `source >= A`.
  - **JLE destination, source**  
    *"Jump if Less Than or Equal"*: Jumps to `destination` if `source <= A`.

- **Routines:**
  - **CALL subroutine**  
    *"Call Subroutine"*: Jumps to `subroutine` or Block Label; saves the current instruction index on the stack.
  - **RTRN**  
    *"Return from Subroutine"*: Pops the stack and returns to the instruction after the call.

#### **Stack Manipulation:**
- **PUSH source**  
  *"Push onto Stack"*: Pushes `source` onto the stack. Literals can also be pushed.
- **POP destination**  
  *"Pop off of Stack"*: Pops the top value from the stack and stores it in `destination`.
- **DUMP**  
  *"Dump Registers"*: Pushes each register's value onto the stack in order.
- **RSTR**  
  *"Restore Registers"*: Restores each register in reverse order from the stack.

  Note: The stack begins at the last address in RAM (0xFF) and grows down ward. It has been officially given 16 addresses, although there are no protections from overflowing or underflowing the stack.

#### **Memory:**
- **MOVE source, destination**  
  *"Move Value"*: Copies the value from `source` into `destination`.
- **LOAD register, source**  
  *"Load Register"*: Copies a value from memory into `register`. Supports immediate values.
- **SAVE register, destination**  
  *"Save Register"*: Copies the value from `register` into `destination`.
- **SWAP source, destination**  
  *"Swap Values"*: Swaps the values of `source` and `destination` (at least one of them must be a register).

#### **Input/Output:**
- **TEXT destination, string**  
  *"Record Text"*: Stores each byte of `string` into memory starting at `destination`.
- **OUT destination, limit**  
  *"Display Output"*: Displays characters starting from `destination` up to `limit` or until a null character.
- **IN destination, limit**  
  *"Read Input"*: Writes standard input as a string starting at `destination`, stopping at `limit` string end.

#### **Other:**
- **NAME address label**
  *"Name Address"*: Assigns a label to the provided address, essentially creating a variable.
- **PIC image**
  *"Picture CPU"*: Prints the status of the CPU at the time the instruction is encountered. The "Image" operand is one byte that defines what gets displayed. The four least significant bits determine what information gets shown:
  ```
  registers:   0b0001
  flags:       0b0010
  stack:       0b0100
  ram:         0b1000
  ```
   For example, `PIC 0b1000` shows RAM, `PIC 0b0110` shows the Stack and Flags, etc. 

   If RAM is selected, the upper nibble is used to define the format. The first two significant bits define the base for the Addresses, and the next two bits define the base for the Values.
   ```
   hex:      0b11
   decimal:  0b10
   octal:    0b01
   binary:   0b00
   ```
   For example, `PIC 0b11001000` will give a view of the RAM in which the addresses are in Hexadecimal and the values are in Binary: 
   ```
   00. 00100011 00000000 00000000 00000000 00000000 00101011 00000000 00001011 |  # . . . . + . . 
   08. 11111111 01000000 01010000 01101100 01100101 01100001 01110011 01100101 |  . @ P l e a s e 
   10. 00100000 01100101 01101110 01110100 01100101 01110010 00100000 01111001 |    e n t e r   y 
   18. 01101111 01110101 01110010 00100000 01101110 01100001 01101101 01100101 |  o u r   n a m e 
   ```
   `PIC 0b10101000` has Decimal addresses and values: 
   ```
   000. 111 111 033 118 121 000 000 025 |  o o ! v y . . . 
   008. 255 064 000 000 000 000 000 000 |  . @ . . . . . . 
   016. 071 114 111 111 118 121 033 000 |  G r o o v y ! . 
   ```
#### **Registers:**

- **User Accessible:**
All User Registers are general purpose. However, some have been named to make their use in certain actions easier.
  - **A (Accumulator)**  
    Used for arithmetic results, and is the inferred destination for many arithmetic and logical operations (e.g., `ADD 4` is equivalent to `ADD 4, A`).
  - **B, C (Bank Registers)**  
    General-purpose registers.
  - **H, L (Data Registers)**  
    Named "High" and "Low" after data registers in 16-bit CPU. Recommended for manipulating address data.
  - **I, J (Index Registers)**  
    Named after iterator variables. Recommended for loops and incrementing.

- **Inaccessible:**
These registers cannot be written to or read from directly, if at all.
  - **Flag Register**  
    Holds status bits and cannot be read or written to directly.

    ### **Flag Register Bits:**
    Bits are ordered from least to most significant.
    |Bit|Name|When set...|
    |-|-|-|
    |0. |Zero     | Result is zero |
    |1. |Negative   | Result is negative |
    |2. |Carry    | Previous operation used a carry or borrow |
    |3. |Overflow   | Previous *signed operation* exceeded the system's range |
    |4. |Comparison   | The previous comparison was *equal* |
    |5. |Condition  | The previous comparison was *greater-than* |
    |6. |Parity   | Result had an even number of ones |
    |7. |Unused/Reserved||

  - **Program Counter (PC)**  
    Holds the address of the current instruction.
  - **Stack Pointer (SP)**  
    Holds the next available address in the stack.

---

