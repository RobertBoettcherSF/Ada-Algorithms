--  Standalone test suite for Sieve_Of_Atkin (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Sieve_Of_Atkin; use Sieve_Of_Atkin;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views of constants (avoid -gnatwc constant-condition).
   function Cap return Natural is (Max_N);

   procedure Expect_Invalid (Label : String; N : Natural) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Natural := Count_Primes (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument: " & Label);
   end Expect_Invalid;

   --  Tiny inline Eratosthenes oracle (not with sibling package).
   function Eratosthenes_Count (N : Natural) return Natural is
      Flags : array (0 .. N) of Boolean := (others => True);
      P, M  : Natural;
      C     : Natural := 0;
   begin
      if N < 2 then
         return 0;
      end if;
      Flags (0) := False;
      Flags (1) := False;
      P := 2;
      while P * P <= N loop
         if Flags (P) then
            M := P * P;
            while M <= N loop
               Flags (M) := False;
               M := M + P;
            end loop;
         end if;
         P := P + 1;
      end loop;
      for I in 2 .. N loop
         if Flags (I) then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Eratosthenes_Count;

begin
   Ada.Text_IO.Put_Line ("Sieve_Of_Atkin test suite");
   Ada.Text_IO.Put_Line ("=========================");

   ------------------------------------------------------------------
   Section ("1. Constants / Floor_Sqrt");
   ------------------------------------------------------------------
   Check (Cap = 200_000, "Max_N = 200_000");
   Check (Limit'First = 0, "Limit'First = 0");
   Check (Limit'Last = Cap, "Limit'Last = Max_N");
   Check (Floor_Sqrt (0) = 0, "Floor_Sqrt 0");
   Check (Floor_Sqrt (1) = 1, "Floor_Sqrt 1");
   Check (Floor_Sqrt (2) = 1, "Floor_Sqrt 2");
   Check (Floor_Sqrt (3) = 1, "Floor_Sqrt 3");
   Check (Floor_Sqrt (4) = 2, "Floor_Sqrt 4");
   Check (Floor_Sqrt (8) = 2, "Floor_Sqrt 8");
   Check (Floor_Sqrt (9) = 3, "Floor_Sqrt 9");
   Check (Floor_Sqrt (15) = 3, "Floor_Sqrt 15");
   Check (Floor_Sqrt (16) = 4, "Floor_Sqrt 16");
   Check (Floor_Sqrt (100) = 10, "Floor_Sqrt 100");
   Check (Floor_Sqrt (10_000) = 100, "Floor_Sqrt 10000");
   Check (Floor_Sqrt (200_000) = 447, "Floor_Sqrt 200000");

   ------------------------------------------------------------------
   Section ("2. Invalid_Argument");
   ------------------------------------------------------------------
   Expect_Invalid ("N=0", 0);
   Expect_Invalid ("N=1", 1);
   Expect_Invalid ("N=Max_N+1", Cap + 1);
   Expect_Invalid ("N=Max_N+100", Cap + 100);

   declare
      Raised : Boolean := False;
   begin
      begin
         Ensure_Valid_N (0);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Ensure_Valid_N 0");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         Ensure_Valid_N (Cap);
         Raised := False;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (not Raised, "Ensure_Valid_N Max_N ok");
   end;

   ------------------------------------------------------------------
   Section ("3. Small sieve flags (N=10)");
   ------------------------------------------------------------------
   declare
      F : constant Flag_Array := Sieve (10);
   begin
      Check (F'First = 0 and F'Last = 10, "Sieve(10) range 0..10");
      Check (not F (0), "0 not prime");
      Check (not F (1), "1 not prime");
      Check (F (2), "2 prime");
      Check (F (3), "3 prime");
      Check (not F (4), "4 composite");
      Check (F (5), "5 prime");
      Check (not F (6), "6 composite");
      Check (F (7), "7 prime");
      Check (not F (8), "8 composite");
      Check (not F (9), "9 composite");
      Check (not F (10), "10 composite");
      Check (Is_Prime_In_Sieve (F, 2), "Is_Prime_In_Sieve 2");
      Check (not Is_Prime_In_Sieve (F, 9), "Is_Prime_In_Sieve 9");
      Check (not Is_Prime_In_Sieve (F, 1), "Is_Prime_In_Sieve 1");
   end;

   declare
      Raised : Boolean := False;
      F : constant Flag_Array := Sieve (10);
   begin
      begin
         declare
            B : constant Boolean := Is_Prime_In_Sieve (F, 11);
            pragma Unreferenced (B);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Is_Prime_In_Sieve out of range");
   end;

   ------------------------------------------------------------------
   Section ("4. Known π(N)");
   ------------------------------------------------------------------
   Check (Count_Primes (10) = 4, "π(10)=4");
   Check (Count_Primes (100) = 25, "π(100)=25");
   Check (Count_Primes (1_000) = 168, "π(1000)=168");
   Check (Count_Primes (10_000) = 1_229, "π(10000)=1229");
   Check (Count_Primes (2) = 1, "π(2)=1");
   Check (Count_Primes (3) = 2, "π(3)=2");
   Check (Count_Primes (20) = 8, "π(20)=8");
   Check (Count_Primes (30) = 10, "π(30)=10");

   ------------------------------------------------------------------
   Section ("5. First primes / list");
   ------------------------------------------------------------------
   declare
      P : constant Prime_List := Primes_Up_To (23);
   begin
      Check (P'Length = 9, "Primes_Up_To(23) length 9");
      Check (P (1) = 2, "1st prime=2");
      Check (P (2) = 3, "2nd prime=3");
      Check (P (3) = 5, "3rd prime=5");
      Check (P (4) = 7, "4th prime=7");
      Check (P (5) = 11, "5th prime=11");
      Check (P (6) = 13, "6th prime=13");
      Check (P (7) = 17, "7th prime=17");
      Check (P (8) = 19, "8th prime=19");
      Check (P (9) = 23, "9th prime=23");
   end;

   declare
      P : constant Prime_List := Primes_Up_To (10);
   begin
      Check (P'Length = 4, "Primes_Up_To(10) length");
      Check (P (1) = 2 and P (2) = 3 and P (3) = 5 and P (4) = 7,
             "Primes_Up_To(10) values");
   end;

   ------------------------------------------------------------------
   Section ("6. Composites / primes via flags");
   ------------------------------------------------------------------
   declare
      F : constant Flag_Array := Sieve (100);
   begin
      Check (not Is_Prime_In_Sieve (F, 9), "9 composite");
      Check (not Is_Prime_In_Sieve (F, 15), "15 composite");
      Check (not Is_Prime_In_Sieve (F, 25), "25 composite");
      Check (not Is_Prime_In_Sieve (F, 49), "49 composite");
      Check (not Is_Prime_In_Sieve (F, 91), "91=7*13 composite");
      Check (not Is_Prime_In_Sieve (F, 1), "1 not prime");
      Check (not Is_Prime_In_Sieve (F, 0), "0 not prime");
      Check (Is_Prime_In_Sieve (F, 97), "97 prime");
      Check (Is_Prime_In_Sieve (F, 89), "89 prime");
      Check (Is_Prime_In_Sieve (F, 2), "2 prime in 100");
      Check (Is_Prime_In_Sieve (F, 53), "53 prime");
      Check (not Is_Prime_In_Sieve (F, 100), "100 composite");
      Check (not Is_Prime_In_Sieve (F, 51), "51 composite");
   end;

   ------------------------------------------------------------------
   Section ("7. Idempotent Count vs List length");
   ------------------------------------------------------------------
   declare
      Ns : constant array (Positive range <>) of Natural :=
        [2, 10, 20, 50, 100, 200, 500, 1_000, 5_000, 10_000];
   begin
      for N of Ns loop
         declare
            C : constant Natural := Count_Primes (N);
            L : constant Prime_List := Primes_Up_To (N);
         begin
            Check (C = L'Length,
                   "Count=List length N=" & Natural'Image (N));
         end;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("8. Fill_Primes / Nth_Prime");
   ------------------------------------------------------------------
   declare
      Buf  : Prime_Buffer;
      Last : Natural;
   begin
      Fill_Primes (30, Buf, Last);
      Check (Last = 10, "Fill_Primes(30) Last=10");
      Check (Buf (1) = 2, "Fill first=2");
      Check (Buf (10) = 29, "Fill last=29");
      Check (Nth_Prime (30, 1) = 2, "Nth_Prime 1");
      Check (Nth_Prime (30, 10) = 29, "Nth_Prime 10");
      Check (Nth_Prime (100, 25) = 97, "25th prime ≤100 is 97");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            P : constant Positive := Nth_Prime (10, 5);
            pragma Unreferenced (P);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Nth_Prime K>π(N)");
   end;

   ------------------------------------------------------------------
   Section ("9. Agree with inline Eratosthenes");
   ------------------------------------------------------------------
   declare
      Ns : constant array (Positive range <>) of Natural :=
        [2, 3, 10, 25, 100, 1_000, 10_000];
   begin
      for N of Ns loop
         Check (Count_Primes (N) = Eratosthenes_Count (N),
                "Atkin=Eratosthenes π N=" & Natural'Image (N));
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("10. Larger checks / Max_N smoke");
   ------------------------------------------------------------------
   Check (Count_Primes (100_000) = 9_592, "π(100000)=9592");
   declare
      C : constant Natural := Count_Primes (Cap);
      L : constant Prime_List := Primes_Up_To (1_000);
   begin
      Check (C = 17_984, "π(200000)=17984");
      Check (L'Length = 168, "Primes_Up_To(1000) length");
      Check (L (168) = 997, "168th prime ≤1000 is 997");
   end;

   --  Monotonicity of π
   Check (Count_Primes (50) <= Count_Primes (100), "π mono 50≤100");
   Check (Count_Primes (100) <= Count_Primes (1_000), "π mono 100≤1000");
   Check (Count_Primes (1_000) <= Count_Primes (10_000), "π mono 1k≤10k");

   --  All listed primes ≤ 100
   declare
      F : constant Flag_Array := Sieve (100);
      Expected : constant array (Positive range <>) of Positive :=
        [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47,
         53, 59, 61, 67, 71, 73, 79, 83, 89, 97];
   begin
      for E of Expected loop
         Check (Is_Prime_In_Sieve (F, E),
                "prime " & Positive'Image (E));
      end loop;
      Check (Expected'Length = Count_Primes (100), "25 primes listed");
   end;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("================================");
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
