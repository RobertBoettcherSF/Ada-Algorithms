--  Sieve of Eratosthenes — Ada 2023 body.
--  Classic sieve from p² with step p; optional odds-only variant.

pragma Ada_2022;

package body Sieve_Of_Eratosthenes
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
      Lo : Natural := 0;
      Hi : Natural := N;
      Mid : Natural;
   begin
      if N = 0 then
         return 0;
      end if;
      --  Hi starts at N; for N ≥ 2, sqrt(N) ≤ N/2 + 1, but binary search
      --  on 0 .. N is fine for educational Max_N.
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
   --  Classic sieve
   ------------------------------------------------------------------

   function Sieve (N : Natural) return Flag_Array is
      Flags : Flag_Array (0 .. N) := (others => True);
      Root  : Natural;
      M     : Natural;
   begin
      Ensure_Valid_N (N);
      Flags (0) := False;
      Flags (1) := False;
      Root := Floor_Sqrt (N);
      for P in 2 .. Root loop
         if Flags (P) then
            M := P * P;
            while M <= N loop
               Flags (M) := False;
               M := M + P;
            end loop;
         end if;
      end loop;
      return Flags;
   end Sieve;

   function Count_Primes (N : Natural) return Natural is
      Flags : constant Flag_Array := Sieve (N);
   begin
      return Count_True (Flags);
   end Count_Primes;

   function Primes_Up_To (N : Natural) return Prime_List is
      Flags : constant Flag_Array := Sieve (N);
      Count : constant Natural := Count_True (Flags);
      Result : Prime_List (1 .. Count);
      J : Natural := 0;
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

   ------------------------------------------------------------------
   --  Odds-only bonus
   ------------------------------------------------------------------

   function Sieve_Odds (N : Natural) return Flag_Array is
      --  Mark only odd composites; even numbers > 2 are composite.
      --  For odd p, step 2p keeps candidates odd.
      Flags : Flag_Array (0 .. N) := (others => False);
      Root  : Natural;
      M     : Natural;
      Step  : Natural;
   begin
      Ensure_Valid_N (N);
      if N >= 2 then
         Flags (2) := True;
      end if;
      for I in 3 .. N loop
         if I rem 2 = 1 then
            Flags (I) := True;
         end if;
      end loop;
      Root := Floor_Sqrt (N);
      declare
         P : Natural := 3;
      begin
         while P <= Root loop
            if Flags (P) then
               M := P * P;
               Step := 2 * P;
               while M <= N loop
                  Flags (M) := False;
                  M := M + Step;
               end loop;
            end if;
            P := P + 2;
         end loop;
      end;
      return Flags;
   end Sieve_Odds;

end Sieve_Of_Eratosthenes;
