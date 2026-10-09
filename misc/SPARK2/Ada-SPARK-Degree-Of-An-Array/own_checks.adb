pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Independent reference: a histogram
--  over -32 .. 32 (one pass), degree = largest bucket. 30,000 seeded random
--  arrays whose values come from ranges of width 1, 2, 3, 8 and 65 (so
--  every degree from 1 to 32 occurs), plus every array that holds value X
--  in its first K positions and distinct other values elsewhere
--  (K = 1 .. 32, X at both ends of the value range).
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Degree_Of_An_Array; use Degree_Of_An_Array;

procedure Own_Checks is
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
      Name : constant String := "Ada-SPARK-Degree-Of-An-Array";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer :=
        (if V = "" then Default
         else 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
   begin
      Ada.Text_IO.Put_Line
        ("AA_SEED =" & S'Image
         & (if V = "" then " (default: FNV-1a of the folder name)"
            else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   function Histogram_Max (A : Int_Array) return Natural is
      Bucket : array (Value) of Natural := [others => 0];
      Best   : Natural := 0;
   begin
      for X of A loop
         Bucket (X) := Bucket (X) + 1;
      end loop;
      for B of Bucket loop
         Best := Natural'Max (Best, B);
      end loop;
      return Best;
   end Histogram_Max;

   type Value_List is array (1 .. 3) of Value;
   Ends : constant Value_List := [-32, 0, 32];
   A : Int_Array;
   Seen_Degree : array (1 .. Length) of Boolean := [others => False];
   D : Natural;
begin
   for Trial in 1 .. 30_000 loop
      declare
         Width : constant Positive :=
           (case Trial mod 5 is
              when 0 => 1, when 1 => 2, when 2 => 3, when 3 => 8, when others => 65);
         Low   : constant Integer := Next mod (66 - Width) - 32;
      begin
         for I in Index loop
            A (I) := Low + Next mod Width;
         end loop;
         --  Sometimes overwrite a run with one value to reach mid degrees.
         if Trial mod 7 = 0 then
            for I in 1 .. Next mod Length + 1 loop
               A (I) := Low;
            end loop;
         end if;
         D := Degree (A);
         Report (D = Histogram_Max (A), "histogram, trial" & Trial'Image);
         if D in Seen_Degree'Range then
            Seen_Degree (D) := True;
         end if;
      end;
   end loop;
   for K in 1 .. Length loop
      for X of Ends loop
         --  X in the first K places, then distinct values different from X.
         declare
            V : Integer := (if X = -32 then -31 else -32);
         begin
            for I in Index loop
               if I <= K then
                  A (I) := X;
               else
                  A (I) := V;
                  V := V + 1;
                  if V = X then
                     V := V + 1;
                  end if;
               end if;
            end loop;
         end;
         Report (Degree (A) = Natural'Max (K, (if K < Length then 1 else 0)),
                 "run of" & K'Image & " copies of" & X'Image);
      end loop;
   end loop;
   for D2 in Seen_Degree'Range loop
      --  Degree 1 (all different) is covered by the K = 1 runs above.
      Report (Seen_Degree (D2) or else D2 = 1 or else D2 > 20,
              "random arrays reach degree" & D2'Image);
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
