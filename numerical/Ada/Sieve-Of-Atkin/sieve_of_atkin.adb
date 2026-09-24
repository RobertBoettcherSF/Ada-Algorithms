--  Sieve of Atkin — Ada 2023 body.
--  Educational mod-12 quadratic form (Atkin–Bernstein / Wikipedia).

pragma Ada_2022;

package body Sieve_Of_Atkin
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------

   procedure Ensure_Valid_N (N : Natural) is
   begin
      if N < 2 or else N > Max_N then
         raise Invalid_Argument;
      end if;
   end Ensure_Valid_N;

   function Floor_Sqrt (N : Natural) return Natural is
      --  Binary search for largest R with R*R ≤ N (overflow-safe via
      --  comparing R ≤ N / R when R > 0).
      Lo  : Natural := 0;
      Hi  : Natural := N;
      Mid : Natural;
   begin
      if N = 0 then
         return 0;
      end if;
      while Lo < Hi loop
         Mid := Lo + (Hi - Lo + 1) / 2;
         if Mid > 0 and then Mid > N / Mid then
            Hi := Mid - 1;
         else
            Lo := Mid;
         end if;
      end loop;
      return Lo;
   end Floor_Sqrt;

   function Count_True (Flags : Flag_Array) return Natural is
      C : Natural := 0;
   begin
      for I in Flags'Range loop
         if Flags (I) then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Count_True;

   ------------------------------------------------------------------
   --  Atkin sieve (mod-12 educational form)
   ------------------------------------------------------------------

   function Sieve (N : Natural) return Flag_Array is
      Flags : Flag_Array (0 .. N) := (others => False);
      Root  : Natural;
      X     : Natural;
      Y     : Natural;
      Num   : Natural;
      XX    : Natural;
      R     : Natural;
      Sq    : Natural;
      M     : Natural;
      Rem12 : Natural;
   begin
      Ensure_Valid_N (N);
      Root := Floor_Sqrt (N);

      --  Quadratic toggles for x, y ≥ 1.
      X := 1;
      while X <= Root loop
         XX := X * X;
         Y := 1;
         while Y <= Root loop
            --  n = 4x² + y² : toggle if n mod 12 ∈ {1, 5}
            Num := 4 * XX + Y * Y;
            if Num <= N then
               Rem12 := Num rem 12;
               if Rem12 = 1 or else Rem12 = 5 then
                  Flags (Num) := not Flags (Num);
               end if;
            end if;

            --  n = 3x² + y² : toggle if n mod 12 = 7
            Num := 3 * XX + Y * Y;
            if Num <= N then
               if Num rem 12 = 7 then
                  Flags (Num) := not Flags (Num);
               end if;
            end if;

            --  n = 3x² − y² (x > y) : toggle if n mod 12 = 11
            if X > Y then
               Num := 3 * XX - Y * Y;
               if Num <= N then
                  if Num rem 12 = 11 then
                     Flags (Num) := not Flags (Num);
                  end if;
               end if;
            end if;

            Y := Y + 1;
         end loop;
         X := X + 1;
      end loop;

      --  Eliminate multiples of squares of primes (r ≥ 5, r² ≤ N).
      R := 5;
      while R <= Root loop
         if Flags (R) then
            Sq := R * R;
            M := Sq;
            while M <= N loop
               Flags (M) := False;
               M := M + Sq;
            end loop;
         end if;
         R := R + 1;
      end loop;

      --  Hardcode 2 and 3; clear 0, 1, 4 (4 never toggled productively).
      Flags (0) := False;
      Flags (1) := False;
      if N >= 2 then
         Flags (2) := True;
      end if;
      if N >= 3 then
         Flags (3) := True;
      end if;
      if N >= 4 then
         Flags (4) := False;
      end if;

      return Flags;
   end Sieve;

   function Count_Primes (N : Natural) return Natural is
      Flags : constant Flag_Array := Sieve (N);
   begin
      return Count_True (Flags);
   end Count_Primes;

   function Primes_Up_To (N : Natural) return Prime_List is
      Flags  : constant Flag_Array := Sieve (N);
      Count  : constant Natural := Count_True (Flags);
      Result : Prime_List (1 .. Count);
      J      : Natural := 0;
   begin
      for I in 2 .. N loop
         if Flags (I) then
            J := J + 1;
            Result (J) := Positive (I);
         end if;
      end loop;
      return Result;
   end Primes_Up_To;

   procedure Fill_Primes
     (N      : Natural;
      Primes : out Prime_Buffer;
      Last   : out Natural)
   is
      Flags : constant Flag_Array := Sieve (N);
   begin
      Last := 0;
      Primes := [others => 1];  -- definite out; unused slots stay 1
      for I in 2 .. N loop
         if Flags (I) then
            Last := Last + 1;
            Primes (Last) := Positive (I);
         end if;
      end loop;
   end Fill_Primes;

   function Nth_Prime (N : Natural; K : Positive) return Positive is
      Flags : constant Flag_Array := Sieve (N);
      Seen  : Natural := 0;
   begin
      for I in 2 .. N loop
         if Flags (I) then
            Seen := Seen + 1;
            if Seen = Natural (K) then
               return Positive (I);
            end if;
         end if;
      end loop;
      raise Invalid_Argument;
   end Nth_Prime;

   function Is_Prime_In_Sieve
     (Flags : Flag_Array;
      K     : Natural) return Boolean
   is
   begin
      if K < Flags'First or else K > Flags'Last then
         raise Invalid_Argument;
      end if;
      return Flags (K);
   end Is_Prime_In_Sieve;

end Sieve_Of_Atkin;
