--  Bloom_Filter body — classic Bloom filter with double hashing.

pragma Ada_2022;

with Ada.Unchecked_Deallocation;
package body Bloom_Filter is

   procedure Free is new Ada.Unchecked_Deallocation
     (Object => Word_Array, Name => Word_Array_Access);

   Word_Bits : constant Natural := 64;

   ---------------------------------------------------------------------------
   -- Controlled
   ---------------------------------------------------------------------------

   overriding procedure Adjust (F : in out Filter) is
      Old : constant Word_Array_Access := F.Bits;
   begin
      if Old /= null then
         F.Bits := new Word_Array'(Old.all);
      end if;
   end Adjust;

   overriding procedure Finalize (F : in out Filter) is
   begin
      if F.Bits /= null then
         Free (F.Bits);
         F.Bits := null;
      end if;
   end Finalize;

   ---------------------------------------------------------------------------
   -- Bit helpers
   ---------------------------------------------------------------------------

   function Bit_Mask (B : Natural) return Word is
      M : Word := 1;
   begin
      for I in 1 .. B loop
         M := M * 2;
      end loop;
      return M;
   end Bit_Mask;

   procedure Set_Bit (F : in out Filter; Index : Natural) is
      W : constant Natural := Index / Word_Bits;
      B : constant Natural := Index mod Word_Bits;
      Mask : constant Word := Bit_Mask (B);
   begin
      F.Bits (W) := F.Bits (W) or Mask;
   end Set_Bit;

   function Get_Bit (F : Filter; Index : Natural) return Boolean is
      W : constant Natural := Index / Word_Bits;
      B : constant Natural := Index mod Word_Bits;
      Mask : constant Word := Bit_Mask (B);
   begin
      return (F.Bits (W) and Mask) /= 0;
   end Get_Bit;

   function Word_Popcount (W : Word) return Natural is
      X : Word := W;
      C : Natural := 0;
   begin
      while X /= 0 loop
         C := C + 1;
         X := X and (X - 1);
      end loop;
      return C;
   end Word_Popcount;

   ---------------------------------------------------------------------------
   -- Hashing (FNV-1a style + mix; double hashing)
   ---------------------------------------------------------------------------

   type U64 is mod 2**64;

   function FNV1a (Data : String) return U64 is
      Hash : U64 := 16#CBF29CE484222325#;
      Prime : constant U64 := 16#100000001B3#;
   begin
      for C of Data loop
         Hash := (Hash xor U64 (Character'Pos (C))) * Prime;
      end loop;
      return Hash;
   end FNV1a;

   function Mix64 (X : U64) return U64 is
      Z : U64 := X;
   begin
      Z := (Z xor (Z / 2**30)) * 16#BF58476D1CE4E5B9#;
      Z := (Z xor (Z / 2**27)) * 16#94D049BB133111EB#;
      Z := Z xor (Z / 2**31);
      return Z;
   end Mix64;

   function Hash_Pair_From_String (Key : String) return U64 is
   begin
      return FNV1a (Key);
   end Hash_Pair_From_String;

   function Hash_Pair_From_Natural (Key : Natural) return U64 is
      --  Encode Key as little-endian bytes into a small buffer string.
      Buf : String (1 .. 8);
      X   : U64 := U64 (Key);
   begin
      for I in Buf'Range loop
         Buf (I) := Character'Val (Natural (X mod 256));
         X := X / 256;
      end loop;
      return FNV1a (Buf);
   end Hash_Pair_From_Natural;

   --  Compute the I-th (0-based) double-hash index.
   function Double_Hash_Index
     (H1, H2 : U64;
      I      : Natural;
      M      : Positive) return Natural
   is
      --  h_i = h1 + i*h2 (mod m); keep H2 nonzero.
      A : constant U64 := H1;
      B : U64 := H2;
      S : U64;
   begin
      if B = 0 then
         B := 1;
      end if;
      S := (A + U64 (I) * B) rem U64 (M);
      return Natural (S);
   end Double_Hash_Index;

   procedure Split_Hashes (H : U64; H1, H2 : out U64) is
   begin
      H1 := H;
      H2 := Mix64 (H xor 16#9E3779B97F4A7C15#);
      if H2 = 0 then
         H2 := 1;
      end if;
   end Split_Hashes;

   procedure Add_Hash (F : in out Filter; H : U64) is
      H1, H2 : U64;
      Idx    : Natural;
   begin
      if F.Bits = null or else F.M = 0 or else F.K = 0 then
         raise Invalid_Argument with "Add: filter not initialised";
      end if;
      Split_Hashes (H, H1, H2);
      for I in 0 .. F.K - 1 loop
         Idx := Double_Hash_Index (H1, H2, I, F.M);
         Set_Bit (F, Idx);
      end loop;
      if F.N < Natural'Last then
         F.N := F.N + 1;
      end if;
   end Add_Hash;

   function Test_Hash (F : Filter; H : U64) return Boolean is
      H1, H2 : U64;
      Idx    : Natural;
   begin
      if F.Bits = null or else F.M = 0 or else F.K = 0 then
         return False;
      end if;
      Split_Hashes (H, H1, H2);
      for I in 0 .. F.K - 1 loop
         Idx := Double_Hash_Index (H1, H2, I, F.M);
         if not Get_Bit (F, Idx) then
            return False;
         end if;
      end loop;
      return True;
   end Test_Hash;

   ---------------------------------------------------------------------------
   -- Math helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Exp (X : Real) return Positive_Real is
      --  Series e^x = sum x^n / n! for |x| modest; scale by squaring.
      Max_Abs : constant Real := 40.0;
      Y       : Real := X;
      Sign_Neg : Boolean := False;
      Result  : Real;
      Term    : Real;
      N       : Natural;
   begin
      if Y > Max_Abs then
         Y := Max_Abs;
      elsif Y < -Max_Abs then
         Y := -Max_Abs;
      end if;
      if Y < 0.0 then
         Sign_Neg := True;
         Y := -Y;
      end if;
      --  Reduce by halves for faster series.
      declare
         Halves : Natural := 0;
      begin
         while Y > 1.0 loop
            Y := Y * 0.5;
            Halves := Halves + 1;
         end loop;
         Result := 1.0;
         Term := 1.0;
         N := 1;
         loop
            Term := Term * Y / Real (N);
            Result := Result + Term;
            exit when abs (Term) < 1.0E-14 or else N > 40;
            N := N + 1;
         end loop;
         for H in 1 .. Halves loop
            Result := Result * Result;
         end loop;
      end;
      if Sign_Neg then
         Result := 1.0 / Result;
      end if;
      if Result < Real'Model_Small then
         return Real'Model_Small;
      end if;
      return Positive_Real (Result);
   end Exp;

   function Ln (X : Positive_Real) return Real is
      --  Newton: solve e^y = X starting from a rough guess.
      Y     : Real;
      Ex    : Real;
      Ratio : Real;
   begin
      if X <= 0.0 then
         raise Invalid_Argument with "Ln: argument must be positive";
      end if;
      --  Rough log2-ish seed via frexp-style scaling.
      Ratio := Real (X);
      Y := 0.0;
      while Ratio > 1.5 loop
         Ratio := Ratio * 0.5;
         Y := Y + 0.693_147_180_56;  -- ln 2
      end loop;
      while Ratio < 0.7 loop
         Ratio := Ratio * 2.0;
         Y := Y - 0.693_147_180_56;
      end loop;
      --  Refine: y <- y + (x - e^y)/e^y = y + x*e^{-y} - 1
      for Iter in 1 .. 25 loop
         Ex := Exp (Y);
         Y := Y + Real (X) / Ex - 1.0;
      end loop;
      return Y;
   end Ln;

   function Ceil_To_Positive (X : Real) return Positive is
      T : Integer;
   begin
      if X <= 1.0 then
         return 1;
      end if;
      T := Integer (X);  -- rounds to nearest; adjust up if truncated
      if Real (T) < X then
         T := T + 1;
      end if;
      if T < 1 then
         return 1;
      end if;
      return Positive (T);
   end Ceil_To_Positive;

   function Round_To_Positive (X : Real) return Positive is
      T : Integer;
   begin
      if X <= 0.5 then
         return 1;
      end if;
      --  Round half up for positive X.
      T := Integer (X + 0.5);
      if T < 1 then
         return 1;
      end if;
      return Positive (T);
   end Round_To_Positive;

   Ln_2 : constant Real := 0.693_147_180_560;

   function Optimal_M
     (N                   : Positive;
      False_Positive_Rate : Probability) return Bit_Count
   is
      --  m = −n ln p / (ln 2)^2
      P   : constant Real := Real (False_Positive_Rate);
      Num : constant Real := -Real (N) * Ln (Positive_Real (P));
      Den : constant Real := Ln_2 * Ln_2;
      M_R : constant Real := Num / Den;
   begin
      return Bit_Count (Ceil_To_Positive (M_R));
   end Optimal_M;

   function Optimal_K
     (M : Bit_Count;
      N : Positive) return Hash_Count
   is
      --  k = (m/n) ln 2
      K_R : constant Real := (Real (M) / Real (N)) * Ln_2;
   begin
      return Hash_Count (Round_To_Positive (K_R));
   end Optimal_K;

   function Optimal_K_From_Rate
     (False_Positive_Rate : Probability) return Hash_Count
   is
      --  k = −ln p / ln 2
      K_R : constant Real :=
        -Ln (Positive_Real (Real (False_Positive_Rate))) / Ln_2;
   begin
      return Hash_Count (Round_To_Positive (K_R));
   end Optimal_K_From_Rate;

   function Theoretical_FPR
     (M : Bit_Count;
      K : Hash_Count;
      N : Natural) return Unit_Interval
   is
      --  (1 − e^(−k n / m))^k
      KN_M : Real;
      Inner : Real;
      Acc   : Real;
   begin
      if N = 0 then
         return 0.0;
      end if;
      KN_M := Real (K) * Real (N) / Real (M);
      Inner := 1.0 - Real (Exp (-KN_M));
      if Inner <= 0.0 then
         return 0.0;
      end if;
      if Inner >= 1.0 then
         return 1.0;
      end if;
      Acc := 1.0;
      for I in 1 .. K loop
         Acc := Acc * Inner;
         if Acc = 0.0 then
            return 0.0;
         end if;
      end loop;
      if Acc > 1.0 then
         return 1.0;
      end if;
      return Unit_Interval (Acc);
   end Theoretical_FPR;

   ---------------------------------------------------------------------------
   -- Filter API
   ---------------------------------------------------------------------------

   function Word_Length_For (M : Bit_Count) return Natural is
   begin
      return (Natural (M) + Word_Bits - 1) / Word_Bits;
   end Word_Length_For;

   function Create
     (M : Bit_Count;
      K : Hash_Count) return Filter
   is
      F : Filter;
      W : constant Natural := Word_Length_For (M);
   begin
      F.Bits := new Word_Array'(0 .. W - 1 => 0);
      F.M := Natural (M);
      F.K := Natural (K);
      F.N := 0;
      return F;
   end Create;

   function Create_For_Capacity
     (N                   : Positive;
      False_Positive_Rate : Probability) return Filter
   is
      M : constant Bit_Count := Optimal_M (N, False_Positive_Rate);
      K : constant Hash_Count := Optimal_K (M, N);
   begin
      return Create (M, K);
   end Create_For_Capacity;

   function Size (F : Filter) return Natural is
   begin
      return F.M;
   end Size;

   function Hash_Functions (F : Filter) return Natural is
   begin
      return F.K;
   end Hash_Functions;

   function Insert_Count (F : Filter) return Natural is
   begin
      return F.N;
   end Insert_Count;

   function Bits_Set (F : Filter) return Natural is
      C : Natural := 0;
   begin
      if F.Bits = null then
         return 0;
      end if;
      for W of F.Bits.all loop
         C := C + Word_Popcount (W);
      end loop;
      --  Cap at M in case unused high bits in last word were somehow set
      --  (we never set them).
      if C > F.M then
         return F.M;
      end if;
      return C;
   end Bits_Set;

   procedure Add (F : in out Filter; Key : String) is
   begin
      Add_Hash (F, Hash_Pair_From_String (Key));
   end Add;

   procedure Add (F : in out Filter; Key : Natural) is
   begin
      Add_Hash (F, Hash_Pair_From_Natural (Key));
   end Add;

   function Might_Contain (F : Filter; Key : String) return Boolean is
   begin
      return Test_Hash (F, Hash_Pair_From_String (Key));
   end Might_Contain;

   function Might_Contain (F : Filter; Key : Natural) return Boolean is
   begin
      return Test_Hash (F, Hash_Pair_From_Natural (Key));
   end Might_Contain;

   function Probably_Contains (F : Filter; Key : String) return Boolean is
   begin
      return Might_Contain (F, Key);
   end Probably_Contains;

   function Probably_Contains (F : Filter; Key : Natural) return Boolean is
   begin
      return Might_Contain (F, Key);
   end Probably_Contains;

   procedure Clear (F : in out Filter) is
   begin
      if F.Bits /= null then
         for I in F.Bits'Range loop
            F.Bits (I) := 0;
         end loop;
      end if;
      F.N := 0;
   end Clear;

   function Fill_Ratio (F : Filter) return Unit_Interval is
   begin
      if F.M = 0 then
         return 0.0;
      end if;
      return Unit_Interval (Real (Bits_Set (F)) / Real (F.M));
   end Fill_Ratio;

   function Estimated_False_Positive_Rate (F : Filter) return Unit_Interval is
   begin
      if F.M = 0 or else F.K = 0 then
         return 0.0;
      end if;
      return Theoretical_FPR
        (Bit_Count (F.M), Hash_Count (F.K), F.N);
   end Estimated_False_Positive_Rate;

   function Estimated_Cardinality (F : Filter) return Non_Negative is
      X   : Natural;
      Fr  : Real;
      Val : Real;
   begin
      if F.M = 0 or else F.K = 0 then
         return 0.0;
      end if;
      X := Bits_Set (F);
      if X = 0 then
         return 0.0;
      end if;
      if X >= F.M then
         --  Saturated: return a large estimate.
         return Real (F.M);
      end if;
      Fr := Real (X) / Real (F.M);
      --  n* = −(m/k) ln(1 − X/m)
      Val := -(Real (F.M) / Real (F.K)) * Ln (Positive_Real (1.0 - Fr));
      if Val < 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Val);
   end Estimated_Cardinality;

end Bloom_Filter;
