pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Repeated_Substring_Pattern; use Repeated_Substring_Pattern;
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
      for K in S'Range loop
         R (First + K - S'First) := S (K);
      end loop;
      return R;
   end To_Text;

   --  Reference: for every proper unit length L dividing N, build the unit
   --  repeated N / L times and compare with the input.
   function Ref (S : String) return Boolean is
      N : constant Natural := S'Length;
   begin
      for L in 1 .. N - 1 loop
         if N mod L = 0 then
            declare
               Unit  : constant String := S (S'First .. S'First + L - 1);
               Built : String (1 .. N);
            begin
               for R in 0 .. N / L - 1 loop
                  Built (R * L + 1 .. R * L + L) := Unit;
               end loop;
               if Built = S then
                  return True;
               end if;
            end;
         end if;
      end loop;
      return False;
   end Ref;

   procedure Compare (S : String) is
   begin
      Check (Is_Repeated (To_Text (S)) = Ref (S), "'" & S & "'");
      --  Same text at a non-1 lower bound
      Check (Is_Repeated (To_Text (S, 7)) = Ref (S), "'" & S & "' at First 7");
   end Compare;

   --  All strings of length N over the first K letters
   procedure Exhaustive (N, K : Natural) is
      S : String (1 .. N) := [others => 'a'];
      Done : Boolean := False;
   begin
      loop
         Compare (S);
         Done := True;
         for P in reverse S'Range loop
            if S (P) < Character'Val (Character'Pos ('a') + K - 1) then
               S (P) := Character'Succ (S (P));
               S (P + 1 .. N) := [others => 'a'];
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
   Check (Is_Repeated (To_Text ("aaaaaa")), "aaaaaa");
   Check (Is_Repeated (To_Text ("ababab")), "ababab");
   Check (Is_Repeated (To_Text ("abcabc")), "abcabc");
   Check (not Is_Repeated (To_Text ("abcdef")), "abcdef");
   Check (Is_Repeated (To_Text ("aabaab")), "aabaab");
   Check (not Is_Repeated (To_Text ("abcabd")), "abcabd");
   Check (not Is_Repeated (To_Text ("abaaaa")), "abaaaa");
   Check (not Is_Repeated (To_Text ("ababaa")), "ababaa");
   Check (not Is_Repeated (To_Text ("")), "empty");
   Check (not Is_Repeated (To_Text ("a")), "a");
   Check (Is_Repeated (To_Text ("zz")), "zz");
   Check (not Is_Repeated (To_Text ("abaab")), "abaab (period 3, length 5)");
   Check (not Is_Repeated (To_Text ("abcab")), "abcab");
   Check (Is_Repeated (To_Text ("xyzxyzxyzxyz")), "xyz x4");
   Check (Is_Repeated (To_Text ("abcde" & "abcde" & "abcde" & "abcde" & "abcde", 3)), "abcde x5 at First 3");

   --  Exhaustive small cases: {a,b} up to length 12, {a,b,c} up to length 8
   for N in 0 .. 12 loop
      Exhaustive (N, 2);
   end loop;
   for N in 0 .. 8 loop
      Exhaustive (N, 3);
   end loop;

   --  Seeded random (seed 20261009): 20,000 texts up to length 60; half are
   --  built by repeating a random unit, so True cases are common
   for K in 1 .. 20_000 loop
      declare
         N : constant Natural := Next (61);
         S : String (1 .. N) := [others => 'a'];
      begin
         if K mod 2 = 0 and then N > 1 then
            declare
               L : constant Positive := 1 + Next (N);
            begin
               for P in 1 .. N loop
                  S (P) := (if P <= L then Character'Val (97 + Next (3)) else S (P - L));
               end loop;
               if Next (4) = 0 then
                  S (1 + Next (N)) := 'd';
               end if;
            end;
         else
            for P in 1 .. N loop
               S (P) := Character'Val (97 + Next (2));
            end loop;
         end if;
         Compare (S);
      end;
   end loop;

   if Fails = 0 then
      Put_Line ("PASS Ada-SPARK-Repeated-Substring-Pattern");
   else
      Put_Line ("FAILED" & Fails'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
