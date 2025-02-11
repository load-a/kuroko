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
- **ADD source, target**  
  *"Add"*: Adds `source` to `target`; stores the sum in `target`.
- **SUB source, target**  
  *"Subtract"*: Subtracts `target` from `source`; stores the difference in `target`.
- **MUL source, target**  
  *"Multiply"*: Multiplies `source` by `target`; stores the product in `target`.
- **DIV source, target**  
  *"Divide"*: Divides `source` by `target`; stores the quotient in `target`.
- **REM source, target**  
  *"Remainder"*: Divides `source` by `target`; stores the remainder in `target`.
- **INC target, step**  
  *"Increase"*: Adds `step` to `target`; step is 1 by default.
- **DEC target, step**  
  *"Decrease"*: Subtracts `step` from `target`; step is 1 by default.

#### **Logic & Bitwise:**
- **AND source, target**  
  *"Logical AND"*: Performs logical AND between `source` and `target`; stores the result in `target`.
- **OR source, target**  
  *"Logical OR"*: Performs logical OR between `source` and `target`; stores the result in `target`.
- **NOT target**  
  *"Logical NOT"*: Inverts `target`.
- **XOR source, target**  
  *"Logical XOR"*: Performs logical XOR between `source` and `target`; stores the result in `target`.
- **LEFT target, step**  
  *"Bit Shift Left"*: Shifts the bits in `target` left by `step` number of times; `step` defaults to 1.
- **RGHT target, step**  
  *"Bit Shift Right"*: Shifts the bits in `target` right by `step` number of times; `step` defaults to 1.

#### **Control Flow:**

- **Branching (comparison with Zero):**
  - **COMP source, target**  
    *"Compare"*: Subtracts `target` from `source`, setting the Flag register based on the result.
  - **ZERO destination**  
    *"Branch if Zero"*: Jumps to `destination` if the Zero flag is set.
  - **POS destination**  
    *"Branch if Positive"*: Jumps to `destination` if no flags are set.
  - **NEG destination**  
    *"Branch if Negative"*: Jumps to `destination` if the Negative flag is set.

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
- **MOVE source, target**  
  *"Move Value"*: Copies the value from `source` into `target`.
- **LOAD register, source**  
  *"Load Register"*: Copies a value from memory into `register`. Supports immediate values.
- **SAVE register, target**  
  *"Save Register"*: Copies the value from `register` into `target`.
- **SWAP source, target**  
  *"Swap Values"*: Swaps the values of `source` and `target` (at least one of them must be a register).

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
    Used for arithmetic results, and is the inferred target for any operation (e.g., `ADD 4` is equivalent to `ADD 4, A`).
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
- The **MOVE** command copies values from source to target without modifying the source.

---