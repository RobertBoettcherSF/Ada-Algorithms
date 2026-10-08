--  Own checks (see tests/SOURCES.txt). Assume Unicode_Collation is wrong or
--  does nothing; compare it with a reference that uses a different method:
--  UCA sort keys (the nonzero primary weights, a 0 separator, the nonzero
--  secondary weights, a 0 separator, the nonzero tertiary weights) compared
--  lexicographically, instead of the level-by-level comparison in the body.
--  All pairs of strings over {a, A, b, 1, -, space} of length 0 .. 3, with
--  the default table, the punctuation-ignoring variant and a tailored table.
pragma Ada_2022;
with Ada.Text_IO;
with Unicode_Collation; use Unicode_Collation;

procedure Own_Checks is
   Alpha : constant String := "aAb1- ";
   subtype Str_Index is Natural range 0 .. 258;  --  1 + 6 + 36 + 216 strings
   Checked : Natural := 0;

   type Key is array (Positive range <>) of Natural;

   function Nth (K : Str_Index) return String is
      Len  : Natural := 0;
      Base : Natural := 0;
      Size : Natural := 1;
   begin
      while K >= Base + Size loop
         Base := Base + Size;
         Size := Size * Alpha'Length;
         Len  := Len + 1;
      end loop;
      declare
         R : String (1 .. Len);
         V : Natural := K - Base;
      begin
         for I in reverse R'Range loop
            R (I) := Alpha (Alpha'First + V mod Alpha'Length);
            V := V / Alpha'Length;
         end loop;
         return R;
      end;
   end Nth;

   function Sort_Key (S : String; T : Character_Table) return Key is
      K : Key (1 .. 3 * S'Length + 2);
      N : Natural := 0;
      procedure Put (W : Weight_Level) is
      begin
         if W /= 0 then N := N + 1; K (N) := Natural (W); end if;
      end Put;
   begin
      for C of S loop Put (T (C).Primary); end loop;
      N := N + 1; K (N) := 0;
      for C of S loop Put (T (C).Secondary); end loop;
      N := N + 1; K (N) := 0;
      for C of S loop Put (T (C).Tertiary); end loop;
      return K (1 .. N);
   end Sort_Key;

   function Ref_Compare (A, B : String; T : Character_Table) return Collation_Result is
      KA : constant Key := Sort_Key (A, T);
      KB : constant Key := Sort_Key (B, T);
   begin
      for I in 1 .. Natural'Min (KA'Length, KB'Length) loop
         if KA (I) < KB (I) then return Less; end if;
         if KA (I) > KB (I) then return Greater; end if;
      end loop;
      return (if KA'Length < KB'Length then Less
              elsif KA'Length > KB'Length then Greater else Equal);
   end Ref_Compare;

   procedure Fail (What, A, B : String; Got, Want : Collation_Result) is
   begin
      Ada.Text_IO.Put_Line ("FAIL own check: " & What & " (""" & A & """, """ & B
                            & """) gave " & Got'Image & ", sort-key reference " & Want'Image);
      raise Program_Error;
   end Fail;

   Default : constant Character_Table := Get_Default_Table;
   No_Punct : Character_Table := Default;
   Tailored : constant Character_Table :=
     Apply_Tailoring (Default, 'b', (Primary => 5, Secondary => 20, Tertiary => 2));  --  b before digits
begin
   --  the punctuation-ignoring variant documents punctuation as weight 0 at all levels
   No_Punct ('-') := (0, 0, 0);
   No_Punct (' ') := (0, 0, 0);
   No_Punct (',') := (0, 0, 0);
   for C in Character loop
      if Tailored (C) /= (if C = 'b' then (5, 20, 2) else Default (C)) then
         Ada.Text_IO.Put_Line ("FAIL own check: Apply_Tailoring changed entry " & C'Image);
         raise Program_Error;
      end if;
   end loop;
   for KA in Str_Index loop
      for KB in Str_Index loop
         declare
            A : constant String := Nth (KA);
            B : constant String := Nth (KB);
         begin
            if Compare_Standard (A, B, Default) /= Ref_Compare (A, B, Default) then
               Fail ("Compare_Standard", A, B, Compare_Standard (A, B, Default), Ref_Compare (A, B, Default));
            end if;
            if Compare_Ignore_Punctuation (A, B, Default) /= Ref_Compare (A, B, No_Punct) then
               Fail ("Compare_Ignore_Punctuation", A, B,
                     Compare_Ignore_Punctuation (A, B, Default), Ref_Compare (A, B, No_Punct));
            end if;
            if Compare_Standard (A, B, Tailored) /= Ref_Compare (A, B, Tailored) then
               Fail ("Compare_Standard (tailored)", A, B,
                     Compare_Standard (A, B, Tailored), Ref_Compare (A, B, Tailored));
            end if;
            Checked := Checked + 1;
         end;
      end loop;
   end loop;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
                         & " string pairs x 3 tables (UCA sort-key reference)");
end Own_Checks;
