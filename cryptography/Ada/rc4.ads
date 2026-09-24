package RC4
  with SPARK_Mode => On
is
   pragma Preelaborate;

   -- Domain types for the RC4 algorithm
   type Byte is mod 256;
   type Byte_Array is array (Natural range <>) of Byte;

   -- Exception raised when an invalid key length is provided
   Invalid_Key_Length : exception;

   -- The context containing the internal state of the RC4 cipher
   type Context is private;

   -- Standard Key-Scheduling Algorithm (KSA)
   -- Initializes the internal state array S and indices I, J.
   procedure Initialize (Ctx : out Context; Key : in Byte_Array)
     with Pre => Key'Length in 1 .. 256,
          Global => null;

   -- RC4-Drop variant KSA
   -- Initializes the state and then drops (discards) the first Drop_Count bytes
   -- of the keystream to mitigate weak key vulnerabilities in standard RC4.
   procedure Initialize_Drop (Ctx : out Context; Key : in Byte_Array; Drop_Count : in Natural)
     with Pre => Key'Length in 1 .. 256,
          Global => null;

   -- Pseudo-Random Generation Algorithm (PRGA)
   -- Advances the internal state and returns a single pseudo-random byte.
   function Next_Byte (Ctx : in out Context) return Byte
     with Global => null;

   -- Encrypts or decrypts the input data using the current context state.
   -- Since RC4 is a stream cipher, encryption and decryption are identical (XOR).
   function Process (Ctx : in out Context; Input : in Byte_Array) return Byte_Array
     with Post => Process'Result'Length = Input'Length,
          Global => null;

   -- Encrypts or decrypts data in place without allocating a new array.
   procedure Process_In_Place (Ctx : in out Context; Data : in out Byte_Array)
     with Global => null;

private
   -- The S-box state array spanning all possible Byte values
   type State_Array is array (Byte) of Byte;

   type Context is record
      S : State_Array := [others => 0];
      I : Byte := 0;
      J : Byte := 0;
   end record;
end RC4;
