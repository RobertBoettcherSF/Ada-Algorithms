--  Implementation of Addition_Chain_Exponentiation.

pragma Ada_2022;

package body Addition_Chain_Exponentiation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Shortest-length table (star-chain BFS), filled once
   ---------------------------------------------------------------------------

   Shortest_Ready : Boolean := False;
   Shortest_Len   : array (1 .. Max_Shortest_N) of Natural :=
     [others => Natural'Last];
   --  Predecessor for reconstructing a shortest star chain:
   --  Pred(N) is the addend a_j such that N = Prev_Last + a_j along a
   --  recorded star step (Prev_Last stored implicitly via search).
   --  We store full chains for reconstruction instead.
   Shortest_Chains : array (1 .. Max_Shortest_N) of Chain;

   procedure Ensure_Shortest_Table
     with Global => null;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Floor_Log2 (N : Positive) return Natural is
      X : Positive := N;
      L : Natural := 0;
   begin
      while X > 1 loop
         X := X / 2;
         L := L + 1;
      end loop;
      return L;
   end Floor_Log2;

   function Popcount (N : Positive) return Natural is
      X : Natural := N;
      C : Natural := 0;
   begin
      while X > 0 loop
         if X mod 2 = 1 then
            C := C + 1;
         end if;
         X := X / 2;
      end loop;
      return C;
   end Popcount;

   function Mod_Nonneg (A, M : Long_Integer) return Long_Integer is
      R : Long_Integer := A mod M;
   begin
      if R < 0 then
         R := R + M;
      end if;
      return R;
   end Mod_Nonneg;

   function Mod_Mul (A, B, M : Long_Integer) return Long_Integer is
   begin
      return Mod_Nonneg (Mod_Nonneg (A, M) * Mod_Nonneg (B, M), M);
   end Mod_Mul;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Chain (C : Chain) return Boolean is
   begin
      if C.Last > Max_Chain_Last then
         return False;
      end if;
      if C.Elements (0) /= 1 then
         return False;
      end if;
      for I in 1 .. C.Last loop
         if C.Elements (I) <= C.Elements (I - 1) then
            return False;
         end if;
         declare
            Ok  : Boolean := False;
            Target : constant Positive := C.Elements (I);
         begin
            Find_Sum :
            for J in 0 .. I - 1 loop
               for K in 0 .. J loop
                  declare
                     Sum : constant Natural :=
                       Natural (C.Elements (J)) + Natural (C.Elements (K));
                  begin
                     if Sum = Natural (Target) then
                        Ok := True;
                        exit Find_Sum;
                     end if;
                  end;
               end loop;
            end loop Find_Sum;
            if not Ok then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Valid_Chain;

   function Chain_Mul_Count (C : Chain) return Natural is
   begin
      if not Is_Valid_Chain (C) then
         raise Invalid_Argument;
      end if;
      return C.Last;
   end Chain_Mul_Count;

   function Chain_Exponent (C : Chain) return Positive is
   begin
      if not Is_Valid_Chain (C) then
         raise Invalid_Argument;
      end if;
      return C.Elements (C.Last);
   end Chain_Exponent;

   ---------------------------------------------------------------------------
   -- Binary chain construction
   ---------------------------------------------------------------------------

   function Binary_Mul_Count (N : Positive) return Natural is
   begin
      if N = 1 then
         return 0;
      end if;
      return Floor_Log2 (N) + Popcount (N) - 1;
   end Binary_Mul_Count;

   function Build_Binary_Chain (N : Positive) return Chain is
      C : Chain;
      --  Build via the Wikipedia recursive binary method using a stack of
      --  pending values, then reverse-fill — equivalent iterative form:
      --  collect the sequence by walking down to 1, then reverse.
      Buf  : array (0 .. Max_Chain_Last) of Positive;
      Top  : Natural := 0;
      X    : Positive := N;
   begin
      --  Walk down: record every value until 1 (inclusive).
      Buf (0) := X;
      while X > 1 loop
         if X mod 2 = 0 then
            X := X / 2;
         else
            X := X - 1;
         end if;
         Top := Top + 1;
         if Top > Max_Chain_Last then
            raise Invalid_Argument;
         end if;
         Buf (Top) := X;
      end loop;
      --  Buf(Top)=1 … Buf(0)=N; reverse into chain order.
      C.Last := Top;
      for I in 0 .. Top loop
         C.Elements (I) := Buf (Top - I);
      end loop;
      return C;
   end Build_Binary_Chain;

   ---------------------------------------------------------------------------
   -- Shortest star-chain BFS (educational, N ≤ Max_Shortest_N)
   ---------------------------------------------------------------------------

   procedure Ensure_Shortest_Table is
      --  Depth-first search of star chains with pruning against Best lengths.
      --  Star step: append Last + Elements(J) for some J ≤ Last.
      Best : array (1 .. Max_Shortest_N) of Natural;
      V    : Element_Array;
      --  Keep one chain per n when first (strictly) improved.
      Saved : array (1 .. Max_Shortest_N) of Chain;

      procedure Search (Last : Natural) is
         Cur : constant Positive := V (Last);
      begin
         if Cur <= Max_Shortest_N and then Last < Best (Cur) then
            Best (Cur) := Last;
            Saved (Cur).Last := Last;
            for I in 0 .. Last loop
               Saved (Cur).Elements (I) := V (I);
            end loop;
         end if;

         if Last >= Max_Chain_Last then
            return;
         end if;
         --  Depth bound: ℓ(n) ≤ Binary_Mul_Count ≤ ⌊log2 n⌋+ν(n)-1 ≤ 31 for n≤32
         if Last >= 12 then
            return;
         end if;

         for J in 0 .. Last loop
            declare
               Sum : constant Natural :=
                 Natural (Cur) + Natural (V (J));
            begin
               if Sum >= 1 and then Sum <= Max_Shortest_N then
                  --  Explore if this length is at most the best known for Sum
                  --  (equal length alternative chains matter for extensions).
                  if Last + 1 <= Best (Sum) then
                     V (Last + 1) := Positive (Sum);
                     Search (Last + 1);
                  end if;
               end if;
            end;
         end loop;
      end Search;

   begin
      if Shortest_Ready then
         return;
      end if;

      for I in 1 .. Max_Shortest_N loop
         Best (I) := Binary_Mul_Count (I);
         Saved (I) := Build_Binary_Chain (I);
      end loop;
      Best (1) := 0;
      Saved (1).Last := 0;
      Saved (1).Elements (0) := 1;

      V (0) := 1;
      Search (0);

      for I in 1 .. Max_Shortest_N loop
         Shortest_Len (I) := Best (I);
         Shortest_Chains (I) := Saved (I);
      end loop;
      Shortest_Ready := True;
   end Ensure_Shortest_Table;

   function Shortest_Chain_Length (N : Positive) return Natural is
   begin
      if N > Max_Shortest_N then
         raise Invalid_Argument;
      end if;
      Ensure_Shortest_Table;
      return Shortest_Len (N);
   end Shortest_Chain_Length;

   function Build_Shortest_Chain (N : Positive) return Chain is
   begin
      if N > Max_Shortest_N then
         raise Invalid_Argument;
      end if;
      Ensure_Shortest_Table;
      return Shortest_Chains (N);
   end Build_Shortest_Chain;

   ---------------------------------------------------------------------------
   -- Evaluation
   ---------------------------------------------------------------------------

   function Evaluate_Chain
     (Base : Long_Integer;
      C    : Chain) return Long_Integer
   is
      Powers : array (0 .. Max_Chain_Last) of Long_Integer;
   begin
      if not Is_Valid_Chain (C) then
         raise Invalid_Argument;
      end if;
      --  Base^1 = Base
      Powers (0) := Base;
      for I in 1 .. C.Last loop
         declare
            Target : constant Positive := C.Elements (I);
            Found  : Boolean := False;
         begin
            Find_Factors :
            for J in 0 .. I - 1 loop
               for K in 0 .. J loop
                  if Natural (C.Elements (J)) + Natural (C.Elements (K))
                    = Natural (Target)
                  then
                     Powers (I) := Powers (J) * Powers (K);
                     Found := True;
                     exit Find_Factors;
                  end if;
               end loop;
            end loop Find_Factors;
            if not Found then
               raise Invalid_Argument;
            end if;
         end;
      end loop;
      return Powers (C.Last);
   end Evaluate_Chain;

   function Evaluate_Chain_Mod
     (Base, Modulus : Long_Integer;
      C             : Chain) return Long_Integer
   is
      Powers : array (0 .. Max_Chain_Last) of Long_Integer;
   begin
      if Modulus <= 1 then
         raise Invalid_Argument;
      end if;
      if not Is_Valid_Chain (C) then
         raise Invalid_Argument;
      end if;
      Powers (0) := Mod_Nonneg (Base, Modulus);
      for I in 1 .. C.Last loop
         declare
            Target : constant Positive := C.Elements (I);
            Found  : Boolean := False;
         begin
            Find_Factors :
            for J in 0 .. I - 1 loop
               for K in 0 .. J loop
                  if Natural (C.Elements (J)) + Natural (C.Elements (K))
                    = Natural (Target)
                  then
                     Powers (I) := Mod_Mul (Powers (J), Powers (K), Modulus);
                     Found := True;
                     exit Find_Factors;
                  end if;
               end loop;
            end loop Find_Factors;
            if not Found then
               raise Invalid_Argument;
            end if;
         end;
      end loop;
      return Powers (C.Last);
   end Evaluate_Chain_Mod;

   function Power_By_Chain
     (Base : Long_Integer;
      Exp  : Positive) return Long_Integer
   is
   begin
      return Evaluate_Chain (Base, Build_Binary_Chain (Exp));
   end Power_By_Chain;

   function Power_By_Chain_Mod
     (Base, Exp, Modulus : Long_Integer) return Long_Integer
   is
   begin
      if Exp <= 0 then
         raise Invalid_Argument;
      end if;
      return Evaluate_Chain_Mod
        (Base, Modulus, Build_Binary_Chain (Positive (Exp)));
   end Power_By_Chain_Mod;

   function Power_By_Shortest_Chain
     (Base : Long_Integer;
      Exp  : Positive) return Long_Integer
   is
   begin
      return Evaluate_Chain (Base, Build_Shortest_Chain (Exp));
   end Power_By_Shortest_Chain;

   function Power_By_Shortest_Chain_Mod
     (Base, Exp, Modulus : Long_Integer) return Long_Integer
   is
   begin
      if Exp <= 0 then
         raise Invalid_Argument;
      end if;
      return Evaluate_Chain_Mod
        (Base, Modulus, Build_Shortest_Chain (Positive (Exp)));
   end Power_By_Shortest_Chain_Mod;

   ---------------------------------------------------------------------------
   -- Tiny binary / naive comparison powers
   ---------------------------------------------------------------------------

   function Power_Binary
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
   is
      Result : Long_Integer := 1;
      B      : Long_Integer := Base;
      E      : Natural := Exp;
   begin
      while E > 0 loop
         if E mod 2 = 1 then
            Result := Result * B;
         end if;
         E := E / 2;
         if E > 0 then
            B := B * B;
         end if;
      end loop;
      return Result;
   end Power_Binary;

   function Pow_Mod
     (Base, Exp, Modulus : Long_Integer) return Long_Integer
   is
      Result : Long_Integer := 1;
      B      : Long_Integer;
      E      : Long_Integer := Exp;
   begin
      if Modulus <= 1 then
         raise Invalid_Argument;
      end if;
      if Exp < 0 then
         raise Invalid_Argument;
      end if;
      B := Mod_Nonneg (Base, Modulus);
      if Exp = 0 then
         return 1;
      end if;
      while E > 0 loop
         if E mod 2 = 1 then
            Result := Mod_Mul (Result, B, Modulus);
         end if;
         E := E / 2;
         if E > 0 then
            B := Mod_Mul (B, B, Modulus);
         end if;
      end loop;
      return Result;
   end Pow_Mod;

   function Power_Naive
     (Base : Long_Integer;
      Exp  : Natural) return Long_Integer
   is
      Result : Long_Integer := 1;
   begin
      if Exp > Max_Naive_Exp then
         raise Invalid_Argument;
      end if;
      for I in 1 .. Exp loop
         Result := Result * Base;
      end loop;
      return Result;
   end Power_Naive;

end Addition_Chain_Exponentiation;
