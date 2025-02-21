# **Kuroko Language**

Kuroko is a simple, educational, assembly-like language designed for learning fundamental low-level programming concepts. It uses a readable syntax, with a focus on clarity and accessibility, making it an ideal stepping stone for those interested in assembly programming. Kuroko is machine-agnostic, simulating an 8-bit environment for educational purposes.

---

## **General Rules**
- The language is case-insensitive.
- Numbers are treated as literals by default.
- **"$"** denotes an address.
- **"@"** indicates a pointer (e.g., `@0xAE` means "the address stored at location $0xAE").
- Subroutines are declared with the `LABEL:` syntax and called using `:LABEL`.
- Numbers are unsigned by default (range: 0–255). A leading `+` or `-` denotes a signed integer (range: -128 to 127).
- Only whole integers are supported.
- Supports Hex, Decimal, and Binary representations.
- Registers: **A**, **B**, **C**, **H**, **L**, **I**, **J**.
- The syntax for operations follows a `VERB DIRECT-OBJECT INDIRECT-OBJECT` structure (e.g., "DO THIS with/using/into THIS").
- Math and logical operations use the structure `OPERAND operation OPERATOR`. For example, `ADD 1 2` means `1 + 2` and `DIV 10 5` means `10 / 5`.
- The **A Register** is the default second operand. If **A** is the first operand, a second operand must be present (when applicable).
- Strings are terminated with a Null Character (0x00). The user must manually ensure null separation.
- Optional operands are enclosed in brackets. Default values, if any, are specified.

---

## **Memory Layout**
The language has a total of **256 addresses**. The first **10 addresses** are reserved for the **registers**. Users are free to write to addresses starting from **$10** onwards.

---

## **Example Program**

Here is a simple "Hello, World!" example in Kuroko:

```assembly
NAME $10 MESSAGE           ; Create a label for address $10
TEXT "Hello, World!" $MESSAGE   ; Store the message at the MESSAGE address

OUT $MESSAGE              ; Output the message to the console

HALT                      ; End execution
```

---

## **Commands**

### **Arithmetic**
"Source" refers to a *Number, Variable, Register, or Address*.  
"Destination" and "Step" refer to a *Variable, Register, or Address*.

- **ADD source, [destination: Accumulator]**  
  Adds `source` to `destination` and stores the result in `destination`.
- **SUB source, [destination: Accumulator]**  
  Subtracts `destination` from `source` and stores the result in `destination`.
- **MUL source, [destination: Accumulator]**  
  Multiplies `source` by `destination` and stores the result in `destination`.  
  Alias: `MULT`
- **DIV source, [destination: Accumulator]**  
  Divides `source` by `destination` and stores the result in `destination`.
- **REM source, [destination: Accumulator]**  
  Divides `source` by `destination` and stores the remainder in `destination`.  
  Alias: `MOD`
- **INC destination, [step: 1]**  
  Adds `step` to `destination` (default is 1).
- **DEC destination, [step: 1]**  
  Subtracts `step` from `destination` (default is 1).

### **Logic & Bitwise**
"Source" refers to a *Number, Variable, Register, or Address*.  
"Destination" and "Step" refer to a *Variable, Register, or Address*.

- **AND source, [destination: Accumulator]**  
  Performs a logical AND between `source` and `destination` and stores the result in `destination`.
- **OR source, [destination: Accumulator]**  
  Performs a logical OR between `source` and `destination` and stores the result in `destination`.
- **NOT destination**  
  Inverts the bits in `destination`.
- **XOR source, [destination: Accumulator]**  
  Performs a logical XOR between `source` and `destination` and stores the result in `destination`.
- **LEFT destination, [step: 1]**  
  Shifts the bits in `destination` left by `step` number of times.
- **RGHT destination, [step: 1]**  
  Shifts the bits in `destination` right by `step` number of times.

### **Control Flow**

- **Branching (comparison with Zero):**
  "Offset" must be an integer (signed or unsigned). Offsets cannot be zero to prevent infinite loops.

  *Note*: Whitespace and certain lexical items (e.g., `NAME` instructions, subroutine `LABEL:`, comments) are removed before execution. They should be considered when using branch instructions.
  
  - **COMP source, destination**  
    Subtracts `destination` from `source`, setting the Flag Register.
  - **ZERO offset**  
    Branches `offset` instructions if the Zero flag is set.
  - **POS offset**  
    Branches `offset` instructions if no flags are set.
  - **NEG offset**  
    Branches `offset` instructions if the Negative flag is set.

- **Jumps (comparison with Accumulator):**
  "Destination" refers to a *Subroutine*. "Source" is the *Number, Register, Address, or Variable* compared to the Accumulator to initiate the jump.
  
  - **JUMP destination**  
    Jumps to `destination`.
  - **JEQ destination, source**  
    Jumps to `destination` if `source == A`.
  - **JLT destination, source**  
    Jumps to `destination` if `source < A`.
  - **JGT destination, source**  
    Jumps to `destination` if `source > A`.
  - **JGE destination, source**  
    Jumps to `destination` if `source >= A`.
  - **JLE destination, source**  
    Jumps to `destination` if `source <= A`.

- **Routines:**
  - **CALL subroutine**  
    Jumps to `subroutine`, saving the current instruction index on the stack.
  - **RTRN**  
    Pops the stack and returns to the instruction after the call.

### **Stack Manipulation**
- **PUSH source**  
  Pushes `source` onto the stack. Literals can also be pushed.
- **POP destination**  
  Pops the top value from the stack and stores it in `destination`.
- **DUMP**  
  Pushes each register's value onto the stack in order.
- **RSTR**  
  Restores each register from the stack in reverse order.

  *Note*: The stack starts at the last address in RAM (0xFF) and grows downward. It has a capacity of 16 addresses, but there are no protections from stack overflows.

### **Memory**
- **MOVE source, destination**  
  Copies the value from `source` into `destination`.
- **LOAD register, source**  
  Copies a value from memory into `register`, supports immediate values.
- **SAVE register, destination**  
  Copies the value from `register` into `destination`.
- **SWAP source, destination**  
  Swaps the values of `source` and `destination` (at least one must be a register).

### **Input/Output**
- **TEXT string, destination**  
  Stores each byte of `string` into memory starting at `destination`.
- **OUT destination, limit**  
  Displays characters from `destination` up to `limit` or until a null character.
- **IN destination, limit**  
  Reads standard input into memory starting at `destination`, stopping at `limit`.

### **Other**
- **NAME address label**  
  Assigns a label to the given address, effectively creating a variable.
- **PIC image**  
  Displays the CPU status at the time the instruction is encountered. The "Image" operand is one byte that defines what gets displayed.

  The four least significant bits control the displayed information:
  ```
  registers:   0b0001
  flags:       0b0010
  stack:       0b0100
  ram:         0b1000
  ```

  The upper nibble defines the format:
  ```
  hex:      0b11
  decimal:  0b10
  octal:    0b01
  binary:   0b00
  ```

  Example: `PIC 0b11001000` shows RAM in hexadecimal addresses and binary values.

---

## **Registers**

### **User-Accessible Registers:**
These are general-purpose, but some are named for convenience.
- **A (Accumulator)**  
  Used for arithmetic results and is the default destination for many operations.
- **B, C (Bank Registers)**  
  General-purpose registers.
- **H, L (Data Registers)**  
  Named for handling address data.
- **I, J (Index Registers)**  
  Used for looping or managing specific memory addresses.

### **Internal Registers:**
- **Flag Register:** Stores condition flags (Zero, Carry, Negative, etc.).
- **PC (Program Counter):** Tracks the current instruction.
- **SP (Stack Pointer):** Points to the current location in the stack.

---

### Conclusion

Kuroko is a unique approach to assembly-style programming, designed to be accessible, educational, and simple while maintaining the power and flexibility of assembly logic. This makes it perfect for anyone looking to dive deeper into low-level programming concepts.

---

Let me know if you'd like any further changes!