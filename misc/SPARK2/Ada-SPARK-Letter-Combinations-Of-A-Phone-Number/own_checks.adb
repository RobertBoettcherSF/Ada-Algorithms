pragma Ada_2022;
--  Own checks for Letter_Combinations_Of_A_Phone_Number (see
--  tests/SOURCES.txt). No expected value comes from the program:
--  * an own keypad written as letter strings, and an own recursive
--    enumeration of every spelling in dictionary order, compared with
--    Count and every Combination (N, K) for all numbers of up to 3 digits;
--  * on seeded random numbers of up to 15 digits: Count against the product
--    of the own key lengths, and for random K: every letter on its key,
--    the own left-to-right rank of the result equals K, and
--    Combination (N, K) < Combination (N, K + 1) in dictionary order;
--  * the ghost Pow4_Table regenerated, and the ghost Suffix_Count / Rank
--    compared with the own values.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Letter_Combinations_Of_A_Phone_Number; use Letter_Combinations_Of_A_Phone_Number;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Letter-Combinations-Of-A-Phone-Number";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer := (if V = "" then Default else Long_Long_Integer'Value (V));
   begin
      Ada.Text_IO.Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default: FNV-1a of the folder name)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   --  The own keypad.
   function Key (D : Character) return String is
     (case D is
        when '2' => "abc", when '3' => "def", when '4' => "ghi", when '5' => "jkl",
        when '6' => "mno", when '7' => "pqrs", when '8' => "tuv", when '9' => "wxyz",
        when others => "");

   function Own_Count (N : String) return Long_Long_Integer is
      C : Long_Long_Integer := 1;
   begin
      for D of N loop
         C := C * Long_Long_Integer (Key (D)'Length);
      end loop;
      return C;
   end Own_Count;

   --  Left-to-right rank: Horner over the letter indices on each key.
   function Own_Rank (N, S : String) return Long_Long_Integer is
      R : Long_Long_Integer := 0;
   begin
      for I in N'Range loop
         declare
            K   : constant String := Key (N (I));
            Pos : Integer := -1;
         begin
            for P in K'Range loop
               if K (P) = S (I) then
                  Pos := P - K'First;
               end if;
            end loop;
            if Pos < 0 then
               return -1;
            end if;
            R := R * Long_Long_Integer (K'Length) + Long_Long_Integer (Pos);
         end;
      end loop;
      return R;
   end Own_Rank;

   function Img (N : String; K : Natural) return String is ("""" & N & """," & K'Image);

   --  1. Exhaustive: every number of 0 .. 3 digits, every spelling.
   Digits_Of : constant String := "23456789";
   procedure Exhaustive (N : String) is
      Index : Natural := 0;
      Buf   : String (1 .. N'Length);
      procedure Spell (I : Positive) is
      begin
         if I > N'Length then
            Report (Combination (N, Index) = Buf, "enumeration" & Img (N, Index));
            Index := Index + 1;
         else
            for C of Key (N (I)) loop
               Buf (I) := C;
               Spell (I + 1);
            end loop;
         end if;
      end Spell;
   begin
      Report (Long_Long_Integer (Count (N)) = Own_Count (N), "count """ & N & """");
      Spell (1);
      Report (Long_Long_Integer (Index) = Own_Count (N), "enumeration size """ & N & """");
      pragma Assert (Suffix_Count (N, 1) = Own_Count (N));
   end Exhaustive;

   procedure All_Numbers (Prefix : String; Left : Natural) is
   begin
      Exhaustive (Prefix);
      if Left > 0 then
         for D of Digits_Of loop
            All_Numbers (Prefix & D, Left - 1);
         end loop;
      end if;
   end All_Numbers;
begin
   All_Numbers ("", 3);

   --  2. Random numbers of up to 15 digits.
   for T in 1 .. 300 loop
      declare
         Len : constant Natural := Next mod 16;
         N   : String (1 .. Len);
      begin
         for I in N'Range loop
            N (I) := Digits_Of (1 + Next mod 8);
         end loop;
         declare
            C : constant Long_Long_Integer := Own_Count (N);
         begin
            Report (Long_Long_Integer (Count (N)) = C, "count """ & N & """");
            for R in 1 .. 5 loop
               declare
                  K : constant Natural := Natural (Long_Long_Integer (Next) mod C);
                  S : constant String := Combination (N, K);
               begin
                  Report (S'First = 1 and then S'Length = Len, "shape" & Img (N, K));
                  Report (Own_Rank (N, S) = Long_Long_Integer (K), "own rank" & Img (N, K));
                  pragma Assert (Rank (N, S, 1) = Long_Long_Integer (K));
                  if Long_Long_Integer (K) + 1 < C then
                     Report (S < Combination (N, K + 1), "dictionary order" & Img (N, K));
                  end if;
               end;
            end loop;
            --  The last spelling is the last letter of every key.
            declare
               S : constant String := Combination (N, Natural (C - 1));
               Ok : Boolean := True;
            begin
               for I in N'Range loop
                  Ok := Ok and then S (I) = Key (N (I)) (Key (N (I))'Last);
               end loop;
               Report (Ok, "last spelling """ & N & """");
            end;
         end;
      end;
   end loop;

   --  3. The ghost table: 4 ** N regenerated.
   declare
      P : Long_Long_Integer := 1;
   begin
      for N in 0 .. Max_Digits loop
         pragma Assert (Pow4_Table (N) = P);
         Checked := Checked + 1;
         P := P * 4;
      end loop;
      Report (P > Long_Long_Integer (Natural'Last), "4 ** 16 does not fit Natural");
   end;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
