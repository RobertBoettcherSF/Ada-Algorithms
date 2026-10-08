--  Own checks (see tests/SOURCES.txt). Assume Fibonacci_Search is wrong; compare
--  every answer with a linear scan of the array (a different method):
--  the result must be 0 exactly when the key is absent, and otherwise an
--  index holding the key. Inputs: every nondecreasing array of length 0 .. 7
--  over 0 .. 3 with keys -1 .. 4; seeded random sorted arrays up to Max_N
--  with small, wide and Integer-extreme value ranges (duplicates, gaps,
--  keys below / above / between elements and Integer'First / Integer'Last).
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Fibonacci_Search; use Fibonacci_Search;

procedure Own_Checks
  with SPARK_Mode => Off
is
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S)
                            & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed    : Long_Long_Integer := AA_Seed (20261008);
   Checked : Natural := 0;

   function Rand (Lo, Hi : Integer) return Integer is   --  Park-Miller
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Rand;

   procedure Fail (What : String; A : Element_Array; Key : Integer) is
   begin
      Ada.Text_IO.Put ("FAIL own check: " & What & " for key" & Key'Image & ", array");
      for X of A loop
         Ada.Text_IO.Put (X'Image);
      end loop;
      Ada.Text_IO.New_Line;
      raise Program_Error;
   end Fail;

   procedure Check_Find (A : Element_Array; Key : Integer; R : Index; What : String) is
      Present : Boolean := False;
   begin
      for X of A loop
         Present := Present or else X = Key;
      end loop;
      Checked := Checked + 1;
      if R > A'Last then
         Fail (What & " returned an index past A'Last", A, Key);
      elsif R = 0 and then Present then
         Fail (What & " missed a key that is present", A, Key);
      elsif R > 0 and then A (R) /= Key then
         Fail (What & " returned an index that does not hold the key", A, Key);
      end if;
   end Check_Find;


   procedure Check_All (A : Element_Array; Key : Integer) is
   begin
      Check_Find (A, Key, Find (A, Key), "Find");
   end Check_All;

   procedure Sort_Up (A : in out Element_Array) is   --  insertion sort (reference only)
      T : Integer; J : Integer;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I); J := I - 1;
         while J >= A'First and then A (J) > T loop
            A (J + 1) := A (J); J := J - 1;
         end loop;
         A (J + 1) := T;
      end loop;
   end Sort_Up;

begin
   --  1. every nondecreasing array of length 0 .. 7 over 0 .. 3
   for N in 0 .. 7 loop
      declare
         A    : Element_Array (1 .. N) := [others => 0];
         Done : Boolean := False;
         Ok   : Boolean;
      begin
         while not Done loop
            Ok := True;
            for I in 1 .. N - 1 loop
               Ok := Ok and then A (I) <= A (I + 1);
            end loop;
            if Ok then
               for Key in -1 .. 4 loop
                  Check_All (A, Key);
               end loop;
            end if;
            Done := True;
            for I in reverse A'Range loop
               if A (I) < 3 then
                  A (I) := A (I) + 1; Done := False; exit;
               end if;
               A (I) := 0;
            end loop;
         end loop;
      end;
   end loop;

   --  2. random sorted arrays: small, wide and Integer-extreme ranges
   for Round in 1 .. 800 loop
      declare
         N    : constant Natural := Rand (0, Max_N);
         A    : Element_Array (1 .. N);
         Mode : constant Natural := Round mod 4;
      begin
         for I in A'Range loop
            A (I) :=
              (case Mode is
                 when 0      => Rand (-3, 3),
                 when 1      => Rand (-1_000_000_000, 1_000_000_000),
                 when 2      => (if Rand (0, 1) = 0 then Integer'First + Rand (0, 5)
                                 else Integer'Last - Rand (0, 5)),
                 when others => Rand (Integer'First, Integer'Last));
         end loop;
         Sort_Up (A);
         Check_All (A, Integer'First);
         Check_All (A, Integer'Last);
         Check_All (A, 0);
         --  six sampled elements, each also +-1 (gaps / duplicates / edges)
         for S in 1 .. (if N = 0 then 0 else 6) loop
            declare
               I : constant Positive := (case S is when 1 => 1, when 2 => N, when others => Rand (1, N));
            begin
               Check_All (A, A (I));
               if A (I) > Integer'First then
                  Check_All (A, A (I) - 1);
               end if;
               if A (I) < Integer'Last then
                  Check_All (A, A (I) + 1);
               end if;
            end;
         end loop;
      end;
   end loop;

   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image & " calls (linear-scan reference)");
end Own_Checks;
