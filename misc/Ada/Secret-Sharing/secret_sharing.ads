with Interfaces;

package Secret_Sharing is

   --  Types for controlling share distribution
   type Share_ID is range 1 .. 255;
   type Threshold_Type is range 1 .. 255;

   -----------------------------------------------------------------------------
   --  Variant 1: Shamir's Secret Sharing (Polynomial k-out-of-n scheme)
   -----------------------------------------------------------------------------
   --  Operates over a prime field GF(P).
   --  We use the Mersenne prime 2^31 - 1, which fits within 32-bit arithmetic.
   Prime : constant := 2_147_483_647;
   type GF_Element is mod Prime;

   --  A single share consists of an X coordinate (the share ID)
   --  and a Y coordinate (the polynomial evaluation).
   type Shamir_Share is record
      X : GF_Element;
      Y : GF_Element;
   end record;

   type Shamir_Share_Array is array (Positive range <>) of Shamir_Share;

   --  Exceptions for invalid runtime inputs
   Duplicate_Share_X   : exception;
   Invalid_Share_Count : exception;

   --  Generates shares using Shamir's scheme.
   --  Requires Threshold <= N (cannot require more shares than generated).
   function Split_Shamir
     (Secret    : GF_Element;
      N         : Share_ID;
      Threshold : Threshold_Type) return Shamir_Share_Array
     with Pre  => Integer (Threshold) <= Integer (N),
          Post => Split_Shamir'Result'Length = Positive (N);

   --  Reconstructs the secret using Lagrange interpolation.
   --  Only requires 'Threshold' shares. Providing more is allowed, but only
   --  the first 'Threshold' shares in the array will be used.
   function Reconstruct_Shamir
     (Shares    : Shamir_Share_Array;
      Threshold : Threshold_Type) return GF_Element
     with Pre => Shares'Length >= Positive (Threshold);

   -----------------------------------------------------------------------------
   --  Variant 2: Trivial Additive/XOR Secret Sharing (n-out-of-n scheme)
   -----------------------------------------------------------------------------
   --  Operates over binary data. All N shares are required to reconstruct.
   type Data_Word is new Interfaces.Unsigned_32;
   type XOR_Share_Array is array (Positive range <>) of Data_Word;

   --  Generates XOR shares.
   function Split_XOR
     (Secret : Data_Word;
      N      : Share_ID) return XOR_Share_Array
     with Post => Split_XOR'Result'Length = Positive (N);

   --  Reconstructs the XOR secret.
   function Reconstruct_XOR
     (Shares : XOR_Share_Array) return Data_Word
     with Pre => Shares'Length > 0;

end Secret_Sharing;
