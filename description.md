### **Language Specification:**

#### **General Rules:**
- Case Insensitive.
- Numbers are treated as literals by default.
- **"$"** indicates an address.
- **"@"** indicates a pointer (e.g., `@0xAE` means "the address held at location $0xAE").
- Declaring a label looks like `Label:`. If a label is used as an operand, it becomes `:Label`.
- Numbers are unsigned by default (range 0–255). A leading `+` or `-` indicates a signed integer (range -128 to 127).
- No support for decimal numbers.
- Registers: **A**, **B**, **C**, **D**, **H**, **L**, **I**, **J**.
- The grammar for any operation is:  
  `VERB DIRECT-OBJECT INDIRECT-OBJECT`  
  or  
  `DO THIS to/at/into THIS`.
- **A** is always the implied second operand. If **A** is the first operand, a second operand must be present (when applicable).
- Strings are read starting from a particular address, stopping at the Null Character.

---

### **Commands:**

#### **Arithmetic:**
- **ADD source, destination**  
  *"Add"*: Adds `source` to `destination`; stores the sum in `destination`.
- **SUB source, destination**  
  *"Subtract"*: Subtracts `destination` from `source`; stores the difference in `destination`.
- **MUL source, destination**  
  *"Multiply"*: Multiplies `source` by `destination`; stores the product in `destination`.
- **DIV source, destination**  
  *"Divide"*: Divides `source` by `destination`; stores the quotient in `destination`.
- **REM source, destination**  
  *"Remainder"*: Divides `source` by `destination`; stores the remainder in `destination`.
- **INC destination, step**  
  *"Increase"*: Adds `step` to `destination`; step is 1 by default.
- **DEC destination, step**  
  *"Decrease"*: Subtracts `step` from `destination`; step is 1 by default.

#### **Logic & Bitwise:**
- **AND source, destination**  
  *"Logical AND"*: Performs logical AND between `source` and `destination`; stores the result in `destination`.
- **OR source, destination**  
  *"Logical OR"*: Performs logical OR between `source` and `destination`; stores the result in `destination`.
- **NOT destination**  
  *"Logical NOT"*: Inverts `destination` by XOR-ing it with 0xFF.
- **XOR source, destination**  
  *"Logical XOR"*: Performs logical XOR between `source` and `destination`; stores the result in `destination`.
- **LEFT destination, step**  
  *"Bit Shift Left"*: Shifts the bits in `destination` left by `step` number of times; `step` defaults to 1.
- **RGHT destination, step**  
  *"Bit Shift Right"*: Shifts the bits in `destination` right by `step` number of times; `step` defaults to 1.

#### **Control Flow:**

- **Branching (comparison with Zero):**
  - **COMP source, destination**  
    *"Compare"*: Subtracts `destination` from `source`, setting the Flag register based on the result.
  - **ZERO offset**  
    *"Branch if Zero"*: Jumps to `offset` if the Zero flag is set.
  - **POS offset**  
    *"Branch if Positive"*: Jumps to `offset` if no flags are set.
  - **NEG offset**  
    *"Branch if Negative"*: Jumps to `offset` if the Negative flag is set.

- **Jumps (comparison with Accumulator):**
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
  *"Read Input"*: Writes standard input as a string starting at `destination`, stopping at `limit` or null.
- **INT destination, limit**  
  *"Convert to Integer"*: Converts each character at `destination` into an integer (or zero) until null or `limit`.

#### **Constants (used as operands):**
- **TRUE, FALSE**  
  *True* is any non-zero value (usually 1 or -1), and *False* is 0.
- **MIN, MAX**  
  *MIN* is 0, and *MAX* is 255 (or -128 and 127 if signed).

#### **Registers:**

- **User Accessible:**
  - **A (Accumulator)**  
    Used for arithmetic results, and is the inferred destination for any operation (e.g., `ADD 4` is equivalent to `ADD 4, A`).
  - **B, C (Bank Registers)**  
    General-purpose storage.
  - **H, L (Data Registers)**  
    Hold two 8-bit values that can be used separately or together as a 16-bit register.
  - **I, J (Index Registers)**  
    Used for loops, supports auto-increment and auto-decrement.

- **Inaccessible:**
  - **Flag Register**  
    Holds status bits and cannot be read or written to directly.
  - **Program Counter (PC)**  
    Holds the address of the current instruction.
  - **Stack Pointer (SP)**  
    Holds the next available address in the stack.

---

### **Additional Notes:**
- The **OUT** command stops printing when it encounters a null character or exceeds the specified byte limit.
- The **MOVE** command copies values from source to destination without modifying the source.

---

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
