pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Longest_Repeating_Character_Replacement; use Longest_Repeating_Character_Replacement;
procedure Tests is
   Fails : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 20 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   function To_Text (S : String; First : Index := 1) return Text_Array is
      R : Text_Array (First .. First + S'Length - 1);
   begin
      for P in S'Range loop
         R (First + P - S'First) := S (P);
      end loop;
      return R;
   end To_Text;

   --  Reference: every window; it qualifies when its length minus the count
   --  of its most frequent character is at most K.
   function Ref (S : String; K : Natural) return Natural is
      Best : Natural := 0;
   begin
      for L in S'Range loop
         for R in L .. S'Last loop
            declare
               Most : Natural := 0;
            begin
               for C in Character range 'A' .. 'Z' loop
                  declare
                     N : Natural := 0;
                  begin
                     for P in L .. R loop
                        if S (P) = C then
                           N := N + 1;
                        end if;
                     end loop;
                     Most := Natural'Max (Most, N);
                  end;
               end loop;
               if R - L + 1 - Most <= K then
                  Best := Natural'Max (Best, R - L + 1);
               end if;
            end;
         end loop;
      end loop;
      return Best;
   end Ref;

   procedure Compare (S : String; K : Natural) is
   begin
      Check (Longest (To_Text (S), K) = Ref (S, K), "'" & S & "' K =" & K'Image);
      Check (Longest (To_Text (S, 9), K) = Ref (S, K), "'" & S & "' at First 9, K =" & K'Image);
   end Compare;

   procedure Exhaustive (N, Letters : Natural; K : Natural) is
      S    : String (1 .. N) := [others => 'A'];
      Done : Boolean;
   begin
      loop
         Compare (S, K);
         Done := True;
         for P in reverse S'Range loop
            if S (P) < Character'Val (Character'Pos ('A') + Letters - 1) then
               S (P) := Character'Succ (S (P));
               S (P + 1 .. N) := [others => 'A'];
               Done := False;
               exit;
            end if;
         end loop;
         exit when Done;
      end loop;
   end Exhaustive;

   Seed  : constant := 20261009;
   State : Long_Long_Integer := Seed;
   function Next (M : Positive) return Natural is
   begin
      State := (State * 1103515245 + 12345) mod 2**31;
      return Natural (State / 65536 mod Long_Long_Integer (M));
   end Next;
begin
   --  The folder's original cases (one replacement)
   Check (Longest (To_Text ("AABABBAA"), 1) = 4, "AABABBAA");
   Check (Longest (To_Text ("ABCDEFGH"), 1) = 2, "ABCDEFGH");
   Check (Longest (To_Text ("AAAAAAAA"), 1) = 8, "AAAAAAAA");
   Check (Longest (To_Text ("ABABABAB"), 1) = 3, "ABABABAB");
   Check (Longest (To_Text ("AABAABAA"), 1) = 5, "AABAABAA");
   Check (Longest (To_Text ("ABCADABC"), 1) = 3, "ABCADABC");
   Check (Longest (To_Text ("AAABBBAA"), 1) = 4, "AAABBBAA");
   Check (Longest (To_Text ("ABCDABCD"), 1) = 2, "ABCDABCD");
   --  Other K and lengths
   Check (Longest (To_Text ("ABAB"), 2) = 4, "ABAB K=2");
   Check (Longest (To_Text ("AABABBA"), 1) = 4, "AABABBA K=1");
   Check (Longest (To_Text (""), 3) = 0, "empty");
   Check (Longest (To_Text ("Z"), 0) = 1, "Z K=0");
   Check (Longest (To_Text ("ABBBCA"), 0) = 3, "ABBBCA K=0");
   Check (Longest (To_Text ("ABC"), 10) = 3, "K larger than text");

   --  Exhaustive: {A,B,C} up to length 8, K = 0 .. 3
   for K in 0 .. 3 loop
      for N in 0 .. 8 loop
         Exhaustive (N, 3, K);
      end loop;
   end loop;

   --  Seeded random (seed 20261009): 5,000 texts up to length 40 over 2..5
   --  letters, K = 0 .. 6
   for T in 1 .. 5_000 loop
      declare
         N       : constant Natural := Next (41);
         Letters : constant Positive := 2 + Next (4);
         S       : String (1 .. N);
      begin
         for P in S'Range loop
            S (P) := Character'Val (Character'Pos ('A') + Next (Letters));
         end loop;
         Compare (S, Next (7));
      end;
   end loop;

   if Fails = 0 then
      Put_Line ("PASS Ada-SPARK-Longest-Repeating-Character-Replacement");
   else
      Put_Line ("FAILED" & Fails'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
