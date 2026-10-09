pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Reference: a different algorithm --
--  points sorted by X (insertion sort), then for each point only the
--  following points whose X gap squared is still below the best distance
--  are tried (the strip sweep). Also checked: the answer does not change
--  when the points are shifted or listed in reverse order.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Closest_Pair_Brute; use Closest_Pair_Brute;

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
      Name : constant String := "Closest-Pair-Brute";
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

   subtype LL is Long_Long_Integer;

   function Sweep (P : Point_Array; N : Count) return LL is
      S    : Point_Array := P;
      Best : LL := LL'Last;
   begin
      for I in 2 .. N loop
         declare
            X : constant Point := S (I);
            J : Natural := I - 1;
         begin
            while J >= 1 and then S (J).X > X.X loop
               S (J + 1) := S (J);
               J := J - 1;
            end loop;
            S (J + 1) := X;
         end;
      end loop;
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            declare
               DX : constant LL := LL (S (J).X - S (I).X);
               DY : constant LL := LL (S (J).Y - S (I).Y);
            begin
               exit when DX * DX >= Best;
               Best := LL'Min (Best, DX * DX + DY * DY);
            end;
         end loop;
      end loop;
      return Best;
   end Sweep;

   P, Q : Point_Array;
begin
   for Rep in 1 .. 60_000 loop
      declare
         N    : constant Count := 1 + Next mod Max_Points;
         Span : constant Positive := (case Next mod 4 is
                                        when 0 => 3, when 1 => 20,
                                        when 2 => 300, when others => 2001);
         Lo   : constant Integer := -1000 + Next mod (2002 - Span);
         Want : LL;
      begin
         for I in Index loop
            P (I) := (X => Lo + Next mod Span, Y => Lo + Next mod Span);
         end loop;
         Want := Sweep (P, N);
         Report (Find (P, N) = Want, "random N =" & N'Image & " span" & Span'Image);
         --  Reversed order of the first N points.
         Q := P;
         for I in 1 .. N loop
            Q (I) := P (N + 1 - I);
         end loop;
         Report (Find (Q, N) = Want, "reversed N =" & N'Image);
         --  Shifted so the points touch the coordinate limits.
         declare
            Min_X, Min_Y : Integer := 1000;
         begin
            for I in 1 .. N loop
               Min_X := Integer'Min (Min_X, P (I).X);
               Min_Y := Integer'Min (Min_Y, P (I).Y);
            end loop;
            Q := P;
            for I in 1 .. N loop
               Q (I) := (X => P (I).X - Min_X - 1000, Y => P (I).Y - Min_Y - 1000);
            end loop;
            Report (Find (Q, N) = Want, "shifted N =" & N'Image);
         end;
         --  Distance_Squared against the coordinate formula.
         declare
            A : constant Point := P (1 + Next mod Max_Points);
            B : constant Point := P (1 + Next mod Max_Points);
         begin
            Report (Distance_Squared (A, B)
                      = (LL (A.X) - LL (B.X)) ** 2 + (LL (A.Y) - LL (B.Y)) ** 2,
                    "Distance_Squared");
         end;
      end;
   end loop;
   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
