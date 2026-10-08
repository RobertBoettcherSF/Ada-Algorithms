--  Own tests for Fibonacci_Number.Compute (written for this repository;
--  see tests/SOURCES.txt). Assumption: Compute is wrong for some n, or
--  only right for the three values tests.adb checks. Expected values come
--  from an independent method, fast doubling in 64-bit integers
--  (F (2k) = F (k) (2 F (k + 1) - F (k)), F (2k + 1) = F (k)**2 + F (k + 1)**2),
--  and from published values of the sequence (OEIS A000045). Properties
--  checked on the outputs: the defining recurrence and Cassini's identity
--  F (n - 1) F (n + 1) - F (n)**2 = (-1)**n.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Fibonacci_Number; use Fibonacci_Number;

procedure Own_Checks is
   subtype Big is Long_Long_Integer;
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  (F (K), F (K + 1)) by fast doubling over the bits of K.
   procedure Doubling (K : Natural; F, G : out Big) is
   begin
      if K = 0 then
         F := 0;
         G := 1;
         return;
      end if;
      declare
         A, B : Big;
      begin
         Doubling (K / 2, A, B);
         declare
            C : constant Big := A * (2 * B - A);   --  F (2m)
            D : constant Big := A * A + B * B;     --  F (2m + 1)
         begin
            if K mod 2 = 0 then
               F := C;
               G := D;
            else
               F := D;
               G := C + D;
            end if;
         end;
      end;
   end Doubling;

   function Ref (K : Natural) return Big is
      F, G : Big;
   begin
      Doubling (K, F, G);
      return F;
   end Ref;

   procedure Expect (Ok : Boolean; What : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         Put_Line ("FAIL " & What);
      end if;
   end Expect;

   type Pair is record
      N : Input;
      V : Result;
   end record;
   --  Published values (OEIS A000045).
   Published : constant array (Positive range <>) of Pair :=
     [(0, 0), (1, 1), (2, 1), (3, 2), (7, 13), (12, 144), (19, 4_181),
      (25, 75_025), (31, 1_346_269), (32, 2_178_309)];
begin
   for N in Input loop
      Expect (Big (Compute (N)) = Ref (N),
              "Compute" & N'Image & " =" & Compute (N)'Image
              & ", fast doubling gives" & Ref (N)'Image);
   end loop;
   for N in 2 .. Input'Last loop
      Expect (Compute (N) = Compute (N - 1) + Compute (N - 2),
              "recurrence at" & N'Image);
   end loop;
   for N in 1 .. Input'Last - 1 loop
      Expect (Big (Compute (N - 1)) * Big (Compute (N + 1))
              - Big (Compute (N)) ** 2 = (if N mod 2 = 0 then 1 else -1),
              "Cassini at" & N'Image);
   end loop;
   for P of Published loop
      Expect (Compute (P.N) = P.V, "published value F (" & P.N'Image & ")");
   end loop;

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image
             & " checks (fast doubling, recurrence, Cassini, published values)");
end Own_Checks;
